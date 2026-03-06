# Sprint 011: Starbound Foraging — Progression-Linked Foraging & Grove Expansion

## Overview

Foraging is the only free resource path in Brew a Potion, but it has zero progression — a 100-brew veteran forages the same commons as a brand new player. Meanwhile, "stars" (`BrewStats.TotalBrewed`, visualized as the Potion Constellation) are purely cosmetic. This creates two problems: the Wild Grove becomes irrelevant once players can afford market ingredients, and stars feel meaningless beyond aesthetics.

This sprint creates a **virtuous feedback loop**: more brews -> more stars -> better forage drops -> rarer ingredients -> rarer brews -> more stars. The system has two pillars: (1) **Star-Scaled Forage Tables** that shift regular node drops from pure commons toward uncommon/rare ingredients as stars increase, and (2) **Grove Expansion** via 3 new sub-zones that unlock at star thresholds, each with 2 dedicated forage nodes offering richer loot pools.

The design is generous-at-zero, rewarding-at-scale. A 0-star player gets useful commons. A 50-star player finds uncommons regularly and unlocks the Shadow Hollow with rare-quality ingredients. A 100-star Archmage has meaningful rare chances from regular nodes. The grove becomes a permanent destination, not a beginner zone you outgrow.

## Scope Anchors (Non-Negotiable)

1. Regular forage nodes use star-scaled probability tables — higher stars = higher chance of uncommon/rare drops.
2. Existing 12 forage nodes continue working for all players (backward compatible). 0-star players receive commons only from regular nodes.
3. 3 new grove sub-zones unlock at star thresholds (10, 25, 50), each with 2 new forage nodes (18 total).
4. Sub-zone access is server-authoritative: star threshold validated on every forage attempt.
5. Rare forage node spawn system enhanced: triggering player's star count influences rare-vs-uncommon split.
6. All forage outcomes computed server-side using player's `BrewStats.TotalBrewed`.
7. Shared config `ForageTuning.lua` is single source of truth for all forage probability tables.
8. Node ID validation is strict — only whitelisted node IDs are accepted.

## Use Cases

1. **New player (0 stars) forages**: Visits WildGrove, finds 12 base nodes. Each gives a common ingredient from its pool. Sees 3 locked sub-zone entrances (dim, misty barriers) with labels: "Starlight Glade — 10 Stars Required."
2. **Player reaches 10 stars**: Notification: "The Starlight Glade has opened in the Wild Grove!" Barrier dissolves. 2 new uncommon-weighted nodes accessible. Base nodes now have ~15% uncommon chance.
3. **Player at 25 stars**: Moonwell Spring unlocks (2 more nodes, water/light themed). Base nodes: ~28% uncommon, ~2% rare.
4. **Player at 50 stars**: Shadow Hollow unlocks (2 more nodes, shadow/fire themed with mixed uncommon/rare pools). Base nodes: ~38% uncommon, ~7% rare. Rare forage spawns shift from 30% to ~50% rare.
5. **Player at 100+ stars (Archmage)**: Full grove access. Base nodes: ~45% uncommon, ~10% rare. Rare forage spawns at 60% rare. Forage Power HUD shows "Archmage Forager."
6. **Rare node spawn**: Uses the triggering player's star count (not server-wide max) to scale rare-vs-uncommon probability.
7. **Player in WildGrove**: HUD shows "Forage Power" badge with tier name and drop bonus percentage.

## Architecture

### Star-to-Forage Probability Mapping

Aligned with `BrewTuning.EvolutionTiers`:

| Star Tier | Stars | Common | Uncommon | Rare |
|-----------|-------|--------|----------|------|
| 0 (Apprentice) | 0-9 | 100% | 0% | 0% |
| 1 (Adept) | 10-24 | 85% | 15% | 0% |
| 2 (Alchemist) | 25-49 | 70% | 28% | 2% |
| 3 (Master) | 50-99 | 55% | 38% | 7% |
| 4 (Archmage) | 100+ | 45% | 45% | 10% |

