# Sprint 008: Nuclear Visual Rebuild — Flat World, Clean Fantasy Zones, Reliable Foraging

## Overview

Sprint 008 is a full visual reset of all playable zones. The current world has accumulated ad-hoc geometry, terrain artifacts, inconsistent elevations, and climbable decorative assets that degrade movement and readability. This sprint removes all non-essential zone visuals and rebuilds the world from a clean baseline while preserving gameplay-critical anchors and script contracts.

The rebuild is constrained by hard world invariants: all zone floors and connecting paths sit on a single Y plane, WildGrove is 3x larger than any other zone, no decorative furniture can be climbed, and foraging must be visibly present and functionally wired end-to-end. The YourShop zone follows the Sunken Crypt SVG specification for spatial layout and tone. The result should be a coherent, bright, stable fantasy environment with zero flicker and zero gameplay regressions.

This sprint is world/visual focused. Core gameplay systems (brewing, market, selling, scoring, upgrades, mutations) remain unchanged and must continue to function by preserving required object names and interaction points.

## Scope Anchors (Non-Negotiable)

1. Full visual nuke-and-rebuild of all 4 zones and connecting paths.
2. Uniform ground plane: floor top at Y=0 across zones and routes.
3. WildGrove area is 3x larger than any other single zone.
4. YourShop layout adheres to `/Users/karim.fanous/Downloads/1_sunken_crypt.svg`.
5. No climbable decorative furniture (CanCollide=false for non-walkable decor above Y=1).
6. No Terrain voxels in any playable zone/path footprint.
7. Foraging works fully: 12 nodes visible, interactable, and rewarding ingredients.
8. No flickering lights; stable brightness and `Shadows=false` for decorative lights.
9. Preserve gameplay-critical object names expected by existing scripts.
10. No script/config changes to gameplay logic in `src/server/Services/` or `src/shared/Config/`.

## Use Cases

1. **New player onboarding**: Player can teleport between zones and instantly understand where to buy, brew, forage, and sell.
2. **Core loop reliability**: Player completes buy -> brew -> claim -> sell without any blocked pathing or broken prompts.
3. **Foraging session**: Player finds and interacts with all 12 forage nodes and receives ingredients consistently.
4. **Exploration quality**: Player traverses WildGrove without terrain obstructions, lighting artifacts, or collision exploits.
5. **Aesthetic consistency**: Player experiences cohesive fantasy visuals with clear zone identity and readable interaction anchors.

## Architecture

### World Invariants

```text
Global Plane:
  Walkable floor top surface Y = 0

Collision Rule:
  Walkable surfaces (floors, ramps, stairs): CanCollide = true
  Decorative objects above Y=1: CanCollide = false

Lighting Rule:
  Decorative point/spot/surface lights:
    Shadows = false
    Brightness = constant (no scripts/tweens flickering)

Terrain Rule:
  No Terrain voxels inside zone/path bounds
```

### Zone Footprint Plan

```text
Reference zone size (Shop/Market/TradingPost): 100 x 100 (or same selected baseline)
WildGrove target: 300 x 100 equivalent area minimum (3x baseline area)

Recommended layout (top view, not to scale):

[IngredientMarket] -- flat path -- [TradingPost]
        |                               |
     flat path                       flat path
        |                               |
      [YourShop] ---- flat path ---- [WildGrove (3x area)]
```

### Preserve vs Rebuild Contract

**Must preserve by name (reposition/re-skin allowed):**
- `ForageNode_1` ... `ForageNode_12`
- `SpawnPoint` in each zone
- `Cauldron`, `CauldronLiquid`, `BrewingSpoon`, `CauldronMedievalFantasy` (YourShop)
- `MarketStall` (IngredientMarket)
- `SellCounter` (TradingPost)
- `DailyDemandBoard` (TradingPost)
- `EvolutionTiers` (YourShop)
- `DustAnchor`, `FireflyAnchor`, `MysticAnchor`, `GoldAnchor`

**Must remove/rebuild:**
- Ad-hoc decorative meshes/parts causing blocked routes or inconsistent style
- Terrain in zone/path play spaces
- Any light setups that flicker or overexpose

