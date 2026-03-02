# Sprint 008: Nuclear Visual Rebuild — Clean Zones, Flat World, Functional Foraging

## Overview

Every zone in the game needs to be torn down to bare gameplay objects and rebuilt with clean, polished fantasy aesthetics. The previous builds suffered from fundamental issues: Roblox Terrain voxels blocking player movement, inconsistent ground levels, climbable furniture, blown-out or pitch-black lighting, and an overall lack of design coherence.

This sprint is a **visual-only rebuild**. All gameplay systems (brewing, selling, foraging, scoring, mutations, market, upgrades) are fully implemented in Lua scripts and will not be touched. We preserve every gameplay-critical object by name and rebuild the decorative world around them.

The key design rules: flat ground everywhere (Y=0), no climbable decorations, no flickering lights, WildGrove = 3x area of other zones, and the shop must follow the Sunken Crypt SVG specification. Each zone gets a distinct visual theme with natural-edge boundaries.

## Scope Anchors (Non-Negotiable)

1. Full visual nuke-and-rebuild of all 4 zones and connecting paths.
2. Uniform ground plane: floor top at Y=0 across zones and routes.
3. WildGrove area is 3x the area of any other single zone (175x175 vs 100x100).
4. YourShop layout adheres to `/Users/karim.fanous/Downloads/1_sunken_crypt.svg`.
5. No climbable decorative furniture (`CanCollide=false` for non-walkable decor above Y=1).
6. No Terrain voxels in any playable zone/path footprint.
7. Foraging works fully: 12 nodes visible, each with a `ProximityPrompt`, granting ingredients.
8. No flickering lights; stable brightness and `Shadows=false` for all decorative lights.
9. Preserve gameplay-critical object names expected by existing scripts.
10. No script/config changes to gameplay logic.

## Use Cases

1. **New player enters**: Spawns in YourShop, sees a coherent dark crypt with clear cauldron at center. Can immediately walk to any zone via flat paths.
2. **Forager explores**: Enters WildGrove (175x175 enchanted forest), finds 12 forage nodes spread across themed sub-areas, clicks them for ingredients.
3. **Brewer in shop**: Interacts with cauldron (center), sees potion collection on wall shelves (left), grimoire lectern area (right, thematic only — recipe book is HUD-driven). Cannot climb any furniture.
4. **Seller at trading post**: Walks to SellCounter, sells potions, checks DailyDemandBoard. Warm wooden merchant hall.
5. **Buyer at market**: Browses MarketStall, buys ingredients. Colorful outdoor bazaar with canopies.

## Architecture

### World Invariants

```
Ground Plane:   All floor top surfaces at Y=0
Collision Rule: Walkable surfaces: CanCollide=true. Decor above Y=1: CanCollide=false
Lighting Rule:  All decorative lights: Shadows=false, constant brightness
Terrain Rule:   No Terrain voxels inside zone/path bounds (50-stud buffer)
```

### Zone Layout (Top-Down)

```
                    [IngredientMarket 100x100]
                    Center: (0, 0, -130)
                           |
                     Path (14 wide)
                           |
    [WildGrove 175x175] --Path-- [YourShop 100x100] --Path-- [TradingPost 100x100]
    Center: (-140, 0, 0)        Center: (0, 0, 0)           Center: (130, 0, 0)
```

### Zone Themes & Boundaries

| Zone | Theme | Boundary Style |
|------|-------|----------------|
| YourShop | Sunken Crypt (dark stone, green glow, gothic) | Stone walls with archway entrances |
| IngredientMarket | Outdoor Mystic Bazaar (colorful canopies, herbs) | Dense hedge rows + potted herb walls |
| TradingPost | Warm Merchant Hall (timber, golden light, fireplace) | Wooden fence + vine-covered trellis |
| WildGrove | Enchanted Forest (bioluminescent, mossy, magical) | Dense tree/rock formations at edges |

### Hard-Contract Preserve List

These objects MUST exist by exact name after rebuild (scripts reference them):