### Regular Node Drop Resolution (Server-Side)

```
ZoneService.resolveForageDrop(player, nodeId):
  1. Validate nodeId against whitelist (reject unknown IDs)
  2. Get player's BrewStats.TotalBrewed (= star count)
  3. Look up tier in ForageTuning.StarTiers
  4. If sub-zone node: validate stars >= zone threshold (reject if insufficient)
  5. Roll random() against tier's Common/Uncommon/Rare weights
  6. If Common: pick from node's common pool
  7. If Uncommon: pick from ForageTuning.UncommonForagePool
  8. If Rare: pick from ForageTuning.RareForagePool
  9. Fallback: if rolled tier has no valid pool for this node, fall back to Common
  10. Return ingredientId
```

### Node Pool Rarity Separation

Base node pools are split by rarity. Existing pools that contain uncommons (e.g., `glowshroom_cap` in node 7) are reclassified:

```
ForageNode_7:
  common: [mushroom, willow_bark]
  uncommon: [glowshroom_cap]

At Tier 0: only common pool rolls
At Tier 1+: uncommon pool becomes accessible via star-weighted roll
```

### Grove Expansion Zones

```
Base Grove (175x175):     12 nodes (ForageNode_1..12)  — always accessible
Starlight Glade (10 ★):  2 nodes  (ForageNode_13..14) — NE alcove
Moonwell Spring (25 ★):  2 nodes  (ForageNode_15..16) — NW alcove
Shadow Hollow (50 ★):    2 nodes  (ForageNode_17..18) — S cave entrance
                          ────────────────────────────
Total:                    18 nodes (6 new, star-gated)
```

### Sub-Zone Node Pools (Mixed Uncommon/Rare)

```
Starlight Glade (10 ★):
  ForageNode_13: common=[mushroom, fern_leaf], uncommon=[moonpetal, glowshroom_cap, sunstone_chip]
  ForageNode_14: common=[river_water, rainwater], uncommon=[crystal_dust, dewdrop_pearl, frost_bloom]

Moonwell Spring (25 ★):
  ForageNode_15: common=[dandelion_puff, mint_sprig], uncommon=[pixie_wing, mermaid_scale, wind_whistle_reed]
  ForageNode_16: common=[cobweb_strand, willow_bark], uncommon=[thundermoss, shadow_vine, nightshade_berry]

Shadow Hollow (50 ★):
  ForageNode_17: common=[charcoal_chunk], uncommon=[ember_root, sulfur_nugget], rare=[dragon_scale, phoenix_feather]
  ForageNode_18: common=[snail_slime], uncommon=[iron_filings, nightshade_berry], rare=[void_essence, ghost_orchid, frozen_amber]
```

Sub-zone nodes use the same star-scaled probability tables. At Tier 3 (50+ stars, required to access Shadow Hollow), players rolling "Rare" from those nodes get actual rare-tier ingredients.

### Rare Node Spawn Enhancement

```
Current: math.random() < 0.30 -> Rare pool, else -> Uncommon pool

Enhanced (per triggering player):
  playerStars = triggerPlayer's BrewStats.TotalBrewed
  tier = ForageTuning.getTierForStars(playerStars)
  rareChance = ForageTuning.RareNodeChanceByTier[tier]

  Tier 0: 30%  (unchanged)
  Tier 1: 35%
  Tier 2: 40%
  Tier 3: 50%
  Tier 4: 60%  (capped)
```

### Forage Power HUD Badge

When player is in WildGrove, a small HUD badge appears:

```
┌─────────────────────┐
│ ★ Alchemist Forager │
│   +28% Uncommon     │
└─────────────────────┘
```

- Shows current forage tier name + primary bonus stat
- Fades in when entering WildGrove, fades out when leaving
- Updates on PlayerDataUpdate if tier changes

### Data Flow

