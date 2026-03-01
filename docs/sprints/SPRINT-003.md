# Sprint 003: Cauldron Ascension — Timed Brewing, VFX Spectacle, Player Stats, Evolving Environment

## Overview

Brewing a potion should feel like casting a spell — dramatic, visual, and rewarding. Right now it's instant and silent: click "Brew", ingredients vanish, potion appears. Sprint 003 transforms the entire brewing experience into a staged spectacle with rarity-based timers, churning spoon animation, escalating VFX (steam → fire → sparks → fireworks), persistent player stats, and an evolving cauldron environment that grows more magical as the player brews more.

This sprint touches all three layers: server (brew state machine with DataStore-persisted ActiveBrew, timer enforcement, stats tracking, schema migration), client (animated brew UI with progress bar, staged VFX orchestration, stats display), and world (stirring spoon, environment evolution tiers). The cauldron area becomes the centerpiece of the game — the moment players screenshot and share.

Design philosophy: "Every brew should feel like a TikTok moment." Rare brews get longer timers and more spectacular effects. The player's cauldron corner visually tells the story of how experienced they are.

## Scope Anchors (Non-Negotiable)

1. **Rarity-based brew timers enforced server-side**: Common=60s, Uncommon=90s, Rare=120s, Mythic=180s. Sludge uses Common (60s).
2. **Disconnect mid-brew persists and completes on schedule**: ActiveBrew stored in DataStore with EndUnix. On reconnect, reconcile by comparing `os.time()` to `EndUnix`.
3. **4 evolution tiers at 10/25/50/100 total brews**: Top tier (100+) includes particle weather and enchanted aura.
4. **Single authoritative brew lifecycle**: `idle → brewing → completed_unclaimed → idle` (claimed). One code path for granting rewards.
5. **Server-authoritative everything**: Ingredient ownership, recipe resolution, timer state, completion reward, stats updates.
6. **No regressions**: Buy/sell/forage/DataStore persistence all work as before.

## Use Cases

1. **First brew excitement**: New player selects 2 common ingredients, clicks Brew, and watches a 60-second sequence — spoon starts stirring, bubbles intensify, steam rises, liquid changes color. Timer counts down. At completion: flash, fireworks, result reveal.
2. **Rare brew anticipation**: Player starts a Rare brew — 120-second timer with intensified VFX profile. The longer wait builds anticipation. The completion is more spectacular.
3. **Discovery celebration**: First time brewing a new recipe triggers extra-dramatic reveal — bigger explosions, "NEW RECIPE!" banner, screen impulse.
4. **Progress tracking**: Player views stats: 47 potions brewed, 12 recipes discovered, total value 3,450 coins, current streak 5, best streak 12.
5. **10-brew milestone**: After 10 brews, magical rune circle appears on the floor around the cauldron. Player notices the change and feels progression.
6. **25-brew milestone**: After 25 brews, floating ingredient jars begin orbiting above the cauldron. The area feels more mystical.
7. **50-brew milestone**: Crystal formations grow from the floor near the cauldron base. The space is clearly an experienced alchemist's.
8. **100-brew prestige**: Full enchanted aura — particle weather (arcane motes), expanded glow radius, floating rune particles, ambient magical hum. Screenshot-worthy flex.
9. **Disconnect safety**: Player disconnects with 40s left on an Uncommon brew. On reconnect, opens cauldron, sees "Your brew finished while you were away!" — auto-claims the completed potion with celebration.
10. **Exploit resistance**: Client attempts to bypass timer — server denies early claim. Only grants result when `os.time() >= EndUnix`.

## Architecture

### Brew State Machine (Server-Authoritative, DataStore-Persisted)

