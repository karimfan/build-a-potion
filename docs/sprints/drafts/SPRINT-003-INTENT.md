# Sprint 003 Intent: Cauldron Brewing Experience — VFX, Brew Timer, Player Stats, Evolving Environment

## Seed

We need to spend cycles improving the brewing of potion experience. We need much better visual effects. Perhaps a spoon that is churning the potion in the cauldron. Steam, fire, fireworks, sparks. Once a potion is brewed we need to reflect that in the players stats: potions mixed, strength of all potions, etc. We also need to pimp the area around the cauldron. It should be more magical and mythical the more potions are brewed. Go nuts with that design: magical, fantastical, large, colorful. Also, we need to introduce a wait time before brewing potions. perhaps 2 mins? Add anything else on the cauldron experience you think is a good fit.

## Context

### Orientation Summary

- **Brewing is currently instant**: BrewingService consumes ingredients and returns result in <1s. BREW_COOLDOWN is just 1 second for rate limiting, not a gameplay timer.
- **No player stats tracking**: Player profile stores Coins, Ingredients, Potions, DiscoveredRecipes, LastLoginUnix — no brew count, no cumulative stats.
- **CauldronGui is functionally minimal**: Two ingredient slots, brew button, result label, ingredient grid. No animation states, progress bar, or staged feedback.
- **Cauldron world object has ambient FX**: Green PointLight, bubble ParticleEmitter, smoke ParticleEmitter, bubbling Sound — but these are always-on static effects, not responsive to brewing activity.
- **YourShop zone already has dense decorations** from Sprint 002: shelves, bottles, herbs, candles, rugs, barrels, sconces. The cauldron area is at (0, 2.5, -8) in the center-back of the shop.

## Recent Sprint Context

### Sprint 001: Vertical Slice
- Built the full core loop: buy ingredients, brew potions, sell, forage
- Server-authoritative architecture with BrewingService, EconomyService, MarketService, PlayerDataService
- DataStore persistence for player state
- All 4 zones navigable with ProximityPrompt interactions

### Sprint 002: World Vibrancy
- Transformed all zones from graybox to dense decorated environments
- Added stone wall + hedge boundaries, marketplace models, ambient audio
- Cauldron got ambient bubble/smoke particles and green glow (static, always-on)
- Fixed spawn collision issues, disabled marketplace model scripts

## Relevant Codebase Areas

### Server
- `ServerScriptService/Services/BrewingService` — Recipe resolution, ingredient consumption, discovery tracking. Currently instant, 1s rate limit only.
- `ServerScriptService/Services/PlayerDataService` — DataStore load/save, profile schema (Version 1). Needs schema migration to add stats fields.

### Client
- `StarterGui/CauldronGui` — ScreenGui with MainFrame containing ingredient slots, brew button, result label. No animation/progress states.
- `StarterGui/FeedbackGui` — Has DiscoveryBanner for new recipe celebrations. Could be extended for brew completion celebration.

### Shared
- `ReplicatedStorage/Shared/Config/Recipes` — Recipe lookup module
- `ReplicatedStorage/Shared/Config/Potions` — Potion definitions with sell values and rarity tiers
- `ReplicatedStorage/Shared/Types` — Shared constants including DATASTORE_VERSION, STARTING_COINS

### World
- `Workspace/Zones/YourShop/Cauldron` — Part at (0, 2.5, -8) with BillboardGui, ProximityPrompt, PointLight, ParticleEmitters, Sound
- `Workspace/Zones/YourShop/CauldronLiquid` — Visual liquid part inside cauldron
- `Workspace/Zones/YourShop/CauldronMedievalFantasy` — Marketplace cauldron model

### Remotes
- `ReplicatedStorage/Remotes/BrewPotion` — RemoteFunction for brew requests (client → server → response)

## Constraints

- Must maintain server-authoritative brew validation (no client-side cheating)
- DataStore schema migration needed (Version 1 → Version 2) — must handle old profiles gracefully
- Brew timer must be server-enforced, not just client visual
- Must not break existing buy/sell/forage flows
- VFX must work on mobile (keep particle budgets reasonable)
- New stats must persist across sessions via DataStore

## Success Criteria

1. Brewing feels like an event — visual spectacle with staged feedback (start → progress → result → celebration)
2. 2-minute brew timer with visible progress bar and can't-skip enforcement
3. Player stats tracked: total potions brewed, per-potion counts, brew streak, total value brewed
4. Cauldron area evolves visually based on player's brewing history (more magical = more brews)
5. Stirring spoon animation during brew
6. Dramatic VFX: steam, fire bursts, sparks, fireworks on completion
7. The cauldron experience is the "golden carrot" moment — screenshot-worthy

## Verification Strategy

- **Play mode test**: Complete full brew cycle, verify timer enforced, stats persisted after rejoin
- **Edge cases**: Brew while already brewing, disconnect during brew, brew with insufficient ingredients
- **Visual inspection**: VFX look spectacular from player camera angle
- **Performance**: No frame drops during brew VFX sequence on desktop
- **DataStore**: Old profiles (Version 1) migrate cleanly to Version 2 with default stats

## Uncertainty Assessment

- Correctness uncertainty: **Medium** — Timer enforcement and DataStore migration need careful implementation
- Scope uncertainty: **Medium** — "Go nuts" on environment evolution is open-ended; need to bound it
- Architecture uncertainty: **Medium** — New brew state machine, timer system, and stats tracking are new patterns

## Open Questions

1. Should the brew timer be exactly 2 minutes for all potions, or vary by rarity (common=30s, rare=2min, mythic=5min)?
2. How many visual evolution stages for the cauldron environment? (e.g., 0 brews, 10 brews, 50 brews, 100 brews)
3. Should the stirring spoon be a 3D model from marketplace or a simple animated Part?
4. Should brew progress be visible to other players visiting the shop?
5. What happens if the player disconnects mid-brew — lose ingredients, or restore them?
6. Should there be a "quick brew" or "instant brew" option (future monetization hook)?
