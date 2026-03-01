# Sprint 002: World Vibrancy — Dense 3D Props, Fantasy Boundaries, Ambient Soundscape

## Overview

Sprint 001 delivered a functional vertical slice — the core loop works, persistence is solid, all four zones exist. But the world looks like a prototype: flat colored floors, a handful of scattered models, and vast empty space between functional elements. Players comparing this to Grow a Garden (21 billion visits) would leave within seconds.

Sprint 002 transforms the world from "functional graybox" to "vibrant, lived-in village." Every zone gets dense 3D props, themed decorations, stone wall + hedge boundaries with vine overgrowth, readable signage, glow/particle effects on key objects, and ambient audio. No gameplay systems change — this is purely visual density, environmental storytelling, and atmosphere. The goal: a screenshot from any angle looks rich enough to post on TikTok.

This is an environment and presentation sprint, not a mechanics sprint. The buy → brew → sell → forage loop should behave identically after implementation, but players should perceive a dramatic increase in polish, warmth, and visual richness.

## Scope Anchors (Non-Negotiable)

Hard requirements confirmed by interview findings and intent:

1. **Density target is "cozy cluttered"**: maximum density, every major surface covered, no visible empty space from normal player-height camera angles.
2. **Zone boundaries must be fantasy alchemy themed**: stone walls + hedges with vine overgrowth. Wooden fences are explicitly excluded.
3. **Ambient audio must be present**: at minimum, looping cauldron bubbling, market chatter, and forest ambience.
4. **All 4 zones receive substantial treatment**: no zone remains sparse.
5. **No gameplay regressions**: existing prompts, teleport paths, and core loop interactions continue functioning.

## Use Cases

1. **First impression quality**: A new player spawns in YourShop and sees a cozy, cluttered alchemy lab — shelves of potion bottles, hanging herbs, candles, a glowing cauldron with bubbling particles. They immediately feel "this is a real place."
2. **Zone identity at a glance**: Each zone is identifiable by atmosphere alone — warm potions and candles (Shop), bustling stalls with hanging banners (Market), golden trading warmth (Trading Post), mystical glowing forest (Wild Grove).
3. **Ambient immersion**: While waiting, browsing, or walking, players hear sounds that keep the world feeling alive — bubbling, chatter, crickets.
4. **Screenshot-worthiness in any direction**: A player can rotate camera in each zone without exposing barren edges or prototype-looking dead space.
5. **Wayfinding through signage**: Signs at zone entrances and key stations tell players where they are and what to do, like Grow a Garden's "Grow All 375R$" signs.
6. **Visual reward moments**: The cauldron glows and bubbles, rare potion displays sparkle, forage nodes pulse with magical energy — creating the "golden carrot" effect.
7. **Functional continuity**: A returning player can still execute the full buy/brew/sell/forage loop exactly as before.

## Architecture

### Environment Layering Model

```
Gameplay Layer (existing, must remain intact)
  ├── ProximityPrompt stations (cauldron, market, sell, forage)
  ├── Teleport points / zone spawn anchors
  └── Interaction hitboxes / paths

Presentation Layer (new in Sprint 002)
  ├── Dense prop pass (tables, shelves, bottles, crates, herbs, decor)
  ├── Boundary pass (stone wall segments + hedges + vine overgrowth)
  ├── Landmark/signage pass (readable zone naming + station signposting)
  ├── FX pass (glows/sparkles/particles on focal objects)
  └── Audio pass (zone-scoped ambient loops)

Validation Layer
  ├── Navigability checks (no collision traps)
  ├── Prompt accessibility checks
  ├── Visual density walkthroughs (6 camera checkpoints per zone)
  └── Performance sanity checks
```

### Zone Identity Targets

| Zone | Identity Goal | Required Visual Language | Required Audio |
|------|---------------|-------------------------|----------------|
| YourShop | Cozy alchemist workshop | Cluttered shelves, bottles, herb bundles, candles, cauldron corner detail | Cauldron bubbling |
| IngredientMarket | Lively trading bazaar | Stalls, hanging items, stacked goods, signage, lantern clusters | Market chatter |
| TradingPost | Warm exchange hall | Counters, display racks, crates, gold-themed props, decorative stonework | Warm fire / coin ambience |
| WildGrove | Mystical gather zone | Layered flora, stones, mushrooms, roots, vine growth, crystals | Forest ambience |

