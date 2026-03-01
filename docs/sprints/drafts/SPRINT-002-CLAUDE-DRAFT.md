# Sprint 002: World Vibrancy — Dense 3D Props, Glowing Effects, Rich Environments

## Overview

Sprint 001 delivered a functional vertical slice — the core loop works, persistence is solid, all four zones exist. But the world looks like a prototype: flat colored floors, a handful of scattered models, and vast empty space between functional elements. Players comparing this to Grow a Garden (21 billion visits) would leave within seconds.

Sprint 002 transforms the world from "functional graybox" to "vibrant, lived-in village." Every zone gets dense 3D props, themed decorations, stone wall + hedge boundaries (fantasy alchemy theme), readable signage, glow/particle effects on key objects, and basic ambient audio. No gameplay systems change — this is purely visual density, environmental storytelling, and atmosphere. The goal: a screenshot from any angle looks rich enough to post on TikTok.

The density target is **cozy cluttered** — every surface has something on it, corners are filled, no empty flat floor visible from player height. This matches the Grow a Garden reference images directly. Zone boundaries use stone walls with vine overgrowth and magical hedges rather than wooden fences, giving our alchemy village its own identity. Basic ambient audio (bubbling cauldron, market chatter, forest sounds) completes the atmosphere.

## Use Cases

1. **First impression quality**: A new player spawns in YourShop and sees a cozy, cluttered alchemy lab — shelves of potion bottles, hanging herbs, candles, a glowing cauldron with bubbling particles. They immediately feel "this is a real place."
2. **Zone identity at a glance**: Walking into each zone feels distinct — warm wood and potions (Shop), bustling market stalls with hanging banners (Market), golden trading hall with coin displays (Trading Post), mystical glowing forest (Wild Grove).
3. **Wayfinding through environment**: Wooden signs at zone entrances and key stations tell players where they are and what to do, like Grow a Garden's "Grow All 375R$" and "Empty Garden" signs.
4. **Visual reward moments**: The cauldron glows and bubbles, rare ingredient displays sparkle, forage nodes pulse with magical energy — creating the "golden carrot" effect from the reference images.
5. **Shareable aesthetics**: Any screenshot or clip looks rich and colorful enough to share — no visible flat empty floor, every angle has visual depth.

## Architecture

This sprint makes no changes to game architecture. All work is in Workspace via:

```
Approach:
  1. Insert marketplace models (via MCP insert_model tool)
  2. Position/scale/configure models (via MCP run_code tool)
  3. Add lighting and particle effects (via run_code: PointLight, ParticleEmitter, SpotLight)
  4. Create signage (via run_code: Part + SurfaceGui + TextLabel)
  5. Build fencing/boundaries (via insert_model + positioning)

No changes to:
  - ServerScriptService (no server code changes)
  - ReplicatedStorage (no config/remote changes)
  - StarterGui (no UI changes)
  - StarterPlayer (no client script changes)
```

### Zone Treatment Pattern

Each zone follows this decoration pattern:

```
Zone Floor (existing)
  ├── Functional Elements (existing: cauldron, stall, counter, nodes)
  ├── Boundary Fencing (new: stone walls with vine overgrowth and magical hedges around perimeter)
  ├── Entrance Signage (new: wooden sign with zone name)
  ├── Station Signs (new: smaller signs at each interaction point)
  ├── Thematic Props (new: 8-15 marketplace models per zone)
  ├── Floor Coverage (new: rugs, crates, barrels to break up flat floor)
  ├── Vertical Interest (new: shelves, hanging items, tall props)
  ├── Ambient Lighting (new: lanterns, candles, point lights)
  └── Particle Effects (new: bubbles, sparkles, dust motes on key objects)
```

## Implementation Plan

### Phase 0: Cleanup & Fix Broken State (~5%)

Before adding new content, fix existing issues that would compound.

**Tasks:**
- [ ] Fix IngredientMarket bounding box (model has extreme coordinate values — reposition to proper location near 0, -0.5, -130)
- [ ] Relocate or delete loose models in workspace root (WoodenFence, PotionBottles, LowPolyTrees, Lantern, Barrel, Mushroom, Fountain, HerbGarden at ~73,57) — either integrate into zones or remove
- [ ] Verify all zone SpawnPoints are at correct heights and positions
- [ ] Ensure all existing ProximityPrompts still trigger correctly

