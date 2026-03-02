# Sprint 007: Zone Overhaul - Fantasy World, Potion Displays, Daily Demand Board, Expanded Wild Grove

## Overview

Sprint 007 upgrades all four zones from mostly functional spaces into cohesive fantasy spaces that visually reflect player progression and improve moment-to-moment readability. The highest-value product change is a persistent potion display system in Your Shop: brewed potions now appear on in-world shelves as physical objects, turning brewing history into visible status and giving players a reason to return to and curate their space.

The interview refinement is locked: potion display shelves stay in fixed world positions for this sprint. Scope is focused on reliable shelf placement, deterministic auto-fill, and persistent display data rather than freeform furniture editing. This keeps implementation cost bounded while still delivering the visual progression fantasy.

Wild Grove doubles in playable footprint and node density, Ingredient Market gets stronger identity plus market refresh announcements, and Trading Post gets a physical Daily Demand Board as a social anchor. The sprint is primarily world-building and UX clarity work, with minimal economy-rule changes beyond announcement and board presentation integration.

## Scope Anchors (Non-Negotiable)

1. **Potion display system ships this sprint** with persistent, in-world visuals tied to brewed potions.
2. **Shelf positions are fixed** (3 authored shelf locations, auto-fill only) for Sprint 007.
3. **Wild Grove is expanded to 2x footprint** and forage node count increases to 12 total.
4. **Daily Demand Board is a physical Trading Post world element** and reflects current demand state.
5. **Market refresh announcements ship** when refresh includes Rare+ stock.
6. **All four zones receive fantasy-theme art pass** with cohesive lighting/decoration language.
7. **No regressions** to core gameplay loop (buy, forage, brew, claim, sell).

## Use Cases

1. **Progress visible in the world**: Player brews over time and sees shelves fill with potion displays in fixed slots.
2. **Fast demand awareness**: Player enters Trading Post and can read Daily Demand from a physical board.
3. **Market excitement moments**: Server receives occasional announcement after refresh when Rare+ items appear.
4. **Exploration value increase**: Expanded Wild Grove supports more varied routes and reduced node contention.
5. **Fantasy atmosphere consistency**: Each zone feels intentionally authored rather than mechanically placed.

## Architecture

### Potion Display Model (Fixed Shelf Slots)

- Author three shelf anchors in `Workspace/Zones/YourShop`.
- Define fixed slot transforms per shelf (e.g., 10 slots per shelf; total cap 30).
- On client zone load, render display models by mapping persisted entries to slot transforms in insertion order (or newest-first if chosen).
- No drag/drop, reposition, rotation, or shelf editing in Sprint 007.

```lua
PotionDisplayEntry = {
    potionId = "healing_salve",
    mutation = "golden", -- optional
    brewedUnix = 1762018800,
}

PlayerState.PotionDisplays = {
    -- ordered list, capped to MAX_DISPLAY_SLOTS
}
```

### Display Render Flow

```text
Claim brew result (server)
  -> append PotionDisplayEntry to PlayerState.PotionDisplays
  -> trim to max slots (30)
  -> replicate player data

Enter shop / data refresh (client)
  -> read PlayerState.PotionDisplays
  -> map entries to fixed slot transforms
  -> spawn/update display props from PotionDisplayTuning
```

### Daily Demand Board Integration

- Board is a physical part with `SurfaceGui` in Trading Post.
- Data source remains server-authoritative demand service.
- Board refreshes on data change and on player zone entry/open.
- Existing sell multiplier behavior remains unchanged; board is a presentation + discoverability surface.

### Market Announcement Rules

- Hook into market refresh completion.
- Compute whether refreshed stock contains at least one Rare+ ingredient.
- Broadcast one global announcement message when true.
- Rate-limit to market refresh cadence; no extra spam channels.

### Wild Grove Expansion Principles

- Increase map footprint from current baseline to 2x area.
- Redistribute/add nodes to preserve traversal pacing and reduce overlap.
- Add themed decoration clusters without blocking interaction paths.
- Validate spawn/nav paths and interaction prompts after decoration pass.

