# Sprint 003: Cauldron Brewing Experience — VFX Spectacle, Brew Timer, Player Stats, Evolving Environment

## Overview

Brewing a potion should feel like casting a spell — dramatic, visual, and rewarding. Right now it's instant and silent: click "Brew", ingredients vanish, potion appears. Sprint 003 transforms the entire brewing experience into a staged spectacle with a 2-minute timer, churning spoon animation, escalating VFX (steam → fire → sparks → fireworks on completion), persistent player stats, and an evolving cauldron environment that grows more magical as the player brews more.

This sprint touches all three layers: server (brew state machine, timer enforcement, stats tracking, DataStore migration), client (animated brew UI with progress bar, staged VFX orchestration, stats display), and world (stirring spoon, environmental evolution based on brew count). The cauldron area becomes the centerpiece of the game — the moment players screenshot and share.

The design philosophy: "Every brew should feel like a TikTok moment." Rare brews get even more spectacular effects. The player's cauldron corner should visually tell the story of how experienced they are.

## Use Cases

1. **First brew excitement**: New player selects 2 ingredients, clicks Brew, and watches a 2-minute sequence unfold — spoon starts stirring, bubbles intensify, steam rises, liquid changes color. Timer counts down. At completion: flash, fireworks, result reveal with fanfare.
2. **Discovery celebration**: First time brewing a new recipe triggers an extra-dramatic reveal — bigger explosions, "NEW RECIPE!" banner, screen shake.
3. **Rare brew spectacle**: Rare/Mythic tier potions produce more intense VFX — bigger fire, more sparks, screen-filling fireworks. These are the viral moments.
4. **Progress tracking**: Player opens their stats panel and sees: 47 potions brewed, 12 recipes discovered, total value brewed 3,450 coins, current streak 5.
5. **Environment evolution**: After 10 brews, magical runes appear on the floor around the cauldron. After 50 brews, floating crystals orbit above. After 100 brews, the entire corner glows with enchanted energy and has its own particle weather.
6. **Patience and anticipation**: The 2-minute timer creates anticipation. Players watch the VFX build. They share "look what's coming" clips mid-brew. The wait makes the result more satisfying.
7. **Mid-brew disconnect safety**: Player disconnects during a brew — ingredients are already consumed (committed at brew start), but the brew completes silently and the potion is added to inventory on next login.

## Architecture

### Brew State Machine

```
IDLE → BREWING → COMPLETING → IDLE
  │        │          │
  │        │          └── Result reveal, stats update, VFX finale
  │        └── Timer running, stirring VFX active, liquid color shifting
  └── Player selects ingredients and clicks "Brew"
```

### Server-Side Brew Flow

```
Client: BrewPotion(ingredient1, ingredient2)
  → Server: BrewingService
     1. Validate ingredients owned
     2. Consume ingredients immediately (atomic)
     3. Resolve recipe → potionId
     4. Start server-side timer (store brewEndTime in player session)
     5. Return { success, potionId, brewDuration, isNewDiscovery, tier }

Client: Shows brew animation for brewDuration seconds

Client: ClaimBrewResult() [after timer expires]
  → Server: BrewingService
     1. Validate timer has expired (os.time() >= brewEndTime)
     2. Add potion to inventory
     3. Update stats (totalBrewed, perPotionCounts, totalValue, streak)
     4. Clear brew state
     5. Return { potionId, potionName, sellValue, isNewDiscovery, updatedStats }

Server: On player disconnect during brew
     1. Immediately complete brew
     2. Add potion to inventory
     3. Update stats
     4. Save to DataStore
```

### DataStore Schema Migration (Version 1 → 2)

```lua
-- Version 2 adds BrewStats
PlayerState = {
    Version = 2,
    Coins = number,
    Ingredients = { [ingredientId] = quantity },
    Potions = { [potionId] = quantity },
    DiscoveredRecipes = { [recipeKey] = true },
    LastLoginUnix = number,
    -- NEW in V2:
    BrewStats = {
        TotalBrewed = number,        -- lifetime potions brewed
        TotalValueBrewed = number,   -- cumulative sell value of all potions
        CurrentStreak = number,      -- consecutive successful (non-sludge) brews
        BestStreak = number,         -- all-time best streak
        PotionCounts = { [potionId] = number },  -- per-potion brew counts
    },
    ActiveBrew = nil,  -- { potionId, brewEndTime } if mid-brew on disconnect
}
```

