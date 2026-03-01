# Sprint 006: Unified Progression Loop — Scoring, Global Leaderboard, Daily Demand, Upgrades, Non-Modal Brew Timer

## Overview

Sprint 006 ships six tightly coupled systems together to create one coherent progression loop: brew while moving, optimize around rotating demand, improve equipment, convert activity into score, and compete globally. This is a full-scope sprint by design: all systems must land in production, with no feature cuts.

The core product outcome is a game loop where every meaningful action contributes to long-term status. Brewing and selling now feed a composite score, that score is published to a global cross-server leaderboard via Roblox `OrderedDataStore`, rare outcomes produce social moments through announcements, and upgrades shape both efficiency and mutation upside. Daily Demand adds strategic variance without changing base recipe rules.

The technical approach is server-authoritative for all economy and score mutation paths, with additive DataStore migration (V3→V4) to preserve existing player progress. UI work emphasizes continuity with current patterns while removing brew-time modality so players stay active during timers.

## Scope Anchors (Non-Negotiable)

1. **All systems ship in this sprint**: scoring, global leaderboard, daily demand board, global announcements, progression/upgrades, non-modal brew timer.
2. **Composite score formula**: time played + rarity-weighted brewing + coin earnings from selling.
3. **Leaderboard is global cross-server** using Roblox `OrderedDataStore` (not server-local only).
4. **Daily Demand**: 3 featured potions per day with 2x-5x sell multiplier.
5. **Non-modal brewing**: brew timer shown on HUD while player continues normal gameplay.
6. **Progression curve target**: generous first 30 minutes, gradual slowdown afterward.
7. **DataStore V3→V4 migration**: idempotent and non-destructive.

## Use Cases

1. **Always-on progress**: Player brews and sells while exploring; score updates immediately on HUD without opening extra menus.
2. **Global competition**: Player checks leaderboard and sees rank against all servers, not just current server instance.
3. **Demand strategy**: Player pivots ingredient spending toward one of today’s 3 boosted potions for a higher return.
4. **Upgrade-driven mastery**: Player buys cauldron tier upgrades to reduce brew duration and increase mutation odds.
5. **Broadcast moments**: Mythic/Divine or premium mutation brews produce visible global announcement events.
6. **Retention curve**: New players achieve early wins quickly, then encounter measured progression friction that creates medium-term goals.

## Architecture

### Composite Score Model

```lua
Score = TimeScore + BrewScore + TradeScore

TimeScore = floor(totalPlaytimeMinutes * 1)
BrewScore = sum(potionTierWeight[potionTier] * count) + mutationBonusPoints
TradeScore = floor(totalCoinsEarnedFromSelling / 10)

TierWeights = {
  Common = 10,
  Uncommon = 25,
  Rare = 100,
  Mythic = 500,
  Divine = 5000,
}

MutationPointBonus = {
  glowing = 10,
  bubbling = 20,
  crystallized = 30,
  shadow = 60,
  rainbow = 120,
  golden = 250,
}
```

### Global Leaderboard (OrderedDataStore)

```lua
-- OrderedDataStore key
"GlobalScoreV1"

-- Entry key
"u_<userId>"

-- Stored numeric value
CompositeScore

Write strategy:
1. Recompute CompositeScore on score-relevant events.
2. Throttle writes per-player (e.g. at most once per 30s unless major change).
3. Update OrderedDataStore with latest score.
4. Keep in-memory cache for current server HUD responsiveness.

Read strategy:
1. Poll top-N list every 30-60s for shared global board UI.
2. Fetch around-player context by reading own score + estimated rank from cached top pages.
```

### Daily Demand Model

```lua
DailyDemand = {
  dateKey = "2026-03-01", -- UTC date
  demands = {
    { potionId = "...", multiplier = 2 },
    { potionId = "...", multiplier = 3 },
    { potionId = "...", multiplier = 5 },
  },
}

Generation:
- Deterministic by UTC date seed for consistency.
- Stored in standard DataStore with dateKey guard.
- Regenerated once per UTC day.
```

### Upgrade Model

