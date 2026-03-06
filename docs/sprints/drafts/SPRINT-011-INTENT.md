# Sprint 011 Intent: Starbound Foraging — Progression-Linked Foraging & Grove Expansion

## Seed

We need to augment the foraging system and connect it to player stars. The more stars a player has the higher the chance they can forage rarer items. We also need to expand the foraging area gradually with the more stars a player has, up to a certain max. Design this link between stars and foraging to make the game stickier and more appealing.

## Context

- Stars = `BrewStats.TotalBrewed` (1 per brew, displayed in ShopRealmController's Potion Constellation)
- Currently foraging is completely flat — no progression. Regular nodes pick from a hardcoded pool of 3 common ingredients per node with uniform random. Rare nodes spawn every 120-240s with a flat 30% rare vs 70% uncommon split. No player stats influence any forage outcome.
- The WildGrove is 175x175 studs with 12 forage nodes spread across 4 quadrants.
- Forage cooldown is 60 seconds per node (server-enforced).
- BrewTuning.EvolutionTiers: 0=Apprentice, 10=Adept, 25=Alchemist, 50=Master, 100=Archmage.
- The game design doc emphasizes "always something new" and "appointment play."

## Recent Sprint Context

- **Sprint 008**: Nuclear visual rebuild of all 4 zones. WildGrove expanded to 175x175 with 12 forage nodes, themed sub-areas, bioluminescent trees, crystal formations.
- **Sprint 009**: Market polish — always-stocked guarantees, flash sales, NPC merchants, server-authoritative stock deduction.
- **Sprint 010**: Progression loop closure — upgrade shop (cauldron tiers + storage), storage limits with soft warnings, 6-step onboarding tutorial.

## Relevant Codebase Areas

- `src/server/Services/ZoneService.lua` — Forage node handling (lines 14-75: regular nodes, lines 82-210: rare node spawning)
- `src/server/Services/ScoreService.lua` — Composite score calculation
- `src/server/Services/PlayerDataService.lua` — Player data including BrewStats.TotalBrewed
- `src/shared/Config/BrewTuning.lua` — Evolution tier thresholds
- `src/client/ShopRealmController.client.lua` — Star visualization (TotalBrewed = star count)
- `src/client/ForageNodeFeedback.client.lua` — Node visual feedback
- `src/shared/Config/Ingredients.lua` — All 44 ingredients with tiers and acquisition flags
- `src/shared/Types.lua` — Constants including FORAGE_COOLDOWN_SECONDS

## Constraints

- Must be server-authoritative (forage outcomes computed on server using player's star count)
- Must persist changes to disk (Rojo sync)
- Must preserve existing remote contracts (ForageNode event, PlayerDataUpdate)
- Follow `_G.*Service` pattern for any new services
- No hard-gating — even 0-star players should be able to forage (just common items)
- Must integrate smoothly with existing 12 forage nodes and rare node spawning system

## Success Criteria

1. Players with more brews (stars) forage rarer ingredients from regular nodes
2. WildGrove exploration area expands visually and functionally with star progression
3. The system creates a virtuous feedback loop: brew more → forage better → brew rarer potions → brew more
4. New players still have a good experience (common foraging works great at 0 stars)
5. High-star players feel meaningfully rewarded in the grove

## Verification Strategy

- Unit test: Verify forage probability tables produce expected tier distributions at each star threshold
- Integration test: Player at 0 stars forages only commons from regular nodes; player at 100 stars has meaningful uncommon/rare chance
- Grove expansion test: Verify new node areas unlock at correct star thresholds
- Regression: Existing 12 nodes still work, rare node spawning still works, cooldowns still enforced
- Edge cases: What happens at exactly 0 stars? At max stars? Player joins mid-expansion?

## Uncertainty Assessment

- Correctness uncertainty: Low — extending existing forage system with star-based probability tables
- Scope uncertainty: Medium — "expand the foraging area" could mean many things (new nodes? larger bounds? new sub-zones?)
- Architecture uncertainty: Low — fits cleanly into existing ZoneService + PlayerDataService pattern

## Open Questions

1. How should grove expansion manifest? New forage nodes appearing? New sub-zones unlocking? Existing area expanding?
2. What star thresholds should gate forage improvements? Should they align with evolution tiers (10/25/50/100)?
3. Should high-star players be able to forage uncommon ingredients from regular nodes, or should the improvement only apply to rare node spawns?
4. Should there be visual feedback in the grove showing the player's forage level (e.g., the grove "blooms" more for advanced players)?
5. Should forage cooldown decrease with stars, or just the rarity of drops?