| Object | Zone | Referenced By |
|--------|------|---------------|
| `SpawnPoint` | All 4 zones | `GameController.client.lua` teleport |
| `Cauldron` | YourShop | `InteractionController.client.lua` ProximityPrompt |
| `CauldronLiquid` | YourShop | VFX controller |
| `BrewingSpoon` | YourShop | VFX controller |
| `CauldronMedievalFantasy` | YourShop | Visual model |
| `EvolutionTiers` | YourShop | Tier progression visuals |
| `MarketStall` | IngredientMarket | `InteractionController.client.lua` ProximityPrompt |
| `SellCounter` | TradingPost | `InteractionController.client.lua` ProximityPrompt |
| `DailyDemandBoard` | TradingPost | SurfaceGui for demand display |
| `ForageNode_1` ... `ForageNode_12` | WildGrove | `ZoneService.lua` forage pools + `ForageNodeFeedback.client.lua` |
| `DustAnchor` | YourShop | Particle emitter host |
| `FireflyAnchor` | WildGrove | Particle emitter host |
| `MysticAnchor` | IngredientMarket | Particle emitter host |
| `GoldAnchor` | TradingPost | Particle emitter host |

**Critical**: Every `ForageNode_*` part MUST have a `ProximityPrompt` child. Name alone is insufficient — `InteractionController.client.lua` fires `Remotes.ForageNode` only on ProximityPrompt trigger.

### Collision Policy Matrix

| Prop Category | CanCollide | Examples |
|---------------|-----------|----------|
| Floor/ground | true | Zone floors, path segments |
| Boundary (natural edge) | true | Hedge rows, fence sections, rock walls |
| Waist-high interactable (Y < 3) | true | Cauldron platform, chest, sell counter, barrels, boulders |
| Shelf/bookcase (any height) | false | Potion shelves, bookcase, tome racks |
| Ceiling/hanging decor | false | Stalactites, chains, vines, canopies |
| Foliage | false | Ferns, bushes, flowers, grass patches, tree canopies |
| Decorative floor detail | false | Rune circles, puddles, moss, scattered items |
| Lighting fixtures | false | Candle clusters, lantern poles, crystal orbs |
| Furniture above Y=1 | false | Tables, lecterns (above base), wall-mounted items |

## Implementation Plan

### Phase 1: Nuclear Cleanup + Terrain Clearance (~15%)

**Tasks:**
- [ ] For each zone: delete ALL children EXCEPT hard-contract objects (see preserve list)
- [ ] Clear ALL Roblox Terrain voxels in region X=[-250, 200], Y=[-20, 30], Z=[-200, 200]
- [ ] Reset global Lighting to balanced defaults
- [ ] Verify each zone has only preserved objects remaining
- [ ] Run name-contract audit: confirm all preserved objects exist with correct names

### Phase 2: Floors, Paths, Boundaries (~15%)

