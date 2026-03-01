# Codex Critique of `SPRINT-002-CLAUDE-DRAFT.md`

## Overall Assessment

Claude's draft is directionally strong and substantially aligned with the intent. It captures the main visual transformation goal, includes the three key interview findings, and provides actionable per-zone prop targets. The document is usable as a planning artifact with minor-to-moderate revisions.

The main issues are not conceptual misses, but execution-level consistency: a few requirements conflict with the stated boundary constraint, density acceptance criteria are still partially subjective, and implementation ownership is biased toward world edits without enough verification scaffolding.

## What Claude Got Right

1. **Core objective fit**: Correctly reframes Sprint 002 as an environment/presentation sprint on top of Sprint 001 systems.
2. **Interview findings included**: Explicitly includes "cozy cluttered" density, stone/hedge/vine boundary direction, and ambient audio requirements.
3. **Zone-by-zone specificity**: Good per-zone prop categories and counts; especially useful for execution in Studio.
4. **Regression awareness**: Calls out prompt/path validation and no gameplay-system changes.
5. **Practical world-state fixes**: Correctly prioritizes IngredientMarket transform issue and loose root model cleanup.

## High-Priority Issues (Should Fix)

1. **Boundary rule inconsistency**
- The document states stone+hedge+vine boundaries are required, but multiple sections still prescribe wooden sign/fence-adjacent aesthetics and one WildGrove task explicitly suggests non-stone natural boundaries as primary.
- Why this matters: it weakens a hard interview requirement and can produce inconsistent final art direction.
- Fix: enforce one boundary standard across all zones: stone base + hedge + vine overgrowth; natural elements can supplement, not replace.

2. **Density acceptance still too subjective**
- "No visible empty flat floor" appears in DoD, but there is no measurable camera-path protocol beyond broad language.
- Why this matters: reviewers can disagree on completion; sprint closure risk increases.
- Fix: add a concrete verification rubric (e.g., 6 camera checkpoints per zone, 360 sweep capture, fail if bare floor patch exceeds agreed threshold).

3. **Asset-performance guardrails are underspecified**
- The draft mentions performance risk but does not define up-front budgets or stop conditions.
- Why this matters: maximum-density scope can regress mobile performance quickly.
- Fix: add per-zone asset budgets (instance count, active lights, particles, concurrent sounds) and a triage order if budget exceeded.

4. **Audio plan missing transition quality criteria**
- Ambient audio tasks exist, but fade behavior and overlap testing are lightly specified.
- Why this matters: poor spatial audio transitions are immediately noticeable and undermine polish.
- Fix: add explicit audio acceptance checks (cross-zone transition walk, max simultaneous loops at boundary seams, rolloff tuning pass).

5. **Execution ownership not clearly partitioned**
- Files summary is workspace-heavy, but there is limited mention of where validation scripts/checklists live.
- Why this matters: execution can drift into manual-only checks with poor reproducibility.
- Fix: add a lightweight verification artifact (checklist doc or repeatable test script) and assign it to a phase.

## Medium-Priority Improvements (Recommended)

1. **Signage language drifts from fantasy-alchemy tone in places**
- Some examples are functional but not stylistically unified.
- Improve by defining a short naming style guide for zone/station signs.

2. **Loose model disposition is ambiguous**
- "Relocate or delete" is correct but not decisive.
- Improve by adding default policy: relocate only if style/perf-compliant; otherwise replace from curated list.

3. **Phase percentages could better reflect risk distribution**
- Cross-zone polish is small while dense placement carries most regression risk.
- Improve by reserving more explicit time for verification and collision cleanup after each zone pass.

## Suggested Concrete Edits

1. Replace any boundary wording that allows primary non-stone solutions with:
- "Primary perimeter treatment must be stone wall segments with hedge and vine overgrowth in every zone."

2. Add a "Density Verification Protocol" section:
- 6 predefined camera checkpoints per zone
- 360-degree screenshot sweep per checkpoint
- pass/fail rule for empty surface exposure

3. Add a "Performance Budget" subsection:
- max decorative instances per zone
- max dynamic lights per zone
- max active particle systems per zone
- fallback removal order when over budget

4. Add an "Audio QA Checklist" subsection:
- zone transition walk path
- overlap/bleed threshold
- loudness normalization pass

5. Add one artifact in files summary:
- `docs/sprints/drafts/SPRINT-002-VALIDATION-CHECKLIST.md` (or equivalent) for repeatable acceptance.

## Verdict

Claude's draft is strong and close to execution-ready. With the boundary consistency fix, measurable density verification, and explicit performance/audio guardrails, it becomes a high-confidence sprint plan.
