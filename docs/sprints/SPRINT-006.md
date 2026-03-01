# Sprint 006: Economy & Progression — Scoring, Global Leaderboard, Daily Demand, Upgrades, Non-Modal Brew Timer

## Overview

Sprint 006 ships six tightly coupled systems to create a complete progression loop. Every meaningful action — brewing, selling, exploring — feeds a composite score visible on a global cross-server leaderboard. The Daily Demand Board adds strategic depth to selling. Cauldron upgrades give clear progression goals. Global announcements create viral social moments. And the brew timer becomes a non-modal HUD element so players stay active during timers.

All six systems ship together — no scope cuts. This is the sprint that transforms Brew a Potion from "functional crafting sim" into "addictive competitive economy."

The progression curve targets 500+ coins in the first 10 minutes (hook), natural friction by 30 minutes (most Common recipes exhausted, Uncommon ingredients needed), and clear upgrade goals by 60 minutes.

## Scope Anchors (Non-Negotiable)

1. **All 6 systems ship**: scoring, global leaderboard, daily demand, upgrades, announcements, non-modal timer
2. **Composite score** = TimeScore + BrewScore (rarity-weighted) + TradeScore (coins from selling)
3. **Global leaderboard** via Roblox OrderedDataStore — cross-server, persists offline
4. **Daily Demand Board** — 3 potions with 2x-5x bonus, rotates at midnight UTC
5. **Non-modal brew timer** — HUD widget, player moves freely during brew
6. **4 cauldron upgrade tiers** with brew time reduction and mutation chance bonuses
7. **Global announcements** for Mythic/Divine brews and Rainbow/Golden mutations
8. **DataStore V3→V4** — idempotent migration, preserves all existing data
9. **Progression curve** — generous first 30 min, gradual slowdown

## Score Formula

```lua
CompositeScore = TimeScore + BrewScore + TradeScore

TimeScore = floor(totalPlayTimeMinutes * 1)

BrewScore = sum of:
  - Per potion brewed: TierWeight * count
    Common=10, Uncommon=25, Rare=100, Mythic=500, Divine=5000
  - Per mutation: MutationBonus
    Glowing=10, Bubbling=20, Crystallized=30, Shadow=60, Rainbow=120, Golden=250

TradeScore = floor(totalCoinsEarnedFromSelling / 10)
```

## Global Leaderboard (OrderedDataStore)

```
DataStore: "GlobalScoreV1" (OrderedDataStore)
Key: "u_<userId>"
Value: CompositeScore (integer)

Write strategy:
- Throttled: max 1 write per 30 seconds per player
- Triggered on: brew claim, sell, score recompute
- Batched: if multiple changes within 30s window, coalesce

Read strategy:
- Poll top 50 every 60 seconds (server-side cache)
- Client requests refresh on leaderboard GUI open
- Player's own rank estimated from cached pages

Fallback:
- If OrderedDataStore unavailable, show server-local scores
- Retry writes on failure with exponential backoff
```

## Daily Demand Board

```lua
DailyDemand = {
    dateKey = "2026-03-01",  -- UTC date string
    demands = {
        { potionId = "healing_salve", multiplier = 2, tier = "Common" },
        { potionId = "storm_bottle", multiplier = 3, tier = "Uncommon" },
        { potionId = "volcanic_frost", multiplier = 5, tier = "Rare" },
    }
}

Generation:
- Deterministic from date: math.randomseed(dateHash) → pick 1 Common (2x), 1 Uncommon/Rare (3x), 1 Rare/Mythic (5x)
- Same demands across ALL servers (deterministic seed)
- Regenerates at midnight UTC (dateKey guard prevents double-generation)
- Stored in server memory, regenerated on demand
```

## Cauldron Upgrade Tiers

| Tier | Name | Cost | Brew Time Reduction | Mutation Bonus | Brew Req |
|------|------|------|---------------------|----------------|----------|
| 1 | Apprentice | Free | 0% | +0% | - |
| 2 | Adept | 1,000 | -20% | +2% | - |
| 3 | Master | 5,000 | -35% | +4% | 50 brews |
| 4 | Archmage | 25,000 | -50% | +8% | 100 brews |

## Non-Modal Brew Timer HUD

```
┌──────────────────────────────────────────┐
│  Coins: 1,234  │  Score: 4,567  │  📖 🏆│  ← Top bar (score + leaderboard btn)
│                                          │
│           (player walks freely)          │
│                                          │
│                         ┌──────────────┐ │
│                         │ 🧪 Brewing   │ │  ← Bottom-right mini timer
│                         │ Healing Salve│ │
│                         │ ████░░ 0:34  │ │
│                         └──────────────┘ │
└──────────────────────────────────────────┘

- Appears on brew start, disappears after claim
- Clickable → opens full CauldronGui for details
- Syncs from server ActiveBrew state
- Player can walk, buy, forage, sell while brewing
```

