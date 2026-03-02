# Sprint 008: Nuclear Visual Rebuild — Clean Zones, Flat World, Functional Foraging

## Overview

Every zone in the game needs to be torn down to bare gameplay objects and rebuilt with clean, polished fantasy aesthetics. The previous builds suffered from fundamental issues: Roblox Terrain voxels blocking player movement, inconsistent ground levels, climbable furniture, blown-out lighting, and an overall lack of design coherence.

This sprint is a **visual-only rebuild**. All gameplay systems (brewing, selling, foraging, scoring, mutations, market, upgrades) are fully implemented and will not be touched. We will preserve every gameplay-critical object by name and rebuild the decorative world around them.

The key design rules: flat ground everywhere (Y=0), no climbable decorations, no flickering lights, WildGrove = 3x area of other zones, and the shop must follow the Sunken Crypt SVG specification.

## Use Cases

1. **New player enters**: Spawns in YourShop, sees a coherent dark crypt with clear cauldron at center. Can immediately walk to any zone via flat paths.
2. **Forager explores**: Enters WildGrove (massive 300x300 area), finds 12 named forage nodes spread across distinct themed sub-areas, clicks them for ingredients.
3. **Brewer in shop**: Interacts with cauldron (center), checks recipe book at grimoire lectern (right), sees potion collection on wall shelves (left). Cannot accidentally climb any furniture.
4. **Seller at trading post**: Walks to SellCounter, sells potions, checks DailyDemandBoard. Clean warm aesthetic.
5. **Buyer at market**: Browses MarketStall, buys ingredients. Magical marketplace feel.

## Architecture

### Zone Layout (Top-Down)

```
                    [IngredientMarket 100x100]
                    Center: (0, 0, -130)
                           |
                     Path (12 wide)
                           |
    [WildGrove 300x300] --Path-- [YourShop 100x100] --Path-- [TradingPost 100x100]
    Center: (-200, 0, 0)         Center: (0, 0, 0)          Center: (130, 0, 0)
```

### Size Rules
- YourShop: 100x100 studs
- IngredientMarket: 100x100 studs
- TradingPost: 100x100 studs
- WildGrove: **300x300 studs** (9x area = 3x each dimension, well over 3x area)
- All paths: 14 studs wide, flat at Y=0

### Ground Rule
- Every floor part: `Position.Y = -1`, `Size.Y = 2` → top surface at Y=0
- Every path part: same formula
- Terrain: cleared in ALL playable regions (zones + paths + 20-stud buffer)

### Anti-Climb Rule
- Any decorative part with `Position.Y > 1.5` that isn't a wall/boundary: `CanCollide = false`
- Floor-level props (barrels, chests, tables): CanCollide = true but max height 3 studs
- Wall shelves, bookcases, hanging items: CanCollide = false

### Lighting Rule
- Global: Ambient 70, OutdoorAmbient 90, Brightness 1.2, ClockTime 14
- No BloomEffect
- All PointLights: `Shadows = false`, brightness 1.0-2.0, range 15-30
- No particle-based flickering

## Implementation Plan

### Phase 1: Nuclear Cleanup (~10%)

**Goal**: Strip every zone to bare gameplay objects, clear all terrain.

**Tasks:**
- [ ] For each zone (YourShop, IngredientMarket, TradingPost, WildGrove):
  - Delete all children EXCEPT gameplay-critical objects (see preserve list)
  - Keep: SpawnPoint, Floor, ForageNodes, Cauldron parts, MarketStall, SellCounter, DailyDemandBoard, EvolutionTiers, particle anchors
- [ ] Clear ALL Roblox Terrain voxels in region X=[-650, 200], Y=[-20, 30], Z=[-200, 200]
- [ ] Reset global Lighting to balanced fantasy defaults
- [ ] Verify each zone has only preserved objects remaining

**Preserve List (by zone):**