```
IDLE
  └─ BrewPotion(ingredientA, ingredientB)
     ├─ Validate: no active brew, owns ingredients
     ├─ Consume ingredients (atomic)
     ├─ Resolve recipe → potionId, rarity
     ├─ Compute EndUnix = os.time() + TimerByRarity[rarity]
     ├─ Persist ActiveBrew = { Status="brewing", StartUnix, EndUnix, IngredientA, IngredientB, ResultPotionId, IsNewDiscovery }
     └─ Return: { success, potionId, brewDuration, rarity, isNewDiscovery }

BREWING
  └─ ClaimBrewResult() OR auto-claim on CauldronGui open
     ├─ Check: os.time() >= EndUnix (or Status already "completed_unclaimed")
     ├─ If not ready: reject
     ├─ Transition to completed_unclaimed (if still brewing)
     ├─ Grant potion to inventory
     ├─ Update BrewStats (TotalBrewed++, PotionCounts, TotalValueBrewed, streak)
     ├─ Check evolution tier threshold
     ├─ Clear ActiveBrew to idle
     ├─ Persist
     └─ Return: { potionId, potionName, sellValue, isNewDiscovery, updatedStats, tierChanged }

ON PROFILE LOAD (reconnect):
  └─ If ActiveBrew.Status == "brewing" AND os.time() >= EndUnix:
     └─ Transition to "completed_unclaimed" (claim when player opens cauldron)
```

### DataStore Schema (Version 1 → Version 2)

```lua
PlayerState = {
    Version = 2,
    Coins = number,
    Ingredients = { [ingredientId] = quantity },
    Potions = { [potionId] = quantity },
    DiscoveredRecipes = { [recipeKey] = true },
    LastLoginUnix = number,
    -- NEW in V2:
    BrewStats = {
        TotalBrewed = 0,
        TotalValueBrewed = 0,
        CurrentStreak = 0,
        BestStreak = 0,
        PotionCounts = {},
    },
    ActiveBrew = {
        Status = "idle",  -- "idle" | "brewing" | "completed_unclaimed"
        StartUnix = 0,
        EndUnix = 0,
        IngredientA = "",
        IngredientB = "",
        ResultPotionId = "",
        IsNewDiscovery = false,
    },
}
```

Migration: V1 profiles get default BrewStats + idle ActiveBrew. Idempotent, never deletes existing fields.

### Timer Rules

```lua
TimerByRarity = {
    Common = 60,
    Uncommon = 90,
    Rare = 120,
    Mythic = 180,
}
-- Sludge (failed brew) uses Common timer (60s)
```

### VFX Timeline (Percentage-Based, Scales to Any Duration)

```
0%    Brew starts
      - Spoon begins stirring (continuous orbit)
      - Cauldron liquid color shifts toward potion theme
      - Ambient bubbles intensify (Rate 8 → 20)
      - Soft steam particles begin

25%   Quarter mark
      - Fire sparks at cauldron base
      - Liquid glow intensifies
      - Steam thickens

50%   Halfway
      - Small fire bursts from cauldron rim
      - Sparks fly outward
      - Liquid is potion-colored and pulsing

75%   Three-quarter mark
      - Fire bursts larger and more frequent
      - Sparks become streaming
      - Glow illuminates nearby area
      - Anticipation sound builds

95%   Pre-completion
      - Peak intensity flash warning
      - Sound crescendo

100%  COMPLETION
      - Screen flash
      - Fireworks burst (5-8 bursts, tier-colored)
      - Fire ring expands from cauldron
      - Spoon rises and fades
      - Result card: potion name + value + tier
      - If new discovery: extra fireworks, bigger banner
      - Rarity multiplier on all VFX intensity
```

### Evolution Tiers

| Tier | Threshold | Visual Additions |
|------|-----------|-----------------|
| 0 | 0-9 brews | Base cauldron, ambient effects |
| 1 | 10-24 | Glowing rune circle on floor (Decal/SurfaceGui, Neon) |
| 2 | 25-49 | + Floating ingredient jars orbiting above (CFrame tween) |
| 3 | 50-99 | + Crystal formations growing from floor near base |
| 4 | 100+ | + Full enchanted aura: particle weather, floating runes, expanded glow, magical hum |

Owner-only visibility this sprint (client-side). Future social sprint adds shared visibility.

## Implementation Plan

### Phase 1: Data Schema + Migration + Brew State Core (~20%)

**Files:**
- `ServerScriptService/Services/PlayerDataService` — Schema migration V1→V2, ActiveBrew persistence
- `ReplicatedStorage/Shared/Types` — DATASTORE_VERSION = 2, brew state constants
- `ReplicatedStorage/Shared/Config/BrewTuning` (new) — TimerByRarity, streak rules

