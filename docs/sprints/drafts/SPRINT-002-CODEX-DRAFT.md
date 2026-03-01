# Sprint 002: World Vibrancy — Dense 3D Props, Fantasy Boundaries, Ambient Soundscape

## Overview

Sprint 002 turns the current functional prototype world into a dense, expressive, and readable fantasy alchemy space without changing gameplay systems. The objective is to close the visual gap identified in the intent: move from sparse flat areas to a "cozy cluttered" world where every zone feels handcrafted, lived-in, and immediately legible from player-height camera angles.

This sprint treats environment density and atmosphere as first-class UX. We will aggressively fill all playable zones with 3D props, define boundaries with stone-and-hedge structures (with vine overgrowth), and add ambient audio loops that reinforce zone identity and player immersion. The work stays architecture-safe by preserving all server-authoritative economy/gameplay flows from Sprint 001.

This is an environment and presentation sprint, not a mechanics sprint. The buy → brew → sell → forage loop should behave identically after implementation, but players should perceive a dramatic increase in polish, warmth, and visual richness.

## Scope Anchors (Non-Negotiable)

These are hard requirements confirmed by interview findings and intent:

1. **Density target is "cozy cluttered"**: maximum density, every major surface covered, and no visible empty space from normal player movement paths.
2. **Zone boundaries must be fantasy alchemy themed**: stone walls + hedges with vine overgrowth. Wooden fences are explicitly out of scope.
3. **Ambient audio must be present**: at minimum, looping cauldron bubbling, market chatter, and forest ambience.
4. **All 4 zones receive substantial treatment**: no zone remains sparse.
5. **No gameplay regressions**: existing prompts, teleport paths, and core loop interactions continue functioning.

## Use Cases

1. **Immediate first-impression quality**: A new player spawns and instantly sees layered props, color variety, and thematic detail instead of broad empty floors.
2. **Readable zone navigation by atmosphere**: A player can infer where they are by environmental identity (alchemy interior, market bustle, trading hub, wild grove ambience) before reading labels.
3. **Ambient immersion during idle moments**: While waiting, browsing, or walking, players hear sounds that keep the world feeling alive.
4. **Screenshot-worthiness in any direction**: A player can rotate camera in each zone without exposing barren edges or prototype-looking dead space.
5. **Functional continuity**: A returning player can still execute buy/brew/sell/forage loop exactly as before.

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
  ├── FX pass (glows/sparkles/highlighted rare displays)
  └── Audio pass (zone-scoped ambient loops)

Validation Layer
  ├── Navigability checks (no collision traps)
  ├── Prompt accessibility checks
  ├── Visual density walkthroughs
  └── Performance sanity checks
