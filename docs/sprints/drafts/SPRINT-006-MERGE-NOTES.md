# Sprint 006 Merge Notes

## Claude Draft Strengths
- Comprehensive system coverage with concrete use cases
- Detailed score formula with tier weights and mutation bonus
- Good HUD layout mockups for non-modal timer and score display
- Progression curve targets with specific minute-based milestones
- Daily Demand deterministic seed approach for cross-server consistency

## Codex Draft Strengths
- Explicit OrderedDataStore architecture with write throttle strategy
- "Full-ship" language — no scope-cut fallback paths
- Mutation point bonuses in score (separate from sell multiplier)
- Concrete leaderboard read/write cadence (30-60s poll, 30s write throttle)
- Cleaner phase decomposition with service dependencies mapped

## Valid Critiques Accepted
1. **CRITICAL: Leaderboard was per-server** — Fixed to global OrderedDataStore (already corrected in draft)
2. **CRITICAL: Scope-cut language** — Removed fallback prioritization. All systems ship.
3. **HIGH: OrderedDataStore throttling** — Added write throttle (30s min between writes per player) and read cadence (60s poll)
4. **MEDIUM: Progression targets not measurable** — Added specific coin targets at 10/30/60 minutes
5. **MEDIUM: Daily Demand UTC rollover** — Added explicit dateKey guard and regeneration logic

## Interview Refinements
1. All 6 systems must ship — no cuts
2. Global cross-server leaderboard via OrderedDataStore

## Final Decisions
- Score formula: Claude's with Codex's mutation point bonuses added
- Leaderboard: Codex's OrderedDataStore architecture with throttle/cadence
- Daily Demand: Claude's deterministic seed approach with Codex's UTC rollover guards
- Upgrades: Claude's 4-tier model
- Non-modal timer: Claude's HUD widget design
- Announcements: Merged — queue with rate limit
