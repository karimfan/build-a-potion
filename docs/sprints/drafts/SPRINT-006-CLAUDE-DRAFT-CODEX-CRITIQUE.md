# Sprint 006 Claude Draft: Codex Critique

## Executive Summary

Claude’s draft is strong on coverage and detail, but it violates a critical interview requirement: it scopes leaderboard to per-server for this sprint rather than global cross-server `OrderedDataStore`. It also introduces a fallback prioritization that implies possible scope cuts, conflicting with the explicit direction that all systems must ship.

## What Claude Draft Gets Right

1. **Comprehensive system list**: Includes all six requested systems plus migration and validation.
2. **Good service decomposition**: Proposes clear new modules (`ScoreService`, `DailyDemandService`, `LeaderboardService`).
3. **Practical data model additions**: V4 profile fields are additive and migration-aware.
4. **Concrete implementation phases**: Task-level clarity is high and execution-friendly.
5. **Server-authoritative posture**: Security section correctly keeps score/economy logic off client.

## High-Severity Issues

1. **Leaderboard scope contradicts interview requirement**
- Claude draft says: “per-server for this sprint (global OrderedDataStore in future).”
- Interview finding requires: **global cross-server now** using `OrderedDataStore`.
- Impact: misses a non-negotiable product constraint and would force redesign next sprint.

2. **Risk mitigation implies scope cuts**
- Claude draft mitigation says to prioritize systems in sequence if scope is too much.
- Interview finding requires: **no scope cuts; all systems must ship**.
- Impact: plan can be interpreted as partial delivery approval under schedule pressure.

## Medium-Severity Issues

1. **Leaderboard architecture under-specified for global operation**
- Even aside from scope mismatch, there is no write-throttle/read-cadence strategy for a global board.
- Missing explicit plan for `OrderedDataStore` write frequency, rank fetch cadence, and fallback behavior.

2. **Progression tuning is not wired to measurable targets**
- Draft states the 30-minute generosity goal, but DoD lacks measurable acceptance thresholds besides one early coin target.
- Could lead to subjective tuning completion without hard pass/fail checks.

3. **Daily demand persistence details are thin**
- Mentions deterministic date seed but doesn’t specify authoritative storage lifecycle (date key, regeneration guard, UTC rollover handling).
- Risk of split-brain state if servers initialize demand differently around day boundaries.

## Low-Severity Issues

1. **Potential overlap between `GameController` and `InteractionController` responsibilities**
- UI responsibilities are split across both files without explicit ownership boundary.

2. **Announcement criteria might over-fire**
- Triggering for Mythic/Divine plus Golden mutation may create noisy UX unless queue/rate limits are defined.

## Concrete Corrections Recommended

1. Replace leaderboard phase with explicit **global `OrderedDataStore` implementation in Sprint 006**, including:
- score write throttling policy,
- top-N fetch cadence,
- player-rank context strategy,
- failure fallback behavior.

2. Replace “prioritize if overloaded” language with a **full-delivery execution model**:
- all feature phases remain required,
- integration/testing phase protects quality,
- no feature de-scope path in sprint text.

3. Tighten DoD with measurable criteria:
- global leaderboard visible and updating across two separate servers,
- demand rollover verified at UTC boundary,
- progression checkpoints at 10/30/60 minutes with target ranges.

4. Add explicit ownership boundaries:
- `InteractionController` for input/view routing,
- `GameController` for HUD state and rendering,
- avoid duplicate timer logic.

## Final Assessment

Claude’s draft is close and structurally solid, but it is not compliant with the interview constraints as written. The two blocking corrections are: (1) make leaderboard global cross-server in this sprint via `OrderedDataStore`, and (2) remove any wording that permits scope cuts. Once corrected, the plan is viable.
