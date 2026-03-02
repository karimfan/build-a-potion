# Sprint 009 Merge Notes

## Claude Draft Strengths
- Clear product framing (always-stocked, flash sales, NPCs)
- Flash sale banner announcement (user requested)
- NPCs in both zones (user confirmed in interview)

## Codex Draft Strengths
- Identified critical `_G.MarketService` registration gap
- Client optimistic desync fix
- Deterministic fallback algorithm for tier guarantees
- Stronger regression/verification plan with multi-client checks
- Better service contract specification

## Valid Critiques Accepted
1. MarketService must be exported as `_G.MarketService = module` — added to Phase 1
2. Client optimistic stock decrement must be removed/reconciled — added to Phase 3
3. Guarantee algorithm needs deterministic fallback (not just "include at least X") — specified
4. Regression tests need failure-path and multi-client checks — expanded verification

## Critiques Rejected
- "Scope drift" on dual NPC and banner — user explicitly requested both in interview
- "Tool-specific NPC instructions" — MCP run_code is how we build in this project, not an abstraction leak

## Interview Refinements Applied
- Banner announcement when flash sale drops (not countdown timer)
- NPCs in both IngredientMarket AND TradingPost

## Final Decisions
- MarketService refactored to module pattern with `_G.MarketService`
- deductStock with atomic check-and-deduct, broadcasts state after
- Client removes optimistic stock mutation, waits for server refresh
- Guaranteed: 4 Common, 2 Uncommon, 1 Rare+ per refresh (deterministic fallback)
- Banner announcement on flash sale via GlobalAnnouncement remote
- NPCs in both zones (Merchant + Trader)