### Boundary System Standard

All zone edges visible to players must follow this 4-layer composition:

1. **Base barrier**: Stone wall or stone ruin segment
2. **Softener**: Hedge line in front of or behind stone
3. **Overgrowth**: Vine meshes/parts draped across stone and hedge seams
4. **Gap handling**: Any seam or corner where floor edge is exposed gets additional foliage/rock clutter

Explicit exclusion: wooden picket/rail fence boundary style. Natural elements (fallen logs, mushroom clusters, rock piles) may supplement stone boundaries in WildGrove but not replace them.

### Performance Budget Guidelines

| Resource | Per-Zone Target | Notes |
|----------|----------------|-------|
| Decorative model instances | ~80-120 | Prefer low-poly marketplace assets |
| Active PointLights | 6-10 | Use Range to limit overlap |
| Active ParticleEmitters | 3-6 | Keep Rate modest, short Lifetime |
| Concurrent Sound loops | 1-2 | Use RollOff to fade between zones |
| Total new parts (all zones) | ~400-500 | Monitor for mobile performance |

If a zone exceeds budget, triage in this order: remove duplicate/redundant props first, then reduce particle rates, then reduce light count.

## Implementation Plan

### Phase 1: World Audit + Cleanup (~10%)

Establish baseline and fix existing issues before adding new content.

**Tasks:**
- [ ] Fix IngredientMarket bounding box (model has extreme coordinate values — investigate root cause, reposition or replace)
- [ ] Audit loose models in workspace root (WoodenFence, PotionBottles, LowPolyTrees, Lantern, Barrel, Mushroom, Fountain, HerbGarden at ~73,57) — relocate into zones if style-consistent, otherwise delete
- [ ] Verify all zone SpawnPoints are at correct heights and positions
- [ ] Tag all gameplay-critical parts (cauldron, market stall, sell counter, forage nodes) that must not be obstructed
- [ ] Define 6 camera checkpoints per zone for density verification (spawn point + 5 walking positions)
- [ ] Ensure all existing ProximityPrompts trigger correctly (baseline test)

### Phase 2: YourShop — Cozy Alchemy Lab (~20%)

Transform the player's home zone into a cluttered, warm alchemy workshop.

**Prop Targets:**
| Category | Items | Count |
|----------|-------|-------|
| Shelving | Wooden shelves with potion bottles, ingredient jars | 3-4 shelf units |
| Potion displays | Glowing potion bottles on tables/shelves | 5-8 bottles |
| Herb storage | Hanging dried herbs, herb racks, plant pots | 3-4 arrangements |
| Furniture | Wooden tables, stools, workbench | 2-3 pieces |
| Lighting | Candles, lanterns, fireplace/brazier | 4-6 light sources |
| Floor coverage | Rugs, scattered books, small crates | 3-5 items |
| Cauldron FX | Bubbling particles, glow, smoke | 1 (enhance existing) |

**Tasks:**
- [ ] Insert potion bottle shelf models and position along walls
- [ ] Insert hanging herb/plant models near ceiling or on racks
- [ ] Insert wooden table + workbench models
- [ ] Insert candle and lantern models, add PointLights (warm yellow Color3(1, 0.85, 0.5), Range 12-16)
- [ ] Add ParticleEmitter to cauldron: green/purple bubbles rising, subtle glow
- [ ] Add PointLight to cauldron (green tint Color3(0.3, 1, 0.5), Brightness 2, Range 20)
- [ ] Insert small rug/carpet model for floor center
- [ ] Insert scattered book/scroll props on tables
- [ ] Add stone wall + hedge perimeter around YourShop zone (Boundary System Standard)
- [ ] Create entrance sign: "Your Potion Shop" (Part + SurfaceGui + TextLabel, fantasy serif font)
- [ ] Create cauldron station sign: "Cauldron" near ProximityPrompt
- [ ] Add dust mote ParticleEmitter to DustAnchor (warm golden particles, slow drift)
- [ ] Fill corners with crates, barrels, or small prop clusters — eliminate all empty space
- [ ] Verify 6 camera checkpoints show no visible empty floor