```
Player brews potion -> BrewStats.TotalBrewed increments
                    -> Stars increase (ShopRealmController visual)
                    -> Forage probability table shifts (ForageTuning lookup)
                    -> Sub-zones unlock at thresholds (GroveExpansionController)
                    -> Better forage drops -> rarer brews -> cycle continues
```

## Implementation Plan

### Phase 1: ForageTuning Config (~10%)

**Files:**
- `src/shared/Config/ForageTuning.lua` — Create
- `default.project.json` — Register

**Tasks:**
- [ ] Create `ForageTuning.lua` with:
  - `StarTiers` table: star thresholds -> {commonWeight, uncommonWeight, rareWeight, tierName}
  - `getTierForStars(starCount)` — returns tier data
  - `rollForageTier(starCount)` — weighted random, returns "Common"/"Uncommon"/"Rare"
  - `UncommonForagePool`: curated list of uncommon ingredient IDs safe for foraging
  - `RareForagePool`: curated list of rare ingredient IDs safe for foraging
  - `SubZones` table: {threshold, nodeIds, name, position hints}
  - `RareNodeChanceByTier`: per-tier rare chance for timed rare node spawns
  - `NodeWhitelist`: set of all valid node IDs (1-18)
  - `isNodeUnlocked(nodeId, starCount)` — returns bool
- [ ] Register in `default.project.json` under `ReplicatedStorage.Shared.Config.ForageTuning`

### Phase 2: Server-Side Forage Enhancement (~25%)

**Files:**
- `src/server/Services/ZoneService.lua` — Major modify

**Tasks:**
- [ ] Import ForageTuning config
- [ ] Add strict node ID validation at top of ForageNode handler (reject unknown IDs)
- [ ] Modify regular forage handler:
  - Get player's TotalBrewed from PlayerDataService
  - Call `ForageTuning.rollForageTier(stars)` to determine drop tier
  - If Common: use node's common pool
  - If Uncommon: use node's uncommon pool if exists, else ForageTuning.UncommonForagePool
  - If Rare: use node's rare pool if exists, else ForageTuning.RareForagePool
  - Fallback: if rolled pool is empty, fall back to common
- [ ] Split existing `nodePools` into rarity-bucketed format:
  - Separate existing uncommon ingredients from common pools (nodes 6-12)
