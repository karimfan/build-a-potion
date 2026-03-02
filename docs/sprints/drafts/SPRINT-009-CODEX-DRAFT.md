# Sprint 009: Trading Post Experience Hardening — Always-Stocked Market, Guaranteed Rare Rotation, Merchant Presence

## Overview

Sprint 009 stabilizes and upgrades the market/trading-post experience by fixing critical economy-path reliability gaps and adding clear marketplace atmosphere. The core gameplay promise is simple: players should always be able to buy ingredients, periodically see exciting higher-tier inventory, and feel like they are interacting with a living market.

This sprint is not a net-new system expansion; it is a targeted hardening and polish pass over existing buy/sell infrastructure. The highest-priority outcome is correctness: market stock must be server-authoritative and mutable, buy actions must actually consume stock, and refresh generation must guarantee minimum availability floors. On top of that, we add a visual merchant NPC to reinforce place identity without introducing new gameplay mechanics.

## Scope Anchors (Non-Negotiable)

1. Market always has purchasable items after each refresh (guaranteed minimum stock floor).
2. Every 5-minute market refresh includes at least one Rare-or-better offer.
3. Buying ingredients decrements server stock correctly (`deductStock` implemented and wired).
4. Existing remote contracts remain intact: `BuyIngredient`, `SellPotion`, `GetMarketOffers`, `MarketRefresh`.
5. Add at least one visible NPC merchant standing behind the active market stall.
6. Selling flow remains fully functional (no regressions to Daily Demand multipliers or score hooks).

## Use Cases

1. **Buyer opens market at any time**: sees non-empty inventory and can purchase at least one item.
2. **Buyer purchases limited stock**: stock decreases for all players after purchase and reaches sold-out state correctly.
3. **Player waits for refresh**: every refresh includes at least one Rare/Mythic/Divine listing.
4. **Seller uses Trading Post**: selling still applies mutation pricing and Daily Demand bonus.
5. **Player enters market zone**: sees a merchant character stationed at the stall, increasing marketplace clarity.

## Architecture

### Current Reliability Gaps to Address

```text
EconomyService.BuyIngredient -> expects _G.MarketService.deductStock(...)
MarketService currently publishes GetMarketOffers/MarketRefresh state
but does not expose a module API or deductStock implementation.

Result: buy path is non-authoritative/non-functional risk and cannot safely mutate stock.
```

### Target Server Authority Model

```text
MarketService (authoritative market state)
  - generateOffers() with tier floors/guarantees
  - getStateSnapshot()
  - deductStock(ingredientId, qty) -> bool, reason
  - broadcastState() after refresh or stock mutations

EconomyService
  - validates player + coins + ingredient
  - calls MarketService.deductStock() first
  - applies coin/inventory mutation only if stock mutation succeeds
  - notifies requesting player + market listeners
```

### Data/Refresh Guarantees

```text
Per refresh:
  - Guaranteed minimum total offers (non-empty market)
  - Guaranteed Common floor
  - Guaranteed Rare+ floor (>=1 offer among Rare/Mythic/Divine)
  - Tier caps still enforced to avoid overflow

Per purchase:
  - Atomic stock decrement on server state
  - Reject when offer missing or stock insufficient
  - Broadcast updated MarketState to clients
```

## Implementation Plan

### Phase 1: Market Service Contract Fix (~25%)

**Files:**
- `src/server/Services/MarketService.lua` - convert to explicit service module contract used via `_G`
- `src/server/Bootstrap.server.lua` - ensure initialization order assumptions still hold

**Tasks:**
- [ ] Refactor `MarketService.lua` into a module-backed service pattern consistent with other `_G.*Service` usage.
- [ ] Add `module.getState()` (snapshot clone) for safe read access.
- [ ] Add `module.deductStock(ingredientId, quantity)` with strict validation.
- [ ] Add `module.refreshNow()`/internal refresh orchestration that centralizes broadcasts.
- [ ] Register `_G.MarketService = module` after initialization.
- [ ] Preserve existing `GetMarketOffers` and `MarketRefresh` remote behavior.

### Phase 2: Stock Generation Guarantees + Tuning Wiring (~20%)

**Files:**
- `src/server/Services/MarketService.lua`
- `src/shared/Config/MarketTuning.lua`
- `src/shared/Types.lua` (only if shared constants are required)

**Tasks:**
- [ ] Replace hardcoded generation knobs with `MarketTuning` values where possible.
- [ ] Enforce minimum non-empty market floor.
- [ ] Enforce guaranteed Rare+ offer per refresh (deterministic fallback injection if RNG misses).
- [ ] Keep tier caps and ingredient uniqueness constraints.
- [ ] Emit refresh diagnostics showing counts per tier and guarantee-path usage.

### Phase 3: Buy Flow Hardening + Client Sync (~20%)

**Files:**
- `src/server/Services/EconomyService.lua`
- `src/client/GameController.client.lua`

**Tasks:**
- [ ] Update buy path to handle `deductStock` return reason and avoid partial transactions.
- [ ] Ensure failed purchases do not mutate local client stock optimistically.
- [ ] Trigger authoritative market state refresh to all clients after successful buys.
- [ ] Preserve existing UX while preventing desync (stock shown should match server truth).
- [ ] Keep anti-spam cooldown behavior intact.

### Phase 4: Merchant NPC Placement (~15%)

