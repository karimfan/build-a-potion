# Sprint 006: Economy & Progression — Scoring, Leaderboard, Daily Demand, Upgrades, Non-Modal Brew Timer

## Overview

Sprint 006 transforms Brew a Potion from a functional crafting sim into an addictive economy with clear progression, social competition, and strategic decisions. The scoring system creates a composite leaderboard that tracks real achievement across time played, brewing skill, and trading success. The Daily Demand Board adds strategic depth to selling (brew what's in demand for 2x-5x bonus). The upgrade system gives players clear progression goals (better cauldrons, more brew stations, storage). And the brew timer moves to a non-modal HUD element so players can walk around, check the market, and forage while brewing.

This sprint also introduces global announcements for Divine/Mythic brews (the viral moment that drives TikTok content) and a progression curve designed to hook in the first 30 minutes then gradually create natural monetization friction — the exact approach that made Grow a Garden successful.

## Scope Anchors (Non-Negotiable)

1. **Composite score** = time_played_score + brew_score (rarity-weighted) + trade_score (coins earned from selling)
2. **Leaderboard** visible in-game, global cross-server using Roblox OrderedDataStore
3. **Daily Demand Board** at Trading Post — 3 potions with 2x-5x bonus, rotates every 24 hours
4. **Non-modal brew timer** — small HUD element showing brew progress, player can move freely
5. **Cauldron upgrade system** — 4 tiers: Apprentice, Adept, Master, Archmage
6. **Global brew announcements** for Mythic/Divine potions and Golden mutations
7. **DataStore V3→V4** migration for score, upgrades, daily demand tracking
8. **Progression curve** — generous early, gradual slowdown

## Use Cases

1. **Score tracking**: Player brews a Rare potion, sees score increase by 800 points in real-time on HUD.
2. **Leaderboard flex**: Player opens leaderboard and sees they're #3 on the server. Motivated to brew more.
3. **Daily Demand strategy**: Player sees "Volcanic Frost 3x bonus today!" on Demand Board. Has the ingredients. Brews it for 7,500 coins instead of 2,500.
4. **Non-modal brewing**: Player starts a brew, closes cauldron GUI, walks to market to buy ingredients for next brew. HUD shows "Brewing... 0:45" in corner.
5. **Cauldron upgrade**: Player buys Adept Cauldron for 1,000 coins. Brew times reduced 20%, mutation chance +2%.
6. **Divine announcement**: Player brews Wish Potion. Server-wide message: "PlayerName just brewed a Wish Potion!" Everyone sees it.
7. **Progression curve**: New player earns 500 coins in first 10 minutes (generous). After 30 minutes, earn rate naturally slows as cheap recipes are exhausted and upgrades get expensive.

## Architecture

### Score Formula

```lua
Score = TimeScore + BrewScore + TradeScore

TimeScore = floor(totalPlayTimeMinutes * 1)  -- 1 point per minute

BrewScore = sum of (PotionTierWeight * count) for all brewed potions
  TierWeights: Common=10, Uncommon=25, Rare=100, Mythic=500, Divine=5000
  Mutation bonus: multiply by mutation sell multiplier

TradeScore = floor(totalCoinsEarnedFromSelling / 10)  -- 1 point per 10 coins sold
```

### Daily Demand Board

```lua
DailyDemand = {
    generatedDate = "2026-03-01",  -- date string, rotates at midnight UTC
    demands = {
        { potionId = "volcanic_frost", multiplier = 3 },
        { potionId = "healing_salve", multiplier = 2 },
        { potionId = "storm_bottle", multiplier = 5 },
    }
}

-- Generated deterministically from date seed (same for all servers)
-- Uses seeded RNG: math.randomseed(dateHash)
-- Picks 1 Common (2x), 1 Uncommon/Rare (3x), 1 Rare/Mythic (5x)
```

### Cauldron Upgrade Tiers

| Tier | Name | Cost | Brew Time Reduction | Mutation Bonus | Unlock |
|------|------|------|---------------------|----------------|--------|
| 1 | Apprentice Cauldron | Free | 0% | +0% | Start |
| 2 | Adept Cauldron | 1,000 coins | -20% | +2% | Available |
| 3 | Master Cauldron | 5,000 coins | -35% | +4% | 50 brews |
| 4 | Archmage Cauldron | 25,000 coins | -50% | +8% | 100 brews |

### Non-Modal Brew Timer HUD

```
┌──────────────────────────────────────────┐
│  [Coins: 1,234]  [Score: 4,567]  [📖]   │  ← Top HUD bar
│                                          │
│                                          │
│                                          │
│                                          │
│                         ┌──────────────┐ │
│                         │ 🧪 Brewing   │ │  ← Bottom-right
│                         │ ████░░ 0:34  │ │     mini timer
│                         └──────────────┘ │
└──────────────────────────────────────────┘
```

### DataStore V4 Schema Additions

```lua
PlayerState.Version = 4
-- NEW fields:
PlayerState.Score = {
    TimePlayedMinutes = 0,
    TotalCoinsFromSelling = 0,
    BrewScoreCache = 0,      -- cached brew score (recomputed from BrewStats)
    CompositeScore = 0,       -- cached total score
}
PlayerState.Upgrades = {
    CauldronTier = 1,         -- 1-4
    BrewStations = 1,         -- number of simultaneous brews (future)
    StorageSlots = 20,        -- ingredient storage capacity (future)
}
PlayerState.DailyDemandClaimed = {}  -- track which demands player has sold to today
```

## Implementation Plan

### Phase 1: Non-Modal Brew Timer HUD (~20%)

**Files:**
- `src/client/InteractionController.client.lua` — Remove GUI close on brew start
- `StarterGui/HudGui` — Add brew timer mini-widget
- `src/client/GameController.client.lua` — Wire brew timer HUD updates

**Tasks:**
- [ ] Remove `cauldronGui.Enabled = false` from brew start flow
- [ ] Add BrewTimerWidget to HudGui: small frame bottom-right with progress bar + countdown
- [ ] Widget shows: potion icon/name, progress bar, countdown timer
- [ ] Widget appears when brew starts, disappears after claim
- [ ] Widget is clickable — opens CauldronGui to see full brew details
- [ ] Player can walk, open market, forage while timer runs
- [ ] Timer syncs from server GetActiveBrewState

### Phase 2: Scoring System + HUD Score Display (~20%)

**Files:**
- `src/server/Services/ScoreService.lua` (new) — Score computation and tracking
- `src/server/Services/PlayerDataService.lua` — V4 migration
- `src/shared/Types.lua` — DATASTORE_VERSION=4
- `StarterGui/HudGui` — Add score display

**Tasks:**
- [ ] Create ScoreService with composite score formula
- [ ] Track TimePlayedMinutes: increment every 60s while player is connected
- [ ] Track TotalCoinsFromSelling: increment on each sell transaction
- [ ] Compute BrewScore from BrewStats.PotionCounts + tier weights
- [ ] CompositeScore = TimeScore + BrewScore + TradeScore
- [ ] Recalculate on each brew claim and sell
- [ ] Add score display to HudGui (next to coin counter)
- [ ] V3→V4 DataStore migration: add Score + Upgrades fields
- [ ] Real-time score updates sent to client via PlayerDataUpdate

### Phase 3: Leaderboard (~10%)

**Files:**
- `src/server/Services/LeaderboardService.lua` (new) — Per-server leaderboard
- `StarterGui/LeaderboardGui` (new) — Leaderboard UI
- `src/client/GameController.client.lua` — Leaderboard button + display

**Tasks:**
- [ ] LeaderboardService: maintain sorted list of {player, score} for current server
- [ ] Update on score changes
- [ ] LeaderboardGui: show top 10 players with scores
- [ ] Add leaderboard button to HudGui
- [ ] Highlight current player's rank
- [ ] Update every 10 seconds

### Phase 4: Daily Demand Board (~15%)

**Files:**
- `src/server/Services/DailyDemandService.lua` (new) — Generate daily demands
- `src/server/Services/EconomyService.lua` — Apply demand bonus on sell
- `Workspace/Zones/TradingPost` — Add Demand Board visual
- `src/client/InteractionController.client.lua` — Show demand board in sell GUI

**Tasks:**
- [ ] DailyDemandService: generate 3 demands deterministically from date seed
- [ ] Pick: 1 Common (2x), 1 Uncommon/Rare (3x), 1 Rare/Mythic (5x)
- [ ] Demands rotate at midnight UTC
- [ ] Show Demand Board in TradingPost zone (BillboardGui or SurfaceGui on a board)
- [ ] Show demand bonuses in SellGui (highlight potions that match today's demand)
- [ ] EconomyService: multiply sell value by demand multiplier if potion matches
- [ ] Track which demands player has sold to today (to show "Sold!" badge)

### Phase 5: Cauldron Upgrades (~15%)

**Files:**
- `src/shared/Config/UpgradeTuning.lua` (new) — Upgrade tiers and costs
- `src/server/Services/BrewingService.lua` — Apply upgrade bonuses to brew time and mutation
- `src/client/InteractionController.client.lua` — Upgrade purchase UI in cauldron
- `StarterGui/CauldronGui` — Add upgrade button

**Tasks:**
- [ ] Create UpgradeTuning config: 4 cauldron tiers with costs, time reduction %, mutation bonus %
- [ ] Add upgrade purchase flow: validate coins, deduct, set CauldronTier in profile
- [ ] Apply brew time reduction: `duration = baseDuration * (1 - tierReduction)`
- [ ] Apply mutation bonus: add CauldronTier bonus to mutation chance calculation
- [ ] Show current tier and upgrade button in CauldronGui
- [ ] Upgrade requires both coins AND brew count threshold (Tier 3=50 brews, Tier 4=100 brews)
- [ ] Visual feedback: cauldron appearance changes with tier (color/glow/particles)

### Phase 6: Global Brew Announcements (~5%)

**Files:**
- `src/server/Services/BrewingService.lua` — Fire announcements
- `ReplicatedStorage/Remotes` — Add GlobalAnnouncement RemoteEvent
- `src/client/FeedbackController.client.lua` — Display announcements

**Tasks:**
- [ ] Create GlobalAnnouncement RemoteEvent
- [ ] On brew claim: if potion tier is Mythic/Divine OR mutation is Rainbow/Golden, fire to all players
- [ ] Message format: "[PlayerName] just brewed a [mutation] [PotionName]!"
- [ ] Display as banner at top of screen for all players, fades after 5 seconds
- [ ] Stack announcements if multiple occur (queue)

### Phase 7: Progression Curve Tuning (~5%)

**Tasks:**
- [ ] First 30 minutes: Common ingredients cheap, Common recipes profitable (25-40 coins per brew vs 10-15 ingredient cost)
- [ ] After 30 minutes: player has discovered most Common recipes, needs Uncommon ingredients (50-130 coins) for better margins
- [ ] After 60 minutes: Uncommon recipes discovered, chasing Rare ingredients. Upgrade costs create friction.
- [ ] Upgrade costs: Tier 2 = 1,000 (achievable in ~15 min), Tier 3 = 5,000 (achievable in ~45 min), Tier 4 = 25,000 (requires significant play)
- [ ] Ensure first-time player experience flows: spawn → buy cheap ingredients → discover first recipe → sell → feel progression

### Phase 8: Validation (~10%)

**Tasks:**
- [ ] Verify score updates in real-time on brew and sell
- [ ] Verify leaderboard sorts correctly
- [ ] Verify Daily Demand gives correct bonus on sell
- [ ] Verify brew timer HUD works while walking around
- [ ] Verify cauldron upgrades reduce brew time and increase mutation chance
- [ ] Verify global announcements fire for Mythic/Divine/Golden
- [ ] Verify V3→V4 migration preserves all existing data
- [ ] Verify progression: new player can earn 500+ coins in first 10 minutes

## Files Summary

| File | Action | Purpose |
|------|--------|---------|
| `src/shared/Types.lua` | Modify | DATASTORE_VERSION=4 |
| `src/shared/Config/UpgradeTuning.lua` | Create | Cauldron upgrade tiers, costs, bonuses |
| `src/server/Services/PlayerDataService.lua` | Modify | V4 migration, score + upgrades fields |
| `src/server/Services/ScoreService.lua` | Create | Composite score computation |
| `src/server/Services/LeaderboardService.lua` | Create | Per-server leaderboard |
| `src/server/Services/DailyDemandService.lua` | Create | Daily demand generation |
| `src/server/Services/BrewingService.lua` | Modify | Apply upgrade bonuses, fire announcements |
| `src/server/Services/EconomyService.lua` | Modify | Daily demand sell bonus |
| `src/client/InteractionController.client.lua` | Modify | Non-modal brew, demand display, upgrade UI |
| `src/client/GameController.client.lua` | Modify | Score HUD, leaderboard button, brew timer widget |
| `src/client/FeedbackController.client.lua` | Modify | Global announcement display |
| `StarterGui/HudGui` | Modify | Score display, brew timer widget |
| `StarterGui/LeaderboardGui` | Create | Leaderboard UI |
| `ReplicatedStorage/Remotes/GlobalAnnouncement` | Create | Server-to-all-clients announcement |
| `Workspace/Zones/TradingPost` | Modify | Daily Demand Board visual |

## Definition of Done

- [ ] Score visible on HUD, updates in real-time on brew/sell
- [ ] Score formula: time + brew (rarity-weighted) + trade (coins/10)
- [ ] Leaderboard shows top 10 global with current player highlighted
- [ ] Daily Demand Board shows 3 potions with bonus multipliers, rotates daily
- [ ] Selling a demand potion gives correct bonus (2x-5x)
- [ ] Brew timer is a non-modal HUD widget (not full-screen)
- [ ] Player can walk around during brew
- [ ] 4 cauldron upgrade tiers purchasable with coins
- [ ] Upgrades reduce brew time and increase mutation chance
- [ ] Global announcement for Mythic/Divine brews and Golden mutations
- [ ] V3→V4 DataStore migration preserves all data
- [ ] Progression: 500+ coins achievable in first 10 minutes
- [ ] No regressions to existing systems

## Risks & Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| 6 systems in one sprint is too much scope | High | High | Prioritize: non-modal timer > scoring > daily demand > upgrades > leaderboard > announcements |
| V4 migration complexity | Medium | High | Idempotent migration, only add fields |
| Score inflation from mutations | Medium | Medium | Cap mutation bonus in score, tune weights |
| Daily Demand same-seed across servers could feel exploitable | Low | Low | Deterministic is fine — creates community coordination |
| Non-modal timer desync | Medium | Medium | Poll server state periodically, reconcile on GUI open |

## Security Considerations

- Score computed server-side only, never from client
- Leaderboard reads from server state, not client-reported scores
- Daily Demand generated from date seed server-side
- Upgrade purchases validated server-side (coin check + brew count gate)
- Global announcements only fired by server, not client-triggered
