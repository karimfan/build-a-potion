# Sprint 009 Intent: Trading Post Experience — Always-Stocked Market, Rare Flash Sales, NPC Merchant

## Seed

We need to flesh out the trading post experience, both for buying and selling:
* There should always be items for sale.
* Every so often, like every 5 mins a rare or more item goes on sale.
* We should have a person stand behind the stall, just to give it the impression of a marketplace.

## Context

- The market already has a 5-minute refresh cycle (MarketService.lua) generating tiered stock, but stock can randomly have zero rare+ items
- `deductStock()` is MISSING from MarketService — buying doesn't reduce stock (infinite buying bug)
- Selling works via SellCounter with daily demand multipliers
- No NPC/merchant character exists in any zone — interactions are purely proximity prompt → GUI
- Buying is in IngredientMarket zone, selling in TradingPost zone
- MarketTuning.lua exists but is not used; values are hardcoded in MarketService

## Recent Sprint Context

- **Sprint 006**: Economy, scoring, daily demand, cauldron upgrades — established the economic foundation
- **Sprint 007**: Zone overhaul plan — potion displays, grove expansion, zone polish
- **Sprint 008**: Nuclear visual rebuild — all zones rebuilt with clean designs, flat ground, working foraging

## Relevant Codebase Areas

- `src/server/Services/MarketService.lua` — Stock generation, refresh loop, offers API
- `src/server/Services/EconomyService.lua` — BuyIngredient, SellPotion handlers
- `src/client/GameController.client.lua` — Market GUI rendering, buy button logic
- `src/client/InteractionController.client.lua` — Proximity prompt routing
- `src/shared/Config/MarketTuning.lua` — Unused config (should be wired up)
- `src/shared/Config/Ingredients.lua` — 58 ingredients with marketChance per tier
- `src/server/Services/DailyDemandService.lua` — Daily demand multipliers

## Constraints

- Server-authoritative: all economy mutations on server
- Must preserve existing remote event contracts (BuyIngredient, SellPotion, GetMarketOffers, MarketRefresh)
- No breaking changes to ingredient/potion data structures
- NPC is visual only (no new gameplay mechanics attached to NPC itself)

## Success Criteria

1. Market always has items for sale — guaranteed minimum stock across tiers
2. Every 5 minutes, at least one Rare+ item appears (guaranteed, not random chance)
3. A visible NPC character stands behind the market stall
4. deductStock() is implemented (stock actually decreases when buying)
5. Existing buy/sell flows continue to work

## Verification Strategy

- Play test: open market GUI, verify items always present
- Wait 5 minutes, verify rare+ item appears
- Buy items, verify stock decreases
- Sell potions, verify coins increase
- Visual check: NPC stands behind stall

## Uncertainty Assessment

- Correctness uncertainty: **Low** — extending well-understood market system
- Scope uncertainty: **Low** — three clear deliverables
- Architecture uncertainty: **Low** — all within existing patterns

## Open Questions

1. Should the NPC be in the IngredientMarket (buying zone) or TradingPost (selling zone) or both?
2. Should the "rare flash sale" be announced globally like current Mythic/Divine announcements?
3. Should stock deduction be broadcast to all players so they see items selling out?
