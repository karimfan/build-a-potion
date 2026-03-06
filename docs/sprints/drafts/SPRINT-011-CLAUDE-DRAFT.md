# Sprint 011: Starbound Foraging — Progression-Linked Foraging & Grove Expansion

## Overview

Foraging is the only free resource acquisition path in Brew a Potion, but it currently has zero progression — a player with 100 brews forages the same commons as a brand new player. This creates a dead-end: once players can afford market ingredients, the Wild Grove becomes irrelevant. Meanwhile, "stars" (TotalBrewed count, displayed as the Potion Constellation above the shop) are purely cosmetic with no gameplay impact beyond evolution tier visuals.

This sprint creates a **virtuous feedback loop** by linking stars to foraging power. More brews → more stars → better forage drops → rarer ingredients → rarer brews → more stars. The system has two pillars: (1) **Star-Scaled Forage Tables** that gradually shift regular node drop pools from pure commons toward uncommon/rare ingredients as star count increases, and (2) **Grove Expansion** that progressively unlocks new forage sub-zones with richer loot tables, giving high-star players new areas to explore.

The design philosophy is generous-at-zero, rewarding-at-scale. A 0-star player still gets useful commons. A 50-star player occasionally finds uncommons. A 100-star player has a meaningful chance at rares from foraging alone — ingredients that normally cost 500+ coins at the market. This makes the grove a permanent destination, not a beginner zone you outgrow.

## Scope Anchors (Non-Negotiable)

1. Regular forage nodes use star-scaled probability tables — higher stars = higher chance of uncommon/rare drops.
2. Existing 12 forage nodes continue working identically for 0-star players (backward compatible).
3. 3 new grove sub-zones unlock progressively at star thresholds (10, 25, 50 stars), each with 2 new forage nodes.
4. New sub-zones are server-authoritative: nodes only grant items if player meets star threshold.
5. Rare forage node spawn system enhanced: star count influences the rare-vs-uncommon split.
6. All forage outcomes computed server-side using player's `BrewStats.TotalBrewed`.
7. Visual feedback: unlocked sub-zones bloom/glow for qualifying players; locked zones appear dim/misty.
8. Shared config `ForageTuning.lua` is single source of truth for all forage probability tables.

## Use Cases

1. **New player (0 stars) forages**: Visits WildGrove, finds 12 base nodes. Each gives a random common ingredient from its pool. Sees 3 locked sub-zone entrances (dim, misty barriers) with labels like "Starlight Glade — 10 Stars Required."
2. **Player reaches 10 stars**: After 10th brew claim, a notification appears: "The Starlight Glade has opened in the Wild Grove!" Player visits and finds 2 new forage nodes with uncommon-weighted pools. Base nodes also now have a ~8% chance of dropping uncommons.
3. **Player at 25 stars**: Moonwell Spring unlocks (2 more nodes, water/light themed). Base nodes now have ~15% uncommon chance, ~2% rare chance.
4. **Player at 50 stars**: Shadow Hollow unlocks (2 more nodes, shadow/fire themed). Base nodes now ~22% uncommon, ~5% rare. Rare forage node spawns shift from 30% rare to 50% rare.
5. **Player at 100 stars (Archmage)**: Full grove access, base nodes have ~30% uncommon, ~8% rare. Rare forage spawns have 70% rare split. The grove is a genuinely valuable endgame resource.
6. **Rare node spawn**: System checks nearest player's star count (or highest in server) to influence rare-vs-uncommon probability on the timed spawn.

## Architecture

### Star-to-Forage Probability Mapping

```
ForageTuning.StarTiers (aligned with BrewTuning.EvolutionTiers):

Stars 0-9  (Apprentice): 100% Common, 0% Uncommon, 0% Rare
Stars 10-24 (Adept):      92% Common, 8% Uncommon, 0% Rare
Stars 25-49 (Alchemist):  83% Common, 15% Uncommon, 2% Rare
Stars 50-99 (Master):     73% Common, 22% Uncommon, 5% Rare
Stars 100+ (Archmage):    62% Common, 30% Uncommon, 8% Rare
```

### Regular Node Drop Resolution (Server-Side)

```
ZoneService.resolveForageDrop(player, nodeId):
  1. Get player's BrewStats.TotalBrewed (= star count)
  2. Look up tier in ForageTuning.StarTiers
  3. Roll random() against tier's Common/Uncommon/Rare weights
  4. If Common: pick from node's existing common pool (unchanged)
  5. If Uncommon: pick from ForageTuning.UncommonForagePool
  6. If Rare: pick from ForageTuning.RareForagePool
  7. Return ingredientId
```

### Grove Expansion Zones

```
Base Grove (175x175):    12 nodes (ForageNode_1..12)  — always accessible
Starlight Glade (10★):  2 nodes  (ForageNode_13..14) — northeast corner
Moonwell Spring (25★):  2 nodes  (ForageNode_15..16) — northwest alcove
Shadow Hollow (50★):    2 nodes  (ForageNode_17..18) — southern cave
                         ────────────────────────────
Total:                   18 nodes (6 new, gated by stars)
```

### Sub-Zone Node Pools (Richer Than Base)