```

### Zone Identity Targets

| Zone | Identity Goal | Required Visual Language | Required Audio |
|------|----------------|--------------------------|----------------|
| `YourShop` | Cozy alchemist workshop | cluttered shelves, bottles, herb bundles, candles, cauldron corner detail | cauldron bubbling (primary) |
| `IngredientMarket` | Lively trading street | stalls, hanging items, stacked goods, signage, lantern clusters | market chatter (primary) |
| `TradingPost` | Warm exchange hall | counters, display racks, crates, posted boards, decorative stonework | low market/chamber bed |
| `WildGrove` | Mystical gather zone | layered flora, stones, mushrooms, roots, vine growth, small ruins | forest ambience (primary) |

### Boundary System Standard

All zone edges visible to players should be treated with this composition:

1. **Base barrier**: stone wall or stone ruin segment.
2. **Softener**: hedge line in front of or behind stone.
3. **Overgrowth**: vine meshes/parts draped across stone and hedge seams.
4. **Gap handling**: any seam or corner where floor edge is exposed gets additional foliage/rock clutter.

Explicit exclusion: wooden picket/rail fence boundary style.

## Implementation Plan

### Phase 1: World Audit + Guardrails (~15%)

**Files/Assets:**
- `Workspace/Zones/*` (Models) — baseline cleanup and anchor verification
- `Workspace/Props` / `Workspace/Foliage` / root loose models — inventory and relocation decisions
- `ServerScriptService` prompt-bearing parts (reference only) — ensure no interaction regressions

**Tasks:**
- [ ] Create a zone-by-zone prop and empty-space audit from player-height viewpoints
- [ ] Identify and tag all gameplay-critical parts that must not be obstructed
- [ ] Document currently misplaced loose models (workspace root cluster) for reuse or replacement
- [ ] Confirm IngredientMarket extreme bounding-box issue root cause and safe remediation path
- [ ] Define a per-zone density target count (minimum prop clusters and surface coverage)

### Phase 2: Dense Prop Pass (Cozy Cluttered) (~35%)

**Files/Assets:**
- `Workspace/Zones/YourShop` — dense alchemy interior pass
- `Workspace/Zones/IngredientMarket` — stall density and clutter pass
- `Workspace/Zones/TradingPost` — full furnishing pass (currently sparse)
- `Workspace/Zones/WildGrove` — layered nature clutter pass
- Roblox marketplace inserts via `insert_model`

**Tasks:**
- [ ] Fill YourShop surfaces and walls with layered alchemy props (shelves, bottles, herb bundles, books, candles)
- [ ] Increase IngredientMarket stall density with stacked goods, hanging decor, and path-side clutter
- [ ] Bring TradingPost from minimal scaffold to full scene with props covering all visible surfaces
- [ ] Add WildGrove ground clutter and vertical variation so no flat empty ground planes remain visible
- [ ] Maintain player path readability while maximizing object density
- [ ] Ensure all zones meet "no visible empty space" checks from at least 6 camera positions per zone

### Phase 3: Boundaries + Signage + FX (~25%)

**Files/Assets:**
- `Workspace/Zones/*/Boundaries` (new/updated folders)
- `Workspace/Billboards` + zone-local signs
- FX objects on cauldron/rare displays/forage points

**Tasks:**
- [ ] Replace or avoid wooden fence boundaries with stone wall systems in every zone
- [ ] Add hedges and vine overgrowth to all major boundary lines and corners
- [ ] Add readable zone/station signs consistent with fantasy alchemy tone
- [ ] Introduce glow/sparkle treatment on at least 3 focal objects (cauldron, rare potion displays, special forage object)
- [ ] Verify signage readability at default camera distance and movement speed

### Phase 4: Ambient Audio Integration (~15%)

**Files/Assets:**
- `Workspace/Zones/YourShop/Sounds` (new)
- `Workspace/Zones/IngredientMarket/Sounds` (new)
- `Workspace/Zones/WildGrove/Sounds` (new)
- Optional shared sound helper under `ReplicatedStorage` if needed

**Tasks:**
- [ ] Add looping cauldron bubbling source in YourShop near brew station
- [ ] Add looping market chatter bed in IngredientMarket with tuned rolloff
- [ ] Add looping forest ambience in WildGrove with subtle spatial falloff
- [ ] Balance sound levels so no zone audio overwhelms UI/action sounds
- [ ] Validate transitions between zones do not produce abrupt clipping or silence gaps

### Phase 5: Regression + Performance Gate (~10%)

**Files/Assets:**
- Existing interaction and UI assets (verification only)

**Tasks:**
- [ ] Verify buy/brew/sell/forage loop end-to-end after world changes
- [ ] Validate all ProximityPrompts remain discoverable and unobstructed
- [ ] Run collision/navigability walkthrough in each zone
- [ ] Perform Studio playtest performance check with added geometry/audio
- [ ] Capture before/after screenshot set for acceptance review

## Files Summary

| Location | Action | Purpose |
|----------|--------|---------|
| `Workspace/Zones/YourShop` | Modify | Apply dense prop pass, boundary treatment, and bubbling ambience |
| `Workspace/Zones/IngredientMarket` | Modify | Increase market density, fix visual cluttering, add chatter ambience |
| `Workspace/Zones/TradingPost` | Modify | Build out currently sparse zone to full visual parity |
| `Workspace/Zones/WildGrove` | Modify | Add layered nature density and forest ambience |
| `Workspace/Props` | Modify | Curate reusable prop sets and place by zone |
| `Workspace/Foliage` | Modify | Re-distribute trees/greens to eliminate dead space |
| `Workspace/Billboards` and zone signs | Modify | Improve world readability and identity |
| `Workspace/Zones/*/Boundaries` | Create/Modify | Standardize stone wall + hedge + vine boundary language |
| `Workspace/Zones/*/Sounds` | Create | Zone-scoped ambient audio sources |

## Definition of Done

- [ ] Every zone passes "cozy cluttered" density checks with no obvious empty floor/surface patches in normal play paths
- [ ] Boundary treatment in all zones uses stone walls + hedges + vine overgrowth
- [ ] No wooden fence style is used as a primary boundary solution
- [ ] Ambient loops are active: cauldron bubbling, market chatter, and forest ambience
- [ ] At least 3 world focal objects have visible glow/sparkle FX
- [ ] All zone and key-station signage is readable while moving
- [ ] Buy/brew/sell/forage interactions still function end-to-end
- [ ] No blocked paths or collision traps introduced by prop density
- [ ] Performance remains acceptable in Studio playtest on target baseline
- [ ] Before/after screenshots clearly show major visual uplift in each zone

## Exit Criteria Walkthrough

1. Spawn at `YourShop` and rotate 360 degrees: confirm no barren surfaces and audible bubbling ambience.
2. Teleport to `IngredientMarket`: confirm dense stall dressing, readable signage, and audible chatter.
3. Walk all market edges: confirm stone/hedge/vine boundaries and no wood-fence fallback.
4. Teleport to `TradingPost`: confirm it no longer appears sparse and supports same visual density standard.
5. Teleport to `WildGrove`: confirm layered foliage/rocks and audible forest ambience.
6. Run full gameplay loop (buy → brew → sell → forage): confirm zero functional regressions.

## Risks & Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Over-cluttering blocks player movement or prompts | Medium | High | Keep interaction clearance envelopes and do collision walkthroughs each pass |
| Mobile performance drops due to model count | Medium | High | Prefer low-poly marketplace assets, reuse instances, test incrementally |
| Visual inconsistency from mixed asset styles | Medium | Medium | Enforce fantasy alchemy palette and curated asset shortlist |
| Audio overlap becomes noisy or fatiguing | Medium | Medium | Tune volume/rolloff per zone, keep ambience as low-bed layers |
| IngredientMarket transform issues persist | Medium | Medium | Isolate broken model, normalize transforms, replace if needed |

## Security Considerations

- Sprint 002 does not introduce new economy remotes or client-authoritative state.
- Maintain server-authoritative logic from Sprint 001 unchanged.
- Ensure decorative additions do not unintentionally expose interaction exploits (e.g., clip-through shortcuts to restricted parts).

## Dependencies

- Depends on Sprint 001 world and systems baseline being present and stable.
- Requires Roblox marketplace assets for fantasy props, stone boundary pieces, hedges/vines, and ambience sound assets.
- Optional follow-up dependency: next sprint can layer advanced feedback/discoverability mechanics on this visual foundation.

## Open Questions

1. Should we define a hard upper budget per zone (instance count/triangles) for mobile guardrails before placement starts?
2. Should ambience be entirely zone-local 3D sounds, or partially mixed with a global low-volume environmental bed?
3. Do we preserve and relocate existing loose root models, or replace with newly curated assets for consistency?
4. Should the IngredientMarket bounding-box fix happen at the start of Phase 2 or as a preflight blocker in Phase 1?
