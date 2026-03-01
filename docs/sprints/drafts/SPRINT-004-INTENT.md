# Sprint 004 Intent: Ingredient Market Overhaul — Full GDD Catalog, Visual Variety, Freshness System

## Seed

Focus on the gathering ingredients experience. The GDD (brew_a_potion.md Section 2.1) defines 58 ingredients across 5 tiers, but only 12 are implemented. Every ingredient currently looks like a generic orb. We need:

1. **Full ingredient catalog** from the GDD: 15 Common, 14 Uncommon, 15 Rare, 12 Mythic, 2 Divine
2. **Visually distinct ingredients** — not orbs. Mushrooms should look like mushrooms, Dragon Scales like scales, Starfall Shards like crystal meteors. Creative, mystical, magical variety.
3. **Freshness system** — ingredients degrade over time, encouraging active play
4. **Affinity tags** — hidden property that affects combination outcomes
5. **Market improvements** — better UI showing element colors, rarity glow, ingredient previews
6. **Per-ingredient rarity chances** — the GDD has specific % chances per ingredient, not just per tier

## Context

- **Current state**: 12 ingredients (8 Common, 2 Uncommon, 2 Rare), no Mythic/Divine. All look like text in the market GUI. No freshness, no affinity.
- **MarketService**: Generates offers using TierRules (chance per tier, stock ranges). Works but needs expansion for per-ingredient chances.
- **MarketTuning**: Simple tier-based rules. Needs individual ingredient appearance rates from GDD.
- **MarketGui**: Text-only list items. Needs visual overhaul with element colors, rarity indicators, ingredient icons/models.
- **Ingredients config**: Basic {id, name, tier, cost, element, description}. Needs freshness decay, affinity, visual model references, per-ingredient market chance.

## Recent Sprint Context

- **Sprint 001**: Core loop, 12 starter ingredients, basic market with 5-min refresh
- **Sprint 002**: World vibrancy, dense props, stone walls, ambient audio
- **Sprint 003**: Cauldron ascension — timed brewing, VFX spectacle, player stats, evolution tiers

## Relevant Codebase Areas

- `ReplicatedStorage/Shared/Config/Ingredients` — Ingredient catalog (12 entries, needs 58)
- `ReplicatedStorage/Shared/Config/MarketTuning` — Tier-based market rules
- `ReplicatedStorage/Shared/Config/Recipes` — Recipe lookups (need new recipes for new ingredients)
- `ServerScriptService/Services/MarketService` — Offer generation, stock, refresh timer
- `StarterGui/MarketGui` — Market browse/buy interface
- `StarterPlayer/StarterPlayerScripts/InteractionController` — Market GUI wiring
- `StarterPlayer/StarterPlayerScripts/GameController` — Market UI rendering
- `Workspace/Zones/IngredientMarket` — Physical market zone

## Constraints

- Must maintain server-authoritative market (no client-side stock manipulation)
- Must not break existing recipes (12 current ingredients stay, new ones add on)
- Must handle the 5-minute refresh cycle with per-ingredient rarity chances
- Market GUI must remain mobile-friendly (not too many items, scrollable)
- Freshness system must integrate with existing DataStore schema (V2→V3 migration)
- Visual ingredient representations should use Roblox primitives + materials + effects (not custom meshes)

## Success Criteria

1. All 58 ingredients from the GDD are in the catalog
2. Each ingredient has a unique visual identity (not orbs) — creative, magical, distinct
3. Market shows ingredients with element-colored backgrounds, rarity glow borders, visual previews
4. Freshness degrades over time, expired ingredients are less effective or worthless
5. Rarer ingredients appear with GDD-specified chances (Mythic 1.5-3%, Rare 10-15%)
6. Players feel excitement and FOMO when rare/mythic ingredients appear in the market

## Uncertainty Assessment

- Correctness: **Low** — extending existing patterns
- Scope: **High** — 58 ingredients is massive, visual variety is creative/subjective
- Architecture: **Medium** — freshness and affinity are new systems

## Open Questions

1. Should freshness degrade in real-time (os.time) or only when the player is online?
2. How should visual ingredient models work in the market GUI — 3D viewport frames or 2D colored shapes?
3. Should the market GUI show all available ingredients or just current stock?
4. How many new recipes should we add for the new ingredients?
5. Should Divine tier ingredients be implemented now or deferred to the monetization sprint?
