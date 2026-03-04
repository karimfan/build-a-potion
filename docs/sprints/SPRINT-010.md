# Sprint 010: Progression Loop — Upgrade Shop, Storage Limits, Onboarding

## Overview

Players can brew, sell, and earn coins — but there's nothing to spend them on. The upgrade system is fully designed in `UpgradeTuning.lua` (4 cauldron tiers with brew time reduction and mutation bonuses) and the data model stores `Upgrades.CauldronTier`, but there is zero UI or server handler to purchase upgrades. The coin economy has no sink, and players plateau immediately.

This sprint closes the progression loop with three features: (1) an **Upgrade Shop** accessed via a persistent HUD button to buy cauldron tiers and storage expansions, (2) **Storage Limits** with soft warnings so inventory management matters, and (3) a **6-step Tutorial** guiding new players through forage → buy → brew → claim → sell.

## Scope Anchors (Non-Negotiable)

1. Players can purchase cauldron upgrades up to tier 4 using coins, validated server-side.
2. Upgrade effects already in `BrewingService` (brew time reduction, mutation bonus) activate after purchase.
3. Storage capacity counted as **total ingredient units** (not unique types) with soft warning.
4. UI shows storage usage (`used/capacity`) with color-coded feedback.
5. First-time players receive a 6-step guided tutorial; does not replay after completion.
6. Existing remote contracts for market/brewing/selling remain backward compatible.

## Use Cases

1. **Player buys cauldron upgrade**: Clicks HUD "Upgrades" button, sees current tier + next tier cost/benefits, clicks "Upgrade" → coins deducted, tier incremented, brew times immediately reduced.
2. **Player nears storage cap**: Sees "18/20 units" counter on HUD. At 20/20, a warning toast appears: "Inventory full! Brew or sell ingredients to make room." Action still succeeds (soft warning, not hard block).
3. **Player upgrades storage**: Buys StorageSlots upgrade → capacity increases from 20 to 30, warning threshold rises.
4. **New player joins**: Tutorial overlay with 6 steps: forage, buy, brew, claim, sell, complete. Each step advances on real server-validated action. Skippable at any time.
5. **Returning player**: Tutorial auto-completed on migration. Never shown.

## Architecture

### Upgrade Purchase Flow

```
Client: HUD "Upgrades" button → opens UpgradeGui
  → Shows CauldronTier (current + next) and StorageSlots (current + next)
  → Click "Upgrade" → fires RemoteFunction "PurchaseUpgrade"(upgradeType)
  ↓
Server: UpgradeService.PurchaseUpgrade(player, upgradeType)
  → Validate: player coins >= next tier cost
  → Validate: current tier < max tier
  → Deduct coins atomically
  → Increment upgrade tier in PlayerData
  → forceSave + notifyClient
  ↓
Client: PlayerDataUpdate → UpgradeGui refreshes
```

### Storage Counting (Total Units, Not Unique Types)

```
PlayerDataService.getTotalIngredientUnits(data):
  → Sum all stack amounts across all ingredient entries
  → e.g., 5 mushroom + 3 river_water + 2 fern_leaf = 10 units

PlayerDataService.getStorageCapacity(data):
  → Look up StorageSlots tier → return capacity (20/30/50)
```

### Storage Soft Warning Flow

```
Server: BuyIngredient / ForageNode / RareForageNode handler
  → After adding ingredient: check totalUnits vs capacity
  → Always allow (soft limit) — include warning flag in data update
  ↓
Client: On data update, check units vs cap
  → If units >= cap: show toast "Inventory full! Upgrade or brew/sell."
  → HUD counter turns red at 100%, orange at 80%
```

### Onboarding State (Server-Authoritative)

```lua
PlayerData.Onboarding = {
    Completed = false,
    CurrentStep = 1,
    Steps = { Forage=false, Buy=false, Brew=false, Claim=false, Sell=false }
}
-- Existing players migrate to Completed=true (skip tutorial)
```

### Service Responsibilities

```
UpgradeService (new)
  → purchaseCauldronUpgrade / purchaseStorageUpgrade
  → validates coins + max tier, mutates atomically

OnboardingService (new)
  → recordAction(player, actionName) — called by existing services
  → advances step state, marks Completed when all done
  → idempotent; persists via PlayerData

PlayerDataService (extend)
  → getTotalIngredientUnits(data), getStorageCapacity(data)
  → onboarding defaults + migration
```

