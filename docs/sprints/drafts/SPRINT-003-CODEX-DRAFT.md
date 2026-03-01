# Sprint 003: Cauldron Ascension — Timed Brewing, Persistent Sessions, and Evolving Magical Theater

## Overview

Sprint 003 upgrades brewing from a transactional click into the center-stage ritual of the game. The player should feel anticipation during the brew, payoff at completion, and long-term progression in the environment itself as they continue brewing over many sessions. This sprint introduces server-enforced brew durations, richer visual choreography, persistent brewing outcomes across disconnects, and progression-driven world evolution around the cauldron.

The design intent is to make the cauldron the "golden carrot" moment: a system players revisit repeatedly because it is rewarding in mechanics, spectacle, and identity expression. We preserve server authority, keep existing buy/sell/forage flows intact, and ship a robust state model that can survive reconnects, migration, and edge cases.

## Scope Anchors (Non-Negotiable)

1. **Rarity-based brew timers are enforced server-side**:
   - Common = 60s
   - Uncommon = 90s
   - Rare = 120s
   - Mythic = 180s
2. **Disconnect mid-brew must still complete on schedule** and persist result server-side for pickup after reconnect.
3. **Cauldron environment evolves through 4 tiers at 10/25/50/100 total brews** with escalating spectacle.
4. **Top tier (100+) must be visually dramatic**, including particle weather and an enchanted aura around the cauldron area.
5. **Brewing remains server-authoritative** (ingredient ownership, recipe resolution, timer state, completion reward).
6. **No regressions to existing loop** (buy ingredients, brew, sell, forage, persistence).

## Use Cases

1. **Timed ritual clarity**: A player starts a Common brew and sees a 60-second countdown with active stirring + VFX feedback.
2. **Rarity anticipation**: A player starts a Rare brew and sees a longer 120-second ritual with intensified FX profile.
3. **Reconnect reliability**: A player disconnects with 40s left in an Uncommon brew, rejoins later, and can claim the completed potion from server state.
4. **Invalid combo still meaningful**: A player brews an unknown combo, waits through timer based on resulting rarity policy (fallback to Common timing for Sludge), then receives Sludge with clear messaging.
5. **Progression payoff**: A player crosses 25 and 50 total brews and immediately sees environment upgrades unlocked around their cauldron.
6. **Prestige moment**: A player reaches 100 total brews and sees particle weather + enchanted aura that is visibly distinct from lower tiers.
7. **Exploit resistance**: A client attempts to bypass timer UI; server denies early claim and only grants completion at authoritative end timestamp.

## Architecture

### Brewing State Model (Server Authoritative)

```
Idle
  -> BrewingActive (StartUnix, EndUnix, InputIngredients, PredictedResultId)
      -> BrewingCompletedUnclaimed (ResultId, IsDiscovery, CompletedUnix)
          -> Idle (after claim)
```

Notes:
- Exactly one active brew per player in this sprint scope.
- Completion is time-based on server timestamps; no client tick trust.
- If player disconnects, state remains in profile; completion is derived from `os.time() >= EndUnix`.

### Data Model Additions (Schema v2)

```
PlayerState = {
  Version = 2,
  Coins = number,
  Ingredients = { [ingredientId] = quantity },
  Potions = { [potionId] = quantity },
  DiscoveredRecipes = { [recipeId] = true },
  LastLoginUnix = number,

  BrewStats = {
    TotalBrews = number,                    -- increments on completed brew
    TotalBrewValue = number,                -- cumulative sell value baseline
    PotionBrewCounts = { [potionId] = number },
    HighestRarityBrewed = string?,          -- Common/Uncommon/Rare/Mythic
  },

  ActiveBrew = {
    Status = "idle" | "brewing" | "completed_unclaimed",
    StartUnix = number?,
    EndUnix = number?,
    IngredientA = string?,
    IngredientB = string?,
    ResultPotionId = string?,
    IsNewDiscovery = boolean?,
    CompletedUnix = number?,
  },
}
```

Migration policy:
- V1 profiles get `BrewStats` defaults and `ActiveBrew = idle`.
- Migration is idempotent and runs on load.

### Timer Rules

```
TimerByRarity = {
  Common = 60,
  Uncommon = 90,
  Rare = 120,
  Mythic = 180,
}
```

Timer source of truth:
1. Resolve recipe server-side.
2. Determine result rarity from potion config.
3. Set `EndUnix = os.time() + TimerByRarity[rarity]`.
4. Persist immediately after brew start mutation.

### Disconnect Completion Behavior

At reconnect/profile load:
1. If `ActiveBrew.Status == brewing` and `os.time() >= EndUnix`, transition to `completed_unclaimed`.
2. Do not require player presence for completion.
3. Player claims result via explicit action (button/proximity interaction) or auto-claim on opening cauldron UI (implementation decision below).

