# Critique: SPRINT-003-CLAUDE-DRAFT

## Findings (Ordered by Severity)

1. **Critical: Disconnect behavior conflicts with interview requirement and timer model**
   - Reference: `SPRINT-003-CLAUDE-DRAFT.md:54-58`, `:19`
   - Issue: The draft says server should "complete immediately on disconnect" and add potion on logout. Interview finding says disconnect mid-brew should still complete and save server-side, which implies completion at scheduled `EndUnix`, not immediate fast-forward.
   - Why it matters: Immediate completion creates an exploit incentive (disconnect to skip wait), breaks timer integrity, and diverges from intended pacing.
   - Fix: Persist active brew (`StartUnix`, `EndUnix`, result metadata) and reconcile on login or claim by comparing `os.time()` to `EndUnix`.

2. **Critical: Active brew stored in session only breaks persistence guarantees**
   - Reference: `SPRINT-003-CLAUDE-DRAFT.md:80`, `:154`
   - Issue: Draft proposes active brew tracking in per-player session state, not DataStore.
   - Why it matters: Server shutdown/crash or migration between servers can lose active brew state, violating disconnect/rejoin reliability.
   - Fix: Store `ActiveBrew` in persisted player profile and save at brew start and completion transitions.

3. **High: Timer narrative is internally inconsistent (fixed 2:00 vs rarity-based durations)**
   - Reference: `SPRINT-003-CLAUDE-DRAFT.md:5`, `:18`, `:87-123`, `:220` vs `:147`
   - Issue: Overview/timeline/testing repeatedly frame a single 2-minute brew, while tasks include rarity durations (60/90/120/180).
   - Why it matters: Team implementation can drift toward one universal timer; QA criteria become ambiguous.
   - Fix: Rewrite timeline and DoD language to be rarity-driven, with an example timeline labeled explicitly as one rarity profile.

4. **High: Evolution tier use-case examples omit the 25-brew milestone**
   - Reference: `SPRINT-003-CLAUDE-DRAFT.md:17`
   - Issue: Use cases mention 10, 50, 100 but skip 25, despite requirement for 10/25/50/100.
   - Why it matters: Missing milestone often gets deprioritized in execution.
   - Fix: Add a use case explicitly validating the 25-brew unlock.

5. **Medium: Result grant timing is contradictory (on disconnect vs claim endpoint)**
   - Reference: `SPRINT-003-CLAUDE-DRAFT.md:46-52`, `:54-58`
   - Issue: One path grants potion on `ClaimBrewResult`; another grants directly on disconnect.
   - Why it matters: Dual grant paths increase risk of duplicates/race conditions.
   - Fix: Use a single authoritative lifecycle: `brewing -> completed_unclaimed -> claimed` with atomic status transition.

6. **Medium: Environment evolution driven by LocalScript may desync across viewers**
   - Reference: `SPRINT-003-CLAUDE-DRAFT.md:205-214`
   - Issue: Tier visuals are controlled by `StarterPlayerScripts/EnvironmentEvolution` only.
   - Why it matters: If shop-visiting/shared visibility is desired, client-only toggling can produce inconsistent views.
   - Fix: Decide visibility contract (owner-only vs shared) and place authority accordingly (server replication or explicitly client-private).

## What Claude Draft Does Well

- Strong experiential framing and clear VFX storytelling.
- Good inclusion of schema migration and stats model expansion.
- Concrete task decomposition across server/client/world with useful production detail.
- Captures top-tier spectacle requirement (particle weather + enchanted aura).

## Recommended Revisions Before Merge

1. Replace immediate-disconnect completion with scheduled timestamp completion.
2. Persist `ActiveBrew` in DataStore-backed profile (not session-only).
3. Normalize all timer language to rarity-based durations (60/90/120/180).
4. Add explicit 25-brew tier use case and acceptance check.
5. Unify reward lifecycle to avoid duplicate grants.
6. Clarify ownership/replication model for tier visuals.
