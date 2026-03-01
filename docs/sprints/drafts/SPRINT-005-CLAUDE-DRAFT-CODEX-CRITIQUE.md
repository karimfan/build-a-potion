# Sprint 005 Claude Draft - Codex Critique

## Overall Assessment

Claude's draft is strong on ambition, readability, and momentum. It captures the spirit of "brewing as centerpiece," proposes a complete recipe matrix, and includes clear phase breakdowns with concrete user-facing outcomes.

The primary gaps are around implementation safety and alignment with existing code/data constraints. The draft is very design-forward, but it needs tighter compatibility planning to reduce regression risk.

## What Claude Did Well

1. **Clear non-negotiable anchors**: 75 recipes, mutation system, unlock milestone, recipe book improvements.
2. **Compelling user-facing vision**: discovery moments and mutation excitement are clearly prioritized.
3. **Concrete matrix structure**: the recipe list makes scope tangible and reviewable.
4. **Correct interview alignment on two major decisions**:
   - Mutation chance scales with quality/freshness.
   - 3-ingredient unlock at 10 brews.
5. **Reasonable phased sequencing** from data first to systems then UI/VFX/testing.

## Critical Gaps

1. **Insufficient backward-compatibility planning for potion storage changes**
- The draft proposes mutation compound keys (`potionId_mutation`) but does not map all affected readers/writers.
- Current code paths in `FeedbackController`, `GameController`, `InteractionController`, and `EconomyService` assume direct `potionId` lookups against `Potions.Data`.
- Without a parse/normalization layer, this can break inventory rendering and selling.

2. **Recipe matrix likely diverges from active ingredient catalog IDs**
- Several names appear mismatched with current catalog conventions (example: `Philosopher's Stone` vs existing "Fragment" naming pattern).
- The draft does not include a validation step to assert every ingredient and potion ID exists.
- This creates high risk of silent Sludge fallbacks or unresolved recipe IDs.

3. **No explicit guardrails on mutation probability math**
- Draft lists base chance + bonuses and also per-mutation rarity percentages, but does not define roll ordering.
- Without explicit two-stage roll (`mutates?` then `which mutation?`) and cap, chance stacking can become inconsistent or unintentionally inflated.

4. **Scope drift into timer retuning without a clear need**
- "Brew Timer Updates" phase proposes new ranges that may conflict with Sprint 003 assumptions and tested lifecycle behavior.
- If timer changes are in scope, they need explicit rationale and migration/UX impact analysis; otherwise defer.

## Medium Gaps

1. **Coverage guarantee not verified**
- Anchor says every ingredient appears in >=2 recipes, but no validation task/script is planned.
- This should be a hard validation artifact, not a manual promise.

2. **Advanced brewing limits not explicitly finalized**
- Draft headline discusses 2-4 ingredient combinations, but implementation only handles 3.
- It should explicitly defer 4-ingredient support to avoid expectation mismatch.

3. **Remote/API contract details are under-specified**
- `BrewPotion` expands input arity, but response shape and rejection reason handling are not clearly defined.
- Client unlock messaging depends on consistent server payload.

4. **Regression strategy is light for high-touch files**
- High-churn files (`BrewingService`, `InteractionController`, `EconomyService`) need explicit regression scenarios beyond happy-path checks.

## Recommended Revisions Before Merge

1. Add a **data validation step** for recipe/potion/ingredient ID integrity and ingredient coverage >=2.
2. Define **mutation algorithm contract** explicitly:
- Stage 1: roll mutation occurrence with capped chance.
- Stage 2: weighted mutation type selection.
3. Add a **mutation key normalization helper** and list all impacted inventory/sell/render call sites.
4. Clarify scope boundary: **2 + unlocked 3 ingredients this sprint; 4 ingredients deferred**.
5. Remove or defer timer retuning unless there is an explicit product decision to retune in Sprint 005.
6. Expand regression checklist for existing 15 recipes, reconnect flow, and sell pipeline with mutated keys.

## Bottom Line

Claude's draft is a strong product/design plan and a good foundation. With stricter compatibility, validation, and algorithm contracts, it can become implementation-ready with materially lower regression risk.