## Implementation Plan

### Phase 1: Potion Display Data + Fixed Slot Infrastructure (~24%)

**Files:**
- `src/server/Services/BrewingService.lua` - append display entries on successful brew claim
- `src/server/Services/PlayerDataService.lua` - ensure `PotionDisplays` default/migration safety
- `src/shared/Config/PotionDisplayTuning.lua` (new) - per-tier/per-mutation visual presets
- `src/shared/Types.lua` - add display entry typing/constants if centralized there

**Tasks:**
- [ ] Add `PotionDisplays` array to player state defaults.
- [ ] Add safe migration behavior for older profiles missing display field.
- [ ] On brew claim, append `{potionId, mutation, brewedUnix}` entry.
- [ ] Enforce max display capacity (30 entries for 3 shelves x 10 slots).
- [ ] Define slot count constants in shared config.
- [ ] Add tests/checks for append + trim logic.

### Phase 2: Your Shop Fixed Shelf Authoring + Client Renderer (~22%)

**Files:**
- `Workspace/Zones/YourShop` - add 3 fixed shelf structures and slot anchors
- `src/client/PotionDisplayController.client.lua` (new) - slot mapping and render lifecycle
- `src/client/GameController.client.lua` - initialize/controller wiring if needed

**Tasks:**
- [ ] Author 3 shelves in fixed positions (left wall, right wall, back wall).
- [ ] Create deterministic slot anchor naming convention (`ShelfA_Slot01` ...).
- [ ] Implement renderer that places display props at fixed anchors only.
- [ ] Support mutation/tier variants via tuning table.
- [ ] Ensure idempotent rerender on data updates.
- [ ] Clean up old instances to prevent duplication/memory leaks.

### Phase 3: Wild Grove 2x Expansion + Node Pass (~22%)

**Files:**
- `Workspace/Zones/WildGrove` - terrain/layout expansion + decor clusters
- `src/server/Services/ForageService.lua` (or current node service) - node placement/bounds updates
- `src/shared/Config/ForageNodes.lua` (if present) - updated node definitions

**Tasks:**
- [ ] Expand grove footprint to 2x current dimensions.
- [ ] Increase node count to 12 and rebalance spawn locations.
- [ ] Add fantasy decor sets (crystals, ruins, glowing flora, canopy accents).
- [ ] Validate all nodes remain reachable and interactable.
- [ ] Confirm spawn points/camera bounds still safe.

### Phase 4: Trading Post Daily Demand Board World Element (~12%)

**Files:**
- `Workspace/Zones/TradingPost` - board model + placement
- `src/client/InteractionController.client.lua` - board view refresh hook
- `src/server/Services/DailyDemandService.lua` - expose/confirm current demand payload path

**Tasks:**
- [ ] Add physical demand board mesh/parts at high-traffic location.
- [ ] Bind SurfaceGui fields to current demand entries and multipliers.
- [ ] Refresh on demand rollover and client session join.
- [ ] Add legibility pass (distance/readability and contrast checks).

### Phase 5: Ingredient Market Aesthetic + Refresh Announcements (~10%)

**Files:**
- `Workspace/Zones/IngredientMarket` - lanterns, herbs, banners, stall polish
- `src/server/Services/MarketService.lua` - Rare+ refresh announcement trigger
- `src/client/FeedbackController.client.lua` - announcement display reuse

**Tasks:**
- [ ] Apply market fantasy pass (cozy stall readability and prop density).
- [ ] Detect Rare+ presence on refresh.
- [ ] Broadcast concise announcement only when condition is met.
- [ ] Reuse existing global banner channel; avoid introducing new modal UI.

### Phase 6: Cross-Zone Integration, Regression, and Performance Validation (~10%)

**Files:**
- `src/server/Services/*.lua` (targeted touch-ups)
- `src/client/*.client.lua` (targeted touch-ups)

