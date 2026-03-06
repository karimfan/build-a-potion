# Sprint 011: Starbound Foraging — Progression-Linked Drops and Grove Expansion

## Overview

Foraging is currently a flat loop: node outcomes are static, rare-node rarity is static, and WildGrove access is effectively fully open from minute one. This misses a key retention opportunity because player stars (`BrewStats.TotalBrewed`) already represent clear progression but do not influence harvest quality or exploration depth.

This sprint links stars directly to foraging in two ways. First, regular node rewards become star-weighted so higher-star players reliably graduate from all-common outcomes into meaningful Uncommon/Rare results, while still preserving beginner-friendly commons. Second, WildGrove progression shifts from "all at once" to tier-based unlocks where additional forage nodes and micro-areas open as stars increase, capped at a defined maximum.

The implementation remains server-authoritative (drop roll + unlock checks on server), preserves existing remote contracts (`ForageNode`, `PlayerDataUpdate`), and uses shared tuning so design can adjust thresholds and probabilities without rewriting service logic.

## Scope Anchors (Non-Negotiable)

1. Stars = `BrewStats.TotalBrewed`; this is the only progression input for foraging rarity and grove unlocks.
2. Regular forage outcomes are server-rolled with star-based tier weighting (not client predicted).
3. 0-star players can always forage from starter nodes and receive valid common outcomes.
4. Grove expansion is gradual and capped: additional nodes unlock at defined star thresholds until full grove access.
5. Existing remotes remain backward compatible: `ForageNode` event and `PlayerDataUpdate` contract are preserved.
6. Rare forage node system remains active, but rare-vs-uncommon odds scale by stars.
7. All tuning (thresholds, weights, unlock map) lives in shared config, not hardcoded in `ZoneService`.

## Use Cases

1. **New player (0 stars) forages**: Can use starter node set, gets common ingredients only, and sees clear locked-node cues for future unlocks.
2. **Mid-progression player (25 stars)**: Unlocks additional grove nodes and begins receiving uncommon drops from regular foraging at noticeable rates.
3. **High-progression player (100+ stars)**: Has full grove access and meaningful rare chance from regular nodes plus elevated rare-node outcomes.
4. **Cross-player consistency**: Two players with different stars forage the same physical node; each receives outcomes based on their own server-side progression.
5. **Progression reveal moment**: Crossing a threshold unlocks new grove node clusters and surfaces feedback so the player understands what changed.

## Architecture

### Star Tier Model (Shared Tuning)

`ForageTuning` defines five star tiers aligned to existing evolution thresholds:

- Tier 0: `0-9` stars
- Tier 1: `10-24` stars
- Tier 2: `25-49` stars
- Tier 3: `50-99` stars
- Tier 4: `100+` stars

Each tier defines drop weights for regular forage:

| Star Tier | Common | Uncommon | Rare |
|-----------|--------|----------|------|
| 0 | 1.00 | 0.00 | 0.00 |
| 1 | 0.85 | 0.15 | 0.00 |
| 2 | 0.70 | 0.28 | 0.02 |
| 3 | 0.55 | 0.38 | 0.07 |
| 4 | 0.40 | 0.45 | 0.15 |

### Grove Expansion Model

Node unlocks are threshold-based and capped at 12 total nodes:

| Unlock Threshold | Newly Unlocked Nodes | Total Active |
|------------------|----------------------|--------------|
| 0 stars | `ForageNode_1..4` | 4 |
| 10 stars | `ForageNode_5..6` | 6 |
| 25 stars | `ForageNode_7..8` | 8 |
| 50 stars | `ForageNode_9..10` | 10 |
| 100 stars | `ForageNode_11..12` | 12 |

Server validates access on every `ForageNode` event. Locked-node attempts do not grant ingredients and optionally return a user-facing unlock hint via `GlobalAnnouncement`.

### Server Roll Flow (Regular Nodes)

```
ForageNode.OnServerEvent(player, nodeId)
  -> validate node exists + cooldown
  -> read stars from PlayerData.BrewStats.TotalBrewed
  -> resolve star tier from ForageTuning
  -> verify node unlocked at this star count
  -> roll drop rarity using tier weights
  -> pick ingredient from node pool matching rolled rarity
  -> award via PlayerDataService.addIngredientStack(..., "forage")
  -> notifyClient + storage warning
```

### Rare Node Scaling

Rare-node spawn cadence remains `120-240s`, but rarity split scales by stars:

- Base rare chance: `30%` at Tier 0
- Max rare chance: `60%` at Tier 4
- Linear or stepwise interpolation via `ForageTuning.RareNodeChanceByTier`

This preserves the existing event loop while rewarding progression with better jackpot odds.

### Client Feedback Model

Client uses existing `PlayerDataUpdate` (`BrewStats.TotalBrewed`) + `ForageTuning` to render grove state:

- Locked nodes: dimmed visuals + disabled prompt + threshold label.
- Newly unlocked nodes: short pulse/glow reveal when crossing threshold.
- Existing `ForageNodeFeedback` cooldown animation remains and only runs for unlocked nodes.

## Implementation Plan

### Phase 1: Shared Forage Progression Tuning (~20%)

**Files:**
- `src/shared/Config/ForageTuning.lua` — Create
- `default.project.json` — Register shared config

**Tasks:**
- [ ] Create `ForageTuning` with:
  - `StarTiers` and threshold helpers
  - Regular-node rarity weights by tier
  - Node unlock thresholds/groups
  - Rare-node rare-chance by tier
- [ ] Add helper APIs (`getTierForStars`, `isNodeUnlocked`, weighted roll helper inputs)
- [ ] Register `ForageTuning` in `default.project.json` under `ReplicatedStorage.Shared.Config`

