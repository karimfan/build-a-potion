# Sprint 010 Merge Notes

## Claude Draft Strengths
- Clear problem articulation (coin economy has no sink)
- Good phase separation (upgrade service, UI, storage, tutorial)
- Concrete testing checklist with regression coverage
- Server-authoritative upgrade purchases

## Codex Draft Strengths
- API/Remote contract matrix (professional, matches Sprint 009 style)
- Server-owned OnboardingService (not just client controller)
- Storage counting as total units, not unique types (correct for stack-based inventory)
- Explicit coverage of rare forage path for storage enforcement
- Includes "Claim brew" as distinct tutorial step (6 steps, not 5)

## Valid Critiques Accepted
1. **Storage counting must be total units, not unique types** — Codex is right. Counting unique ingredient types allows hoarding unlimited units of one type. Must count total stack amounts.
2. **Add "Claim brew" tutorial step** — brewing and claiming are separate actions. Tutorial should be 6 steps: forage, buy, brew, claim, sell, done.
3. **Server-side onboarding service** — tutorial progression should be validated server-side, not client-driven. Add OnboardingService with action hooks in existing services.
4. **Rare forage path needs storage check too** — both standard ForageNode handler AND rare node Triggered handler need enforcement.
5. **Add API/Remote contract matrix** — matches Sprint 009 style.

## Critiques Rejected (with reasoning)
1. **"Remove StorageSlots upgrade tiers from Sprint 010"** — User explicitly chose "warn but allow" for storage, AND the upgrade shop is the whole point. Storage upgrades give coins a sink. Keeping it, but marking as Phase 2 (after core cauldron upgrades).

## Interview Refinements Applied
- **Upgrade access**: HUD button (always visible, like Recipe Book)
- **Storage enforcement**: Soft warning (warn but allow, not hard block)
- Tutorial auto-completes for existing players

## Final Decisions
- Storage = total ingredient units (not unique types)
- Tutorial = 6 steps (forage, buy, brew, claim, sell, complete)
- OnboardingService on server (not just client controller)
- Rare forage path included in storage checks
- StorageSlots upgrades kept (user wants coin sink)
- API/Remote contract matrix included
