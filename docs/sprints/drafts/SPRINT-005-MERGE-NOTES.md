# Sprint 005 Merge Notes

## Claude Draft Strengths
- Complete 75-recipe matrix with creative potion names and element synergy storytelling
- Detailed mutation type table with specific chances and multipliers
- Visual design guide for discovery VFX per mutation type
- Recipe design philosophy with clear tier rules

## Codex Draft Strengths
- Explicit 2-stage mutation algorithm (mutates? → which type?)
- Mutation key normalization helper to avoid breaking existing inventory readers
- Ingredient coverage validation step as hard gate
- Cleaner 10-brew unlock coupling to existing Tier 1 milestone
- Explicit 4-ingredient deferral

## Valid Critiques Accepted
1. **Mutation storage breaks existing readers**: Need compound key parser. Add normalization helper.
2. **Recipe IDs must match actual ingredient catalog IDs**: Add validation script.
3. **2-stage mutation roll needed**: Stage 1 = mutates? Stage 2 = which mutation? With cap.
4. **Timer retuning should be deferred**: Keep Sprint 003 timers, don't change in this sprint.
5. **4-ingredient explicitly deferred**: Only 2 and 3 this sprint.
6. **Coverage validation required**: Script to verify every ingredient in >=2 recipes.

## Critiques Rejected
- None, all valid.

## Interview Refinements Applied
1. Mutation chance scales with quality: base 5% + tier bonuses + freshness bonus
2. 3-ingredient recipes unlock at 10 brews (Tier 1 evolution)

## Final Decisions
- **Recipe matrix**: Claude's 75 recipes adopted (creative names, element synergy)
- **Mutation algorithm**: Codex's 2-stage roll with configurable cap
- **Storage**: Compound key with `__` separator (potionId__mutation), + parser helper
- **Timers**: Keep Sprint 003 values, no changes
- **4 ingredients**: Explicitly deferred
- **Validation**: Add recipe/ingredient integrity validation
