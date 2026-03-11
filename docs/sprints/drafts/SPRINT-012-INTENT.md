# Sprint 012 Intent: Potion Arena — PvP Duels with Auto-Sim & Boost Mechanic

## Seed

Add a fighting arena where players wager potions and duel. Power comes from stars + potion rarity. Auto-simulated fight with a button-mash "boost" mechanic that adds up to 20% bonus power. Winner takes one potion from the loser + bonus stars.

## Context

- Game has 4 zones (YourShop, IngredientMarket, TradingPost, WildGrove). Arena will be 5th zone.
- Stars (BrewStats.StarCount) represent weighted progression — Common=1, Uncommon=2, Rare=5, Mythic=10, Divine=25 per brew.
- Potions have 5 tiers (Common/Uncommon/Rare/Mythic/Divine) with mutations (Glowing through Golden).
- Server-authoritative architecture, `_G.*Service` pattern, Remotes for client-server communication.
- MutationTuning.Types has sell multipliers per mutation (2x-10x).
- Game design emphasizes social/viral moments, screenshot-worthy reveals, TikTok content.

## Relevant Codebase Areas

- `src/server/Services/EconomyService.lua` — Buy/sell patterns, potion inventory mutation
- `src/server/Services/PlayerDataService.lua` — Player data, potion counts, star count
- `src/shared/Config/Potions.lua` — Potion data with tiers and sell values
- `src/shared/Config/MutationTuning.lua` — Mutation multipliers
- `src/shared/Config/ForageTuning.lua` — Star weights, computeStarCount
- `src/client/BrewVFXController.client.lua` — VFX patterns, sound patterns
- `src/client/FeedbackController.client.lua` — Announcement system
- `default.project.json` — Rojo registration

## Open Questions

1. Should there be a cooldown between duels?
2. Should spectators be able to watch?
3. What happens if a player disconnects mid-duel?
4. Should there be a minimum star/potion requirement to enter the arena?