**Tasks:**
- [ ] Create BrewTuning config: `{ TimerByRarity = { Common=60, Uncommon=90, Rare=120, Mythic=180 }, SludgeTimer = 60 }`
- [ ] Add V2 schema defaults to PlayerDataService: BrewStats + ActiveBrew
- [ ] Implement migration: if Version==1, add defaults, set Version=2. Idempotent.
- [ ] On profile load: reconcile stale ActiveBrew (if Status=="brewing" and os.time()>=EndUnix → set "completed_unclaimed")
- [ ] Update Types module: DATASTORE_VERSION=2, brew state enum strings
- [ ] Save profile at brew start and claim transitions (not just autosave interval)

### Phase 2: Server — Timed Brewing Lifecycle (~20%)

**Files:**
- `ServerScriptService/Services/BrewingService` — Rewrite with state machine
- `ReplicatedStorage/Remotes/ClaimBrewResult` (new) — RemoteFunction
- `ReplicatedStorage/Remotes/GetActiveBrewState` (new) — RemoteFunction

**Tasks:**
- [ ] Rewrite BrewPotion handler:
  - Reject if ActiveBrew.Status != "idle"
  - Validate ingredient ownership, consume atomically
  - Resolve recipe → potionId, determine rarity
  - Set ActiveBrew = { Status="brewing", StartUnix, EndUnix, ingredients, result, discovery }
  - Persist immediately
  - Return brew info to client
- [ ] Implement ClaimBrewResult handler:
  - Check Status is "brewing" with os.time()>=EndUnix OR "completed_unclaimed"
  - Grant potion to inventory
  - Update BrewStats: TotalBrewed++, PotionCounts[id]++, TotalValueBrewed+=value
  - Streak: non-sludge increments CurrentStreak (update BestStreak if higher), sludge resets to 0
  - Check evolution tier threshold changes
  - Clear ActiveBrew to idle, persist
  - Return completion payload with stats + tier change flags
- [ ] Implement GetActiveBrewState: return current ActiveBrew snapshot for client sync
- [ ] Add both new RemoteFunctions to Remotes folder
- [ ] On PlayerRemoving: ensure profile saves with current ActiveBrew state (no special handling needed — just save)

### Phase 3: Client — Brew UI + Progress Bar + Timer (~20%)

**Files:**
- `StarterGui/CauldronGui` — Add progress bar, timer, brew states
- `StarterGui/CauldronGui/CauldronController` — State machine, countdown, claim
- `StarterGui/FeedbackGui` — Enhanced discovery + tier-up celebrations

**Tasks:**
- [ ] Add BrewProgressBar: horizontal fill bar scaling to brew duration
- [ ] Add countdown timer text (shows remaining seconds)
- [ ] Add rarity badge showing potion tier before confirming brew
- [ ] UI states: IDLE (ingredient selection), BREWING (progress bar + timer), RESULT (potion card + stats)
- [ ] BrewBtn disabled while Status != "idle"
- [ ] On brew start: fire BrewPotion, start client countdown + VFX trigger
- [ ] On timer complete: fire ClaimBrewResult, show result card with celebration
- [ ] On CauldronGui open: check GetActiveBrewState — resume timer if brewing, auto-claim if completed_unclaimed
- [ ] Auto-claim UX: "Your brew finished while you were away!" + celebration sequence
- [ ] Stats panel (accessible from HudGui or CauldronGui): TotalBrewed, Recipes Discovered, TotalValue, CurrentStreak, BestStreak
- [ ] Enhanced discovery banner: bigger, particle burst, screen impulse

### Phase 4: World VFX — Stirring Spoon + Staged Effects (~20%)

**Files:**
- `Workspace/Zones/YourShop/Cauldron` — Spoon model, enhanced particles
- `StarterPlayer/StarterPlayerScripts/BrewVFXController` (new) — VFX orchestration

**Tasks:**
- [ ] Insert marketplace spoon/ladle model, parent to cauldron area
- [ ] Animate spoon: orbital rotation around cauldron center during brew (CFrame tween loop)
- [ ] Implement percentage-based VFX timeline:
  - 0-25%: Intensified bubbles + soft steam particles
  - 25-50%: Fire sparks at base (new ParticleEmitter)
  - 50-75%: Fire bursts + outward sparks + liquid color pulse
  - 75-100%: Peak intensity, streaming sparks, glow expansion
  - 100%: Fireworks burst, flash, fire ring, spoon fade
