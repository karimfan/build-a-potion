# Sprint 010: Progression Loop — Upgrade Shop, Storage Limits, Onboarding

## Overview

Players can brew, sell, and earn coins — but there's nothing to spend them on. The upgrade system is fully designed in `UpgradeTuning.lua` (4 cauldron tiers with brew time reduction and mutation bonuses) and the data model stores `Upgrades.CauldronTier`, but there is zero UI or server handler to actually purchase upgrades. This means the entire coin economy has no sink, and players hit a ceiling almost immediately.

This sprint closes the progression loop by adding: (1) an **Upgrade Shop** with a dedicated UI to buy cauldron tiers, (2) **Storage Limits** enforcement so inventory management matters and the StorageSlots upgrade becomes meaningful, and (3) a **5-step Tutorial** that guides new players through their first forage → brew → sell cycle.

## Use Cases

1. **Player buys cauldron upgrade**: Opens upgrade panel (HUD button or cauldron interaction), sees current tier + next tier cost/benefits, clicks "Upgrade" → coins deducted, tier incremented, brew times immediately reduced.
2. **Player hits storage cap**: Tries to buy ingredient with full inventory → server rejects with "Inventory full! Upgrade storage or brew/sell ingredients." UI shows "18/20 slots" counter.
3. **New player joins**: Tutorial overlay appears with 5 steps: (1) Welcome, (2) Walk to Wild Grove and forage, (3) Walk to Market and buy an ingredient, (4) Walk to Cauldron and brew, (5) Walk to Trading Post and sell. Each step highlights the relevant zone button.
4. **Player upgrades storage**: Buys StorageSlots upgrade → capacity increases from 20 to 30 (etc.), unblocking further ingredient accumulation.

## Architecture

### Upgrade Purchase Flow

```
Client: UpgradeController → RemoteFunction "PurchaseUpgrade"
  ↓
Server: UpgradeService.PurchaseUpgrade(player, upgradeType)
  → Validate: player has enough coins
  → Validate: upgrade available (not max tier)
  → Deduct coins atomically
  → Increment upgrade tier
  → Force save + notify client
  ↓
Client: receives updated player data → UI refreshes
```

### Storage Enforcement Flow

```
Server: EconomyService.BuyIngredient handler
  → Before adding ingredient: check getIngredientCount(data) vs StorageSlots cap
  → If over cap: return { success=false, error="Inventory full!" }

Server: ZoneService.ForageNode handler
  → Same check before addIngredientStack

Client: HUD shows "X/Y slots" counter, updates on data change
```

### Tutorial State

```lua
PlayerData.TutorialStep = 0  -- 0=not started, 1-5=in progress, 6=completed
```

## Implementation Plan

### Phase 1: Upgrade Service + Remote (~25%)

**Files:**
- `src/server/Services/UpgradeService.lua` — Create
- `src/shared/Config/UpgradeTuning.lua` — Add StorageSlots tiers
- `src/server/Bootstrap.server.lua` — Register UpgradeService

**Tasks:**
- [ ] Create `UpgradeService.lua` with `PurchaseUpgrade` RemoteFunction handler
- [ ] Validate upgrade type ("CauldronTier" or "StorageSlots")
- [ ] Check current tier < max tier
- [ ] Check player coins >= next tier cost
- [ ] Deduct coins, increment tier, forceSave, notifyClient
- [ ] Add StorageSlots tiers to UpgradeTuning: Tier 1=20, Tier 2=30 (2000 coins), Tier 3=50 (8000 coins)
- [ ] Register `_G.UpgradeService` and add to Bootstrap
- [ ] Create `PurchaseUpgrade` RemoteFunction in Remotes folder

### Phase 2: Upgrade UI (~20%)

**Files:**
- `src/client/InteractionController.client.lua` — Add upgrade panel to cauldron GUI (or new UpgradeGui)

**Tasks:**
- [ ] Add "Upgrades" button to HUD (next to Recipe Book button)
- [ ] Create UpgradeGui ScreenGui in StarterGui with:
  - Current cauldron tier + name
  - Next tier: name, cost, benefits (brew time reduction %, mutation bonus %)
  - "Upgrade" button (greyed out if not enough coins or max tier)
  - Storage section: current capacity, next tier cost
- [ ] Wire to PurchaseUpgrade remote
- [ ] Refresh UI on PlayerDataUpdate
- [ ] Show success/failure feedback popup