### Phase 1: YourShop — Cozy Alchemy Lab (~25%)

Transform the player's home zone from bare room to cluttered, warm alchemy workshop.

**Prop Targets:**
| Category | Items | Count |
|----------|-------|-------|
| Shelving | Wooden shelves with potion bottles, ingredient jars | 3-4 shelf units |
| Potion displays | Glowing potion bottles on tables/shelves | 5-8 bottles |
| Herb storage | Hanging dried herbs, herb racks, plant pots | 3-4 arrangements |
| Furniture | Wooden tables, stools, workbench | 2-3 pieces |
| Lighting | Candles, lanterns, fireplace/brazier | 4-6 light sources |
| Floor coverage | Rugs, scattered books, small crates | 3-5 items |
| Cauldron upgrade | Bubbling particle effect, glow, smoke | 1 (enhance existing) |

**Tasks:**
- [ ] Insert potion bottle shelf models and position along walls
- [ ] Insert hanging herb/plant models near ceiling or on racks
- [ ] Insert wooden table + workbench models
- [ ] Insert candle and lantern models, add PointLights (warm yellow, range 12-16)
- [ ] Add ParticleEmitter to cauldron: green/purple bubbles rising, subtle glow
- [ ] Add PointLight to cauldron (green tint, brightness 2, range 20)
- [ ] Insert small rug/carpet model for floor center
- [ ] Insert scattered book/scroll props on tables
- [ ] Add stone wall + vine hedge perimeter around YourShop zone (fantasy alchemy aesthetic)
- [ ] Create entrance sign: "Your Potion Shop" on wooden sign (Part + SurfaceGui)
- [ ] Create cauldron station sign: "Cauldron" with potion icon
- [ ] Add dust mote ParticleEmitter to DustAnchor (warm golden particles, slow drift)
- [ ] Fill corners with crates, barrels, or small prop clusters to eliminate empty space

### Phase 2: IngredientMarket — Bustling Bazaar (~25%)

Transform from single market stall to a rich, multi-stall marketplace.

**Prop Targets:**
| Category | Items | Count |
|----------|-------|-------|
| Market stalls | Additional stall models with awnings/canopies | 2-3 extra stalls |
| Hanging goods | Banners, lanterns, hanging herbs from stall roofs | 5-8 hanging items |
| Crates & barrels | Merchandise displays, storage crates | 4-6 clusters |
| Ground decoration | Cobblestone paths, hay bales, flower pots | 3-5 items |
| Signage | Price signs, stall labels, welcome banner | 3-4 signs |
| Lighting | Market lanterns on poles, string lights feel | 4-6 lanterns |
| Flora | Potted herbs, flower boxes on stalls | 3-4 plants |

**Tasks:**
- [ ] Fix IngredientMarket model positioning (move to proper world coordinates)
- [ ] Insert 2-3 additional market stall models for visual density
- [ ] Insert wooden crate and barrel clusters around stalls
- [ ] Insert hanging lantern models on stall posts, add PointLights (warm orange)
- [ ] Insert potted plant/herb models on and around stalls
- [ ] Insert banner/awning decorations on stalls
- [ ] Add stone wall + hedge perimeter around market zone
- [ ] Create entrance sign: "Ingredient Market" on large wooden sign
- [ ] Create merchant stall sign: "Buy Ingredients" near ProximityPrompt
- [ ] Insert hay bale or sack models as floor gap-fillers
- [ ] Add subtle ParticleEmitter on mystic anchor (floating sparkle dust)
- [ ] Position a small fountain or well as market center feature
- [ ] Fill walkway edges with flower pots and small prop clusters

### Phase 3: TradingPost — Golden Trading Hall (~20%)

The most bare zone — needs the biggest transformation.

**Prop Targets:**
| Category | Items | Count |
|----------|-------|-------|
| Counter upgrade | Enhanced sell counter with display shelves behind it | 1 enhanced station |
| Coin/treasure | Coin piles, treasure chests, gold displays | 3-4 gold-themed props |
| Furniture | Trading tables, benches, display cases | 3-4 pieces |
| Lighting | Golden-tinted lanterns, warm sconces | 4-5 light sources |
| Signage | "Trading Post" entrance, "Sell Potions" counter sign | 2-3 signs |
| Decoration | Tapestries/banners, potion display shelves | 3-4 decorative elements |
| Floor coverage | Rugs, scattered coins, wooden floor details | 2-3 items |