```
Starlight Glade (10★):
  ForageNode_13: [moonpetal, glowshroom_cap, sunstone_chip]     (Uncommon)
  ForageNode_14: [crystal_dust, dewdrop_pearl, frost_bloom]     (Uncommon)

Moonwell Spring (25★):
  ForageNode_15: [pixie_wing, mermaid_scale, iron_filings]      (Uncommon)
  ForageNode_16: [thundermoss, shadow_vine, nightshade_berry]   (Uncommon)

Shadow Hollow (50★):
  ForageNode_17: [dragon_scale, phoenix_feather, void_essence]  (Rare — huge)
  ForageNode_18: [ghost_orchid, frozen_amber, stormglass_shard] (Rare — huge)
```

### Rare Node Spawn Enhancement

```
Current: math.random() < 0.30 → Rare, else → Uncommon
Enhanced:
  highestStars = max TotalBrewed across connected players
  baseRareChance = 0.30
  starBonus = math.min(highestStars * 0.004, 0.40) -- max +40% at 100 stars
  rareChance = math.min(baseRareChance + starBonus, 0.70) -- capped at 70%
```

### Client-Side Grove Expansion Visuals

```
GroveExpansionController (new client script):
  On PlayerDataUpdate:
    1. Read player's TotalBrewed
    2. For each sub-zone:
       - If stars >= threshold: show zone (fade in parts, enable ProximityPrompts)
       - If stars < threshold: show locked barrier (dim, misty, label with required stars)
    3. On threshold crossing: play unlock VFX (particle burst, sound, notification)
```

### Data Flow

```
Player brews potion → BrewStats.TotalBrewed increments
                     → Stars increase (visual, ShopRealmController)
                     → Forage probability table shifts (ForageTuning lookup)
                     → Sub-zones unlock at thresholds (GroveExpansionController)
                     → Better forage drops → rarer brews → cycle continues
```

## Implementation Plan

### Phase 1: ForageTuning Config (~10%)

**Files:**
- `src/shared/Config/ForageTuning.lua` — Create

**Tasks:**
- [ ] Create `ForageTuning.lua` with:
  - `StarTiers` table: star thresholds → {commonWeight, uncommonWeight, rareWeight}
  - `UncommonForagePool`: list of uncommon ingredient IDs available via forage
  - `RareForagePool`: list of rare ingredient IDs available via forage
  - `SubZones` table: threshold, nodeIds, position data, pools
  - `RareNodeStarScaling`: base chance + per-star bonus + cap
  - `getForageTier(starCount)` helper function
  - `rollForageTier(starCount)` — returns "Common", "Uncommon", or "Rare"

### Phase 2: Server-Side Forage Enhancement (~25%)

**Files:**
- `src/server/Services/ZoneService.lua` — Modify regular + rare node logic

**Tasks:**
- [ ] Import ForageTuning config
- [ ] Modify regular forage handler (ForageNode event):
  - Get player's TotalBrewed from PlayerDataService
  - Call ForageTuning.rollForageTier(stars) to determine drop tier
  - If Common: use existing node pool (unchanged behavior)
  - If Uncommon: pick random from ForageTuning.UncommonForagePool
  - If Rare: pick random from ForageTuning.RareForagePool