## API/Remote Contract Matrix

| Remote | Direction | Change | Notes |
|--------|-----------|--------|-------|
| `BuyIngredient` | Client → Server | Preserve | Storage warning after transaction |
| `ForageNode` | Client → Server | Preserve | Storage warning + onboarding hook |
| `BrewPotion` | Client → Server | Preserve | Onboarding hook |
| `ClaimBrewResult` | Client → Server | Preserve | Onboarding hook |
| `SellPotion` | Client → Server | Preserve | Onboarding hook |
| `PlayerDataUpdate` | Server → Client | Extend payload | Includes onboarding state |
| `PurchaseUpgrade` | Client → Server | **New** | Server-authoritative upgrade purchase |

## Implementation Plan

### Phase 1: Data Contract + Migration (~15%)

**Files:**
- `src/server/Services/PlayerDataService.lua` — Storage helpers + onboarding defaults
- `src/shared/Config/UpgradeTuning.lua` — Add StorageSlots tiers

**Tasks:**
- [ ] Add `getTotalIngredientUnits(data)` — sum all stack amounts across all ingredients
- [ ] Add `getStorageCapacity(data)` — lookup StorageSlots tier → return cap (20/30/50)
- [ ] Export both on `_G.PlayerDataService`
- [ ] Add `Onboarding` to default profile: `{ Completed=false, CurrentStep=1, Steps={...} }`
- [ ] Migration: existing players get `Onboarding.Completed = true`
- [ ] Add StorageSlots tiers to UpgradeTuning:
  - Tier 1: 20 units (free, default)
  - Tier 2: 30 units (2,000 coins)
  - Tier 3: 50 units (8,000 coins)

### Phase 2: Upgrade Service + UI (~25%)

**Files:**
- `src/server/Services/UpgradeService.lua` — Create
- `src/server/Bootstrap.server.lua` — Register
- `src/client/InteractionController.client.lua` — HUD button + UpgradeGui
- `default.project.json` — Add UpgradeService to Rojo

**Tasks:**
- [ ] Create `UpgradeService.lua` with `PurchaseUpgrade` RemoteFunction handler
- [ ] Validate upgrade type ("CauldronTier" or "StorageSlots")
- [ ] Check current tier < max tier, coins >= next tier cost
- [ ] Deduct coins, increment tier, forceSave, notifyClient
- [ ] Register `_G.UpgradeService`, add to Bootstrap requiredServices
- [ ] Add "Upgrades" HUD button (next to RecipeBookBtn)
- [ ] Create UpgradeGui: cauldron section + storage section + coins display
- [ ] Grey out button if insufficient coins or max tier
- [ ] Refresh on PlayerDataUpdate

### Phase 3: Storage Counter + Soft Warnings (~15%)

**Files:**
- `src/client/InteractionController.client.lua` — Slot counter
- `src/client/FeedbackController.client.lua` — Warning toast

**Tasks:**
- [ ] Add inventory counter to cauldron GUI: "Inventory: X/Y"
- [ ] Use `getTotalIngredientUnits` for X, `getStorageCapacity` for Y
- [ ] Color: white (normal), orange (>=80%), red (>=100%)
- [ ] On data update at/over cap: show toast via FeedbackController
- [ ] Warning: "Inventory full! Upgrade storage or brew/sell ingredients."

### Phase 4: Onboarding System (~30%)

**Files:**
- `src/server/Services/OnboardingService.lua` — Create (server-authoritative)
- `src/client/OnboardingController.client.lua` — Create (UI)
- `src/server/Services/ZoneService.lua` — Forage hook
- `src/server/Services/EconomyService.lua` — Buy/Sell hooks
- `src/server/Services/BrewingService.lua` — Brew/Claim hooks
- `src/server/Bootstrap.server.lua` — Register OnboardingService
- `default.project.json` — Add new scripts to Rojo

**Tasks:**
- [ ] Create `OnboardingService.lua`:
  - `recordAction(player, actionName)` — validates + advances step
  - Called from existing services at successful completion points
  - Marks Completed when all 5 actions done
  - Persists via PlayerDataService
- [ ] Add hooks in existing services:
  - ZoneService forage handler → `recordAction(player, "Forage")`
  - EconomyService buy handler → `recordAction(player, "Buy")`
  - BrewingService brew handler → `recordAction(player, "Brew")`
  - BrewingService claim handler → `recordAction(player, "Claim")`
  - EconomyService sell handler → `recordAction(player, "Sell")`