### Phase 3: IngredientMarket — Bustling Bazaar (~20%)

Transform from single market stall to a rich, multi-stall marketplace.

**Prop Targets:**
| Category | Items | Count |
|----------|-------|-------|
| Market stalls | Additional stall models with awnings/canopies | 2-3 extra stalls |
| Hanging goods | Banners, lanterns, hanging herbs from stall roofs | 5-8 hanging items |
| Crates & barrels | Merchandise displays, storage crates | 4-6 clusters |
| Ground decoration | Cobblestone path details, sacks, flower pots | 3-5 items |
| Signage | Price signs, stall labels, welcome banner | 3-4 signs |
| Lighting | Market lanterns on poles | 4-6 lanterns |
| Flora | Potted herbs, flower boxes on stalls | 3-4 plants |

**Tasks:**
- [ ] Fix IngredientMarket model positioning (confirmed fix from Phase 1)
- [ ] Insert 2-3 additional market stall models for visual density
- [ ] Insert wooden crate and barrel clusters around stalls
- [ ] Insert hanging lantern models on stall posts, add PointLights (warm orange Color3(1, 0.7, 0.3))
- [ ] Insert potted plant/herb models on and around stalls
- [ ] Insert banner/awning decorations on stalls
- [ ] Add stone wall + hedge perimeter around market zone (Boundary System Standard)
- [ ] Create entrance sign: "Ingredient Market" on large wooden sign (Part + SurfaceGui)
- [ ] Create merchant stall sign: "Buy Ingredients" near ProximityPrompt
- [ ] Insert sack and hay bale models as floor gap-fillers
- [ ] Add subtle ParticleEmitter on MysticAnchor (floating sparkle dust)
- [ ] Position a small fountain or well as market center feature
- [ ] Fill walkway edges with flower pots and small prop clusters
- [ ] Verify 6 camera checkpoints show no visible empty floor

### Phase 4: TradingPost — Golden Trading Hall (~15%)

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
- [ ] Insert golden-tinted lantern models, add PointLights (gold/amber Color3(1, 0.85, 0.4), Range 15)
- [ ] Insert banner/tapestry models on posts
- [ ] Add stone wall + hedge perimeter around TradingPost zone (Boundary System Standard)
- [ ] Create entrance sign: "Trading Post" on large wooden sign
- [ ] Create sell counter sign: "Sell Potions" near ProximityPrompt
- [ ] Add PointLight to GoldAnchor (warm gold glow + subtle sparkle particles)
- [ ] Insert rug/carpet model under trading area
- [ ] Fill empty corners with barrel stacks, crate clusters, or potion displays
- [ ] Add a decorative centerpiece (large potion bottle display or merchant statue)
- [ ] Verify 6 camera checkpoints show no visible empty floor

### Phase 5: WildGrove — Enchanted Forest (~15%)

Enhance the existing nature zone into a mystical, glowing forest.

**Prop Targets:**
| Category | Items | Count |
|----------|-------|-------|
| Trees | Additional colorful/magical tree models (pink, purple, blue-green) | 3-5 trees |
| Mushrooms | Giant colorful mushrooms (fantasy style) | 3-4 mushroom clusters |
| Rocks | Mossy rocks, crystal formations | 3-4 rock clusters |
| Flora | Ferns, flowers, vines, bushes | 5-8 plant clusters |
| Forage enhancement | Glow effects on existing forage nodes | 6 (all existing nodes) |
| Lighting | Fairy lights, bioluminescent glow, moonlight pools | 3-4 light sources |
| Boundaries | Stone ruins + hedge + vine overgrowth perimeter | Full perimeter |