## DataStore V4 Schema Additions

```lua
PlayerState.Version = 4

-- NEW:
PlayerState.Score = {
    TimePlayedMinutes = 0,
    TotalCoinsFromSelling = 0,
    BrewScoreCache = 0,
    MutationScoreCache = 0,
    CompositeScore = 0,
    LastLeaderboardWriteUnix = 0,
}

PlayerState.Upgrades = {
    CauldronTier = 1,
    BrewStations = 1,       -- future: parallel brewing
    StorageSlots = 20,      -- future: ingredient storage expansion
}

PlayerState.DailyDemandState = {
    LastSoldDateKey = "",
    SoldPotionIds = {},     -- potionIds sold to demand today
}
```

## Implementation Plan

### Phase 1: Non-Modal Brew Timer HUD (~15%)

**Tasks:**
- [ ] Remove `cauldronGui.Enabled = false` from brew start in InteractionController
- [ ] Add BrewTimerWidget to HudGui: compact frame (bottom-right) with potion name + progress bar + countdown
- [ ] Widget visible during active brew, hidden when idle
- [ ] Clickable to re-open CauldronGui
- [ ] Timer syncs from server GetActiveBrewState periodically
- [ ] Player can walk, open market, forage, sell while widget shows

### Phase 2: Scoring System + V4 Migration (~15%)

**Tasks:**
- [ ] Update Types: DATASTORE_VERSION=4
- [ ] Add V4 defaults to PlayerDataService: Score, Upgrades, DailyDemandState
- [ ] V3→V4 migration: add new fields with defaults, idempotent
- [ ] Create ScoreService: composite score computation from formula
- [ ] Track TimePlayedMinutes: increment every 60s while connected
- [ ] Track TotalCoinsFromSelling: hook into EconomyService sell flow
- [ ] Recompute CompositeScore on brew claim, sell, and time accrual
- [ ] Add score display to HudGui (next to coin counter)
- [ ] Score updates sent to client via PlayerDataUpdate

### Phase 3: Global Leaderboard (~15%)

**Tasks:**
- [ ] Create LeaderboardService: OrderedDataStore reads/writes
- [ ] Write throttle: max 1 write per 30s per player, coalesce changes
- [ ] Read: poll top 50 every 60s, cache server-side
- [ ] Create GetLeaderboard RemoteFunction for client requests
- [ ] Create LeaderboardGui: top 50 list with rank, name, score
- [ ] Highlight current player's position
- [ ] Add leaderboard button (trophy icon) to HudGui
- [ ] Fallback to server-local if OrderedDataStore unavailable

### Phase 4: Daily Demand Board (~15%)

**Tasks:**
- [ ] Create DailyDemandService: generate demands from UTC date seed
- [ ] Pick 3 potions: 1 Common (2x), 1 Uncommon/Rare (3x), 1 Rare/Mythic (5x)
- [ ] Create GetDailyDemand RemoteFunction
- [ ] Update EconomyService sell: multiply value if potion matches demand
- [ ] Show Demand Board in TradingPost zone (SurfaceGui on a board part)
- [ ] Highlight demand potions in SellGui with bonus badge
- [ ] Track which demands player has sold to today (per-date)

### Phase 5: Cauldron Upgrades (~15%)

**Tasks:**
- [ ] Create UpgradeTuning config: 4 tiers with costs, reductions, bonuses, brew requirements
- [ ] Add upgrade purchase flow in BrewingService or EconomyService
- [ ] Validate: enough coins, meets brew count requirement, not already at tier
- [ ] Apply brew time reduction: `duration = baseDuration * (1 - tierReduction)`
- [ ] Apply mutation bonus: add cauldronTierBonus to mutation chance
- [ ] Show upgrade button in CauldronGui with tier info, cost, requirements
- [ ] Cauldron visual changes with tier (glow color/intensity)

### Phase 6: Global Brew Announcements (~5%)

**Tasks:**
- [ ] Create GlobalAnnouncement RemoteEvent
- [ ] On brew claim: fire to all if Mythic/Divine or Rainbow/Golden mutation
- [ ] Message: "[PlayerName] just brewed a [mutation] [PotionName]!"
- [ ] Display as top banner, fade after 5s
- [ ] Queue announcements (max 3 stacked)

### Phase 7: Progression Curve Tuning (~5%)

