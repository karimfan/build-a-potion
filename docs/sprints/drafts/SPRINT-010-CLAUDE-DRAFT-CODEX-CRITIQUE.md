# Critique: SPRINT-010-CLAUDE-DRAFT

## Overall Assessment

Strong draft direction and good alignment with the intent themes (upgrade sink, storage pressure, onboarding). The plan is readable and phased well, but there are several correctness and scope risks that should be resolved before execution.

## Findings (Highest Severity First)

1. **Storage-cap algorithm is likely incorrect for this codebase** (`SPRINT-010-CLAUDE-DRAFT.md:95`).
- Draft proposes `getUsedSlots(data)` as "count unique ingredient types".
- Current inventory model is stack-based quantities (`Ingredients[id].stacks[{amount,...}]`), not unique-type slots.
- Counting unique types allows near-infinite units under one type and fails to create real storage pressure.
- Recommendation: capacity should count total ingredient units across stacks, with a shared helper in `PlayerDataService` used by both `EconomyService` and `ZoneService`.

2. **Scope creep beyond intent: adds full StorageSlots upgrade economy** (`SPRINT-010-CLAUDE-DRAFT.md:67`, `:153`).
- Intent success criteria require storage enforcement + visible capacity, not a new multi-tier storage upgrade progression.
- Adding new storage upgrade tiers increases design, tuning, UI, and migration surface area materially.
- Recommendation: keep storage capacity fixed in Sprint 010; defer storage-capacity monetization/tiering to Sprint 011.

3. **Tutorial step model skips "claim brew" action, leaving core loop partially unguided** (`SPRINT-010-CLAUDE-DRAFT.md:120`).
- Progression detection lists forage/buy/brew/sell, but not `ClaimBrewResult`.
- In this game, claiming is a distinct action and frequent point of confusion.
- Recommendation: include explicit claim step or at least claim gate before sell step completion.

4. **Server-side tutorial progression ownership is underspecified** (`SPRINT-010-CLAUDE-DRAFT.md:102-122`).
- Plan mainly adds a client `TutorialController`, but does not clearly define where authoritative step advancement is validated.
- If progression is client-driven, it is brittle and can desync from actual server actions.
- Recommendation: add a server onboarding service/state machine; existing services emit action events after successful server validation.

5. **Storage checks mention only primary forage handler, not rare forage path** (`SPRINT-010-CLAUDE-DRAFT.md:91-97`).
- `ZoneService` currently grants ingredients in both standard forage and rare-node `prompt.Triggered` path.
- Missing the rare path leaves an over-cap bypass.
- Recommendation: explicitly enforce storage checks in both forage code paths.

## Medium-Priority Gaps

1. **Remote/contract section is missing.**
- Sprint 009-style plans usually document contract changes explicitly.
- This sprint introduces `PurchaseUpgrade`; that should be listed with compatibility notes.

2. **Migration policy for existing players is opinionated but unexplained** (`SPRINT-010-CLAUDE-DRAFT.md:110`).
- Auto-setting all existing players to completed tutorial may be right, but should be called out as a product decision/tradeoff.

3. **`default.project.json` change is asserted without confirming need** (`SPRINT-010-CLAUDE-DRAFT.md:148`).
- May be necessary, but should be tied to actual script locations used for Rojo sync.

## Strengths Worth Keeping

1. Clear articulation of the progression problem and why Sprint 010 matters.
2. Good separation of upgrade UI, storage enforcement, and tutorial implementation phases.
3. Concrete testing checklist including regression coverage.
4. Correct emphasis on server-authoritative upgrade purchases.

## Suggested Merge Deltas (Actionable)

1. Replace unique-type slot counting with total-unit counting helper in `PlayerDataService`.
2. Remove storage-tier upgrade scope from Sprint 010 (or mark explicitly as stretch).
3. Add explicit tutorial step for `ClaimBrewResult`.
4. Add server-owned onboarding progression contract (service + action hooks).
5. Add storage enforcement requirement for both standard and rare forage grants.
6. Add API/Remote contract matrix section to match current sprint planning style.

## Final Verdict

The draft is a strong starting point, but it is not execution-safe yet. With the storage-counting correction, scope trim, and server-authoritative onboarding additions, it becomes production-ready for Sprint 010.
