# Sprint 008 Intent: Nuclear Visual Rebuild — Clean Zones, Flat World, Functional Foraging

## Seed

Nuke all existing zone visuals and rebuild from scratch. Clean, polished fantasy designs. No flickering lights. The foraging area (WildGrove) must be 3x larger than any other zone. The shop (YourShop) must adhere to the Sunken Crypt SVG spec. All ground must be at the same Y level. Players must not be able to climb bookcases or decorative furniture. Foraging must actually work (nodes present, interactable, connected to server logic). Total visual design reset.

## Context

- All 4 zones have broken visual builds from ad-hoc MCP construction: blown-out lighting, Terrain voxels blocking paths, climbable furniture, inconsistent ground levels, chaotic aesthetics
- All gameplay systems (brewing, selling, foraging, market, scoring, mutations, upgrades) are fully implemented in Lua and working — this sprint is PURELY visual/world build
- Roblox Terrain geometry exists in the world and must be cleared from all playable areas
- The SVG at `/Users/karim.fanous/Downloads/1_sunken_crypt.svg` defines the shop design spec

## Recent Sprint Context

- **Sprint 005**: 75 recipes, mutation system, 3-ingredient brewing — all working
- **Sprint 006**: Scoring, leaderboard, daily demand, cauldron upgrades, non-modal brew timer — all working
- **Sprint 007**: Potion displays, wild grove expansion, market announcements, zone polish — systems working but visuals are the problem

## Relevant Codebase Areas

### Gameplay-Critical Objects (MUST PRESERVE by name)
- `ForageNode_1` through `ForageNode_12` — Parts in WildGrove, referenced by ZoneService.lua forage pools
- `SpawnPoint` — Part in each zone, used by GameController.client.lua for teleportation
- `Cauldron`, `CauldronLiquid`, `BrewingSpoon`, `CauldronMedievalFantasy` — in YourShop, used by InteractionController
- `MarketStall` — in IngredientMarket, ProximityPrompt target
- `SellCounter` — in TradingPost, ProximityPrompt target
- `DailyDemandBoard` — in TradingPost, SurfaceGui target
- `EvolutionTiers` folder — in YourShop, visual tier progression
- `DustAnchor`, `FireflyAnchor`, `MysticAnchor`, `GoldAnchor` — particle emitter hosts

### Scripts (DO NOT TOUCH)
- `src/server/Services/ZoneService.lua` — forage logic, rare node spawning
- `src/client/InteractionController.client.lua` — all GUI interactions
- `src/client/GameController.client.lua` — zone teleportation
- `src/client/ForageNodeFeedback.client.lua` — node visual feedback

### Config (DO NOT TOUCH)
- All files in `src/shared/Config/` — recipes, ingredients, potions, tuning

## Constraints

- All ground surfaces at Y=0 (floor top surface) across all zones and paths
- All decorative furniture above Y=1 must have CanCollide=false (no climbing bookcases, shelves, etc.)
- No Terrain voxels in any playable area — clear all terrain in zone + path regions
- ForageNode parts must have ProximityPrompts (or be detectable by ForageNodeFeedback.client.lua which finds by name pattern)
- No flickering lights — all lights must have Shadows=false, constant brightness
- WildGrove area = 3x the area of any other zone
- Shop must follow Sunken Crypt SVG layout and color palette
- Paths between zones must be flat, unobstructed, walkable

## Success Criteria

1. Player can walk freely between all 4 zones without getting stuck
2. All 12 forage nodes are visible, interactable, and grant ingredients
3. Rare forage nodes spawn correctly in the expanded WildGrove
4. Shop layout matches the Sunken Crypt SVG (cauldron center, potion wall left, grimoire right, etc.)
5. No surface is climbable that shouldn't be
6. Lighting is consistent, bright enough to see clearly, with no flickering
7. All existing gameplay (brew, sell, buy, forage, score, upgrades) continues to work

## Verification Strategy

- **Walkability test**: Start play mode, teleport to each zone, walk around entire perimeter and to every interaction point
- **Forage test**: Click all 12 forage nodes, verify ingredients are received
- **Brew test**: Complete a full brew cycle (select ingredients, brew, claim result)
- **Sell test**: Sell a potion at TradingPost
- **Buy test**: Buy an ingredient at IngredientMarket
- **Climb test**: Attempt to jump on every bookcase, shelf, table — should slide off
- **Path test**: Walk between all zone pairs via paths
- **Visual inspection**: Screenshot each zone for aesthetic quality

## Uncertainty Assessment

- Correctness uncertainty: **Low** — gameplay code is untouched, this is purely visual
- Scope uncertainty: **Low** — clear requirements (nuke and rebuild 4 zones)
- Architecture uncertainty: **Low** — using MCP run_code to place parts, well-understood pattern
- Terrain clearing uncertainty: **Medium** — must ensure ALL terrain voxels are found and cleared

## Open Questions

1. What size should the non-grove zones be? (Current: 100x100 for shop, market, trading post)
2. Should the Ingredient Market and Trading Post get specific design themes, or just clean fantasy defaults?
3. How dense should the WildGrove foliage be? (Current attempt was 2000+ parts — might cause performance issues)
4. Should zone boundary walls be visible stone walls, or invisible barriers with natural-looking edges?