### VFX Timeline (2-minute brew)

```
0:00  Brew starts
      - Spoon begins stirring (continuous rotation)
      - Cauldron liquid color starts shifting toward potion color
      - Ambient bubbles intensify (Rate 8 → 20)
      - Soft steam particles begin rising

0:30  Quarter mark
      - Fire sparks begin around cauldron base
      - Liquid glow intensifies
      - Steam thickens

1:00  Halfway
      - Small fire bursts from cauldron rim
      - Sparks fly outward
      - Camera subtle shake
      - Liquid is now fully potion-colored and pulsing

1:30  Three-quarter mark
      - Fire bursts larger and more frequent
      - Sparks become streaming
      - Glow expands to illuminate nearby area
      - Anticipation sound builds

1:55  Pre-completion
      - Everything intensifies to peak
      - Bright flash warning
      - Sound crescendo

2:00  COMPLETION
      - Screen flash
      - Fireworks burst upward (5-8 bursts, tier-colored)
      - Fire ring expands outward from cauldron
      - Spoon stops, rises, disappears
      - Result card appears with potion name + value
      - If new discovery: extra fireworks, bigger banner, camera impulse
```

### Cauldron Environment Evolution

```
Tier 0 (0 brews):     Base cauldron, no extras
Tier 1 (10+ brews):   Magical rune circle on floor (glowing SurfaceGui)
Tier 2 (25+ brews):   + Floating ingredient jars orbiting above cauldron
Tier 3 (50+ brews):   + Crystalline formations growing from floor near cauldron
Tier 4 (100+ brews):  + Full enchanted aura: particle weather, expanded glow radius,
                         ambient magical hum, floating runes in the air
```

## Implementation Plan

### Phase 1: Server — Brew Timer + State Machine + Stats (~30%)

**Files:**
- `ServerScriptService/Services/BrewingService` — Rewrite with timer, state machine, stats
- `ServerScriptService/Services/PlayerDataService` — Schema migration V1→V2
- `ReplicatedStorage/Shared/Types` — Update DATASTORE_VERSION to 2
- `ReplicatedStorage/Shared/Config/BrewTuning` (new) — Timer durations, streak rules
- `ReplicatedStorage/Remotes/ClaimBrewResult` (new) — RemoteFunction for post-timer claim

**Tasks:**
- [ ] Create BrewTuning config: `{ Durations = { Common = 60, Uncommon = 90, Rare = 120, Mythic = 180 } }` — timer varies by potion rarity
- [ ] Rewrite BrewingService with brew state machine:
  - BrewPotion: validate → consume → resolve recipe → set timer → return brew info
  - ClaimBrewResult: validate timer expired → add potion → update stats → return result
  - On PlayerRemoving: if active brew, complete immediately and save
- [ ] Add BrewStats to PlayerDataService default profile
- [ ] Implement schema migration: if Version == 1, add empty BrewStats and set Version = 2
- [ ] Add ClaimBrewResult RemoteFunction to Remotes folder
- [ ] Add server-side active brew tracking (per-player session state, not DataStore)
- [ ] Update stats atomically: TotalBrewed++, PotionCounts[id]++, TotalValueBrewed += value, streak logic
- [ ] Streak rules: non-sludge increments streak, sludge resets to 0. Track BestStreak.

### Phase 2: Client — Brew UI + Progress Bar + Timer (~25%)

**Files:**
- `StarterGui/CauldronGui` — Major redesign with progress bar, timer, states
- `StarterGui/CauldronGui/CauldronController` (LocalScript) — Brew flow orchestration
- `StarterGui/FeedbackGui` — Enhanced discovery celebration