| Zone | Objects to Keep |
|------|----------------|
| YourShop | CauldronMedievalFantasy, Cauldron, CauldronLiquid, BrewingSpoon, SpawnPoint, EvolutionTiers, DustAnchor |
| IngredientMarket | MarketStall, SpawnPoint, MysticAnchor, MarketStall_Left, MarketStall_Right, MarketStall_Back |
| TradingPost | SellCounter, SpawnPoint, GoldAnchor, DailyDemandBoard, BoardFrame_* |
| WildGrove | ForageNode_1 through ForageNode_12, SpawnPoint, FireflyAnchor |

### Phase 2: World Shell — Floors, Walls, Paths (~15%)

**Goal**: Establish the physical world geometry.

**Tasks:**
- [ ] Create/resize Floor parts for all 4 zones (Y=-1, SizeY=2, top at Y=0)
- [ ] YourShop floor: 100x100, Cobblestone, dark color per SVG
- [ ] IngredientMarket floor: 100x100, Cobblestone, warm tone
- [ ] TradingPost floor: 100x100, WoodPlanks, warm brown
- [ ] WildGrove floor: 300x300, Grass, natural green
- [ ] Build natural-edge boundaries for each zone:
  - YourShop: Stone walls with archway gaps (crypt theme demands hard walls)
  - IngredientMarket: Dense hedge rows + large potted herb walls (outdoor bazaar)
  - TradingPost: Wooden fence + vine-covered trellis (merchant hall)
  - WildGrove: Dense tree/rock formations at edges (natural forest boundary)
  - All boundaries: CanCollide=true (they ARE boundaries)
  - Each zone has 16-stud natural openings at entrances
- [ ] Build 3 connecting paths:
  - ShopToMarket: X=[-6,6], Z=[-80,-50], Y=-1
  - ShopToTrade: X=[50,80], Z=[-7,7], Y=-1
  - ShopToGrove: X=[-50,-10], Z=[-7,7], Y=-1 (extends to grove)
- [ ] Verify: walk from any zone to any other zone without obstruction

### Phase 3: YourShop — The Sunken Crypt (~25%)

**Goal**: Build the shop exactly per SVG spec.

**Layout (from SVG):**
```
    [Dripping Ceiling D]  [Stone Stairway E]
    [                                        ]
    [P                                     B ]
    [o   Hanging Chains                    o ]
    [t                                     o ]
    [i        [C Grand Cauldron]           k ]
    [o                                     s ]
    [n   [I Ingredient Chest]    [L]   [S] . ]
    [W                           Can   Spi . ]
    [a                           dle   der . ]
    [l                                       ]
    [l                                       ]
```

**Tasks:**
- [ ] **Grand Cauldron (center, Z=-8)**: Stone platform (CanCollide=true, low), reposition existing CauldronMedievalFantasy/Cauldron/CauldronLiquid. Add 4 chains from ceiling (CanCollide=false). Green neon rune circle under platform (CanCollide=false).
- [ ] **Potion Wall (left, X=-44)**: 4 stone shelf slabs against west wall. Shelf parts CanCollide=false. 40 colored glass vials on shelves (CanCollide=false). SurfaceLights on select vials for glow. Cobweb parts connecting shelves (CanCollide=false, Transparency=0.7).
- [ ] **Grimoire Lectern (upper right, X=35, Z=-30)**: Stone lectern base (CanCollide=true, height 4). Book on top (CanCollide=false). Bookcase along east wall — back panel + 5 shelf slabs + tomes. ALL bookcase parts above Y=1.5: CanCollide=false.
- [ ] **Ingredient Chest (lower left, X=-25, Z=10)**: Wood chest body (CanCollide=true, max 3 studs tall). Iron bands, padlock. Glow part (CanCollide=false). Scattered ingredient bits (CanCollide=false).
- [ ] **Spider Nest (lower right, X=35, Z=15)**: Web strands and sheets (CanCollide=false, Transparency 0.6-0.8). Egg sacs (CanCollide=false).
- [ ] **Candle Clusters (9 positions)**: Skull bases at floor level (CanCollide=true, small). Candles + flames (CanCollide=false). PointLights: warm orange, brightness 1.5, range 20, Shadows=false.
- [ ] **Dripping Ceiling**: Stalactites (CanCollide=false). 6 invisible anchor parts with ParticleEmitter for water drips.
- [ ] **Stone Stairway / Entrance (south, Z=50)**: NO actual stairs (ground is flat). Just decorative arch pillars at entrance. Torch brackets with PointLights.
- [ ] **Hanging Chains**: 6 chains from ceiling in various spots (CanCollide=false).
- [ ] **Floor Details**: 4 neon rune circles (CanCollide=false), water puddles, moss patches on walls, blood stone accents.
- [ ] **Color Palette**: Deep Void #0a1628, Crypt Moss #1a3a2a, Potion Green #2d6b4f, Aged Wood #8b5e3c, Candlelight #d4a843, Blood Stone #5c1a1a
- [ ] **Materials**: Slate walls, Cobblestone floor

