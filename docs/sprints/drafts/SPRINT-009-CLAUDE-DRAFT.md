# Sprint 009: Trading Post Experience — Always-Stocked Market, Rare Flash Sales, NPC Merchant

## Overview

The market experience needs to feel alive and reliable. Currently, stock generation is probabilistic — sometimes players find nothing interesting for sale. The `deductStock()` function is missing, so bought items never decrease. And the market stalls are lifeless — no merchant character to sell to you.

This sprint delivers three improvements: (1) guaranteed always-stocked market with minimum offerings per tier, (2) a guaranteed Rare+ "flash sale" item every 5-minute refresh cycle, and (3) a visible NPC merchant character behind the market stall to give life to the marketplace.

## Use Cases

1. **New player visits market**: Always finds Common and Uncommon ingredients for sale. Never sees an empty market.
2. **Returning player checks market**: Every 5 minutes, a guaranteed Rare or better item appears — creates a reason to check back.
3. **Player buys items**: Stock actually decreases. When stock hits 0, item shows "Sold Out." Other players see the same stock.
4. **Visual atmosphere**: An NPC merchant stands behind the stall, making the market feel like a real trading post.

## Architecture

### Stock Generation (Enhanced)

```
generateOffers():
  1. Guarantee minimums:
     - At least 4 Common ingredients (always)
     - At least 2 Uncommon ingredients (always)
     - At least 1 Rare+ ingredient (flash sale, guaranteed)
  2. Roll additional offers probabilistically (existing logic)
  3. Mark the guaranteed Rare+ as "Flash Sale" with visual indicator
```

### deductStock() Implementation

```
deductStock(ingredientId, quantity):
  1. Find offer in MarketState.Offers by ingredientId
  2. If offer.stock >= quantity: deduct and return true
  3. If offer.stock < quantity: return false (reject buy)
  4. Broadcast updated MarketState to all clients
```

### NPC Merchant (Visual Only)

```
MCP run_code:
  - Insert R15 NPC model behind MarketStall
  - Anchor, disable scripts
  - Add merchant-themed clothing parts
  - Add PointLight for warmth
  - Optional: BillboardGui with "Merchant" label
```

## Implementation Plan

### Phase 1: Fix deductStock + Always-Stocked Guarantees (~40%)

**Files:**
- `src/server/Services/MarketService.lua` — Add deductStock(), enhance generateOffers()
- `src/shared/Config/MarketTuning.lua` — Wire up config instead of hardcoded values

**Tasks:**
- [ ] Implement `MarketService.deductStock(ingredientId, quantity)`:
  - Find offer by ingredientId in MarketState.Offers
  - Validate stock >= quantity
  - Deduct stock
  - Broadcast updated state to all clients via MarketRefresh remote
  - Return success/failure boolean
- [ ] Update `EconomyService.BuyIngredient` to check deductStock return value
- [ ] Enhance `generateOffers()` with guaranteed minimums:
  - Always include at least 4 Common ingredients
  - Always include at least 2 Uncommon ingredients
  - Always include at least 1 Rare+ ingredient (the "flash sale")
- [ ] Mark flash sale items with a `flashSale = true` flag in offer data
- [ ] Wire up MarketTuning.lua values instead of hardcoded constants

### Phase 2: Flash Sale Announcements + Client UI (~30%)

**Files:**
- `src/server/Services/MarketService.lua` — Flash sale announcement
- `src/client/GameController.client.lua` — Flash sale visual indicator in market GUI

**Tasks:**
- [ ] On refresh, if flash sale item is Rare+, broadcast global announcement:
  - Format: "Flash Sale! [Ingredient Name] now available at the Market!"
  - Use existing announcement system (Remotes.GlobalAnnouncement)
- [ ] In market GUI, highlight flash sale items:
  - Gold border/frame around flash sale cards
  - "FLASH SALE" badge overlay
  - Pulsing glow effect on the card
- [ ] Show "Sold Out" state when stock reaches 0 (disable buy button, grey out)

### Phase 3: NPC Merchants in Both Zones (~20%)

**Files:**
- Workspace via MCP — Place NPC models

**Tasks:**
- [ ] Create NPC merchant behind MarketStall in IngredientMarket:
  - R15 humanoid rig (anchored, no scripts)
  - Positioned behind stall counter facing players
  - Merchant-themed: hooded robe, warm colors
  - BillboardGui with "Merchant" label
  - Warm PointLight for atmosphere
- [ ] Create NPC merchant behind SellCounter in TradingPost:
  - Similar R15 rig, different colors (gold/brown for trade theme)
  - BillboardGui with "Trader" label
  - Positioned behind sell counter
- [ ] Both NPCs: anchored, no blocking player movement, behind counters

### Phase 4: Verification (~10%)

**Tasks:**
- [ ] Playtest: open market, verify 4+ Common, 2+ Uncommon, 1+ Rare always present
- [ ] Buy items, verify stock decreases in GUI
- [ ] Wait for refresh, verify flash sale item appears with visual indicator
- [ ] Sell potions at TradingPost, verify coins increase
- [ ] Visual check: NPC stands behind stall

## Files Summary

| File | Action | Purpose |
|------|--------|---------|
| `src/server/Services/MarketService.lua` | Modify | Add deductStock, enhance generateOffers, flash sale logic |
| `src/server/Services/EconomyService.lua` | Modify | Check deductStock return value on buy |
| `src/shared/Config/MarketTuning.lua` | Modify | Wire up as source of truth for market config |
| `src/client/GameController.client.lua` | Modify | Flash sale UI indicators, sold-out state |
| Workspace (MCP) | Create | NPC merchant model behind MarketStall |

## Definition of Done

- [ ] Market always has 4+ Common, 2+ Uncommon, 1+ Rare+ items
- [ ] deductStock() works — buying reduces stock, stock=0 shows "Sold Out"
- [ ] Flash sale Rare+ item guaranteed every refresh with visual indicator
- [ ] Flash sale announced globally on refresh
- [ ] NPC merchant visible behind market stall
- [ ] Existing buy/sell flows work without regression
- [ ] No infinite buying exploit (deductStock validates stock > 0)

## Risks & Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| deductStock race condition (two players buy last item simultaneously) | Medium | Low | Server-side atomic check-and-deduct in single function |
| Flash sale always same item | Low | Low | Use random selection from Rare+ pool each refresh |
| NPC model too large / blocks stall | Low | Medium | Position behind counter, test in play mode |
| MarketRefresh broadcast too frequent | Low | Low | Only broadcast on stock change, not on every buy |

## Security Considerations

- deductStock must be server-authoritative (no client trust)
- Rate limit on BuyIngredient already exists (0.5s cooldown)
- Stock validation prevents buying more than available

## Dependencies

- Sprint 008 visual rebuild (completed — zones are clean)
- Existing MarketService, EconomyService, GameController patterns