**Tasks:**
- [ ] Add BrewProgressBar to CauldronGui MainFrame: horizontal bar that fills over brew duration
- [ ] Add BrewTimer text showing countdown (2:00, 1:59, ... 0:00)
- [ ] Add brew state management: IDLE (show ingredient slots), BREWING (show progress), RESULT (show outcome)
- [ ] During BREWING state: hide ingredient selection, show progress bar + timer + cancel info
- [ ] During RESULT state: show potion name, sell value, tier, new discovery badge
- [ ] BrewBtn disabled while already brewing
- [ ] On brew start: fire BrewPotion remote, get brew info, start client timer + VFX
- [ ] On timer complete: fire ClaimBrewResult remote, get final result, show result card
- [ ] Add stats button to CauldronGui or HudGui that shows BrewStats panel
- [ ] Stats panel shows: Total Brewed, Recipes Found, Total Value, Current Streak, Best Streak
- [ ] Enhanced discovery banner: bigger, more particles, screen impulse

### Phase 3: World VFX — Stirring Spoon + Staged Effects (~25%)

**Files:**
- `Workspace/Zones/YourShop/Cauldron` — Add spoon, enhance particles
- `StarterPlayer/StarterPlayerScripts/BrewVFXController` (new LocalScript) — Orchestrate world VFX

**Tasks:**
- [ ] Insert marketplace spoon/ladle model OR create simple spoon Part
- [ ] Animate spoon rotation during brew (CFrame tween, orbiting above cauldron liquid)
- [ ] Stage VFX timeline (see Architecture section):
  - 0:00-0:30: Intensified bubbles + soft steam
  - 0:30-1:00: Fire sparks at cauldron base
  - 1:00-1:30: Fire bursts + outward sparks + liquid pulse
  - 1:30-2:00: Peak intensity, streaming sparks, glow expansion
  - 2:00: Fireworks burst, fire ring, flash, result
- [ ] Create ParticleEmitters for each stage (steam, sparks, fire, fireworks)
- [ ] Fireworks: upward particle bursts with tier-appropriate colors (common=blue, rare=gold, mythic=rainbow)
- [ ] Liquid color tween: shift CauldronLiquid.Color toward potion's theme color during brew
- [ ] Glow expansion: increase CauldronGlow.Range from 20→40 during brew, flash to 60 at completion
- [ ] Sound: brewing intensity sound that builds, completion chime/explosion sound
- [ ] All VFX clean up after brew completes (reset to ambient state)

### Phase 4: Evolving Cauldron Environment (~15%)

**Files:**
- `Workspace/Zones/YourShop` — New decorative elements based on brew count
- `StarterPlayer/StarterPlayerScripts/EnvironmentEvolution` (new LocalScript) — Checks stats and shows/hides tiers

**Tasks:**
- [ ] Create Tier 1 elements (10+ brews): glowing rune circle on floor under cauldron (Decal or SurfaceGui with rune texture, Neon glow)
- [ ] Create Tier 2 elements (25+ brews): 3-4 floating jar models orbiting above cauldron (use CFrame tween loop)
- [ ] Create Tier 3 elements (50+ brews): crystal formation models growing from floor near cauldron base
- [ ] Create Tier 4 elements (100+ brews): full enchanted aura — expanded particle weather, floating rune particles, ambient magical hum sound, purple/gold glow radius
- [ ] All tier elements start hidden (Transparency=1 or parent=nil)
- [ ] EnvironmentEvolution script: on player data load, check TotalBrewed, show appropriate tier elements
- [ ] Update tier display after each brew completion
- [ ] Tier transitions should be animated (fade in, scale up) for dramatic reveal when crossing threshold

### Phase 5: Polish + Integration Testing (~5%)

**Tasks:**
- [ ] Verify full brew cycle: select ingredients → brew starts → 2 min timer → claim result → stats updated
- [ ] Test edge cases: brew while brewing (rejected), disconnect mid-brew (completes on rejoin), insufficient ingredients
- [ ] Verify DataStore migration: create V1 profile, rejoin, confirm V2 migration with default BrewStats
- [ ] Test all VFX stages visually — each should be distinct and escalating
- [ ] Test environment evolution: manually set TotalBrewed to 10, 25, 50, 100 and verify each tier shows
- [ ] Mobile viewport check: VFX and UI work on narrow screen
- [ ] Performance: no frame drops during peak VFX moment