- [ ] Add sub-zone node validation:
  - ForageNode_13..18: check player stars >= zone threshold before granting
  - If insufficient stars: ignore forage attempt (prompt won't show client-side anyway)
- [ ] Add sub-zone node pools to `nodePools` table
- [ ] Enhance rare node spawn:
  - Calculate server-wide highest star count
  - Apply star bonus to rare-vs-uncommon split
- [ ] Add forage cooldown entries for new nodes (13..18)

### Phase 3: Sub-Zone World Building (~20%)

**Files:**
- Workspace via MCP run_code — Create 3 sub-zone areas + 6 new forage nodes

**Tasks:**
- [ ] **Starlight Glade** (NE corner, around X=-80, Z=-60):
  - Small clearing with bioluminescent flowers and starlight crystal formations
  - 2 forage nodes (ForageNode_13, ForageNode_14) with ProximityPrompts
  - Entrance arch with "Starlight Glade" BillboardGui
  - Locked barrier: semi-transparent misty wall (Transparency 0.5, ForceField material)
- [ ] **Moonwell Spring** (NW corner, around X=-200, Z=-40):
  - Enchanted pool clearing with moonlit water features
  - 2 forage nodes (ForageNode_15, ForageNode_16) with ProximityPrompts
  - Entrance arch + locked barrier
- [ ] **Shadow Hollow** (S edge, around X=-140, Z=60):
  - Dark cave entrance with purple crystal lighting
  - 2 forage nodes (ForageNode_17, ForageNode_18) with ProximityPrompts
  - Entrance arch + locked barrier
- [ ] All locked barriers: dim appearance, "X Stars Required" label
- [ ] All new nodes: ProximityPrompt with ActionText="Forage", MaxActivationDistance=10

### Phase 4: Client-Side Grove Expansion Controller (~20%)

**Files:**
- `src/client/GroveExpansionController.client.lua` — Create
- `default.project.json` — Register new client script

**Tasks:**
- [ ] Create `GroveExpansionController.client.lua`:
  - On player data update, read TotalBrewed
  - For each sub-zone in ForageTuning.SubZones:
    - Find zone barrier and nodes in workspace
    - If stars >= threshold: fade out barrier, enable node ProximityPrompts
    - If stars < threshold: show barrier, disable node ProximityPrompts, show label
  - On threshold crossing (stars just passed a gate):
    - Play unlock particle burst on the barrier location
    - Send notification: "The [Zone Name] has opened in the Wild Grove!"
    - Barrier dissolves with TweenService animation
- [ ] On initial load: set all zones to correct state (no animation, just show/hide)
- [ ] Locked zone labels show: "[Zone Name] — [X] Stars Required"

### Phase 5: Rojo Registration + Integration (~10%)

**Files:**
- `default.project.json` — Add ForageTuning + GroveExpansionController
- `src/server/Bootstrap.server.lua` — No change needed (ZoneService already registered)

**Tasks:**
- [ ] Add ForageTuning to Rojo config under ReplicatedStorage.Shared.Config
- [ ] Add GroveExpansionController to Rojo config under StarterPlayerScripts
- [ ] Verify ForageTuning is accessible from both server and client

### Phase 6: Testing + Verification (~15%)

**Tasks:**
- [ ] **0-star forage test**: New player forages all 12 base nodes → only common ingredients
- [ ] **Star probability test**: Player at 50 stars forages 20+ times → verify uncommon drops appear
- [ ] **Sub-zone gate test**: Player at 5 stars → cannot interact with Starlight Glade nodes
- [ ] **Sub-zone unlock test**: Player reaches 10 stars → Starlight Glade barrier fades, nodes accessible, notification shown
- [ ] **Sub-zone loot test**: Starlight Glade nodes drop uncommon ingredients
- [ ] **Shadow Hollow test**: Player at 50+ stars → rare ingredients from Shadow Hollow nodes
- [ ] **Rare node enhancement test**: Server with 100-star player → rare node spawns have ~70% rare chance
- [ ] **Backward compatibility**: 12 base nodes still work for all players
- [ ] **Cooldown test**: New nodes (13-18) respect 60s cooldown
- [ ] **Visual test**: Locked zones look dim/misty, unlocked zones are vivid
- [ ] **Regression**: Market buy, brew, sell, mutations, daily demand all unchanged

## Files Summary

| File | Action | Purpose |
|------|--------|---------|
| `src/shared/Config/ForageTuning.lua` | Create | Star-to-forage probability tables, sub-zone definitions, pools |
| `src/server/Services/ZoneService.lua` | Modify | Star-scaled drops, sub-zone validation, rare node enhancement |
| `src/client/GroveExpansionController.client.lua` | Create | Sub-zone unlock visuals, barrier show/hide, unlock VFX |
| `default.project.json` | Modify | Register ForageTuning + GroveExpansionController |
| Workspace (MCP) | Create | 3 sub-zones with 6 forage nodes + barriers |

## Definition of Done

- [ ] Regular forage nodes drop uncommon/rare ingredients scaled by star count
- [ ] 0-star players get only commons from regular nodes (no regression)
- [ ] 3 sub-zones exist in WildGrove with 2 forage nodes each (6 new nodes total)
- [ ] Sub-zones locked behind star thresholds (10, 25, 50)
- [ ] Locked sub-zones show dim barriers with star requirement labels
- [ ] Sub-zone unlock plays dissolve animation + notification
- [ ] Sub-zone nodes have richer loot pools (uncommon/rare)
- [ ] Rare forage node spawn rare-vs-uncommon split improves with server star count
- [ ] ForageTuning.lua is single source of truth for all forage probabilities
- [ ] All 18 forage nodes have ProximityPrompts and server-enforced cooldowns
- [ ] No gameplay regression (market, brewing, selling, mutations)

## Risks & Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Sub-zone coordinates outside WildGrove bounds | Medium | High | Verify against 175x175 grove dimensions before build |
| ForageTuning not accessible on client | Low | Medium | Register in ReplicatedStorage via Rojo config |
| Rare drops too generous at high stars | Medium | Medium | Conservative probability caps (8% max rare from regular nodes) |
| Sub-zone unlock desync (client thinks locked, server allows) | Low | High | Server validates star threshold on every forage; client is visual only |
| New nodes missing ProximityPrompts | Medium | High | Audit script after MCP world build |
| Grove expansion clutters WildGrove | Low | Medium | Sub-zones are small alcoves at edges, not central area |

## Security Considerations

- All forage outcomes remain server-authoritative
- Sub-zone access validated server-side (star threshold check) — client barriers are cosmetic only
- No new remote endpoints needed (uses existing ForageNode event)
- Star count read from authoritative PlayerData, not client-supplied
- Rate limiting preserved (60s cooldown per node)

## Dependencies

- Sprint 008 WildGrove layout (175x175 with 12 base nodes)
- Sprint 010 progression infrastructure (BrewStats tracking)
- BrewTuning.EvolutionTiers (star thresholds)
- Ingredients.lua (uncommon/rare ingredient pools)