Chosen UX in this sprint:
- Auto-claim when opening cauldron UI if state is `completed_unclaimed`, with celebratory sequence.

### Evolution Tier System

Tier thresholds by `BrewStats.TotalBrews`:
- Tier 0: `<10` (baseline)
- Tier 1: `10-24`
- Tier 2: `25-49`
- Tier 3: `50-99`
- Tier 4: `>=100` (spectacular tier)

Tier 4 required effects:
- Area particle weather (spark rain / arcane motes) around cauldron zone
- Enchanted aura ring/light treatment around cauldron apparatus
- Stronger completion reveal profile

### Client/Server Interaction Flow

```
[Start Brew]
Client -> RemoteFunction:BrewPotion(ingredientA, ingredientB)
Server:
  - validate no active brew
  - validate ingredient ownership
  - consume ingredients
  - resolve recipe
  - compute rarity timer
  - persist ActiveBrew=brewing with EndUnix
  - return ack + EndUnix + predicted result metadata (safe subset)
Client:
  - enter brewing state UI
  - show countdown from EndUnix
  - play staged VFX + stirring loop

[Poll/Refresh]
Client -> RemoteFunction:GetActiveBrewState()
Server returns authoritative state snapshot

[Claim Completion]
Client -> RemoteFunction:ClaimCompletedBrew()
Server:
  - verify completed_unclaimed OR brewing with now>=EndUnix then transition
  - grant potion inventory
  - update BrewStats and discoveries
  - recalc evolution tier
  - clear ActiveBrew to idle
  - persist
  - return completion payload + tier change flags
```

## Implementation Plan

### Phase 1: Data Schema + Migration + Brew State Core (~20%)

**Files:**
- `ServerScriptService/Services/PlayerDataService` - Migrate profile v1->v2, persist `BrewStats` and `ActiveBrew`
- `ReplicatedStorage/Shared/Types` - Add brew status enums/constants
- `ReplicatedStorage/Shared/Config/Potions` - Ensure rarity metadata complete for timing rules

**Tasks:**
- [ ] Add v2 schema defaults (`BrewStats`, `ActiveBrew`)
- [ ] Implement migration function with idempotent guards
- [ ] Add helper accessors for active brew read/write
- [ ] Add validation around malformed legacy fields
- [ ] Add tests/check harness for migration scenarios

### Phase 2: Server-Enforced Timed Brewing (~20%)

**Files:**
- `ServerScriptService/Services/BrewingService` - Timer lifecycle, start/complete/claim logic
- `ReplicatedStorage/Remotes` - Add `GetActiveBrewState`, `ClaimCompletedBrew` remotes

**Tasks:**
- [ ] Implement `TimerByRarity` mapping (60/90/120/180)
- [ ] Start brew flow stores `StartUnix` + `EndUnix`
- [ ] Prevent starting a second brew while active
- [ ] Add server transition for elapsed brews (`brewing` -> `completed_unclaimed`)
- [ ] Implement claim endpoint to award potion and clear state
- [ ] Persist at critical transitions (start, complete transition, claim)

### Phase 3: Reconnect/Offline Completion Reliability (~10%)

**Files:**
- `ServerScriptService/Services/PlayerDataService`
- `ServerScriptService/Services/BrewingService`

**Tasks:**
- [ ] On profile load, reconcile stale active brew by time
- [ ] Guarantee ingredient consumption is not rolled back by disconnect
- [ ] Guarantee completion is deterministic by timestamp
- [ ] Add logging for reconciliation decisions for debugging

### Phase 4: Cauldron UI State Machine + Progress UX (~15%)

**Files:**
- `StarterGui/CauldronGui` - Add state panels and progress bar
- `StarterGui/CauldronGui/CauldronController` - Countdown loop, state sync, auto-claim trigger
- `StarterGui/FeedbackGui` - Completion and tier-up overlays

**Tasks:**
- [ ] Add distinct UI states: Idle, Brewing, Completed
- [ ] Show server-derived countdown (no local authority)
- [ ] Display rarity badge and expected duration before confirm
- [ ] Add reconnect resume UX ("Your brew finished while you were away")
- [ ] Trigger auto-claim path when completed state detected

### Phase 5: VFX Pass - Brew Ceremony (~15%)

**Files:**
- `Workspace/Zones/YourShop/Cauldron`
- `Workspace/Zones/YourShop/CauldronLiquid`
- `StarterPlayerScripts` or cauldron-local effect controller script (based on existing project pattern)

**Tasks:**
- [ ] Add animated stirring spoon rig/part sequence during active brew
- [ ] Stage VFX by timeline (start burst, sustained simmer, completion burst)
- [ ] Add rarity-scaled intensity profiles (Common low -> Mythic high)
- [ ] Add completion fireworks/sparks profile with budget guards
- [ ] Validate mobile-safe emitter rates and lifetimes

