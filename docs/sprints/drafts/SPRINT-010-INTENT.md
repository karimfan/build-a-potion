# Sprint 010 Intent: Progression Loop — Upgrade Shop, Storage Limits, Onboarding

## Seed

Given what we have built so far, and in reading the codebase, what are the top 3 features you think are a must-have for this game?

## Context

- Game has a complete core loop: forage → buy ingredients → brew potions → sell → earn coins
- 4 decorated zones: wizard workshop, enchanted forest, marketplace, trading post
- Mutations, freshness, daily demand, scoring, leaderboards all working
- **But**: players earn coins with nothing to spend them on (no upgrade shop)
- **But**: no inventory pressure (unlimited stacking, storage slots unenforced)
- **But**: new players have zero guidance (no tutorial)

## Recent Sprint Context

- **Sprint 007**: Zone overhaul — potion displays, grove expansion, daily demand board, fantasy polish
- **Sprint 008**: Nuclear visual rebuild — clean zones, flat world, collision policies, hard-contract objects
- **Sprint 009**: Trading post — always-stocked market, flash sales, NPC merchants, deductStock fix

## Relevant Codebase Areas

- `src/shared/Config/UpgradeTuning.lua` — 4 cauldron tiers defined (costs, bonuses), but NO purchase flow
- `src/server/Services/PlayerDataService.lua` — `Upgrades = { CauldronTier=1, BrewStations=1, StorageSlots=20 }`
- `src/server/Services/EconomyService.lua` — buy/sell handlers, but no upgrade purchase handler
- `src/server/Services/BrewingService.lua` — already reads CauldronTier for brew time reduction + mutation bonus
- `src/client/InteractionController.client.lua` — main UI controller, could host upgrade UI
- No tutorial/onboarding code exists anywhere

## Constraints

- Server-authoritative economy (all coin/upgrade mutations on server)
- Must not break existing brew/sell/buy flows
- Must work with Rojo sync (disk files are source of truth)
- CanCollide=false on all decor (world traversability)

## Success Criteria

1. Players can spend coins to upgrade their cauldron through 4 tiers
2. Storage limits are enforced — buying/foraging blocked when full, UI shows capacity
3. New players receive a guided 5-step tutorial on first join

## Verification Strategy

- Play test: purchase upgrade, verify brew time reduction
- Play test: fill inventory to cap, try to buy — should be blocked
- Play test: new player join, tutorial appears and guides through core loop
- Regression: brew, sell, buy, forage all still work

## Uncertainty Assessment

- Correctness uncertainty: Low — straightforward CRUD on existing data
- Scope uncertainty: Medium — tutorial scope could balloon
- Architecture uncertainty: Low — extends existing patterns (_G.Service, remotes, client controllers)

## Open Questions

1. Should upgrades be accessed via a dedicated NPC/station, or a HUD button?
2. Should the tutorial be skippable?
3. Should storage limits block purchases entirely, or just warn?
