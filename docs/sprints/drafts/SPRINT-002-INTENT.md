# Sprint 002 Intent: World Vibrancy — Dense 3D Props, Glowing Effects, Rich Environments

## Seed

We need to make the game as vibrant and elegant as Grow a Garden. Specifically:

1. Colorful 3D objects in the world (not flat platforms) — potion bottles, cauldrons, herb racks, shelves, plants
2. Glowing/sparkle effects on rare items (golden carrot equivalent = glowing legendary potions with light rays)
3. Rich environment — fences, garden plots, fountains, signs, trees, decorative elements
4. Clear signage — wooden signs with readable text (zone names, prices, labels)
5. Dense, populated world — no empty space, every area has visual interest

The game currently has flat colored floors with a few blocks on them. We need to make the world feel dense and lived-in with actual 3D objects — potion bottles, shelves, herb racks, tables, cauldron decorations, market stalls with hanging items, trees, fences, etc.

## Context

### Orientation Summary

- **Sprint 001** delivered the vertical slice: 4 zones (YourShop, IngredientMarket, TradingPost, WildGrove), core loop (buy → brew → sell → forage), DataStore persistence, rotating market with rarity-weighted selection
- **Sprint 002** was previously drafted (focused on discoverability, feedback, atmosphere) but never finalized. This sprint replaces that plan with a focus on visual density and world richness — a prerequisite for the feedback/atmosphere work
- **Current world is sparse**: flat colored Part floors per zone, a handful of marketplace models (many mispositioned at ~73,57 in workspace root instead of in zones), basic functional parts (cauldron, sell counter, forage nodes). TradingPost has almost nothing. Wild Grove has one nature model
- **69 maple trees** exist in a Foliage folder, 6 billboards, 7 torches, 1 fence in Props — but these appear to be outside the main zones and don't create the "lived-in" density needed
- **IngredientMarket bounding box is broken** (position values in the e+26 range), suggesting a model with extreme coordinates that needs fixing
- **The gap vs Grow a Garden reference images** is massive: we need dense 3D decorations, fencing around zones, themed signage, hanging herbs, shelving, colorful flora, sparkle/glow effects, and no visible empty flat space

## Recent Sprint Context

### Sprint 001: Vertical Slice — Full World, Core Loop, Persistent Economy
- Established the full 4-zone map, server-authoritative architecture, DataStore persistence
- Built all core services: PlayerDataService, MarketService, EconomyService, BrewingService, ZoneService
- Created all GUIs: Market, Cauldron, Sell, RecipeBook, HUD, TopBar navigation
- Inserted some marketplace models but focused on "functional over pretty"
- The world works mechanically but looks like a prototype

### Sprint 002 (Previous Codex Draft — Never Finalized)
- Focused on station discoverability (signage, beacons, landmarks), action feedback (FeedbackOrchestrator), and zone atmosphere
- Codex critique noted missing file ownership, need for server-confirmed feedback gating, and scope dilution
- This work is still relevant and some elements will be incorporated, but the primary gap is now visual density and 3D richness

## Relevant Codebase Areas

### World Structure (Workspace)
- `Workspace/Zones/YourShop` — 652 descendants, has CauldronMedievalFantasy + FantasyPotionShopInterior models
- `Workspace/Zones/IngredientMarket` — 379 descendants, has MedievalMarketStallShop model (broken bounding box)
- `Workspace/Zones/TradingPost` — 12 descendants, extremely bare (floor, spawn, counter, sign, anchor)
- `Workspace/Zones/WildGrove` — 43 descendants, has NatureForestTreesRocksEnvironment model + 6 forage nodes
- `Workspace/Props` — 9 items (bridge, 7 torches, fence)
- `Workspace/Foliage` — 69 maple trees
- `Workspace/Billboards` — 6 billboards
- Loose models in workspace root: fence, potion bottles, trees, lantern, barrel, mushrooms, fountain, herb garden (all clustered at ~73,57, not integrated into zones)

### Lighting
- Warm amber ambient (Atmosphere, Sky, Bloom, DepthOfField, SunRays already configured)
- ClockTime 14 (afternoon), Brightness 2

### Roblox MCP Tools Available
- `insert_model` — Search and insert marketplace models
- `run_code` — Execute Lua to position/configure models, add effects, create parts

## Constraints

- Must use Roblox marketplace models (via `insert_model`) rather than building from mesh — we're not 3D modelers
- Must maintain server-authoritative architecture from Sprint 001 (no gameplay changes this sprint)
- Must not break existing ProximityPrompts, zone teleports, or GUI triggers
- Performance: keep polygon count manageable for mobile — prefer low-poly stylized assets
- Zone floors should remain navigable (no collision traps from dense props)
- All 4 zones must receive attention — no zone left empty
- Must preserve existing functional elements (cauldron, market stall, sell counter, forage nodes)

## Success Criteria

1. **Visual density**: Every zone has enough 3D props that there is no visible empty flat floor from the player's perspective
2. **Zone identity**: Each zone looks and feels distinct — cozy alchemy lab (YourShop), bustling market (IngredientMarket), warm trading hall (TradingPost), mystical forest (WildGrove)
3. **Signage**: Every zone has readable wooden signs identifying it and its key stations
4. **Fencing/boundaries**: Zone edges are defined with fences, walls, or natural barriers — not just floor edge
5. **Glow effects**: At least 3 items in the world have visible glow/sparkle/particle effects (cauldron, rare potion displays, forage nodes)
6. **Prop variety**: At least 5 distinct prop types per zone (e.g., YourShop: shelves, bottles, herbs, tables, candles)
7. **Color richness**: World uses a wide color palette (not just green/brown) — colorful bottles, flowers, banners, lanterns
8. **Grow a Garden parity feel**: A screenshot of any zone could sit alongside the reference images without looking barren

## Verification Strategy

- **Visual inspection**: Take screenshots from player height in each zone and compare side-by-side with Grow a Garden references
- **Playtest walkthrough**: Run play mode and walk through all 4 zones — verify no empty sight lines, all signs readable, all functional elements still work
- **Performance check**: Run in Studio play mode and verify no significant frame drops from added geometry
- **Functional regression**: Verify buy/brew/sell/forage loop still works after world changes

## Uncertainty Assessment

- Correctness uncertainty: **Low** — This is a visual/art sprint, not systems work. Success is visually verifiable.
- Scope uncertainty: **Medium** — The "make it look like Grow a Garden" bar is subjective. We need to define concrete prop counts and zone treatments to bound the work.
- Architecture uncertainty: **Low** — No code architecture changes. All work is in Workspace via `insert_model` and `run_code`.

## Open Questions

1. Should we fix the IngredientMarket's broken bounding box as part of this sprint or treat it as a separate fix?
2. What's the right approach for the loose models currently at ~73,57 in workspace root — relocate into zones or delete and re-insert fresh?
3. Should zone boundaries be wooden fences (like Grow a Garden), stone walls (alchemy theme), hedges, or mixed?
4. For glow effects, should we use PointLights + particle emitters on existing objects, or insert dedicated "rare display" models?
5. How many marketplace model insertions is reasonable before we hit performance concerns on mobile?