### Phase 6: Evolution Environment Tiers (~15%)

**Files:**
- `Workspace/Zones/YourShop` (tiered decorations/effects groups)
- `ServerScriptService/Services/BrewingService` (tier calculation)
- `StarterGui/FeedbackGui` (tier unlock messaging)

**Tasks:**
- [ ] Implement threshold calculation at 10/25/50/100
- [ ] Author 5 tier presets (0-4) as togglable object groups
- [ ] Tier 1: extra candles/glow accents
- [ ] Tier 2: added magical flora/particles
- [ ] Tier 3: richer ambient effects + enhanced cauldron surround
- [ ] Tier 4: particle weather + enchanted aura + high-prestige scene dressing
- [ ] Add one-time tier-up announcement UX

### Phase 7: Regression + Validation Gate (~5%)

**Files:**
- Existing service test harnesses/manual test checklist docs

**Tasks:**
- [ ] Verify buy/brew/sell/forage still work end-to-end
- [ ] Verify timer values exactly match rarity matrix
- [ ] Verify reconnect behavior across each rarity timer
- [ ] Verify no duplicate rewards via repeated claim requests
- [ ] Verify tier unlocks at 10/25/50/100 exactly
- [ ] Verify top-tier effects appear and are stable

## Files Summary

| File/Location | Action | Purpose |
|---------------|--------|---------|
| `ServerScriptService/Services/PlayerDataService` | Modify | Schema v2 migration and active brew persistence |
| `ServerScriptService/Services/BrewingService` | Modify | Timed brewing lifecycle, claim logic, tier progression |
| `ReplicatedStorage/Shared/Types` | Modify | Brew state constants and shared enums |
| `ReplicatedStorage/Shared/Config/Potions` | Modify | Rarity completeness for timer mapping |
| `ReplicatedStorage/Remotes` | Modify | Add brew-state and claim remotes |
| `StarterGui/CauldronGui` | Modify | Brewing progress/resume/completion UI states |
| `StarterGui/CauldronGui/CauldronController` | Modify | Client state sync and countdown rendering |
| `StarterGui/FeedbackGui` | Modify | Completion and tier unlock feedback |
| `Workspace/Zones/YourShop/Cauldron` | Modify | Timed brew VFX + tier-reactive visuals |
| `Workspace/Zones/YourShop` | Modify | Evolution tier environment assets |

## Definition of Done

- [ ] Server enforces rarity timers exactly: Common 60s, Uncommon 90s, Rare 120s, Mythic 180s.
- [ ] Brew cannot be claimed before server `EndUnix`.
- [ ] Disconnecting during brew does not cancel progress.
- [ ] Rejoin after timer expiry yields completed brew claimable from server state.
- [ ] Brew completion increments `TotalBrews` and relevant potion counters.
- [ ] Evolution tiers unlock exactly at 10/25/50/100 brews.
- [ ] Tier 4 visibly includes particle weather and enchanted aura treatment.
- [ ] Brewing VFX pipeline includes stirring + staged feedback + completion burst.
- [ ] No regression in buy/sell/forage interactions.
- [ ] Data migration from v1 profiles succeeds without data loss.

## Risks & Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Time drift or timestamp misuse causes early/late completion | Medium | High | Use server `os.time()` only; never trust client countdown for authority |
| Duplicate reward claims via race requests | Medium | High | Atomic claim transition server-side with status check + immediate persist |
| Migration errors for old profiles | Medium | High | Idempotent migration defaults + targeted migration tests |
| VFX overload on low-end/mobile devices | Medium | Medium | Tiered emitter budgets, cap rates, test on low graphics settings |
| Tier assets become visually noisy/cluttered | Medium | Medium | Curate per-tier art direction and enforce max concurrent FX |
| UI desync after reconnect | Low | Medium | Poll authoritative state on open and periodic refresh during brew |

## Security Considerations

- Keep all gameplay-critical state transitions on server (`start`, `complete`, `claim`).
- Validate ingredient ownership and active brew status on every brew request.
- Reject client attempts to forge completion or tier progression.
- Ensure inserted visual assets contain no executable scripts unless explicitly audited.

## Dependencies

- Depends on Sprint 001 foundations (server-authoritative economy + persistence).
- Builds on Sprint 002 world decoration baseline (cauldron zone already enriched).
- Requires consistent potion rarity data in shared config.

## Open Questions

1. Should `Sludge` always use Common timer (60s), or should failed brew timer derive from highest input rarity?
2. Should completed brew auto-claim immediately on player join, or only when opening Cauldron UI (current plan: on opening UI)?
3. For tier visuals, should effects be visible only to owner or to all visitors in the shop instance?
4. Is one active brew slot sufficient for this sprint, or should parallel brewing be staged as future progression work?