- [ ] Create `OnboardingController.client.lua`:
  - On join: check Onboarding state from player data
  - If not Completed: show tutorial overlay
  - 6 steps:
    1. "Welcome to Brew a Potion!" → auto-advance after 3s
    2. "Forage ingredients in the Wild Grove!" → highlight Forage button
    3. "Buy ingredients at the Market!" → highlight Buy button
    4. "Brew a potion at your Cauldron!" → highlight My Shop button
    5. "Claim your brew and sell it!" → highlight Sell button
    6. "You're ready! Discover recipes and upgrade your cauldron." → dismiss
  - "Skip Tutorial" button on every step
  - UI updates from PlayerDataUpdate (server drives progression)

### Phase 5: Testing + Regression (~15%)

**Tasks:**
- [ ] Purchase cauldron Tier 1→2: verify 1000 coins deducted, brew time reduced 20%
- [ ] Purchase at max tier (4): verify rejection
- [ ] Purchase with insufficient coins: verify rejection
- [ ] Storage counter shows correct total units / capacity
- [ ] Fill to 20 units, buy more: warning toast appears, ingredient still added
- [ ] Upgrade storage to Tier 2 (30): counter updates
- [ ] New player: tutorial appears, complete all 6 steps via real actions
- [ ] Existing player: tutorial NOT shown (Completed=true on migration)
- [ ] Regression: brew, sell, buy, forage, mutations, daily demand, rare nodes

## Files Summary

| File | Action | Purpose |
|------|--------|---------|
| `src/server/Services/UpgradeService.lua` | Create | Upgrade purchase handler |
| `src/server/Services/OnboardingService.lua` | Create | Server-authoritative tutorial tracking |
| `src/client/OnboardingController.client.lua` | Create | Tutorial UI |
| `src/shared/Config/UpgradeTuning.lua` | Modify | Add StorageSlots tiers |
| `src/server/Bootstrap.server.lua` | Modify | Register new services |
| `src/server/Services/PlayerDataService.lua` | Modify | Storage helpers + onboarding data + migration |
| `src/server/Services/EconomyService.lua` | Modify | Onboarding hooks for buy/sell |
| `src/server/Services/ZoneService.lua` | Modify | Onboarding hook for forage |
| `src/server/Services/BrewingService.lua` | Modify | Onboarding hooks for brew/claim |
| `src/client/InteractionController.client.lua` | Modify | HUD Upgrades button, storage counter |
| `src/client/FeedbackController.client.lua` | Modify | Storage warning toast |
| `default.project.json` | Modify | Register new scripts in Rojo |

## Definition of Done

- [ ] Cauldron upgrades purchasable through 4 tiers via HUD button
- [ ] Storage upgrades purchasable (20 → 30 → 50 units)
- [ ] Storage counted as total ingredient units (not unique types)
- [ ] HUD shows inventory counter (X/Y) with color warnings
- [ ] Soft warning toast when inventory at/over cap
- [ ] New players see 6-step server-validated tutorial
- [ ] Tutorial includes explicit "Claim brew" step
- [ ] Tutorial skippable, persists across sessions
- [ ] Existing players auto-skip tutorial
- [ ] Both standard and rare forage paths include storage checks
- [ ] All existing gameplay works without regression

## Risks & Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Datastore migration nil-field edge cases | Medium | High | Defensive defaults + idempotent field init |
| Storage cap logic diverges across paths | Medium | Medium | Centralized helpers in PlayerDataService |
| Onboarding steps fire out of order | Medium | Medium | Idempotent step tracking, not strict ordering |
| Upgrade purchase race condition | Low | Medium | Server-authoritative, Luau single-threaded |
| Tutorial overwhelms new players | Medium | Low | Skip button always visible |

## Security Considerations

- All upgrade purchases server-authoritative (coin validation on server)
- Onboarding progression recorded from server-validated actions, not client claims
- Storage checks are advisory (soft warning) — no exploit surface
- Rate limiting on PurchaseUpgrade (reuse ACTION_COOLDOWN pattern)
- No new exploitable remotes

## Dependencies

- Sprint 009 economy infrastructure (`_G.MarketService`, deductStock)
- UpgradeTuning.lua (4 cauldron tiers already defined)
- Existing `_G.PlayerDataService` and `_G.ScoreService` patterns
- Sprint 008 world contracts (Cauldron, MarketStall, SellCounter, ForageNode_*)
