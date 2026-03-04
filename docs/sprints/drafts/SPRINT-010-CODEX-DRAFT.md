# Sprint 010: Progression Loop Foundation — Cauldron Upgrades, Storage Pressure, First-Join Onboarding

## Overview

The game now has a strong earn loop (forage, buy, brew, sell), but progression pressure and onboarding clarity are still missing. Coins accumulate without a meaningful sink, ingredient inventory has no hard capacity constraints, and first-time players are not guided through the loop. This creates weak mid-term motivation and a high risk of early drop-off.

Sprint 010 introduces three must-have progression systems as one coherent pass: (1) server-authoritative cauldron tier purchasing, (2) enforced ingredient storage capacity with clear UI feedback, and (3) a guided first-session tutorial that walks new players through the full core loop once. The design goal is to convert existing systems into a structured progression funnel without destabilizing buy/brew/sell contracts already shipped in prior sprints.

## Scope Anchors (Non-Negotiable)

1. Players can purchase cauldron upgrades up to tier 4 using coins, validated server-side.
2. Upgrade effects already in `BrewingService` (brew time reduction, mutation bonus) are visibly activated after purchase.
3. Ingredient storage capacity is enforced on both buy and forage paths.
4. UI shows storage usage (`used/capacity`) and actionable full-inventory feedback.
5. First-time players receive a 5-step guided tutorial and it does not replay after completion.
6. Existing remote contracts for market/brewing/selling remain backward compatible (no regressions).

## Use Cases

1. **Player with enough coins upgrades cauldron**: buys next tier, coins deduct once, tier increases, brew speed/mutation bonus reflect new tier.
2. **Player at storage cap tries to buy**: purchase is rejected server-side, client gets clear "Storage full" feedback.
3. **Player at storage cap forages node**: forage grant is rejected or skipped cleanly, no silent overfill.
4. **New player joins for first time**: sees guided objectives for forage -> buy -> brew -> claim -> sell.
5. **Returning player who completed tutorial**: no onboarding overlay is shown.

## Architecture

### Progression Data Model Additions

```text
PlayerData (existing)
  Upgrades.CauldronTier
  Upgrades.StorageSlots
  BrewStats.TotalBrewed

PlayerData (new/extended)
  Onboarding = {
    Completed = false,
    CurrentStep = 1,
    Steps = {
      Forage = false,
      Buy = false,
      Brew = false,
      Claim = false,
      Sell = false,
    }
  }
```

### Service Responsibilities

```text
UpgradeService (new)
  - purchaseNextCauldronTier(player)
  - validates coins + brew requirement + max tier
  - mutates Upgrades.CauldronTier + Coins atomically

PlayerDataService (extend)
  - storage helpers: getIngredientUnits, getStorageCapacity, canAddIngredients
  - onboarding state defaults + migration

EconomyService / ZoneService / BrewingService (extend)
  - call storage guard before adding ingredients
  - emit onboarding progress events for buy/sell/forage/brew/claim

OnboardingService (new)
  - records objective completion events
  - advances step state once per objective
  - idempotent completion; persists via PlayerData
```

### Event/Flow Model

```text
Upgrade purchase:
Client Upgrade UI -> PurchaseCauldronUpgrade remote -> UpgradeService
-> validate next tier + requirements -> deduct coins + set tier -> PlayerDataUpdate

Storage guard:
BuyIngredient / ForageNode -> PlayerDataService.canAddIngredients(data, amount)
-> reject if over cap -> return reason + notify client

Onboarding progression:
Action occurs in existing services
-> _G.OnboardingService.recordAction(player, action)
-> updates Onboarding state
-> PlayerDataUpdate drives onboarding UI step transitions on client
```

## Implementation Plan

### Phase 1: Data Contract + Migration (~25%)

**Files:**
- `src/server/Services/PlayerDataService.lua`
- `src/shared/Types.lua`

**Tasks:**
- [ ] Add onboarding defaults to new profiles (`Onboarding.Completed`, `CurrentStep`, `Steps`).
- [ ] Bump datastore schema version and add migration path for existing players.
- [ ] Add storage utility functions in `PlayerDataService`:
  - `getIngredientUnits(data)`
  - `getStorageCapacity(data)`
  - `canAddIngredients(data, amount)`
