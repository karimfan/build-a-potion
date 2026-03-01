# Sprint 005 Intent: Brewing Potions — Full Recipe Matrix, Mutation System, Enhanced Discovery

## Seed

Brewing is the central mechanic. Currently we have 15 recipes for 59 ingredients — most combinations produce Sludge. This sprint designs and implements a full recipe matrix of 75+ discoverable recipes across all tiers, adds the Mutation System (Glowing, Bubbling, Crystallized, Shadow, Rainbow, Golden variants with 2x-10x sell multipliers), supports 2-4 ingredient combinations (not just 2), and enhances the discovery celebration for rare finds.

## Context

- **Current state**: 15 recipes using only 12 of the original ingredients. 47 new ingredients from Sprint 004 have ZERO recipes. BrewingService supports 2-ingredient combos only.
- **Sprint 003** added timed brewing with rarity-based timers (Common 60s, Rare 120s, Mythic 180s), brew VFX, player stats, and evolution tiers. The timer/VFX infrastructure exists.
- **Sprint 004** expanded the ingredient catalog to 59 with visual archetypes, per-ingredient market odds, freshness system, and V3 DataStore migration.
- **The GDD calls for 50-75 recipes** at launch, with recipes spanning Common→Mythic→Divine outcomes. The Mutation System is a key viral mechanic (mirrors Grow a Garden's mutation system).

## Key Design Decisions Needed

1. **Recipe matrix**: Design 75+ recipes that use all 59 ingredients. Element-matching combos should produce better results. Higher tier ingredients = higher tier potions.
2. **2-4 ingredient support**: Currently only 2-ingredient combos. Need to support 3 and 4 ingredient "advanced" recipes for higher-tier outcomes.
3. **Mutation system**: Random chance for mutations that multiply sell value. Mutations are visual variants (Glowing, Bubbling, Crystallized, Shadow, Rainbow, Golden).
4. **Discovery UX**: First-time discoveries of rare recipes should be TikTok-worthy moments.
5. **Recipe book enhancement**: Show all discoverable recipes with hints for undiscovered ones.

## Relevant Codebase

- `src/shared/Config/Recipes.lua` — Current 15 recipes, sorted-pair lookup
- `src/shared/Config/Potions.lua` — 16 potions (15 + sludge)
- `src/server/Services/BrewingService.lua` — 2-ingredient brew flow, timer, stats, claim
- `src/client/InteractionController.lua` — CauldronGui with 2 ingredient slots
- `src/shared/Config/BrewTuning.lua` — Timer durations, VFX multipliers

## Open Questions

1. Should 3-4 ingredient recipes require a cauldron upgrade (future progression) or be available from the start?
2. Should mutation chance be fixed (e.g., 5%) or scale with ingredient quality/freshness?
3. How should the recipe key work for 3-4 ingredients? Sorted concatenation?
4. Should element-matching provide a bonus (e.g., same-element combo = higher tier potion)?
