# Sprint 001 Merge Notes

## Claude Draft Strengths
- Concrete starter content tables (8 ingredients, 11 recipes with exact IDs, costs, and sell values)
- Clear iterative build strategy showing how all 9+ sprints connect
- Detailed architecture diagram with clean service decomposition
- Good use case descriptions for the core loop

## Codex Draft Strengths
- Correctly baselined to all 4 interview constraints as non-negotiable scope anchors
- Explicit "Scope Anchors" section — good pattern for communicating hard requirements
- Better data model specification (PlayerState schema with Version field for migrations)
- DataStore persistence architecture with autosave, retry/backoff, BindToClose
- Exit Criteria Demo Script — concrete step-by-step verification walkthrough
- Wild Grove foraging included as a day-one zone with actual gameplay
- Recipe Book UI included in Sprint 001
- MarketTuning config as separate module — good for iteration
- ZoneService as a dedicated server service

## Valid Critiques Accepted
1. **Critical: Scope mismatch** — Claude's draft was written before the interview and proposed single-room + session-only. Codex is correct: the final sprint must honor all 4 interview constraints. ACCEPTED.
2. **High: DoD validates wrong slice** — Claude's DoD didn't include zone traversal, persistence, or market refresh checks. ACCEPTED.
3. **High: Sprint sequencing debt** — Deferring persistence and zones would force rewrites. ACCEPTED.
4. **Medium: Market under-specified** — Rotating stock needs explicit scheduler, rarity weights, stock quantities, client broadcasting. ACCEPTED.
5. **Medium: Persistence/security incomplete** — Need DataStore schema versioning, retry/backoff, autosave cadence, leave/close saves. ACCEPTED.

## Critiques Rejected (with reasoning)
- None rejected. All critiques are valid because Claude's draft was written pre-interview. The merge must fully incorporate interview decisions.

## Interview Refinements Applied
- Full 4-zone map with teleportation in Sprint 001
- Marketplace models for art from day one
- 5-minute rotating market stock with rarity-weighted selection
- DataStore persistence from day one

## Final Decisions
1. **Use Codex's structure** as the base (scope anchors, 5-phase implementation, exit criteria demo)
2. **Incorporate Claude's concrete content** (ingredient table, recipe table with exact values, architecture diagram)
3. **Add Claude's iterative roadmap** showing how future sprints build on this foundation
4. **Keep Codex's data model** (PlayerState with Version, MarketState)
5. **Merge both file lists** into a unified summary
6. **Use Codex's DoD** which validates the correct product slice
7. **Add Claude's economy detail** (specific coin values, profit margin analysis)
8. **Include Wild Grove foraging** from Codex's draft as day-one content
9. **Include Recipe Book UI** from Codex's draft