**Files/Areas:**
- `Workspace/Zones/IngredientMarket` (preferred) and/or `Workspace/Zones/TradingPost`
- Optional helper under `src/server/Services/` only if runtime spawn is required

**Tasks:**
- [ ] Place one merchant NPC behind `MarketStall` with stable anchor/collision settings.
- [ ] Ensure NPC is visual only (no required prompt/remotes attached).
- [ ] Verify NPC does not obstruct player pathing or stall prompt interaction radius.
- [ ] Match zone visual tone from Sprint 008 rebuild.

### Phase 5: Regression & Compatibility Pass (~20%)

**Files:**
- `src/server/Services/EconomyService.lua`
- `src/server/Services/DailyDemandService.lua`
- `src/client/InteractionController.client.lua`
- `src/client/GameController.client.lua`

**Tasks:**
- [ ] Validate SellPotion still computes mutation-aware pricing correctly.
- [ ] Validate Daily Demand multiplier still applies to base potion ID.
- [ ] Validate Market GUI updates correctly on `MarketRefresh` events.
- [ ] Verify no regressions to buy/sell prompt flows (`MarketStall`, `SellCounter`).
- [ ] Confirm no new remote endpoints are required.

## API/Remote Contract Matrix

| Remote | Direction | Change | Notes |
|--------|-----------|--------|-------|
| `GetMarketOffers` | Client -> Server (invoke) | Preserve | Returns current market snapshot |
| `MarketRefresh` | Server -> Client (event) | Preserve | Fired on scheduled refresh and post-purchase stock mutation |
| `BuyIngredient` | Client -> Server (event) | Preserve | Server-side behavior hardened, no signature change |
| `SellPotion` | Client -> Server (event) | Preserve | No contract change |

## Files Summary

| File / Area | Action | Purpose |
|-------------|--------|---------|
| `src/server/Services/MarketService.lua` | Modify (major) | Authoritative stock mutation API + guaranteed refresh generation |
| `src/shared/Config/MarketTuning.lua` | Modify | Centralize market generation/tier-floor tuning |
| `src/server/Services/EconomyService.lua` | Modify | Buy transaction safety and stock-consumption integration |
| `src/client/GameController.client.lua` | Modify | Remove/limit optimistic stock behavior; honor authoritative refresh |
| `Workspace/Zones/IngredientMarket` | Modify | Add visual merchant NPC behind stall |
| `src/server/Bootstrap.server.lua` | Verify/minor modify | Ensure service init order remains deterministic |

## Definition of Done

- [ ] Market refreshes every 300s and never results in empty purchasable inventory.
- [ ] Each refresh contains at least one Rare-or-higher offer.
- [ ] Buying ingredient decreases server stock; insufficient stock rejects cleanly.
- [ ] Market stock change propagates to connected clients reliably.
- [ ] Existing buy/sell/remotes remain backward compatible.
- [ ] Sell flow (including Daily Demand multiplier) passes regression tests.
- [ ] Merchant NPC is visible in market zone and does not interfere with interactions.
- [ ] No new warnings/errors introduced during core buy/sell gameplay path.

## Verification Plan

1. **Market non-empty test**: trigger multiple refreshes; assert offer count > 0 each cycle.
2. **Rare+ guarantee test**: on each refresh, assert at least one offer tier in `{Rare, Mythic, Divine}`.
3. **Stock decrement test**: buy same ingredient repeatedly until stock zero; next purchase must fail.
4. **Multi-client sync test**: two clients open market; one buys item; both clients see updated stock.
5. **Economy integrity test**: failed buy does not deduct coins or add inventory.
6. **Sell regression test**: sell normal and mutated potion; validate payout and demand multiplier behavior.
7. **NPC placement test**: verify merchant is present and prompt interactions still trigger correctly.

## Risks & Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Service refactor introduces startup ordering bug | Medium | High | Keep `_G.MarketService` registration explicit and verified at startup |
| Client stock desync due to optimistic decrement | High | Medium | Make server broadcast authoritative state post-purchase; avoid local-only mutation |
| Rare+ guarantee over-concentrates on same ingredients | Medium | Low | Shuffle pools + fallback from eligible unseen rare pool |
| Tuning migration changes market feel too much | Medium | Medium | Preserve current caps/floors as baseline, tune minimally this sprint |
| NPC collides with players/prompt | Low | Medium | Anchor and non-blocking collision policy; validate prompt access radius |

## Security Considerations

- All market mutations remain server-authoritative.
- No client-provided price/stock values are trusted.
- Buy transaction ordering stays stock-check -> coin/inventory mutation to prevent dupes.
- Remote payload validation remains strict for `ingredientId` and `quantity` bounds.

## Dependencies

- Sprint 006 economy/scoring infrastructure (ScoreService, DailyDemandService).
- Sprint 008 zone rebuild outputs (market stall placement and pathing).
- Existing ingredient catalog and market eligibility metadata in `Ingredients.lua`.

## Open Questions

1. Should the merchant NPC be duplicated in both `IngredientMarket` and `TradingPost`, or only at `MarketStall` for this sprint?
2. Should Rare+ refresh events use existing `GlobalAnnouncement` now, or defer announcements to a later UX sprint?
3. Do we want strict minimum count for Rare+ (exactly 1) or allow tunable floor (1..N) from `MarketTuning`?

## Assumptions

- `CLAUDE.md` is not present in this repository; planning conventions were derived from `docs/sprints/README.doc`, latest sprint documents, and existing draft patterns.
