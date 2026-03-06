# Critique: SPRINT-011-CLAUDE-DRAFT

## Overall Assessment

Strong product direction and a clear player-facing loop, with good use of shared tuning and server-authoritative intent. The main issues are implementation safety and scope control: several parts conflict with current `ZoneService` behavior or introduce unnecessary world-building risk for a progression-focused sprint.

## Findings (Highest Severity First)

1. **`0-star = common only` is not actually guaranteed by the proposed server logic** (`SPRINT-011-CLAUDE-DRAFT.md:52-55`, `:238`).
- Draft says Common roll uses "existing common pool (unchanged)."
- Current `ZoneService` node pools include non-common ingredients in multiple base nodes (`glowshroom_cap`, `dewdrop_pearl`, `nightshade_berry`), so 0-star players can still receive Uncommon.
- This directly conflicts with DoD item "0-star players get only commons."
- Recommendation: explicitly split/normalize base node pools by rarity in config and enforce `Common` filter at roll time.

2. **Server trust boundary is still too weak for forage node IDs** (`SPRINT-011-CLAUDE-DRAFT.md:148-151`).
- Plan validates star gates for nodes `13..18`, but does not require strict validation of *all* `nodeId` values.
- Current server code falls back to `{"mushroom"}` for unknown node IDs, so exploiters can farm with spoofed names unless this is fixed.
- Recommendation: hard-validate `nodeId` against an allowlist of known forage nodes before cooldown/reward logic.

3. **Rare-node scaling based on "highest player in server" violates individual progression design** (`SPRINT-011-CLAUDE-DRAFT.md:29`, `:90-94`, `:244`).
- A low-star player can receive boosted rare-node quality just by sharing a server with a high-star player.
- This weakens the intended personal loop (brew more -> your forage improves).
- Recommendation: scale rare-node outcomes by the triggering player (or per-player instanced reward on interaction), not by global server max.

4. **Scope expansion to 6 new physical nodes + 3 new sub-zones is high-cost and not required to satisfy intent** (`SPRINT-011-CLAUDE-DRAFT.md:15`, `:157-177`).
- Intent requires gradual grove expansion, but not necessarily new world construction.
- New geometry, barriers, labels, and MCP world edits add heavy content risk and QA surface for a systems sprint.
- Recommendation: implement expansion by progressive unlock of existing `ForageNode_1..12` first; treat new sub-zones as optional stretch.

5. **Client gating language overstates authority for prompt enable/disable** (`SPRINT-011-CLAUDE-DRAFT.md:103-104`, `:190-191`).
- Disabling prompts client-side is UX only; it does not secure access.
- The draft mentions server validation, but this should be a hard requirement for every forage request path, not just sub-zone nodes.
- Recommendation: explicitly codify server-first gate checks in DoD and in Phase 2 acceptance criteria.

## Medium-Priority Gaps

1. **Probability verification is too weak for balance claims** (`SPRINT-011-CLAUDE-DRAFT.md:214`).
- "20+ forages" at one tier is insufficient to validate weighted tables.
- Recommendation: include deterministic sampling pass (e.g., 5k-10k rolls per tier) and threshold tolerances.

2. **No explicit compatibility note for existing `ForageNodeFeedback` behavior.**
- Current feedback script assumes active forage nodes and runs pulse/shrink logic broadly.
- With gated/locked nodes, this needs a clear integration plan to avoid visual mismatch.

3. **Economy impact from guaranteed rare-heavy Shadow Hollow pools is under-modeled** (`SPRINT-011-CLAUDE-DRAFT.md:80-83`).
- Two nodes with rare-only pools at 50 stars can materially change ingredient scarcity and market relevance.
- Recommendation: start with mixed Uncommon/Rare pools and tune upward after telemetry.

## Strengths Worth Keeping

1. Clear articulation of the retention loop and why stars should affect foraging.
2. Good choice to centralize probabilities and thresholds in `ForageTuning.lua`.
3. Strong emphasis on preserving existing remote contracts and server-side outcome resolution.
4. Useful UX idea for threshold-based unlock messaging.

## Suggested Merge Deltas (Actionable)

1. Make node ID validation strict for all forage requests; reject unknown IDs.
2. Normalize base node pools into rarity buckets and enforce true common-only behavior at Tier 0.
3. Replace "highest-stars-on-server" rare scaling with player-specific scaling.
4. Reduce baseline scope to existing 12-node progressive unlock; keep 6 new nodes as stretch.
5. Add statistical validation criteria for probability tuning (multi-tier, high sample size).
6. Add explicit `ForageNodeFeedback` integration tasks for locked-node visuals/animation rules.

## Final Verdict

The draft is directionally strong but not execution-safe yet. With strict node validation, true Tier-0 common enforcement, player-specific scaling, and a trimmed expansion scope, it becomes a robust sprint plan for implementation.