- [ ] Export these helpers on `_G.PlayerDataService` for service reuse.
- [ ] Ensure `notifyClient` payload includes new onboarding fields without breaking current UI readers.

### Phase 2: Upgrade Purchase System (~25%)

**Files:**
- `src/server/Services/UpgradeService.lua` (new)
- `src/server/Bootstrap.server.lua`
- `src/client/InteractionController.client.lua` (or `GameController.client.lua`)
- `src/shared/Config/UpgradeTuning.lua` (verify only; modify only if needed)

**Tasks:**
- [ ] Add `UpgradeService` with server-authoritative `purchaseNextCauldronTier` flow.
- [ ] Validate purchase requirements from `UpgradeTuning.getNextTier(currentTier)`:
  - coin cost
  - `BrewStats.TotalBrewed >= brewReq`
  - max tier bound
- [ ] Deduct coins and set `Upgrades.CauldronTier` atomically on success.
- [ ] Trigger `PlayerDataUpdate` after purchase.
- [ ] Wire service in `Bootstrap.server.lua` required list.
- [ ] Add/verify upgrade purchase remote endpoint and client request handling.
- [ ] Add simple upgrade UI entry point and status view (current tier, next tier cost/req, buy button state).

### Phase 3: Storage Enforcement Across Economy Paths (~25%)

**Files:**
- `src/server/Services/EconomyService.lua`
- `src/server/Services/ZoneService.lua`
- `src/client/GameController.client.lua`
- `src/client/InteractionController.client.lua`

**Tasks:**
- [ ] In `EconomyService.BuyIngredient`, enforce storage capacity before stock/coin mutation.
- [ ] In `ZoneService` forage handlers (standard + rare node), enforce storage capacity before adding ingredient.
- [ ] Return/emit consistent rejection messaging (`Storage full`) for blocked acquisitions.
- [ ] Add HUD storage text (`current / max`) sourced from `PlayerDataUpdate`.
- [ ] Disable/gray market buy interactions in UI when at capacity (UX aid only; server remains source of truth).
- [ ] Preserve existing market stock decrement logic and anti-spam cooldowns.

### Phase 4: First-Join Tutorial System (~20%)

**Files:**
- `src/server/Services/OnboardingService.lua` (new)
- `src/server/Bootstrap.server.lua`
- `src/server/Services/EconomyService.lua`
- `src/server/Services/ZoneService.lua`
- `src/server/Services/BrewingService.lua`
- `src/client/OnboardingController.client.lua` (new)

**Tasks:**
- [ ] Implement onboarding objective state machine:
  - Step 1: Forage ingredient
  - Step 2: Buy ingredient from market
  - Step 3: Start brew
  - Step 4: Claim brew result
  - Step 5: Sell potion
- [ ] Record action hooks in existing services at successful completion points only.
- [ ] Mark tutorial complete and prevent replay once all steps are done.
- [ ] Build minimal objective UI panel with current objective text + completion ticks.
- [ ] Add skip option policy: keep available but explicit (marks onboarding complete).

### Phase 5: Verification + Regression Gate (~5%)

**Tasks:**
- [ ] Upgrade purchase test for each tier transition and requirement failure paths.
- [ ] Brew duration regression check pre/post upgrade tier increase.
- [ ] Mutation chance smoke test to verify tier bonus still applied.
- [ ] Fill inventory to cap and verify buy/forage are both blocked server-side.
- [ ] Validate storage HUD updates after buy, forage, brew ingredient consumption.
- [ ] New-player tutorial full-run test from step 1 through step 5.
- [ ] Returning-player test confirms tutorial does not reappear.
- [ ] Core loop regression: brew, claim, sell, buy, forage all functional.

## API/Remote Contract Matrix