### Interaction Continuity

Existing interaction scripts bind by object names and prompts:
- `GameController.client.lua`: zone teleport via `SpawnPoint`
- `InteractionController.client.lua`: proximity prompt routing by parent name (`MarketStall`, `Cauldron`, `SellCounter`, `ForageNode*`)
- `ZoneService.lua`: forage reward pools keyed by `ForageNode_*`
- `ForageNodeFeedback.client.lua`: feedback/pulse by `ForageNode` name match

The rebuild succeeds only if these name contracts remain intact.

## Implementation Plan

### Phase 1: Baseline Audit and Freeze (~10%)

**Files/Areas:**
- `Workspace/Zones/*` (audit only)
- `Workspace/Terrain`

**Tasks:**
- [ ] Snapshot current world and capture a zone inventory by name.
- [ ] Record required keep-list objects and current parents.
- [ ] Define final baseline zone dimensions (single source of truth for 1x zone area).
- [ ] Declare exact playable bounds for terrain-clearing and validation.

### Phase 2: World Nuke and Terrain Clearance (~20%)

**Files/Areas:**
- `Workspace/Zones/YourShop`
- `Workspace/Zones/IngredientMarket`
- `Workspace/Zones/TradingPost`
- `Workspace/Zones/WildGrove`
- `Workspace/Terrain`

**Tasks:**
- [ ] Remove all non-essential visual assets from each zone.
- [ ] Preserve and isolate keep-list objects in temporary staging folders during teardown.
- [ ] Clear Terrain voxels across all zone and connector bounds.
- [ ] Re-establish empty zone shells with clean top-level organization per zone.

### Phase 3: Flat Ground and Navigation Grid (~20%)

**Files/Areas:**
- `Workspace/Zones/*` floors and connectors

**Tasks:**
- [ ] Rebuild all floors so top surfaces align at Y=0.
- [ ] Build flat connector paths between every zone pair used in normal play.
- [ ] Verify no step/jump discontinuities on critical routes.
- [ ] Reposition each zone `SpawnPoint` safely above floor centerline.
- [ ] Ensure walkability around `MarketStall`, `Cauldron`, and `SellCounter` interaction radii.

### Phase 4: Zone Rebuild (Sunken Crypt Shop + Fantasy Cohesion) (~25%)

**Files/Areas:**
- `Workspace/Zones/YourShop` (SVG-driven)
- `Workspace/Zones/IngredientMarket`
- `Workspace/Zones/TradingPost`
- `Workspace/Zones/WildGrove`

**Tasks:**
- [ ] Implement YourShop layout from Sunken Crypt SVG (center cauldron focus, wall zoning, readable lanes).
- [ ] Rebuild IngredientMarket with clean stall-first readability and stable ambient fantasy dressing.
- [ ] Rebuild TradingPost with clear sell approach and visible DailyDemandBoard anchor.
- [ ] Rebuild WildGrove as 3x-area exploration zone with controlled density and unobstructed node access.
- [ ] Apply coherent material/color language across all zones (single fantasy art direction).

### Phase 5: Collision and Lighting Hardening (~10%)

**Files/Areas:**
- All zone decorative assets and lights

**Tasks:**
- [ ] Set non-walkable decorative objects above Y=1 to `CanCollide=false`.
- [ ] Keep only intentional collision on floors, path blockers, and required gameplay geometry.
- [ ] Remove flicker sources (scripts/tweens/randomized light intensity).
- [ ] Normalize decorative lights to non-flicker constants with `Shadows=false`.
- [ ] Validate readability at interaction points under default camera and movement.

### Phase 6: Foraging Reliability Pass (~10%)

**Files/Areas:**
- `Workspace/Zones/WildGrove/ForageNode_*`

**Tasks:**
- [ ] Place all 12 forage nodes in reachable, visible positions within WildGrove.
- [ ] Ensure each node has/retains a valid `ProximityPrompt` and expected naming convention.
- [ ] Validate prompt distance and line-of-sight behavior for natural interactions.
- [ ] Verify rare forage node spawns in playable WildGrove coordinates and remains reachable.