**Tasks:**
- [ ] Insert 3-5 additional fantasy tree models (colorful — pink, purple, blue-green like Grow a Garden)
- [ ] Insert giant fantasy mushroom models with glow effects (PointLight + ParticleEmitter)
- [ ] Insert mossy rock and crystal formation models
- [ ] Insert fern, flower, and bush models to fill ground-level gaps
- [ ] Add ParticleEmitter to all 6 forage nodes: pulsing glow when ready (green/cyan particles, Rate 5, Lifetime 2)
- [ ] Add PointLight to each forage node (soft green Color3(0.3, 1, 0.5), Range 8)
- [ ] Enhance FireflyAnchor particles (increase count, add yellow/green glow)
- [ ] Create entrance sign: "Wild Grove" on mossy stone sign
- [ ] Create forage instruction sign: "Click glowing plants to forage"
- [ ] Add stone ruin + hedge + vine boundary (Boundary System Standard — supplemented with fallen logs, mushroom clusters, rock piles)
- [ ] Add 2-3 small pools/ponds with blue glow (Part + Neon material + PointLight) for atmosphere
- [ ] Insert vine/moss decorations on trees for vertical visual interest
- [ ] Verify 6 camera checkpoints show no visible empty ground

### Phase 6: Ambient Audio (~5%)

Add zone-scoped ambient sound to bring the world to life.

**Tasks:**
- [ ] Add looping cauldron bubbling sound to YourShop cauldron (Sound object: Looped=true, Volume=0.3, RollOffMaxDistance=40, RollOffMinDistance=5)
- [ ] Add market chatter/ambient bustle sound to IngredientMarket center (Sound: Looped=true, Volume=0.2, RollOffMaxDistance=60, RollOffMinDistance=10)
- [ ] Add forest ambiance (crickets, wind, rustling) to WildGrove center (Sound: Looped=true, Volume=0.25, RollOffMaxDistance=80, RollOffMinDistance=10)
- [ ] Add warm fire crackling to TradingPost (Sound: Looped=true, Volume=0.2, RollOffMaxDistance=40, RollOffMinDistance=5)
- [ ] Walk transition paths between all zone pairs — verify no abrupt audio clipping or harsh overlap
- [ ] Verify audio levels don't overwhelm UI click/action sounds
- [ ] Test at zone boundary seams: max 2 simultaneous ambient loops audible at any point

### Phase 7: Cross-Zone Polish & Paths (~5%)

Connect zones visually and finalize cohesion.

**Tasks:**
- [ ] Upgrade path parts between zones: apply cobblestone material (Material = Enum.Material.Cobblestone)
- [ ] Line paths with stone posts, lanterns, or flower beds
- [ ] Add trees/bushes along path edges to frame transitions
- [ ] Redistribute Foliage folder maple trees for better world coverage (not all in one cluster)
- [ ] Add 2-3 decorative elements at path intersections (signposts, benches, lamp posts)
- [ ] Set all decorative props: Anchored=true, CanCollide=false (barriers: CanCollide=true)
- [ ] Final lighting pass: ensure no zone is too dark or washed out

### Phase 8: Regression + Performance Gate (~10%)

Validate everything works end-to-end.

**Tasks:**
- [ ] Run Exit Criteria Walkthrough (see below)
- [ ] Verify buy/brew/sell/forage loop end-to-end
- [ ] Validate all ProximityPrompts remain discoverable and unobstructed
- [ ] Run collision/navigability walkthrough in each zone (no stuck spots)
- [ ] Performance check in Studio play mode — verify no significant frame drops
- [ ] Count total added instances per zone vs performance budget
- [ ] Capture before/after screenshot set for each zone

## Files Summary

| Location | Action | Purpose |
|----------|--------|---------|
| `Workspace/Zones/YourShop` | Modify | Dense alchemy prop pass, boundary, bubbling audio, signage |
| `Workspace/Zones/IngredientMarket` | Modify | Fix position, add stalls, density pass, chatter audio, signage |
| `Workspace/Zones/TradingPost` | Modify | Full furnishing pass (currently bare), gold theme, audio, signage |
| `Workspace/Zones/WildGrove` | Modify | Fantasy flora density, forage node FX, forest audio, signage |
| `Workspace/Zones/Path_*` | Modify | Cobblestone material, edge decorations |
| `Workspace/Props` | Modify | Reorganize/curate into zone-appropriate placements |
| `Workspace/Foliage` | Modify | Redistribute trees for world coverage |
| `Workspace (root)` | Modify | Clean up loose models (relocate or delete) |
| `Workspace/Zones/*/Boundaries` | Create | Stone wall + hedge + vine perimeter per zone |
| `Workspace/Zones/*/Sounds` | Create | Zone-scoped ambient audio sources |