**Tasks:**
- [ ] Create/resize Floor parts: `Position.Y=-1, Size.Y=2` (top at Y=0)
  - YourShop: 100x100, Cobblestone, dark (#1e1c19)
  - IngredientMarket: 100x100, Cobblestone, warm (#6b5a3e)
  - TradingPost: 100x100, WoodPlanks, brown (#8b6b3c)
  - WildGrove: 175x175, Grass, natural green (#2d4123)
- [ ] Build 3 connecting paths (14-wide, flat at Y=-1, Size.Y=2):
  - ShopToMarket: Z corridor between shop and market
  - ShopToTrade: X corridor between shop and trading post
  - ShopToGrove: X corridor between shop and grove
- [ ] Build natural-edge boundaries per zone theme:
  - YourShop: Slate stone walls with 16-stud archway gaps
  - IngredientMarket: Dense hedge parts + potted herb walls
  - TradingPost: Wooden fence + vine trellis sections
  - WildGrove: Dense tree trunk + boulder formations at edges
- [ ] Reposition SpawnPoints: Y=0.5 at zone center or near entrance

### Phase 3: YourShop — The Sunken Crypt (~25%)

**SVG Layout:**
```
    [D Dripping Ceiling]  [E Entrance Arch]
    [                                       ]
    [P Potion Wall]            [B Grimoire  ]
    [  (left wall)]            [   Lectern  ]
    [                                       ]
    [         [C Grand Cauldron]            ]
    [                                       ]
    [   [I Ingredient]    [L Candles] [S Spider]
    [      Chest   ]                  [  Nest  ]
```

**Color Palette:** Deep Void #0a1628, Crypt Moss #1a3a2a, Potion Green #2d6b4f, Aged Wood #8b5e3c, Candlelight #d4a843, Blood Stone #5c1a1a

**Tasks:**
- [ ] **Grand Cauldron (C, center Z=-8)**: Stone platform (CanCollide=true, Y<1.5). Reposition CauldronMedievalFantasy, Cauldron, CauldronLiquid, BrewingSpoon. 4 chains from ceiling (CanCollide=false). Green neon rune circle (CanCollide=false).
- [ ] **Potion Wall (P, left X=-44)**: 4 stone shelf slabs against west wall (CanCollide=false). 40 colored glass vials (CanCollide=false). SurfaceLights on select vials.
- [ ] **Grimoire Lectern (B, upper right X=35 Z=-30)**: Stone lectern base (CanCollide=true, max 4 studs). Book on top (CanCollide=false). Bookcase against east wall: all parts CanCollide=false.
- [ ] **Ingredient Chest (I, lower left X=-25 Z=10)**: Wood chest (CanCollide=true, max 3 studs). Iron bands, padlock. Glow part + scattered bits (CanCollide=false).
- [ ] **Spider Nest (S, lower right X=35 Z=15)**: Web strands (CanCollide=false, Transparency 0.6-0.8). Egg sacs (CanCollide=false).
- [ ] **Candle Clusters (L, 9 positions)**: Skull bases at floor (CanCollide=true, small). Candles + flames (CanCollide=false). PointLights: warm orange #d4a843, brightness 1.5, range 20, Shadows=false.
- [ ] **Dripping Ceiling (D)**: Stalactites (CanCollide=false). 6 invisible anchors with ParticleEmitter water drips.
- [ ] **Entrance (E, south Z=50)**: NO stairs (flat ground). Decorative arch pillars + torch PointLights.
- [ ] **Hanging Chains**: 6 chains from ceiling (CanCollide=false).
- [ ] **Floor Details**: Neon rune circles, water puddles, moss patches, blood stone accents (all CanCollide=false).
- [ ] **Materials**: Slate walls, Cobblestone floor.

### Phase 4: IngredientMarket — Outdoor Mystic Bazaar (~12%)

**Theme**: Colorful outdoor market with fabric canopies, hanging herbs, warm purple/blue magical lighting.

**Tasks:**
- [ ] Reposition MarketStall to center area with ProximityPrompt verified
- [ ] 4 wooden stall frames with colored fabric canopy parts (CanCollide=false on canopies)
- [ ] 6 lantern posts with warm PointLights (Shadows=false)
- [ ] Crate stacks + barrel groups at corners (CanCollide=true, low)
- [ ] Central fountain/well as landmark (CanCollide=true base only)
- [ ] Hanging herb + banner decorations (CanCollide=false)
- [ ] BuySign SurfaceGui over main stall
- [ ] EntranceSign at south facing shop path
- [ ] Reposition MysticAnchor for particle coverage

### Phase 5: TradingPost — Warm Merchant Hall (~12%)

**Theme**: Timber-frame hall with wood plank floor, warm fireplace, golden lighting.

**Tasks:**
- [ ] Reposition SellCounter to center area with ProximityPrompt verified
- [ ] DailyDemandBoard with frame (rebuild or reuse, verify SurfaceGui)
- [ ] Wooden trading desks/benches (CanCollide=true, low)
- [ ] Gold pile decorations near SellCounter (CanCollide=false)
- [ ] Fireplace model (CanCollide=true base, CanCollide=false fire)
- [ ] Tapestry/rug parts (CanCollide=false)
- [ ] Crate decorations at edges (CanCollide=true, low)
- [ ] Warm golden lanterns (Shadows=false)
- [ ] EntranceSign facing shop path
- [ ] Reposition GoldAnchor for particle coverage

### Phase 6: WildGrove — Enchanted Forest (175x175) (~15%)

**Tasks:**
- [ ] Reposition ForageNode_1 through ForageNode_12:
  - Spread across 4 quadrants (3 per quadrant)
  - Each node: visible part + **ProximityPrompt child** (MANDATORY)
  - Distinctive visual per node (size, color, shape variety)
- [ ] 20 large trees (trunk CanCollide=true, canopy CanCollide=false)
- [ ] 6 glowing bioluminescent trees (Neon trunks, PointLights)
- [ ] 2 enchanted ponds (glass cylinders, glow, lily pads) (CanCollide=false water)
- [ ] 1 stream (5 segments, stepping stones) (CanCollide=false water, CanCollide=true stones)
- [ ] 1 ancient stone ruin (pillar CanCollide=true, lintel CanCollide=false)
- [ ] 3 fairy rings (mushroom circles, CanCollide=false)
- [ ] 8 giant mushrooms (stem CanCollide=true, cap CanCollide=false)
- [ ] 10 crystal formations (Neon, PointLights, CanCollide=false)
- [ ] Undergrowth: 15 ferns, 10 bushes, 5 flower meadows (all CanCollide=false)
- [ ] 3 winding dirt trail paths (Ground material)
- [ ] 6 mossy boulders (CanCollide=true)
- [ ] Fog + firefly particle emitters (reposition FireflyAnchor)
- [ ] 8 fairy orb lights spread across area
- [ ] **Verify rare spawn coordinates**: ZoneService.lua hardcodes spawn X/Z ranges — confirm they land within 175x175 grove bounds after rebuild

### Phase 7: Lighting + Collision Hardening (~6%)

**Tasks:**
- [ ] Set global Lighting:
  - Ambient: RGB(70, 65, 75), OutdoorAmbient: RGB(90, 85, 100)
  - Brightness: 1.2, ClockTime: 14
  - FogEnd: 600, FogStart: 300
  - No BloomEffect, no ColorCorrectionEffect
  - Atmosphere: density 0.2, haze 3
- [ ] Audit EVERY PointLight/SurfaceLight/SpotLight in workspace: set Shadows=false
- [ ] Audit every part above Y=1 against collision policy matrix: enforce CanCollide rules
- [ ] Verify no Terrain voxels remain (re-scan playable region)

### Phase 8: Verification + Regression Gate (~5%)

**Tasks:**
- [ ] **Name-contract audit**: Script to verify all hard-contract objects exist by name in correct zone parent
- [ ] **ProximityPrompt audit**: Verify prompts on Cauldron, MarketStall, SellCounter, ForageNode_1..12
- [ ] **Walkability test**: Teleport to each zone, walk full perimeter, walk between all zone pairs
- [ ] **Forage test**: Click all 12 nodes, verify ingredients received
- [ ] **Rare spawn test**: Confirm rare node spawn location is within WildGrove bounds
- [ ] **Brew test**: Complete a full brew cycle (select, brew, wait, claim)
- [ ] **Sell test**: Sell a potion at SellCounter
- [ ] **Buy test**: Buy an ingredient at MarketStall
- [ ] **Anti-climb test**: Attempt to jump on every shelf, bookcase, table, mushroom cap — should fail
- [ ] **Visual inspection**: Screenshot each zone, verify aesthetic coherence

## Files Summary

| File / Area | Action | Purpose |
|-------------|--------|---------|
| Workspace Zones (via MCP) | Rebuild | All visual world construction |
| Workspace Terrain | Clear | Remove all blocking terrain voxels |
| Lighting service | Configure | Balanced fantasy lighting defaults |
| No Lua scripts | — | Scripts are NOT modified |

## Definition of Done

- [ ] All 4 zones visually rebuilt from clean baseline (no legacy clutter)
- [ ] Ground plane flat at Y=0 across all zones and paths
- [ ] WildGrove is 175x175 (3x area of 100x100 zones)
- [ ] YourShop matches Sunken Crypt SVG layout
- [ ] No Terrain voxels in playable areas
- [ ] No climbable decorative surfaces (collision policy enforced)
- [ ] All 12 ForageNodes visible with ProximityPrompts, granting ingredients
- [ ] Rare forage node spawns within WildGrove bounds
- [ ] Cauldron brew/claim works end-to-end
- [ ] Market buy works
- [ ] TradingPost sell works
- [ ] All lights: Shadows=false, no flicker
- [ ] Name-contract audit passes (all required objects present)
- [ ] Each zone has distinct visual theme with natural-edge boundaries

## Risks & Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Name-contract break during teardown | Medium | High | Keep-list staging + name audit before test |
| Rare spawn coords outside new WildGrove bounds | Medium | High | Verify ZoneService.lua spawn ranges vs new layout |
| Terrain remnants missed | Medium | High | Clear with 50-stud buffer, re-scan after build |
| Collision policy inconsistency | Medium | Medium | Prop-category matrix + anti-climb test pass |
| ZoneService forage pool code fragility | Low | High | Runtime forage test for all 12 nodes; escalate as hotfix if broken |
| Part count causes lag in WildGrove | Low | Medium | Budget ~600 parts max, use CanCollide=false on decorations |
| Lighting too dim/bright | Low | Low | Moderate global + test each zone |

## Security Considerations

- No gameplay code modified — no new attack surfaces
- All interactions remain server-authoritative
- Preserve prompt/name contracts to avoid accidental bypasses
- No hidden collision pockets for out-of-bounds exploits

## Dependencies

- Sprint 005-007 gameplay systems (all complete, untouched)
- Sunken Crypt SVG spec file