| Remote | Direction | Change | Notes |
|--------|-----------|--------|-------|
| `BuyIngredient` | Client -> Server | Preserve | Add storage-cap validation before transaction |
| `ForageNode` | Client -> Server | Preserve | Add storage-cap validation before grant |
| `BrewPotion` | Client -> Server | Preserve | Hook onboarding step completion only |
| `ClaimBrewResult` | Client -> Server | Preserve | Hook onboarding step completion only |
| `SellPotion` | Client -> Server | Preserve | Hook onboarding step completion only |
| `PlayerDataUpdate` | Server -> Client | Extend payload | Include onboarding state + storage usage derivables |
| `PurchaseCauldronUpgrade` | Client -> Server | New | Server-authoritative upgrade purchase endpoint |

## Files Summary

| File / Area | Action | Purpose |
|-------------|--------|---------|
| `src/server/Services/PlayerDataService.lua` | Modify (major) | Datastore migration + storage/onboarding helpers |
| `src/server/Services/UpgradeService.lua` | Create | Upgrade purchase validation + mutation |
| `src/server/Services/OnboardingService.lua` | Create | Tutorial step tracking and persistence |
| `src/server/Services/EconomyService.lua` | Modify | Storage enforcement + onboarding buy/sell hooks |
| `src/server/Services/ZoneService.lua` | Modify | Storage enforcement + onboarding forage hook |
| `src/server/Services/BrewingService.lua` | Modify | Onboarding brew/claim hooks |
| `src/server/Bootstrap.server.lua` | Modify | Add new services to startup contract |
| `src/client/OnboardingController.client.lua` | Create | Guided objective UI for first-time flow |
| `src/client/GameController.client.lua` | Modify | Storage display and market UX disable state |
| `src/client/InteractionController.client.lua` | Modify | Upgrade UI trigger integration |

## Definition of Done

- [ ] Player can purchase cauldron upgrades through all valid tiers with correct cost/requirements.
- [ ] Invalid upgrade purchases fail cleanly (insufficient coins, brew requirement unmet, max tier reached).
- [ ] Brew time and mutation bonus reflect upgraded cauldron tier in live gameplay.
- [ ] Storage capacity is enforced on market buy and forage acquisition paths.
- [ ] Storage usage is visible in HUD and updates from authoritative server state.
- [ ] First-join tutorial guides player through all 5 objectives and persists completion.
- [ ] Tutorial does not replay for completed players unless explicitly reset.
- [ ] No regression in existing market refresh, brew, claim, sell, and forage loops.
- [ ] No new server warnings/errors during core loop playtest.

## Risks & Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Datastore migration introduces nil-field edge cases | Medium | High | Defensive defaults in migration + idempotent field initialization |
| Storage cap logic diverges across buy vs forage | Medium | Medium | Centralize checks in `PlayerDataService.canAddIngredients` |
| Onboarding step completion triggers out of order | Medium | Medium | Enforce deterministic state machine keyed by expected next step |
| Upgrade purchase race/double-fire | Low | Medium | Server-side validation per request + existing action cooldown patterns |
| Client UI mismatch with server rejects | Medium | Low | Keep UI as hint only; rely on server rejection + `PlayerDataUpdate` reconciliation |

## Security Considerations

- Upgrade purchases are server-authoritative; client never writes tier or coin values directly.
- Storage enforcement occurs server-side before inventory mutation to prevent overfill exploits.
- Onboarding progression is recorded from validated server actions, not client claims.
- Existing remote payload validation patterns (type checks, quantity bounds, cooldowns) are preserved.

## Dependencies

- Sprint 008 world/prompt contracts (`Cauldron`, `MarketStall`, `SellCounter`, `ForageNode_*`).
- Sprint 009 market authority changes (`_G.MarketService.deductStock`, `MarketRefresh`).
- Existing `UpgradeTuning` tier table and `BrewingService` tier effect application.

## Open Questions

1. Should storage capacity count total ingredient units (recommended) or unique ingredient types?
2. Should tutorial skip mark completion permanently, or only for current session?
3. Should upgrade access be a world interaction point (NPC/station) or HUD-driven panel in this sprint?
4. Do we want to ship storage-slot upgrades this sprint, or keep `StorageSlots` fixed at 20 and defer expansion economy to Sprint 011?

## Assumptions

- Service scripts continue using the existing `_G.*Service` pattern for cross-service calls.
- `Remotes` container already exists and can be extended with one new upgrade purchase endpoint.
- A lightweight onboarding panel is sufficient; no cinematic cutscenes are required this sprint.
