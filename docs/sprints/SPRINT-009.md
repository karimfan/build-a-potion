# Sprint 009: Trading Post Experience — Always-Stocked Market, Flash Sales, NPC Merchants

## Overview

The market experience needs to feel alive, reliable, and worth checking back. Currently, stock generation is purely probabilistic — players sometimes find nothing interesting. The `deductStock()` function is missing from MarketService, so buying doesn't actually reduce stock (infinite buying bug). The market stalls are lifeless — no merchant character to give the sense of a real marketplace.

This sprint delivers four improvements: (1) guaranteed always-stocked market with tier minimums, (2) a guaranteed Rare+ "flash sale" every 5-minute refresh with a banner announcement, (3) fix the stock deduction system so buying is server-authoritative, and (4) NPC merchant characters in both the IngredientMarket and TradingPost.

## Scope Anchors (Non-Negotiable)

1. Market always has purchasable items after each refresh (guaranteed tier minimums).
2. Every 5-minute refresh includes at least one Rare+ offer ("flash sale").
3. Buying ingredients decrements server stock (`deductStock` implemented, `_G.MarketService` registered).
4. Banner announcement when flash sale drops (via GlobalAnnouncement remote).
5. NPC merchant in IngredientMarket + NPC trader in TradingPost.
6. Existing remote contracts preserved: `BuyIngredient`, `SellPotion`, `GetMarketOffers`, `MarketRefresh`.
7. Client does NOT optimistically mutate stock — waits for server-authoritative refresh.

## Use Cases

1. **New player visits market**: Always finds Common and Uncommon ingredients for sale. Never empty.
2. **Player waits for refresh**: Every 5 minutes, a banner appears: "Flash Sale! [Rare Ingredient] now at the Market!" — creates urgency to check.
3. **Player buys items**: Stock decreases server-side. When stock=0, shows "Sold Out." All players see same stock.
4. **Player sells potions**: SellCounter in TradingPost still applies mutation pricing + Daily Demand multiplier.
5. **Visual atmosphere**: Merchant NPC behind buy stall, Trader NPC behind sell counter. Marketplace feels alive.

## Architecture

### MarketService Module Contract

```lua
-- MarketService must be exported as _G.MarketService
local module = {}
module.getState()                          -- returns MarketState snapshot
module.deductStock(ingredientId, qty)      -- atomic check-and-deduct, returns bool
module.broadcastState()                    -- fires MarketRefresh to all clients
_G.MarketService = module
```

### Stock Generation Algorithm (Deterministic Guarantees)

```
generateOffers():
  1. Roll normal probabilistic offers (existing logic with caps)
  2. Count offers per tier
  3. BACKFILL to meet minimums:
     - If Common < 4: randomly add unique Commons from eligible pool until 4
     - If Uncommon < 2: randomly add unique Uncommons until 2
     - If Rare+ < 1: randomly add one Rare (or Mythic if available) — this is the "flash sale"
  4. Mark the guaranteed Rare+ offer with flashSale = true
  5. Return final offers list
```

### deductStock Implementation

```
deductStock(ingredientId, quantity):
  1. Find offer in MarketState.Offers by ingredientId
  2. If not found or offer.stock < quantity: return false
  3. offer.stock -= quantity
  4. broadcastState() to all connected clients
  5. Return true
```

### Client Stock Sync (Fix Desync)

```
Current (broken): client decrements offer.stock locally on click
Fixed: client sends BuyIngredient, waits for server MarketRefresh event,
       then rebuilds market UI from authoritative state
```

## Implementation Plan

### Phase 1: MarketService Module Refactor + deductStock (~30%)

**Files:**
- `src/server/Services/MarketService.lua` — Refactor to module pattern, add deductStock, register `_G.MarketService`

**Tasks:**
- [ ] Refactor MarketService into module pattern (consistent with other `_G.*Service` exports)
- [ ] Add `module.deductStock(ingredientId, quantity)`: atomic check-and-deduct, returns boolean
- [ ] Add `module.broadcastState()`: fires `MarketRefresh` to all players with current MarketState
- [ ] Add `module.getState()`: returns MarketState for GetMarketOffers invocations
- [ ] Register `_G.MarketService = module` at end of file
- [ ] Call `broadcastState()` after each successful deductStock
- [ ] Update `EconomyService.BuyIngredient` handler to check deductStock return value before coin/inventory mutation

### Phase 2: Always-Stocked Guarantees + MarketTuning (~20%)

**Files:**
- `src/server/Services/MarketService.lua` — Enhanced generateOffers
- `src/shared/Config/MarketTuning.lua` — Wire up as source of truth

**Tasks:**
- [ ] Update `generateOffers()` with deterministic backfill:
  - After normal roll, count per-tier offers
  - Backfill Common to 4, Uncommon to 2, Rare+ to 1
  - Mark guaranteed Rare+ as `flashSale = true`