| Tier | Name | Cost (Coins) | Brew Time Reduction | Mutation Chance Bonus |
|------|------|---------------|---------------------|------------------------|
| 1 | Apprentice | 0 | 0% | +0% |
| 2 | Adept | 1,000 | 20% | +2% |
| 3 | Master | 5,000 | 35% | +4% |
| 4 | Archmage | 25,000 | 50% | +8% |

Unlock gates:
- Tier 3 requires at least 50 total brews.
- Tier 4 requires at least 100 total brews.

### Non-Modal Brew Timer

- Active brew remains server-authoritative (`ActiveBrew` state).
- HUD widget subscribes to replicated player data and server reconciliation.
- Cauldron panel no longer forces full-screen lockout on brew start.
- Clicking HUD timer re-opens detailed cauldron panel.

### DataStore V4 Additions

```lua
Version = 4

Score = {
  TimePlayedMinutes = 0,
  TotalCoinsFromSelling = 0,
  BrewScoreCache = 0,
  CompositeScore = 0,
  LastLeaderboardWriteUnix = 0,
}

Upgrades = {
  CauldronTier = 1,
  BrewStations = 1,
  StorageSlots = 20,
}

DailyDemand = {
  LastSoldDateKey = "",
  SoldPotionIds = {},
}
```

## Implementation Plan

### Phase 1: Data and Service Foundations (~18%)

**Files:**
- `src/shared/Types.lua` - bump `DATASTORE_VERSION` to 4
- `src/server/Services/PlayerDataService.lua` - V3→V4 migration + default fields
- `src/server/Bootstrap.server.lua` - initialize new services in correct order

**Tasks:**
- [ ] Add V4 defaults for score, upgrades, daily-demand tracking.
- [ ] Implement idempotent V3→V4 migration path.
- [ ] Add migration tests/check helpers for partial old profiles.
- [ ] Ensure replicated payload includes new V4 fields.

### Phase 2: Score Service + Event Wiring (~16%)

**Files:**
- `src/server/Services/ScoreService.lua` (new)
- `src/server/Services/BrewingService.lua`
- `src/server/Services/EconomyService.lua`

**Tasks:**
- [ ] Create `ScoreService` with deterministic composite-score recompute.
- [ ] Add minute-based playtime accrual while connected.
- [ ] Track and accumulate sell-earned coins into `TradeScore` source.
- [ ] Recompute score on brew claim, sell, and timed accrual.
- [ ] Expose score update hooks used by leaderboard + HUD.

### Phase 3: Global Leaderboard via OrderedDataStore (~18%)

**Files:**
- `src/server/Services/LeaderboardService.lua` (new)
- `src/client/GameController.client.lua`
- `src/client/InteractionController.client.lua`

**Tasks:**
- [ ] Implement `OrderedDataStore` writer with per-player throttle.
- [ ] Publish score deltas from `ScoreService` to global board storage.
- [ ] Implement server cache for top entries + refresh cadence.
- [ ] Add client-facing API/remotes for top list + player snapshot.
- [ ] Build global leaderboard UI list with current-player highlighting.

### Phase 4: Daily Demand Board + Economy Multipliers (~14%)

**Files:**
- `src/server/Services/DailyDemandService.lua` (new)
- `src/server/Services/EconomyService.lua`
- `src/client/InteractionController.client.lua`

**Tasks:**
- [ ] Generate/persist daily demand set (UTC-based date key).
- [ ] Apply demand multiplier during sell pricing server-side.
- [ ] Surface active demands and multipliers in Trading Post UI.
- [ ] Track per-player “sold today” indicators for board feedback.

### Phase 5: Upgrades and Progression Curve Tuning (~14%)

**Files:**
- `src/shared/Config/UpgradeTuning.lua` (new)
- `src/server/Services/BrewingService.lua`
- `src/client/InteractionController.client.lua`

**Tasks:**
- [ ] Add upgrade definitions and unlock requirements.
- [ ] Implement purchase validation and coin deduction server-side.
- [ ] Apply tier bonuses to brew duration and mutation chance.
- [ ] Add cauldron upgrade UI states (owned, purchasable, locked).
- [ ] Tune early-game costs/rewards to hit first-30-minute target.

### Phase 6: Non-Modal Brew Timer HUD + Flow Rewrite (~12%)

**Files:**
- `src/client/InteractionController.client.lua`
- `src/client/GameController.client.lua`