**Tasks:**
- [ ] Insert treasure chest and coin pile models near sell counter
- [ ] Insert trading table and bench models for social area
- [ ] Insert potion display shelf behind sell counter (visual reward for selling)
- [ ] Insert golden-tinted lantern models, add PointLights (gold/amber, range 15)
- [ ] Insert banner/tapestry models on walls or posts
- [ ] Add stone wall + hedge perimeter around TradingPost zone
- [ ] Create entrance sign: "Trading Post" on large wooden sign
- [ ] Create sell counter sign: "Sell Potions" near ProximityPrompt
- [ ] Add PointLight to GoldAnchor (warm gold glow, subtle sparkle particles)
- [ ] Insert rug/carpet model under trading area
- [ ] Fill empty corners with barrel stacks, crate clusters, or potion displays
- [ ] Add a decorative centerpiece (large potion bottle display or merchant statue)

### Phase 4: WildGrove — Enchanted Forest (~15%)

Enhance the existing nature zone into a mystical, glowing forest.

**Prop Targets:**
| Category | Items | Count |
|----------|-------|-------|
| Trees | Additional colorful/magical tree models | 3-5 trees |
| Mushrooms | Giant colorful mushrooms (fantasy style) | 3-4 mushroom clusters |
| Rocks | Mossy rocks, crystal formations | 3-4 rock clusters |
| Flora | Ferns, flowers, vines, bushes | 5-8 plant clusters |
| Forage enhancement | Glow effects on existing forage nodes | 6 (all existing nodes) |
| Lighting | Fairy lights, bioluminescent glow, moonlight pools | 3-4 light sources |
| Natural boundaries | Fallen logs, rock walls, thick hedge | Perimeter treatment |

**Tasks:**
- [ ] Insert 3-5 additional fantasy tree models (colorful — pink, purple, blue-green like Grow a Garden)
- [ ] Insert giant fantasy mushroom models with glow effects
- [ ] Insert mossy rock and crystal formation models
- [ ] Insert fern, flower, and bush models to fill ground-level gaps
- [ ] Add ParticleEmitter to all 6 forage nodes: pulsing glow when ready (green/cyan particles)
- [ ] Add PointLight to each forage node (soft green, range 8)
- [ ] Enhance FireflyAnchor particles (increase count, add yellow/green glow)
- [ ] Create entrance sign: "Wild Grove" on rustic/mossy wooden sign
- [ ] Create forage instruction sign: "Click glowing plants to forage"
- [ ] Use fallen logs, rock walls, and dense bush clusters as natural perimeter (instead of fences)
- [ ] Add 2-3 small pools/ponds with blue glow for atmosphere
- [ ] Insert vine/moss decorations on trees for vertical visual interest

### Phase 5: Ambient Audio (~5%)

Add basic ambient sound to bring zones to life.

**Tasks:**
- [ ] Add looping cauldron bubbling sound to YourShop cauldron (Sound object, Looped=true, Volume=0.3, RollOffMaxDistance=40)
- [ ] Add market chatter/ambient bustle sound to IngredientMarket center (Sound, Looped=true, Volume=0.2, RollOffMaxDistance=60)
- [ ] Add forest ambiance (crickets, wind, rustling leaves) to WildGrove center (Sound, Looped=true, Volume=0.25, RollOffMaxDistance=80)
- [ ] Add coin jingling / warm fire crackling to TradingPost (Sound, Looped=true, Volume=0.2, RollOffMaxDistance=40)
- [ ] Ensure all sounds use RollOff so they fade naturally between zones and don't overlap harshly
- [ ] Test audio balance: no zone's sound should bleed annoyingly into adjacent zones

### Phase 6: Cross-Zone Polish & Paths (~5%)

Connect zones visually and ensure the whole world feels cohesive.