- [ ] Rarity multiplier: scale particle Rate, Size, and Brightness by rarity (Common=1x, Mythic=2.5x)
- [ ] Fireworks: upward particle bursts, tier-colored (common=blue, uncommon=green, rare=gold, mythic=rainbow)
- [ ] Liquid color tween: CauldronLiquid.Color shifts to potion theme during brew
- [ ] Glow expansion: CauldronGlow.Range from 20→40 during brew, flash to 60 at completion
- [ ] Sound: brewing intensity build + completion chime/explosion
- [ ] All VFX clean up after completion (reset to ambient state)
- [ ] Mobile budget: cap particle rates, test on low graphics

### Phase 5: Evolving Cauldron Environment (~15%)

**Files:**
- `Workspace/Zones/YourShop` — Tier element groups
- `StarterPlayer/StarterPlayerScripts/EnvironmentEvolution` (new) — Tier display logic

**Tasks:**
- [ ] Create Tier 1 elements (10+ brews): Neon rune circle on floor under cauldron (Part with SurfaceGui, circular glow)
- [ ] Create Tier 2 elements (25+ brews): 3-4 floating jar models orbiting above (CFrame tween loop, gentle bob)
- [ ] Create Tier 3 elements (50+ brews): Crystal formation models at cauldron base (marketplace insert + PointLight glow)
- [ ] Create Tier 4 elements (100+ brews): Particle weather (arcane motes falling), floating rune particles, expanded purple/gold glow, ambient magical hum Sound
- [ ] All tier elements start hidden (Transparency=1 or outside workspace)
- [ ] EnvironmentEvolution script: on player data load, read TotalBrewed, show appropriate tier
- [ ] Update display after each brew claim (check tier change flag from server)
- [ ] Tier transitions animate: fade-in, scale-up for dramatic reveal when crossing threshold
- [ ] Tier-up announcement in FeedbackGui: "Cauldron Evolved! Tier 2 Unlocked!"

### Phase 6: Regression + Validation (~5%)

**Tasks:**
- [ ] Full brew cycle: select → brew starts → timer → claim → stats updated → VFX complete
- [ ] Test all 4 rarity timers: Common 60s, Uncommon 90s, Rare 120s, Mythic 180s
- [ ] Test Sludge uses Common timer (60s)
- [ ] Test cannot start second brew while one active
- [ ] Test disconnect mid-brew → reconnect → auto-claim works
- [ ] Test V1→V2 migration: old profile gets default BrewStats, ActiveBrew idle
- [ ] Test streak: 3 non-sludge brews → streak=3, then sludge → streak=0, BestStreak=3
- [ ] Test evolution tiers: set TotalBrewed to 10/25/50/100, verify each tier shows
- [ ] Test existing flows: buy/sell/forage still work
- [ ] Test cannot claim non-existent brew (error handling)
- [ ] Mobile viewport: UI and VFX work on narrow screen
- [ ] Performance: no frame drops during peak VFX

## Files Summary

| Location | Action | Purpose |
|----------|--------|---------|
| `ServerScriptService/Services/BrewingService` | Rewrite | Brew state machine, timer lifecycle, stats, claim logic |
| `ServerScriptService/Services/PlayerDataService` | Modify | Schema V2 migration, ActiveBrew persistence, load reconciliation |
| `ReplicatedStorage/Shared/Types` | Modify | DATASTORE_VERSION=2, brew state constants |
| `ReplicatedStorage/Shared/Config/BrewTuning` | Create | TimerByRarity, SludgeTimer, streak config |
| `ReplicatedStorage/Remotes/ClaimBrewResult` | Create | RemoteFunction for post-timer claim |
| `ReplicatedStorage/Remotes/GetActiveBrewState` | Create | RemoteFunction for brew state sync |
| `StarterGui/CauldronGui` | Rewrite | Progress bar, timer, brew states, result card |
| `StarterGui/CauldronGui/CauldronController` | Rewrite | Client state machine, countdown, VFX trigger |
| `StarterGui/FeedbackGui` | Modify | Enhanced discovery + tier-up celebrations |
| `StarterPlayer/StarterPlayerScripts/BrewVFXController` | Create | World VFX orchestration during brew |
| `StarterPlayer/StarterPlayerScripts/EnvironmentEvolution` | Create | Cauldron environment tier display |
| `Workspace/Zones/YourShop/Cauldron` | Modify | Spoon model, enhanced particles, tier elements |
| `Workspace/Zones/YourShop` | Modify | Rune circle, floating jars, crystals, enchanted aura |