### Phase 3: Storage Limits Enforcement (~20%)

**Files:**
- `src/server/Services/EconomyService.lua` — Add storage check to BuyIngredient
- `src/server/Services/ZoneService.lua` — Add storage check to ForageNode
- `src/client/InteractionController.client.lua` — Show slot counter in cauldron GUI

**Tasks:**
- [ ] Add helper: `getUsedSlots(data)` — count unique ingredient types in data.Ingredients
- [ ] In BuyIngredient handler: if usedSlots >= StorageSlots cap → reject with error
- [ ] In ForageNode handler: same check before addIngredientStack
- [ ] Add "Inventory: X/Y" label to cauldron GUI header
- [ ] Update on PlayerDataUpdate events
- [ ] Show warning color when near cap (orange at 80%, red at 100%)

### Phase 4: Tutorial System (~25%)

**Files:**
- `src/client/TutorialController.client.lua` — Create
- `src/server/Services/PlayerDataService.lua` — Add TutorialStep field

**Tasks:**
- [ ] Add `TutorialStep` to default profile (default=0)
- [ ] Add migration for existing players (set TutorialStep=6 = completed, skip tutorial)
- [ ] Create TutorialController client script:
  - On join: check TutorialStep from player data
  - If step < 6: show tutorial overlay
  - Step 1: "Welcome to Brew a Potion! Let's learn the basics."
  - Step 2: "Go forage ingredients in the Wild Grove" → highlight Forage button
  - Step 3: "Buy ingredients at the Market" → highlight Buy button
  - Step 4: "Brew a potion at your Cauldron" → highlight My Shop button
  - Step 5: "Sell your potion at the Trading Post" → highlight Sell button
  - Step 6: "You're ready! Discover recipes and upgrade your cauldron."
- [ ] Each step advances when the relevant action is detected (forage event, buy event, brew event, sell event)
- [ ] "Skip Tutorial" button always visible
- [ ] Save TutorialStep on each advancement

### Phase 5: Testing (~10%)

**Tasks:**
- [ ] Purchase cauldron upgrade Tier 1→2: verify 1000 coins deducted, brew time reduced
- [ ] Purchase at max tier: verify rejection
- [ ] Purchase with insufficient coins: verify rejection
- [ ] Fill inventory to 20 slots, try to forage: verify blocked
- [ ] Upgrade storage to 30, forage again: verify unblocked
- [ ] New player tutorial: step through all 5 steps
- [ ] Existing player: tutorial does NOT appear (TutorialStep=6)
- [ ] Regression: brew, sell, buy, forage all work

## Files Summary

| File | Action | Purpose |
|------|--------|---------|
| `src/server/Services/UpgradeService.lua` | Create | Purchase upgrade handler |
| `src/shared/Config/UpgradeTuning.lua` | Modify | Add StorageSlots tiers |
| `src/server/Bootstrap.server.lua` | Modify | Register UpgradeService |
| `src/client/InteractionController.client.lua` | Modify | Upgrade UI + slot counter |
| `src/server/Services/EconomyService.lua` | Modify | Storage check on buy |
| `src/server/Services/ZoneService.lua` | Modify | Storage check on forage |
| `src/server/Services/PlayerDataService.lua` | Modify | TutorialStep field |
| `src/client/TutorialController.client.lua` | Create | Tutorial flow |
| `default.project.json` | Modify | Register new scripts |

## Definition of Done

- [ ] Cauldron upgrades purchasable through 4 tiers (coins deducted, effects applied)
- [ ] Storage upgrades purchasable (capacity increases)
- [ ] Storage limits enforced on buy + forage (rejected when full)
- [ ] HUD shows inventory counter (X/Y slots)
- [ ] New players see 5-step tutorial guiding core loop
- [ ] Tutorial skippable, advances on real actions, persists across sessions
- [ ] Existing players don't see tutorial
- [ ] All existing gameplay works without regression

## Risks & Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Upgrade purchase race condition | Low | Medium | Server-authoritative, Luau single-threaded |
| Storage enforcement breaks existing flow | Medium | High | Check returns error message, client shows it |
| Tutorial annoying for returning players | Medium | Low | Skip button + auto-complete for existing players |
| UpgradeService init order | Low | Medium | Bootstrap registration pattern, same as other services |

## Dependencies

- Sprint 009 economy infrastructure (market, selling)
- UpgradeTuning.lua (already exists with 4 cauldron tiers)
- Existing _G.PlayerDataService pattern