- [ ] Add sub-zone node validation:
  - ForageNode_13..18: check `ForageTuning.isNodeUnlocked(nodeId, stars)` before granting
  - If locked: silently reject (client shouldn't show prompt, but server validates anyway)
- [ ] Add sub-zone node pools (13..18) to `nodePools` table
- [ ] Enhance rare node spawn:
  - On ProximityPrompt trigger: use triggering player's star count
  - Replace `math.random() < 0.30` with `math.random() < ForageTuning.RareNodeChanceByTier[tier]`
- [ ] Add structured debug logging: `[ZoneService] player=X stars=Y tier=Z rolled=Uncommon ingredient=moonpetal node=ForageNode_7`

### Phase 3: Sub-Zone World Building (~20%)

**Files:**
- Workspace via MCP run_code — Create 3 sub-zone areas + 6 new forage nodes

**Tasks:**
- [ ] **Starlight Glade** (NE corner of WildGrove, approx X=-90, Z=-70):
  - Small clearing with bioluminescent flowers and starlight crystal formations
  - 2 forage nodes (ForageNode_13, ForageNode_14) with ProximityPrompts
  - Entrance arch with "Starlight Glade" BillboardGui label
  - Locked barrier: semi-transparent ForceField-material wall (Transparency 0.5)
  - Lock label: "10 Stars Required" BillboardGui
- [ ] **Moonwell Spring** (NW corner, approx X=-190, Z=-50):
  - Enchanted pool clearing with moonlit water features
  - 2 forage nodes (ForageNode_15, ForageNode_16) with ProximityPrompts
  - Entrance arch + locked barrier + label
- [ ] **Shadow Hollow** (S edge, approx X=-130, Z=70):
  - Dark cave entrance with purple crystal lighting
  - 2 forage nodes (ForageNode_17, ForageNode_18) with ProximityPrompts
  - Entrance arch + locked barrier + label
- [ ] All new nodes: ProximityPrompt with ActionText="Forage", MaxActivationDistance=10, RequiresLineOfSight=false
- [ ] Verify all 6 new nodes within WildGrove 175x175 bounds (center approx -140, 0, 0)

### Phase 4: Client-Side Grove Expansion Controller + Forage Power HUD (~20%)

**Files:**
- `src/client/GroveExpansionController.client.lua` — Create
- `default.project.json` — Register

**Tasks:**
- [ ] Create `GroveExpansionController.client.lua`:
  - On `PlayerDataUpdate`, read `BrewStats.TotalBrewed`
  - For each sub-zone in `ForageTuning.SubZones`:
    - Find barrier and nodes in workspace WildGrove
    - If stars >= threshold: fade out barrier (TweenService), enable ProximityPrompts on nodes
    - If stars < threshold: show barrier, disable ProximityPrompts, show lock label
  - On threshold crossing (first time stars pass a gate):
    - Play particle burst on barrier location
    - Fire notification: "The [Zone Name] has opened in the Wild Grove!"
    - Barrier dissolves with TweenService animation
  - On initial load: set all zones to correct state without animation
- [ ] **Forage Power HUD badge**:
  - Create small frame in HudGui (or FeedbackGui)
  - Show when player is in WildGrove zone (detect via position polling, reuse FeedbackController zone check pattern)
  - Display: star icon + tier name + primary bonus (e.g., "+28% Uncommon")
  - Update on PlayerDataUpdate
  - Fade in/out on zone enter/leave
- [ ] **ForageNodeFeedback compatibility**:
  - Locked nodes: skip pulse animation (check Transparency > 0.5 or prompt disabled)
  - Unlocked nodes: existing behavior unchanged
- [ ] Register in `default.project.json` under StarterPlayerScripts

### Phase 5: Rojo Registration + Integration (~5%)

**Files:**
- `default.project.json` — Add ForageTuning + GroveExpansionController

**Tasks:**
- [ ] Add `ForageTuning` to Rojo config under `ReplicatedStorage.Shared.Config`
- [ ] Add `GroveExpansionController` to Rojo config under `StarterPlayerScripts`
- [ ] Verify ForageTuning is accessible from both server (ZoneService) and client (GroveExpansionController)

### Phase 6: Testing + Verification (~20%)

**Tasks:**
- [ ] **Probability validation**: Run 5000+ simulated rolls per star tier, verify distributions within 2% tolerance of configured weights
- [ ] **0-star test**: New player forages all 12 base nodes -> only common ingredients (verify node pools correctly separated)
- [ ] **Tier 1 test**: Player at 15 stars forages 50+ times -> uncommons appear at ~15% rate
- [ ] **Sub-zone gate test**: Player at 5 stars -> cannot interact with Starlight Glade nodes (prompt disabled + server rejects)
- [ ] **Sub-zone unlock test**: Player reaches 10 stars -> barrier fades, nodes accessible, notification shown
- [ ] **Sub-zone loot test**: Starlight Glade nodes drop uncommon ingredients via star-weighted tables
- [ ] **Shadow Hollow test**: Player at 50+ stars -> rare ingredients possible from Shadow Hollow nodes
- [ ] **Rare node enhancement test**: Player with 100 stars triggers rare node -> ~60% chance of rare-tier drop
- [ ] **Node ID security test**: Send spoofed nodeId "ForageNode_99" -> server rejects, no ingredient granted
- [ ] **Per-player isolation test**: Two players with different stars forage same node -> different tier outcomes
- [ ] **Forage Power HUD test**: Badge appears in WildGrove, disappears in other zones, updates on brew
- [ ] **ForageNodeFeedback test**: Locked nodes don't pulse; unlocked nodes pulse normally
- [ ] **Backward compatibility**: 12 base nodes work for all players, cooldowns enforced
- [ ] **Regression**: Market buy, brew/claim, sell, mutations, daily demand, rare node spawning all unchanged

## Files Summary

| File | Action | Purpose |
|------|--------|---------|
| `src/shared/Config/ForageTuning.lua` | Create | Star tiers, probability tables, sub-zone definitions, node pools, helpers |
| `src/server/Services/ZoneService.lua` | Major modify | Star-scaled drops, node ID validation, sub-zone gating, rare node enhancement |
| `src/client/GroveExpansionController.client.lua` | Create | Sub-zone unlock visuals, barriers, Forage Power HUD badge |
| `default.project.json` | Modify | Register ForageTuning + GroveExpansionController |
| Workspace (MCP) | Create | 3 sub-zones with 6 forage nodes + barriers + labels |

## Definition of Done

- [ ] Regular forage nodes drop uncommon/rare ingredients scaled by `BrewStats.TotalBrewed`
- [ ] 0-star players receive ONLY commons from regular nodes (pools correctly separated by rarity)
- [ ] 3 sub-zones exist in WildGrove with 2 forage nodes each (6 new, 18 total)
- [ ] Sub-zones locked behind star thresholds (10, 25, 50) — validated server-side
- [ ] Locked sub-zones show dim barriers with star requirement labels
- [ ] Sub-zone unlock plays dissolve animation + notification on threshold crossing
- [ ] Sub-zone nodes have mixed uncommon/rare loot pools (not pure rare)
- [ ] Rare forage node rare-vs-uncommon split scales by triggering player's stars (not server max)
- [ ] All node IDs strictly validated against whitelist — unknown IDs rejected
- [ ] ForageTuning.lua is single source of truth for all forage probabilities and thresholds
- [ ] Forage Power HUD badge shows tier name + bonus when in WildGrove
- [ ] All 18 forage nodes have ProximityPrompts and server-enforced 60s cooldowns
- [ ] Probability distributions verified via 5000+ roll sampling per tier
- [ ] No gameplay regression (market, brewing, selling, mutations, daily demand)

## Risks & Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Sub-zone coordinates outside WildGrove bounds | Medium | High | Verify against 175x175 grove dimensions; test node positions |
| Base node pool reclassification breaks existing drops | Medium | High | Keep all current ingredients accessible; only change which tier bucket they're in |
| Rare drops too generous, devaluing market | Medium | Medium | Conservative caps (10% max rare from regular nodes), mixed sub-zone pools |
| Sub-zone unlock desync (client vs server) | Low | High | Server validates on every forage; client barriers are cosmetic |
| ForageNodeFeedback breaks on locked nodes | Medium | Medium | Skip pulse for nodes with disabled prompts |
| New nodes missing ProximityPrompts after MCP build | Medium | High | Audit script after world build; explicit prompt verification test |
| Node pool empty for rolled tier | Low | Medium | Fallback to common pool with warning log |

## Security Considerations

- All forage outcomes remain server-authoritative — client never submits rarity or ingredient
- Sub-zone access validated server-side on every forage request (client barriers are UX only)
- Strict node ID whitelist prevents spoofed node farming
- Star count read from authoritative PlayerData, not client-supplied
- Rate limiting preserved (60s cooldown per node, server-enforced)
- No new remote endpoints (uses existing ForageNode event + PlayerDataUpdate)

## Dependencies

- Sprint 008 WildGrove layout (175x175 with 12 base nodes)
- Sprint 010 progression infrastructure (BrewStats.TotalBrewed tracking)
- BrewTuning.EvolutionTiers (threshold alignment)
- Ingredients.lua (uncommon/rare ingredient pools)
- PlayerDataService stack inventory + notification flow
