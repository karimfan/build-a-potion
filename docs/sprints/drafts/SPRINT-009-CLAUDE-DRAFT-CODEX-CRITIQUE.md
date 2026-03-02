# Sprint 009 Claude Draft Critique (Codex)

## Overall Assessment

Claude’s draft has a strong direction and captures the product intent clearly: always-stocked market, guaranteed Rare+ cadence, real merchant presence, and stock deduction correctness. The structure is readable and implementation-oriented.

The major gaps are in execution realism against the current codebase. The plan under-specifies core service wiring required to make `deductStock()` actually callable, leaves an existing client/server stock-desync behavior unaddressed, and expands scope beyond intent in ways that increase sprint risk.

## Findings (Ordered by Severity)

### 1. Critical: Missing service-contract fix for `MarketService` means `deductStock()` plan is incomplete

**Where:** Phase 1 (`MarketService.lua`, `EconomyService.lua`)

**Problem:** `EconomyService` calls `_G.MarketService`, but current `MarketService.lua` is script-style and does not expose `_G.MarketService` module APIs. Adding a `deductStock()` function inside the file is insufficient unless the service is explicitly exported/registered for `_G` consumption.

**Why this matters:** Buy flow reliability is the sprint’s highest-priority functional fix. Without service wiring, buy can still fail at runtime regardless of generation logic.

**Required amendment:** Add explicit service contract work:
- `_G.MarketService = module`
- `module.deductStock(...)`
- `module.getState()` or equivalent
- Verify Bootstrap/init ordering assumptions.

### 2. High: Client-side optimistic stock decrement desync is not addressed

**Where:** Phase 2 UI tasks and DoD

**Problem:** Current `GameController.client.lua` decrements local `offer.stock` immediately on click before server confirmation. If server rejects (rate limit, insufficient stock, service failure), client can show incorrect stock until next refresh.

**Why this matters:** Draft promises “other players see same stock” and “sold out correctness,” but without fixing optimistic local mutation this remains inconsistent.

**Required amendment:** Include explicit client hardening:
- Do not mutate local stock pre-ack, or
- Immediately reconcile from server-authoritative `MarketRefresh` on buy response.

### 3. High: Scope drift adds unrequested features that raise risk

**Where:** Phase 2 and Phase 3

**Problem:** The plan introduces flash-sale badges, pulsing glow effects, global announcements, and a second NPC at `SellCounter`. The intent asks for guaranteed Rare+ availability and a merchant presence, not a full flash-sale UX + dual-zone NPC rollout.

**Why this matters:** Sprint risk increases without clear necessity; visual polish items can consume time needed for service correctness and regression safety.

**Required amendment:** Re-scope to intent-minimum first:
- One guaranteed Rare+ offer per refresh.
- One merchant NPC at market stall.
- Make announcements/UI flair optional stretch goals.

### 4. High: Guarantee algorithm is under-specified for edge cases

**Where:** Architecture “Stock Generation (Enhanced)”

**Problem:** The draft states fixed minimums (4 Common, 2 Uncommon, 1 Rare+) but does not specify fallback behavior when tier pools/chances/caps conflict.

**Why this matters:** In production data, pool constraints or cap interactions can silently violate guarantees.

**Required amendment:** Define deterministic fallback sequence:
1. Roll normal generation with caps.
2. Backfill missing floors using unique eligible items from tier pools.
3. If a tier pool is exhausted, log and degrade predictably (never empty market).

### 5. Medium: Risk table understates broadcast/update cost and contradicts task behavior

**Where:** Risks & Mitigations

**Problem:** Risk says “MarketRefresh broadcast too frequent” mitigation is “only broadcast on stock change, not on every buy.” But every successful buy is a stock change.

**Why this matters:** This contradiction hides potential network/update churn and implementation ambiguity.

**Required amendment:** Clarify intended model:
- Broadcast on successful buy (authoritative correctness),
- Keep payload compact and throttled only if required,
- Or add selective delta events (future sprint).

### 6. Medium: Regression plan is too shallow for economy-critical changes

**Where:** Phase 4 Verification

**Problem:** Verification steps are mostly manual and single-client; they omit failure-path and concurrency checks.

**Why this matters:** This sprint touches transaction correctness and shared stock state.

**Required amendment:** Add explicit checks for:
- Two-player “last stock” contention.
- Failed purchase leaves coins/inventory unchanged.
- Sell flow regression (mutation and DailyDemand multiplier unaffected).
- Stock sync across two clients post-purchase.

### 7. Medium: DoD is stronger than implementation detail in places

**Where:** Definition of Done

**Problem:** DoD asserts no infinite buying exploit and shared stock correctness, but implementation tasks do not include explicit atomicity/reason-code handling, state cloning safety, or init-order validation.

**Required amendment:** Add dedicated task items for transaction atomicity and service initialization verification.

### 8. Low: “MCP run_code” architecture note is tooling-specific and not sprint-document portable

**Where:** NPC Merchant architecture subsection

**Problem:** References execution mechanism rather than architecture/output.

**Why this matters:** Sprint docs should remain implementation-portable and tool-agnostic.

**Required amendment:** Replace with workspace placement requirements and acceptance criteria only.

## Strengths Worth Keeping

1. Clear articulation of user-facing goals and why this sprint matters.
2. Good emphasis on server-authoritative stock mutation via `deductStock()`.
3. Practical phase layout with file-level pointers.
4. Inclusion of sold-out state and shared-stock expectations.

## Recommended Amendments Before Merge

1. Add explicit `MarketService` module/export wiring and `_G` registration tasks.
2. Add client desync fix for optimistic stock decrement in `GameController.client.lua`.
3. Trim scope to core intent (single NPC + guaranteed Rare+ + stock correctness), treating flash-sale polish as optional.
4. Specify deterministic fallback algorithm for guarantee floors.
5. Expand regression suite to include multi-client and failure-path tests.
6. Replace tool-specific NPC instructions with environment-level acceptance criteria.

## Bottom Line

Claude’s draft is directionally correct and close to mergeable, but it is not execution-safe yet for the highest-risk objective (buy/stock correctness). Addressing service wiring, client sync correctness, and scope control will make it sprint-ready.