### Phase 2: ZoneService Forage Progression Core (~35%)

**Files:**
- `src/server/Services/ZoneService.lua` — Major modify

**Tasks:**
- [ ] Replace hardcoded regular-node reward selection with star-tier weighted selection.
- [ ] Split node pools into rarity buckets per node (`Common`, `Uncommon`, `Rare`) and validate pools are non-empty for rolled tier.
- [ ] Add node unlock guard before reward grant (`ForageNode` event path).
- [ ] Keep per-node cooldown behavior unchanged (`Types.FORAGE_COOLDOWN_SECONDS`).
- [ ] Add structured debug logs: stars, tier, rolled rarity, ingredient, nodeId.
- [ ] Scale rare-node uncommon/rare split by star tier using `ForageTuning`.
- [ ] Maintain existing storage warning behavior and remote notifications.

### Phase 3: Grove Unlock Visualization (~20%)

**Files:**
- `src/client/ForageNodeFeedback.client.lua` — Major modify
- `src/client/EnvironmentEvolution.client.lua` — Minor modify (optional threshold celebration hook)

**Tasks:**
- [ ] Resolve current star tier from `PlayerDataUpdate` payload.
- [ ] Apply unlocked/locked presentation to all `ForageNode_*` parts in WildGrove:
  - Locked: high transparency, muted light, prompt disabled, optional unlock text.
  - Unlocked: full visual + prompt enabled.
- [ ] Add one-time reveal effect when nodes become newly unlocked.
- [ ] Ensure existing cooldown shrink/restore animation only applies to unlocked nodes.

### Phase 4: Progression Messaging + UX Clarity (~10%)

**Files:**
- `src/server/Services/ZoneService.lua` — Minor modify
- `src/client/FeedbackController.client.lua` — Minor modify

**Tasks:**
- [ ] On first forage after crossing threshold, send concise unlock announcement:
  - Example: "Wild Grove expanded: 2 new forage nodes unlocked."
- [ ] On locked-node interaction attempt, provide threshold hint:
  - Example: "Reach 25 stars to unlock this node cluster."
- [ ] Reuse existing `GlobalAnnouncement` flow; no new remote contract required.

### Phase 5: Verification + Balancing Pass (~15%)

**Files:**
- `src/server/Services/ZoneService.lua` (debug-only sampling helper guarded by dev flag)
- Manual playtest checklist in sprint execution notes

**Tasks:**
- [ ] Probability sampling sanity check per tier (10k rolls): verify distributions within tolerance.
- [ ] 0-star validation: only starter nodes active, regular drops always Common.
- [ ] 10/25/50/100-star validation: node unlock counts and rarity shifts match tuning.
- [ ] Rare-node validation: rare chance increases by tier and caps correctly.
- [ ] Regression checks: cooldown still enforced, inventory updates still save/notify, rare-node lifetime cleanup still works.
- [ ] Multiplayer check: player-specific drops/unlocks do not leak across users.

## Files Summary

| File | Action | Purpose |
|------|--------|---------|
| `src/shared/Config/ForageTuning.lua` | Create | Source of truth for star tiers, rarity weights, unlock gates |
| `default.project.json` | Modify | Register new shared config in Rojo tree |
| `src/server/Services/ZoneService.lua` | Major modify | Server-authoritative star-linked drops, unlock gating, rare-node scaling |
| `src/client/ForageNodeFeedback.client.lua` | Major modify | Locked/unlocked node visuals and unlock reveal behavior |
| `src/client/EnvironmentEvolution.client.lua` | Minor modify | Optional progression synergy cues tied to forage unlock thresholds |
| `src/client/FeedbackController.client.lua` | Minor modify | Player-facing unlock/locked-node messaging polish |

## Definition of Done

- [ ] Regular forage rarity is explicitly tied to `BrewStats.TotalBrewed` tiers.
- [ ] 0-star players can forage normally from starter nodes and receive common outcomes.
- [ ] Grove expansion unlocks additional node sets at 10/25/50/100 stars, capped at full access.
- [ ] Rare-node rare chance scales upward with stars and respects configured cap.
- [ ] Locked-node attempts are safely rejected server-side with user guidance.
- [ ] Existing remotes remain compatible; no regressions in buy/brew/sell/forage flows.
- [ ] Shared tuning allows threshold/weight changes without logic rewrites.
- [ ] Manual verification confirms expected distributions and unlock behavior.

## Risks & Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Early tiers feel too stingy, harming new-player sentiment | Medium | High | Keep Tier 0 fully common but increase quantity/feedback quality; tune Tier 1 uncommon entry conservatively |
| Weighted pools produce empty-roll edge cases on some nodes | Medium | Medium | Validate node rarity buckets at startup; fallback to common pool with warning log |
| Locked-node visuals desync from server unlock logic | Medium | Medium | Derive both from same `ForageTuning` thresholds and stars field |
| Rare-node scaling over-incentivizes high-tier farming | Medium | Medium | Cap rare chance and monitor economy impact vs market pricing |
| Additional visual state updates affect client performance | Low | Medium | Only refresh node state on data updates and threshold changes, not every frame |

## Security Considerations

- Forage outcome selection remains server-authoritative; client never submits rarity or ingredient choice.
- Node unlock checks run server-side for every forage event.
- Existing anti-spam/cooldown protections stay in place.
- No new privileged remotes introduced; existing event surfaces reused.

## Dependencies

- Sprint 008 world contracts (`ForageNode_1..12`, WildGrove geometry)
- Sprint 010 progression baseline (`BrewStats.TotalBrewed`, onboarding/player data path)
- `PlayerDataService` stack inventory + notification flow
- `BrewTuning.EvolutionTiers` (threshold alignment source)