## Files Summary

| Location | Action | Purpose |
|----------|--------|---------|
| `ServerScriptService/Services/BrewingService` | Rewrite | Brew state machine, timer, stats, disconnect safety |
| `ServerScriptService/Services/PlayerDataService` | Modify | Schema migration V1→V2, BrewStats defaults |
| `ReplicatedStorage/Shared/Types` | Modify | DATASTORE_VERSION = 2 |
| `ReplicatedStorage/Shared/Config/BrewTuning` | Create | Timer durations, rarity multipliers, streak config |
| `ReplicatedStorage/Remotes/ClaimBrewResult` | Create | New RemoteFunction for post-timer claim |
| `StarterGui/CauldronGui` | Rewrite | Progress bar, timer, brew states, result card, stats |
| `StarterGui/FeedbackGui` | Modify | Enhanced discovery celebration |
| `StarterPlayer/StarterPlayerScripts/BrewVFXController` | Create | World VFX orchestration during brew |
| `StarterPlayer/StarterPlayerScripts/EnvironmentEvolution` | Create | Cauldron area visual evolution by brew count |
| `Workspace/Zones/YourShop/Cauldron` | Modify | Add spoon, enhance particles, tier elements |
| `Workspace/Zones/YourShop` | Modify | Rune circle, floating jars, crystals, enchanted aura |

## Definition of Done

- [ ] Clicking "Brew" starts a timed sequence (server-enforced, not skippable)
- [ ] Progress bar and countdown timer visible during brew
- [ ] Stirring spoon animates during brew
- [ ] VFX escalate through 4 stages over the brew duration
- [ ] Completion triggers fireworks, flash, and result reveal
- [ ] Rare/Mythic brews have more spectacular completion effects
- [ ] New recipe discovery has extra celebration (banner, bigger fireworks)
- [ ] BrewStats tracked: TotalBrewed, TotalValueBrewed, CurrentStreak, BestStreak, PotionCounts
- [ ] Stats persist across sessions (DataStore V2)
- [ ] Old V1 profiles migrate cleanly to V2
- [ ] Cauldron environment evolves at 4 tiers (10/25/50/100 brews)
- [ ] Cannot start new brew while one is in progress
- [ ] Disconnect mid-brew completes the brew and saves result
- [ ] All VFX clean up after brew (no lingering particles)
- [ ] No frame drops during brew VFX sequence

## Risks & Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| DataStore migration corrupts existing data | Low | Critical | Default empty BrewStats for V1 profiles, never delete existing fields |
| Brew timer desync (client shows done but server says no) | Medium | High | Server is authority; client adds 1s buffer before ClaimBrewResult |
| VFX overwhelm mobile performance | Medium | Medium | Cap particle rates, use distance culling, test on minimum spec |
| Player disconnects after consuming ingredients but before brew completes | Medium | High | Server completes brew immediately on disconnect and saves |
| Floating objects/orbiting jars cause visual clutter | Low | Medium | Keep evolution elements close to cauldron, fade with distance |
| 2-minute wait feels too long | Medium | Medium | VFX make the wait entertaining; future monetization: Instant Brew for Robux |

## Security Considerations

- Brew timer server-enforced: ClaimBrewResult checks os.time() >= brewEndTime
- Cannot claim brew that doesn't exist (server tracks active brew per player)
- Stats only updated server-side, never trusted from client
- Schema migration is backward-compatible (only adds fields, never removes)
- Rate limiting on BrewPotion and ClaimBrewResult remotes

## Dependencies

- Sprint 001 (core loop, DataStore persistence, BrewingService)
- Sprint 002 (cauldron ambient FX, world decorations)
- Roblox Creator Marketplace for spoon model
- Sound assets for brew stages and completion

## Open Questions

1. Should there be a "quick brew" Robux option from day one, or defer to monetization sprint?
2. Should other players visiting the shop see the brew VFX?
3. How detailed should the spoon animation be — simple orbit, or bobbing/tilting too?
4. Should environment evolution persist between sessions (show tier on login) or rebuild each time?