**Tasks:**
- [ ] Remove brew-start modal lock behavior.
- [ ] Add compact brew timer HUD card with progress and remaining time.
- [ ] Keep timer synchronized with server `ActiveBrew` state.
- [ ] Preserve quick path back to cauldron details from HUD element.

### Phase 7: Global Announcements + Integration Validation (~8%)

**Files:**
- `src/server/Services/BrewingService.lua`
- `src/client/FeedbackController.client.lua`

**Tasks:**
- [ ] Trigger announcement events for Mythic/Divine outcomes and premium mutations.
- [ ] Queue and display announcement banners without UI overlap.
- [ ] End-to-end verify that all six systems operate together in one session.

## Files Summary

| File | Action | Purpose |
|------|--------|---------|
| `src/shared/Types.lua` | Modify | DataStore version bump, shared constants |
| `src/shared/Config/UpgradeTuning.lua` | Create | Upgrade tiers, costs, and bonuses |
| `src/server/Bootstrap.server.lua` | Modify | Register/initialize new services |
| `src/server/Services/PlayerDataService.lua` | Modify | V4 migration and persistence fields |
| `src/server/Services/ScoreService.lua` | Create | Composite score ownership and recompute |
| `src/server/Services/LeaderboardService.lua` | Create | Global OrderedDataStore reads/writes |
| `src/server/Services/DailyDemandService.lua` | Create | Daily demand generation and retrieval |
| `src/server/Services/BrewingService.lua` | Modify | Upgrade effects and announcement triggers |
| `src/server/Services/EconomyService.lua` | Modify | Demand multiplier and score event hooks |
| `src/client/GameController.client.lua` | Modify | Score HUD, leaderboard panel, timer updates |
| `src/client/InteractionController.client.lua` | Modify | Non-modal brew flow, upgrades, demand UI |
| `src/client/FeedbackController.client.lua` | Modify | Announcement display queue |

## Definition of Done

- [ ] All six Sprint 006 systems are present and enabled in the same release.
- [ ] Composite score updates correctly for time, brewing, and selling.
- [ ] Global leaderboard is cross-server and backed by `OrderedDataStore`.
- [ ] Leaderboard UI shows top global players and current player context.
- [ ] Daily Demand rotates every UTC day and applies correct 2x-5x multipliers.
- [ ] Non-modal brew timer is active; player remains fully mobile while brewing.
- [ ] Upgrade purchases work, persist, and apply correct brew/mutation modifiers.
- [ ] Mythic/Divine + qualifying mutation announcements broadcast reliably.
- [ ] V3→V4 migration is idempotent and preserves existing inventory/progression.
- [ ] Early progression target achieved: strong first-30-minute earning feel.
- [ ] No regressions in existing brewing, selling, market, or recipe behavior.

## Risks & Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| OrderedDataStore write pressure from frequent score changes | High | High | Throttled writes, batched updates, server cache fallback |
| Cross-system integration bugs due to full-scope delivery | High | High | Service contracts, phased integration tests, launch checklist |
| Migration edge cases from partially old profiles | Medium | High | Idempotent migration with defensive defaults and validation logs |
| Demand multipliers destabilize economy | Medium | Medium | Clamp multipliers to configured range; monitor sell-value deltas |
| Non-modal timer desync between client/server | Medium | Medium | Authoritative server timestamps + periodic client reconciliation |

## Security Considerations

- Score calculation is fully server-side; client only receives display values.
- Leaderboard writes are server-owned and keyed by authenticated `UserId`.
- Daily demand and sell multipliers are server-authored.
- Upgrade purchase checks (coins + unlock gates) are server-enforced.
- Announcement events are server-triggered only.

## Dependencies

- Sprint 003 timed brewing state (`ActiveBrew`) and HUD sync behavior.
- Sprint 004 ingredient economy + freshness structure.
- Sprint 005 mutation outcomes and potion value model.
- Roblox DataStoreService (`DataStore` + `OrderedDataStore`).

## Open Questions

1. Should global leaderboard reset seasonally or remain lifetime cumulative at launch?
2. Should Daily Demand be globally identical (date-seeded) or curated by live-ops data later?
3. Do we want separate local-server mini-leaderboard in addition to the required global board?