**Tasks:**
- [ ] Verify: new player earns 500+ coins in first 10 minutes with Common recipes
- [ ] Verify: by 30 minutes, Common recipes exhausted, player needs Uncommon ingredients
- [ ] Upgrade costs: Tier 2 (1,000) achievable ~15 min, Tier 3 (5,000) ~45 min, Tier 4 (25,000) requires significant play
- [ ] Ensure ingredient costs vs potion values create positive but tightening margins

### Phase 8: Validation (~15%)

**Tasks:**
- [ ] Score updates on brew + sell in real-time
- [ ] Leaderboard shows global top 50, updates correctly
- [ ] Daily Demand gives correct bonus, rotates at UTC midnight
- [ ] Brew timer HUD works while walking around
- [ ] Cauldron upgrades reduce time and increase mutation chance
- [ ] Global announcements fire for Mythic/Divine/Golden
- [ ] V3→V4 migration preserves all data
- [ ] OrderedDataStore writes throttled (no rate limit errors)
- [ ] No regressions to buy/brew/sell/forage

## Files Summary

| File | Action | Purpose |
|------|--------|---------|
| `src/shared/Types.lua` | Modify | DATASTORE_VERSION=4 |
| `src/shared/Config/UpgradeTuning.lua` | Create | 4 cauldron tiers, costs, bonuses |
| `src/server/Bootstrap.server.lua` | Modify | Initialize new services |
| `src/server/Services/PlayerDataService.lua` | Modify | V4 migration, score + upgrades fields |
| `src/server/Services/ScoreService.lua` | Create | Composite score computation + time tracking |
| `src/server/Services/LeaderboardService.lua` | Create | Global OrderedDataStore reads/writes |
| `src/server/Services/DailyDemandService.lua` | Create | Daily demand generation |
| `src/server/Services/BrewingService.lua` | Modify | Apply upgrade bonuses, fire announcements |
| `src/server/Services/EconomyService.lua` | Modify | Demand multiplier, score hooks |
| `src/client/GameController.client.lua` | Modify | Score HUD, leaderboard button, brew timer widget |
| `src/client/InteractionController.client.lua` | Modify | Non-modal brew, demand display, upgrade UI |
| `src/client/FeedbackController.client.lua` | Modify | Announcement banner queue |
| `StarterGui/HudGui` | Modify | Score display, timer widget, leaderboard button |
| `StarterGui/LeaderboardGui` | Create | Global leaderboard UI |
| `ReplicatedStorage/Remotes/GlobalAnnouncement` | Create | Server-to-all announcement |
| `ReplicatedStorage/Remotes/GetLeaderboard` | Create | Leaderboard data fetch |
| `ReplicatedStorage/Remotes/GetDailyDemand` | Create | Daily demand data fetch |
| `Workspace/Zones/TradingPost` | Modify | Demand Board visual |

## Definition of Done

- [ ] All 6 systems present and functional
- [ ] Score visible on HUD, updates in real-time on brew/sell/time
- [ ] Score formula correctly weights: time + brew (tier) + trade (coins/10)
- [ ] Global leaderboard shows top 50 cross-server via OrderedDataStore
- [ ] Leaderboard writes throttled (30s min), reads cached (60s poll)
- [ ] Daily Demand shows 3 potions with 2x-5x, rotates at UTC midnight
- [ ] Selling demand potion gives correct bonus multiplier
- [ ] Brew timer is a non-modal HUD widget (player walks freely)
- [ ] 4 cauldron upgrades purchasable, reduce brew time, increase mutation chance
- [ ] Global announcements for Mythic/Divine brews and Rainbow/Golden mutations
- [ ] V3→V4 DataStore migration idempotent, preserves all data
- [ ] Progression: 500+ coins in first 10 min, friction by 30 min
- [ ] No regressions to existing systems

## Risks & Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| OrderedDataStore rate limits | High | High | 30s write throttle, coalesce, exponential backoff |
| 6 systems in one sprint | High | High | Full-scope commitment, phased integration, no cuts |
| V4 migration edge cases | Medium | High | Idempotent, defensive defaults, validation logging |
| Non-modal timer desync | Medium | Medium | Server-authoritative, periodic client reconciliation |
| Daily Demand economy imbalance | Medium | Medium | Clamped multipliers (2x-5x), monitor sell-value spikes |
| Score inflation from mutations | Medium | Medium | Separate mutation bonus points, tune weights |

## Security

- Score computed server-side only
- Leaderboard writes server-owned, keyed by authenticated UserId
- Daily Demand generated server-side from deterministic seed
- Upgrade purchases server-validated (coins + brew gate)
- Announcements server-triggered only
- Client receives display values only, never submits score/rank
