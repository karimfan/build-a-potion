# Sprint 003 Merge Notes

## Claude Draft Strengths
- Strong experiential framing ("casting a spell", "TikTok moment") that communicates the design intent
- Detailed VFX timeline with specific timestamps and escalating stages
- Concrete Roblox implementation details (ParticleEmitter rates, PointLight ranges, Color3 values)
- Full BrewStats schema with streak tracking (CurrentStreak, BestStreak)
- Per-phase task breakdown with specific file paths

## Codex Draft Strengths
- Formal brew state machine with 3 explicit states: `idle → brewing → completed_unclaimed → idle`
- ActiveBrew persisted in DataStore profile (not just session memory) — critical for disconnect safety
- Reconciliation logic on profile load (check `os.time() >= EndUnix` to transition stale brews)
- Auto-claim UX when opening cauldron UI after reconnect ("Your brew finished while you were away")
- Explicit exploit prevention (timer authority, atomic claim transitions, duplicate reward prevention)
- Sludge timer policy as open question (good edge case to resolve)

## Valid Critiques Accepted

1. **CRITICAL: Disconnect should NOT fast-forward brew** — Claude's draft said "complete immediately on disconnect." Codex correctly identified this as an exploit vector. **Fix: Persist ActiveBrew with EndUnix in DataStore; reconcile on next login by comparing os.time() to EndUnix.**

2. **CRITICAL: ActiveBrew must be DataStore-persisted, not session-only** — Server crashes or migrations would lose active brew state. **Fix: Store ActiveBrew in player profile, save at brew start and claim transitions.**

3. **HIGH: Timer narrative inconsistent (2-minute references vs rarity-based)** — Claude's overview and VFX timeline repeatedly said "2-minute" while tasks said rarity-based. **Fix: Normalize all language to rarity-driven. VFX timeline becomes a proportional system, not fixed timestamps.**

4. **HIGH: Missing 25-brew tier in use cases** — Claude listed 10/50/100 but skipped 25. **Fix: Add explicit use case and DoD check for 25-brew tier.**

5. **MEDIUM: Unified reward lifecycle needed** — Claude had dual grant paths (ClaimBrewResult vs disconnect-immediate). **Fix: Single lifecycle: brewing → completed_unclaimed → claimed. One claim path.**

6. **MEDIUM: Evolution visibility contract** — **Fix: Owner-only visibility for this sprint (client-side). Future social sprint can add shared visibility.**

## Critiques Rejected

None — all Codex critiques were valid and actionable.

## Interview Refinements Applied

1. **Rarity-based timers**: Common=60s, Uncommon=90s, Rare=120s, Mythic=180s (confirmed)
2. **Disconnect completes + saves**: Via DataStore-persisted ActiveBrew with EndUnix reconciliation (confirmed, implementation corrected per Codex critique)
3. **4 evolution tiers at 10/25/50/100**: Top tier spectacular with particle weather + enchanted aura (confirmed)

## Final Decisions

- **State machine**: Adopt Codex's 3-state model (idle/brewing/completed_unclaimed) persisted in DataStore
- **VFX timeline**: Keep Claude's staged escalation concept but parameterize by brew duration (percentage-based, not fixed timestamps)
- **Stats model**: Keep Claude's BrewStats with streak tracking (Codex omitted streaks)
- **Sludge timer**: Use Common duration (60s) for Sludge — no rarity lookup needed
- **Auto-claim on UI open**: Adopt Codex's approach — reconnect shows "Your brew finished!" and claims automatically
- **Evolution visibility**: Owner-only this sprint (client-side LocalScript)
- **Spoon model**: Insert from marketplace, simple orbital rotation