### Phase 4: IngredientMarket — Outdoor Mystic Bazaar (~15%)

**Goal**: Colorful outdoor marketplace with fabric canopies and magical wares. Distinct from the crypt — vibrant and bustling.

**Theme**: Open-air bazaar with colored fabric canopies (purple/gold/teal), hanging herbs, glowing lanterns, cobblestone ground. Natural edge boundaries: dense hedges and potted herb walls.

**Tasks:**
- [ ] Reposition existing MarketStall meshes to center area
- [ ] Build 4 wooden market stall frames with colored fabric canopy parts (CanCollide=false on canopies)
- [ ] Natural boundary edges: dense hedge rows + large potted herb plants around perimeter
- [ ] Entrance archways: wooden beam + hanging banner (natural gap, no stone walls)
- [ ] Lantern posts (6, evenly spaced) with warm PointLights
- [ ] Crate stacks and barrel groups at corners (CanCollide=true, low)
- [ ] Herb pot decorations (CanCollide=false above Y=1.5)
- [ ] Hanging banner/tapestry parts (CanCollide=false)
- [ ] Central fountain or well as landmark
- [ ] Warm purple/blue magical lighting theme
- [ ] "BuySign" SurfaceGui over main stall
- [ ] EntranceSign at south (facing shop path)

### Phase 5: TradingPost — Warm Merchant's Hall (~15%)

**Goal**: Warm wooden merchant hall with fireplace. Cozy interior feel, distinct from the cold crypt. Golden lighting.

**Theme**: Timber-frame hall with wood plank floor, warm fireplace, trading desks, gold-themed decor. Natural edge boundaries: wooden fence + vine-covered trellis.

**Tasks:**
- [ ] Reposition SellCounter to center
- [ ] Natural boundary edges: wooden fence + climbing vine parts around perimeter
- [ ] Entrance archways: timber beam archway (natural, no stone walls)
- [ ] Build DailyDemandBoard with frame (reuse existing or rebuild)
- [ ] Wooden trading desks/benches (CanCollide=true, low)
- [ ] Gold pile decorations near SellCounter (CanCollide=false)
- [ ] Fireplace model (warm centerpiece, CanCollide=true base only)
- [ ] Tapestry/rug parts for warmth (CanCollide=false)
- [ ] Crate decorations at edges (CanCollide=true, low)
- [ ] Warm golden lantern lighting
- [ ] EntranceSign facing shop path

### Phase 6: WildGrove — Enchanted Forest (300x300) (~20%)

**Goal**: Massive explorable forest with 12 working forage nodes.

**Tasks:**
- [ ] Reposition ForageNode_1 through ForageNode_12 spread across 300x300 area
  - Each node: visible, has ProximityPrompt or is named correctly for ForageNodeFeedback to find
  - Distinctive visual per node (color, shape, size)
  - Spread into 4 quadrants: NW, NE, SW, SE (3 nodes each)