### Phase 7: Verification and Regression Gate (~5%)

**Tasks:**
- [ ] Run walkability test through all zone perimeters and all inter-zone paths.
- [ ] Run 12-node forage pass and verify ingredient acquisition events.
- [ ] Run full brew cycle at cauldron and claim output.
- [ ] Run sell flow at SellCounter and buy flow at MarketStall.
- [ ] Run anti-climb checks on all bookcases/shelves/decorative sets.
- [ ] Capture before/after screenshots for each zone and one inter-zone route matrix.

## Files Summary

| File / Area | Action | Purpose |
|-------------|--------|---------|
| `Workspace/Zones/YourShop` | Rebuild | Sunken Crypt-conformant shop layout with preserved interaction anchors |
| `Workspace/Zones/IngredientMarket` | Rebuild | Clear market readability and stable fantasy visuals |
| `Workspace/Zones/TradingPost` | Rebuild | Functional sell hub + clear DailyDemandBoard placement |
| `Workspace/Zones/WildGrove` | Rebuild/Expand | 3x area, reliable forage traversal, clean fantasy exploration space |
| `Workspace/Terrain` | Clear in bounds | Remove path-blocking terrain voxels from playable areas |
| `Workspace/Zones/*/SpawnPoint` | Reposition/Preserve | Maintain teleport contracts in flat world |
| `Workspace/Zones/WildGrove/ForageNode_1..12` | Preserve/Reposition | Keep script contracts while ensuring functional foraging |
| `Workspace/Zones/*` decorative assets | Replace | Enforce no-climb policy and cohesive visual language |

## Definition of Done

- [ ] All 4 zones visually rebuilt from clean baseline (no legacy clutter retained).
- [ ] Ground plane is flat and consistent (walkable top at Y=0) across zones and connectors.
- [ ] WildGrove playable area is at least 3x the area of any other individual zone.
- [ ] YourShop layout matches Sunken Crypt SVG intent (functional zoning + visual spec).
- [ ] No Terrain voxels remain in playable zone/path bounds.
- [ ] Decorative climb exploits removed (`CanCollide=false` on non-walkable decor above Y=1).
- [ ] All 12 forage nodes are visible, interactable, and grant ingredients.
- [ ] Rare forage node spawn is reachable and collectible in rebuilt WildGrove.
- [ ] Market buy, cauldron brew/claim, and sell interactions all work with no regressions.
- [ ] Lighting is stable and readable with no flicker and no decorative shadow artifacts.

## Risks & Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Name-contract break during teardown (`ForageNode_*`, anchors, counters) | Medium | High | Keep-list staging + final name audit checklist before test pass |
| Over-decoration reduces traversal clarity | Medium | Medium | Enforce minimum path widths and interaction clear-zones |
| WildGrove 3x scale introduces sparse or repetitive feel | Medium | Medium | Use clustered composition with intentional landmarks and node distribution |
| Collision cleanup misses climb exploits | High | Medium | Explicit anti-climb pass by prop category + jump test matrix |
| Terrain remnants remain under/inside floors | Medium | High | Bounded terrain sweep + camera-underfloor inspection pass |
| Lighting becomes dim/flat after flicker removal | Low | Medium | Set target brightness ranges and validate at all interaction points |

## Security Considerations

- No trust boundary changes: all economy/forage rewards stay server-authoritative.
- No new client remotes or server handlers introduced.
- Preserve existing prompt and object-name contracts to avoid accidental bypasses.
- Avoid hidden collision pockets that could enable out-of-bounds exploits.

## Dependencies

- Sprint 006 systems (daily demand, scoring, global announcements) must remain operational.
- Sprint 007 zone assets may be reused selectively, but layout/collision/lighting must be rebuilt to new constraints.
- Sunken Crypt reference SVG at `/Users/karim.fanous/Downloads/1_sunken_crypt.svg`.

## Assumptions

- `CLAUDE.md` project-conventions file is not present in this repository; sprint style and constraints are derived from `docs/sprints/README.doc`, recent sprint docs, and the Sprint 008 intent file.