**Tasks:**
- [ ] End-to-end verify brew -> claim -> shelf render persistence.
- [ ] Verify board and announcement behavior under normal play sessions.
- [ ] Validate no regressions in buy/forage/brew/sell loops.
- [ ] Check client performance in expanded Wild Grove and decorated zones.
- [ ] Fix collision/pathing issues introduced by environmental props.

## Files Summary

| File | Action | Purpose |
|------|--------|---------|
| `src/server/Services/BrewingService.lua` | Modify | Persist potion display entries on brew claim |
| `src/server/Services/PlayerDataService.lua` | Modify | Add default/migration-safe `PotionDisplays` field |
| `src/shared/Config/PotionDisplayTuning.lua` | Create | Display prefab and effect mapping by tier/mutation |
| `src/shared/Types.lua` | Modify | Shared types/constants for display entries and caps |
| `src/client/PotionDisplayController.client.lua` | Create | Render fixed-slot shelf displays in Your Shop |
| `src/client/GameController.client.lua` | Modify | Initialize/update display controller lifecycle |
| `src/client/InteractionController.client.lua` | Modify | Daily Demand board UI update hooks |
| `src/client/FeedbackController.client.lua` | Modify | Market refresh announcement display reuse |
| `src/server/Services/MarketService.lua` | Modify | Rare+ stock detection and announcement trigger |
| `src/server/Services/DailyDemandService.lua` | Modify | Board payload exposure/refresh integration |
| `src/server/Services/ForageService.lua` | Modify | Wild Grove node updates for expanded layout |
| `Workspace/Zones/YourShop` | Modify | Fixed-position potion shelves + slot anchors |
| `Workspace/Zones/WildGrove` | Modify | 2x expansion, decoration, node space |
| `Workspace/Zones/TradingPost` | Modify | Physical Daily Demand Board placement |
| `Workspace/Zones/IngredientMarket` | Modify | Cozy fantasy market art pass |

## Definition of Done

- [ ] Brewed potions create persistent display entries and appear on shop shelves.
- [ ] Shelf layout is fixed (3 shelves, fixed slot anchors, auto-fill only).
- [ ] Maximum displayed potion entries is enforced at 30.
- [ ] Wild Grove footprint is doubled and total forage nodes = 12.
- [ ] Daily Demand Board is present in Trading Post and shows live demand data.
- [ ] Market refresh announcement fires only when refresh contains Rare+ stock.
- [ ] All four zones pass fantasy-theme visual cohesion review.
- [ ] Core gameplay loop has no functional regressions.
- [ ] Client performance remains acceptable in expanded/decorated zones.

## Risks & Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Display object count impacts client performance in decorated shop | Medium | Medium | Hard cap at 30 displays; use lightweight props; batch cleanup on rerender |
| Decor pass introduces collision/pathing blockers | Medium | High | Run interaction/pathing sweep per zone; keep no-block corridors near key interactables |
| Demand board data desync with server state | Low | Medium | Board reads from server-authoritative payload and refreshes on key events |
| Announcement spam reduces signal quality | Medium | Medium | Trigger only on Rare+ stock and only at refresh cadence |
| Wild Grove expansion causes sparse/empty regions | Medium | Medium | Use themed clusters and node redistribution with traversal playtests |

## Security Considerations

- Potion display data is authored server-side on claim events only.
- Board demand values are server-authored; client renders read-only payload.
- Market announcement trigger is server-owned and condition-gated.
- No client authority introduced for economy, inventory, or demand multipliers.

## Dependencies

- Sprint 005 mutation metadata and compound potion identity conventions.
- Sprint 006 Daily Demand service/data model and announcement UI channel.
- Existing zone loading and interaction controller patterns for world GUIs.

## Open Questions

1. Should display ordering be oldest-first (timeline) or newest-first (recent flex) by default?
2. Should duplicate potions stack visually in one slot or always consume separate slots?
3. Should Daily Demand Board include a countdown to next UTC rollover in Sprint 007 or defer?
4. Are weather events in Wild Grove in-scope now, or intentionally deferred to Sprint 008?