- [ ] 25 large trees (trunk + canopy spheres, canopy CanCollide=false)
- [ ] 8 glowing/bioluminescent trees (Neon trunks, PointLights)
- [ ] 3 enchanted ponds (glass cylinders, PointLight glow, lily pads)
- [ ] 1 stream (5 connected segments, stepping stones)
- [ ] 2 ancient stone ruins (pillar + lintel + fallen blocks, CanCollide=true for pillars only)
- [ ] 4 fairy rings (mushroom circles)
- [ ] 10 giant mushrooms (stem CanCollide=true, cap CanCollide=false)
- [ ] 15 crystal formations (Neon, PointLights, CanCollide=false)
- [ ] 20 ferns + 15 bushes + 8 flower meadows (CanCollide=false)
- [ ] 4 winding dirt trail paths (Ground material parts)
- [ ] 8 mossy boulders (CanCollide=true, organic shapes)
- [ ] Fog particle emitter covering the area
- [ ] Firefly particle emitter
- [ ] 10 fairy orb lights spread across area

### Phase 7: Final Polish & Verification (~10%)

**Tasks:**
- [ ] Set global Lighting:
  - Ambient: RGB(70, 65, 75)
  - OutdoorAmbient: RGB(90, 85, 100)
  - Brightness: 1.2
  - ClockTime: 14
  - FogEnd: 600, FogStart: 300
  - No BloomEffect, no ColorCorrectionEffect
  - Atmosphere: density 0.2, haze 3
- [ ] Audit EVERY PointLight/SurfaceLight in workspace: Shadows=false
- [ ] Audit EVERY part above Y=1.5 that isn't a boundary wall: CanCollide=false
- [ ] Verify Terrain is cleared in ALL playable regions
- [ ] Playtest walkability: teleport to each zone, walk full perimeter
- [ ] Playtest foraging: click all 12 nodes
- [ ] Playtest brewing: complete a brew cycle
- [ ] Playtest selling: sell a potion
- [ ] Playtest buying: buy an ingredient

## Files Summary

| File | Action | Purpose |
|------|--------|---------|
| Workspace (via MCP) | Modify | All visual rebuilding done via run_code |
| Lighting service | Modify | Reset to balanced fantasy defaults |
| Terrain | Modify | Clear all voxels in playable areas |
| No Lua scripts | — | Scripts are NOT modified in this sprint |

## Definition of Done

- [ ] All 4 zones have clean, coherent visual designs
- [ ] Player can walk between all zones without getting stuck on anything
- [ ] All 12 ForageNodes are present, visible, and grant ingredients when clicked
- [ ] Rare forage nodes spawn in WildGrove (server-side, existing code)
- [ ] Cauldron brewing works end-to-end
- [ ] Market buying works
- [ ] Trading post selling works
- [ ] Recipe book is accessible
- [ ] No decorative surface is climbable (CanCollide=false above Y=1.5)
- [ ] No lights flicker (all Shadows=false)
- [ ] Ground is flat Y=0 everywhere
- [ ] WildGrove is 300x300 (3x dimension = 9x area vs 100x100 zones)
- [ ] YourShop follows Sunken Crypt SVG layout
- [ ] No Terrain voxels in any playable area

## Risks & Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Terrain voxels missed in some region | Medium | High (player stuck) | Clear terrain in massive region with 50-stud buffer beyond zone bounds |
| Part count causes performance issues | Low | Medium | Keep WildGrove under 500 parts, use CanCollide=false on decorations |
| ForageNode names don't match server code | Low | High (foraging breaks) | Verify names match ZoneService.lua exactly: ForageNode_1 through ForageNode_12 |
| ProximityPrompts missing on interaction objects | Low | High | Verify prompts exist on Cauldron, MarketStall, SellCounter, ForageNodes after rebuild |
| Lighting too dark or too bright | Medium | Low | Use moderate values, test in play mode, iterate |

## Security Considerations

- No gameplay code is modified — no new attack surfaces
- All interactions remain server-authoritative
- Visual-only changes carry no security risk

## Dependencies

- Sprint 005-007 gameplay systems (all complete, untouched)
- Sunken Crypt SVG spec file (read once, applied in Phase 3)

## Open Questions

1. Should IngredientMarket and TradingPost have distinct design themes beyond "clean fantasy"?
2. Part budget for WildGrove — 300-500 parts should be fine for performance?
3. Should boundary walls be visible stone or invisible with natural edges?