## Definition of Done

- [ ] Server enforces rarity timers: Common 60s, Uncommon 90s, Rare 120s, Mythic 180s
- [ ] Sludge (failed brew) uses Common timer (60s)
- [ ] Brew cannot be claimed before server EndUnix
- [ ] Cannot start new brew while one is active
- [ ] ActiveBrew persisted in DataStore (survives disconnect/server crash)
- [ ] Disconnect during brew → reconnect → claim completed brew with celebration
- [ ] Stirring spoon animates during brew
- [ ] VFX escalate through 4 proportional stages during brew
- [ ] Completion triggers fireworks, flash, and result reveal (tier-colored)
- [ ] Rare/Mythic brews have more spectacular effects (rarity multiplier)
- [ ] New recipe discovery has extra celebration
- [ ] BrewStats tracked and persisted: TotalBrewed, TotalValueBrewed, CurrentStreak, BestStreak, PotionCounts
- [ ] V1 profiles migrate cleanly to V2 with default stats
- [ ] Evolution tiers unlock at 10/25/50/100 brews with animated transitions
- [ ] Tier 4 (100+) includes particle weather and enchanted aura
- [ ] Evolution is owner-only visibility (client-side)
- [ ] Stats viewable in UI panel
- [ ] All VFX clean up after brew (no lingering particles)
- [ ] No regressions: buy/sell/forage/persistence work
- [ ] No frame drops during peak VFX

## Exit Criteria Walkthrough

1. Open CauldronGui → select Mushroom + River Water (Common) → click Brew → confirm 60s timer starts
2. Watch VFX escalate through 4 stages over 60 seconds → spoon stirs → completion fireworks
3. Result card shows "Healing Salve" + sell value → stats panel shows TotalBrewed=1
4. Brew Crystal Dust + Moonpetal (Uncommon) → confirm 90s timer
5. Brew Dragon Scale + Moonpetal (Rare) → confirm 120s timer with more intense VFX
6. Brew unknown combo → confirm 60s timer → get Sludge → streak resets
7. Disconnect mid-brew → reconnect → open cauldron → "Your brew finished!" auto-claim
8. Set TotalBrewed to 10 → see rune circle appear. Set to 25 → floating jars. 50 → crystals. 100 → full enchanted aura
9. Leave and rejoin → verify stats persist, evolution tier still visible
10. Try buy/sell/forage → confirm all still work

## Risks & Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| DataStore migration corrupts existing profiles | Low | Critical | Idempotent migration, only adds fields, never removes |
| Timer desync (client says done, server says no) | Medium | High | Server is authority; client adds 1s buffer before claim |
| Duplicate reward via repeated claim requests | Medium | High | Atomic status transition; reject claim if not brewing/completed_unclaimed |
| VFX overwhelm mobile | Medium | Medium | Cap particle rates, rarity budget, test on low spec |
| 60s-180s wait feels too long | Medium | Medium | VFX spectacle fills the time; future: Instant Brew Robux option |
| ActiveBrew data bloats profile | Low | Low | Fixed-size fields, clear on claim |

## Security Considerations

- Brew timer server-enforced: ClaimBrewResult checks `os.time() >= EndUnix`
- Cannot claim brew that doesn't exist (server validates Status)
- Stats only updated server-side, never trusted from client
- Schema migration backward-compatible (only adds, never removes)
- Rate limiting on all brew remotes
- Inspect marketplace models (spoon) for hidden scripts

## Dependencies

- Sprint 001 (core loop, DataStore, BrewingService, Remotes)
- Sprint 002 (cauldron ambient FX, world decorations)
- Roblox Creator Marketplace for spoon model, crystal models
- Sound assets for brew stages and completion effects