## Definition of Done

- [ ] Every zone passes density check: 6 camera checkpoints per zone, 360-degree sweep, no bare floor patches visible
- [ ] Boundary treatment in all zones uses stone walls + hedges + vine overgrowth (Boundary System Standard)
- [ ] No wooden fence style used as a primary boundary solution
- [ ] Ambient loops active in all 4 zones: cauldron bubbling, market chatter, forest ambience, trading warmth
- [ ] Audio transitions between zones are smooth (no abrupt clipping, max 2 simultaneous loops at boundaries)
- [ ] At least 3 world focal objects have visible glow/sparkle FX (cauldron, forage nodes, one display)
- [ ] All zone and key-station signage is readable while moving (SurfaceGui + TextLabel)
- [ ] Buy/brew/sell/forage interactions still function end-to-end
- [ ] No blocked paths or collision traps introduced by prop density
- [ ] All decorative props: Anchored=true, CanCollide=false; boundary walls: CanCollide=true
- [ ] Performance acceptable in Studio playtest (no visible frame drops)
- [ ] Per-zone instance counts within performance budget guidelines
- [ ] Before/after screenshots clearly show major visual uplift in each zone

## Exit Criteria Walkthrough

1. Spawn at YourShop → rotate 360 degrees → confirm no barren surfaces, audible bubbling ambience, glowing cauldron
2. Teleport to IngredientMarket → confirm dense stall dressing, readable signage, audible market chatter
3. Walk all market edges → confirm stone/hedge/vine boundaries, no wood-fence fallback
4. Teleport to TradingPost → confirm it no longer appears sparse, gold theme visible, warm audio
5. Teleport to WildGrove → confirm layered foliage/rocks, glowing forage nodes, audible forest ambience
6. Walk all zone paths → confirm cobblestone material, edge decorations, smooth audio transitions
7. Run full gameplay loop: buy ingredients → brew potion → sell potion → forage node → confirm zero functional regressions
8. Check DataStore persistence: leave and rejoin → verify coins/inventory/recipes intact

## Risks & Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Marketplace model quality varies wildly | High | Medium | Preview before bulk inserting; remove/replace poor quality ones |
| Over-cluttering blocks player movement or prompts | Medium | High | Maintain interaction clearance envelopes; collision walkthrough after each zone |
| Mobile performance drops from model count | Medium | High | Prefer low-poly assets, enforce per-zone budget, test incrementally |
| Inserted models have broken collisions/scale | Medium | Medium | Normalize after insertion; set decorative CanCollide=false |
| Visual inconsistency from mixed asset styles | Medium | Medium | Curate fantasy alchemy palette; reject clashing styles |
| Audio overlap at zone boundaries | Medium | Medium | Tune Volume/RollOff per zone; validate transition paths |
| IngredientMarket transform fix breaks references | Low | High | Document state before changes; test market buy flow after |

## Security Considerations

- No server code changes — no new attack surface
- All new content is static Workspace objects (no scripts on decorative props)
- Inspect inserted marketplace models for hidden scripts before keeping them
- Maintain server-authoritative logic from Sprint 001 unchanged
- Ensure decorative additions don't create clip-through shortcuts to restricted areas

## Dependencies

- Sprint 001 complete (zones, functional elements, core loop all in place)
- Roblox Creator Marketplace accessible for model insertion
- MCP tools (insert_model, run_code) functional for world building
- Marketplace audio assets available for ambient sounds

## Open Questions

1. Should we define a hard upper instance budget per zone for mobile guardrails, or treat the performance budget as soft guidelines?
2. Should ambience be entirely zone-local 3D sounds, or include a subtle global environmental bed?
3. Should the IngredientMarket bounding-box fix involve repositioning the existing model or replacing it entirely?
4. Should we create a "rare potion display" object in YourShop that glows — as a preview of future shop customization?