- [ ] Wire up `MarketTuning.lua` values instead of hardcoded constants
- [ ] Update MarketTuning with new fields: `minCommon=4, minUncommon=2, minRarePlus=1`
- [ ] Log generation diagnostics: tier counts, whether backfill was used

### Phase 3: Flash Sale Banner + Client Stock Fix (~25%)

**Files:**
- `src/server/Services/MarketService.lua` — Flash sale announcement
- `src/client/GameController.client.lua` — Remove optimistic stock, add flash sale UI

**Tasks:**
- [ ] On refresh, if flash sale offer exists, fire `GlobalAnnouncement` to all players:
  - Format: "Flash Sale! [Ingredient Name] now available at the Market!"
- [ ] In market GUI, highlight flash sale items:
  - Gold border around flash sale card
  - "FLASH SALE" text badge on the card
- [ ] Show "Sold Out" state when offer.stock=0 (grey out, disable buy button)
- [ ] **Remove optimistic stock decrement** in GameController buy handler
- [ ] After buy click, wait for next `MarketRefresh` event to rebuild UI (server is source of truth)

### Phase 4: NPC Merchants in Both Zones (~15%)

**Files:**
- Workspace via MCP — Place NPC models

**Tasks:**
- [ ] Create NPC merchant behind MarketStall in IngredientMarket:
  - R15 humanoid parts (anchored, no scripts, CanCollide=false)
  - Positioned behind stall counter, facing players
  - Warm-toned merchant clothing
  - BillboardGui: "Merchant" label
  - Warm PointLight (Shadows=false)
- [ ] Create NPC trader behind SellCounter in TradingPost:
  - Similar R15 rig, gold/brown theme
  - BillboardGui: "Trader" label
  - Positioned behind sell counter
- [ ] Both NPCs: anchored, behind counters, no player obstruction

### Phase 5: Verification + Regression (~10%)

**Tasks:**
- [ ] **Market non-empty test**: Open market after refresh, verify 4+ Common, 2+ Uncommon, 1+ Rare+
- [ ] **Stock decrement test**: Buy same item repeatedly until stock=0, verify "Sold Out" state
- [ ] **Failed buy test**: Attempt to buy with 0 stock, verify coins/inventory unchanged
- [ ] **Flash sale test**: Wait for refresh, verify banner appears, verify flash sale card highlighted
- [ ] **Multi-client sync**: Two clients see same stock after one buys
- [ ] **Sell regression**: Sell potion with mutation + daily demand, verify correct payout
- [ ] **NPC visual check**: Both NPCs visible, not blocking interaction prompts

## Files Summary

| File | Action | Purpose |
|------|--------|---------|
| `src/server/Services/MarketService.lua` | Major modify | Module pattern, deductStock, guarantees, flash sale |
| `src/server/Services/EconomyService.lua` | Minor modify | Check deductStock return before transaction |
| `src/shared/Config/MarketTuning.lua` | Modify | Wire up as config source of truth |
| `src/client/GameController.client.lua` | Modify | Remove optimistic stock, flash sale UI, sold-out state |
| Workspace (MCP) | Create | NPC merchants in both zones |

## Definition of Done

- [ ] Market always has 4+ Common, 2+ Uncommon, 1+ Rare+ items per refresh
- [ ] deductStock works: buying reduces stock, stock=0 = "Sold Out"
- [ ] No optimistic client stock — server is source of truth
- [ ] Flash sale Rare+ guaranteed every refresh, announced via banner
- [ ] Flash sale items visually highlighted in market GUI
- [ ] NPC merchant in IngredientMarket, NPC trader in TradingPost
- [ ] Existing buy/sell flows work without regression
- [ ] Sell correctly applies mutation + Daily Demand multipliers
- [ ] No infinite buying exploit
- [ ] `_G.MarketService` properly registered and callable

## Risks & Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| `_G.MarketService` init order issue | Medium | High | Explicit registration + Bootstrap verification |
| Race condition on last-stock buy | Medium | Low | Atomic check-and-deduct in single function, Luau is single-threaded |
| Client desync during buy→refresh gap | Low | Medium | Server broadcasts immediately after deductStock |
| Flash sale always same ingredient | Low | Low | Random selection from shuffled Rare+ pool each refresh |
| NPC blocks stall interaction | Low | Medium | CanCollide=false, positioned behind counter |

## Security Considerations

- deductStock is server-authoritative (no client trust)
- Rate limit on BuyIngredient preserved (0.5s cooldown)
- Stock validation prevents buying more than available
- No new remote endpoints introduced

## Dependencies

- Sprint 006 economy/scoring infrastructure
- Sprint 008 zone rebuild (market stall placement)