**Tasks:**
- [ ] Upgrade path parts between zones: add cobblestone material or insert path models
- [ ] Line paths with fence posts, lanterns, or flower beds
- [ ] Add trees/bushes along path edges to frame transitions
- [ ] Ensure Foliage folder maple trees are sensibly distributed (not all in one cluster)
- [ ] Redistribute or remove billboards if they conflict with new props
- [ ] Add 2-3 decorative elements at path intersections (signposts, benches, lamp posts)
- [ ] Final lighting pass: ensure no zone is too dark or washed out
- [ ] Verify all new props have CanCollide set appropriately (decorative = false, barriers = true)
- [ ] Performance check: count total parts added, ensure reasonable for mobile

## Files Summary

| Location | Action | Purpose |
|----------|--------|---------|
| `Workspace/Zones/YourShop` | Modify | Add 15-20 decorative props, lighting, particles, signage, fencing |
| `Workspace/Zones/IngredientMarket` | Modify | Fix position, add stalls, props, lanterns, signage, fencing |
| `Workspace/Zones/TradingPost` | Modify | Major decoration pass — props, lighting, signage, fencing |
| `Workspace/Zones/WildGrove` | Modify | Add fantasy flora, glow effects on nodes, natural boundaries |
| `Workspace/Zones/Path_*` | Modify | Upgrade path materials, add edge decorations |
| `Workspace/Props` | Modify | May reorganize existing props into zones |
| `Workspace/Foliage` | Modify | Redistribute trees for better coverage |
| `Workspace (root)` | Modify | Clean up loose models (relocate or delete) |

## Definition of Done

- [ ] **YourShop** has 15+ decorative props (shelves, bottles, herbs, candles, furniture), glowing cauldron, stone wall + hedge perimeter, entrance sign
- [ ] **IngredientMarket** has 3+ market stalls, hanging lanterns, crates/barrels, potted plants, stone wall + hedge perimeter, entrance sign, fixed positioning
- [ ] **TradingPost** has trading furniture, gold-themed props, sell display, lanterns, stone wall + hedge perimeter, entrance sign (no longer bare)
- [ ] **WildGrove** has colorful fantasy trees, mushrooms, rocks, glowing forage nodes, natural boundary, entrance sign
- [ ] All 4 zones have entrance signs with readable zone names (SurfaceGui + TextLabel)
- [ ] All key stations have small identification signs (Cauldron, Buy Ingredients, Sell Potions, Forage)
- [ ] At least 3 objects have visible glow/sparkle particle effects (cauldron, forage nodes, one special display)
- [ ] Paths between zones have edge decorations (lanterns, stone posts, or flora)
- [ ] Basic ambient audio plays in each zone (cauldron bubbling, market chatter, forest sounds, trading warmth)
- [ ] No visible empty flat floor from player-height camera in any zone
- [ ] All existing gameplay functions work: buy, brew, sell, forage, teleport, DataStore persistence
- [ ] Runs at playable framerate in Studio play mode
- [ ] Screenshot comparison with Grow a Garden reference images shows comparable visual density

## Risks & Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Marketplace model quality varies wildly | High | Medium | Preview models before bulk inserting; remove/replace poor quality ones |
| Too many parts causes mobile performance issues | Medium | High | Set decorative props to CanCollide=false and Anchored=true; use low-poly models; monitor part count |
| Inserted models have oversized/broken collisions | Medium | Medium | Normalize collision boxes after insertion; test navigation in play mode |
| New props obstruct ProximityPrompts | Medium | High | Test all interactions after each zone pass; maintain clear approach paths to stations |
| IngredientMarket fix breaks existing references | Low | High | Document current state before changes; test market buy flow after repositioning |
| Visual clutter makes navigation confusing | Medium | Medium | Use consistent signage pattern; maintain clear pathways between zones |

## Security Considerations

- No server code changes — no new attack surface
- All new content is static Workspace objects (no scripts attached to decorative props)
- Ensure no inserted marketplace models contain hidden scripts (inspect model contents)

## Dependencies

- Sprint 001 complete (zones, functional elements, core loop all in place)
- Roblox Creator Marketplace accessible for model insertion
- MCP tools (insert_model, run_code) functional for bulk world building

## Open Questions

1. Should we create a "rare potion display" object in YourShop that glows — as a preview of future shop customization?
2. Should the Foliage/Props/Billboards folders be reorganized into zone-specific folders for cleanliness?
3. What Roblox audio asset IDs should we use for ambient sounds, or should we search the marketplace?
4. How many stone wall segments are needed per zone perimeter — should we estimate part counts before inserting?
