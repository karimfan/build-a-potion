# Sprint 007: Zone Overhaul — Potion Displays, Expanded Wild Grove, Daily Demand Board, Fantasy Polish

## Overview

Sprint 007 transforms all 4 zones into immersive fantasy environments. The centerpiece is the **Potion Display System**: every brew adds a visual vial/bottle to your shop shelves — a shelf full of glowing, colorful potions is the ultimate flex. The **Wild Grove doubles in size** to 240x240 with dense fantasy decoration and 12 forage nodes. The **Daily Demand Board** becomes a physical in-world display. The **Ingredient Market** gets new-stock announcements. Everything is MAGICAL, FANTASY, bold and colorful.

## Scope Anchors

1. **Potion Display System** — 3 fixed shelves, brewed potions appear as visual vials
2. **Wild Grove 2x expansion** — 240x240, 12 forage nodes, dense fantasy decor
3. **Market refresh announcements** — notify all players when Rare+ stock appears
4. **Daily Demand Board** — physical SurfaceGui display in Trading Post
5. **Fantasy theme** — magical, colorful, bold across all zones

## Potion Display System

### Visual Tiers
| Tier | Display Style |
|------|--------------|
| Common | Simple glass vial, subtle color matching potion |
| Uncommon | Glass vial with soft glow (PointLight) |
| Rare | Ornate bottle with golden rim, particle sparkles |
| Mythic | Crystal bottle with pulsing aura, dramatic particles |
| Divine | Floating golden vial, holy glow, dramatic particle trail |

### Mutation Variants
| Mutation | Visual Modifier |
|----------|----------------|
| Glowing | Neon material, brighter light |
| Bubbling | Bubble particles rising |
| Crystallized | Crystal formations on bottle |
| Shadow | Dark ForceField material, shadow particles |
| Rainbow | Color-shifting Neon, prismatic particles |
| Golden | Metal material, gold color, coin sparkles |

### Data Model
```lua
PlayerState.PotionDisplays = {
    { potionId = "healing_salve", mutation = nil, brewedUnix = 12345 },
    { potionId = "volcanic_frost", mutation = "Golden", brewedUnix = 12346 },
    ...
}
-- Max 30 entries (3 shelves x 10)
-- Oldest removed when full
```

## Wild Grove Expansion

### New Layout (240x240)
- 12 forage nodes in themed clusters:
  1-3: Mushroom Glade (mushroom, willow bark, snail slime)
  4-6: Crystal Stream (river water, rainwater, dewdrop pearl)
  7-8: Herb Garden (fern leaf, mint sprig, dandelion puff)
  9-10: Shadow Nook (cobweb strand, charcoal chunk, pebble dust)
  11: Ancient Tree (acorn cap, willow bark, honey drop)
  12: Mystic Pool (clay mud, firefly glow, mint sprig)

### Fantasy Decoration
- Giant colorful mushroom clusters (4 groups)
- Crystal formations with colored glow (6 clusters)
- Ancient stone ruins/archways (2 sets)
- Enchanted trees: pink cherry blossom, purple magical, blue-green
- Glowing pools with mist particles (4 pools)
- Vine-covered rock formations
- Fairy light strings between trees
- Dense ambient fog and firefly particles
- Rare spawn nodes continue (every 2-4 minutes)

## Market Announcements

On every 5-minute market refresh:
- Check if any Rare, Mythic, or Divine ingredients appeared
- If yes: fire GlobalAnnouncement to all players
- Format: "Market refreshed! [Dragon Scale] and [X] more items now available!"
- Common/Uncommon restocks are silent (too frequent to announce)

## Daily Demand Board

Physical wooden board in Trading Post zone:
- Large SurfaceGui showing 3 demand potions
- Each entry: potion name, tier badge, multiplier (2x/3x/5x)
- Glowing neon frame around the board
- Updates at UTC midnight
- Positioned prominently near the sell counter
- "HOT DEMAND!" header with flame emoji styling

## Implementation Plan

### Phase 1: Potion Display System (~25%)
- [ ] Add 3 display shelf Parts to YourShop walls
- [ ] Create PotionDisplayTuning config
- [ ] Create PotionDisplayController client script
- [ ] Add PotionDisplays to player data (V5 migration or append to V4)
- [ ] On brew claim, add entry to PotionDisplays
- [ ] Render vials on shelves based on player data
- [ ] Tier-based visual: material, color, particles

### Phase 2: Wild Grove Expansion (~30%)
- [ ] Expand floor to 240x240
- [ ] Update boundaries for new size
- [ ] Add 6 new forage nodes (total 12)
- [ ] Insert fantasy decoration models: mushrooms, crystals, ruins, trees
- [ ] Add glowing pools, vine formations, fairy lights
- [ ] Dense fog and firefly particles
- [ ] Update path from shop to grove for new distance

### Phase 3: Market Announcements (~10%)
- [ ] Add announcement logic to MarketService refresh
- [ ] Only announce Rare+ stock
- [ ] Use existing GlobalAnnouncement remote

### Phase 4: Daily Demand Board (~15%)
- [ ] Create physical board Part in Trading Post
- [ ] Add SurfaceGui with demand display
- [ ] Wire to DailyDemandService data
- [ ] Glowing frame, "HOT DEMAND!" header
- [ ] Update on UTC midnight

### Phase 5: Zone Polish (~15%)
- [ ] Trading Post: social seating, treasure displays, warm lighting
- [ ] Market: hanging herbs, banners, NPC merchant figure, more lanterns
- [ ] YourShop: ensure wizard lair theme consistent

### Phase 6: Testing (~5%)
- [ ] All 12 forage nodes work
- [ ] Potion displays render and persist
- [ ] Market announcements fire
- [ ] Demand board visible
- [ ] No regressions

## Files Summary

| File | Action | Purpose |
|------|--------|---------|
| `src/client/PotionDisplayController.client.lua` | Create | Render potion vials in shop |
| `src/shared/Config/PotionDisplayTuning.lua` | Create | Display configs per tier |
| `src/server/Services/BrewingService.lua` | Modify | Add to PotionDisplays on claim |
| `src/server/Services/PlayerDataService.lua` | Modify | PotionDisplays field |
| `src/server/Services/MarketService.lua` | Modify | Refresh announcements |
| `Workspace/Zones/YourShop` | Modify | Display shelves |
| `Workspace/Zones/WildGrove` | Modify | 2x expansion + decor |
| `Workspace/Zones/TradingPost` | Modify | Demand board + social area |
| `Workspace/Zones/IngredientMarket` | Modify | Fantasy polish |

## Definition of Done

- [ ] Brewed potions appear as visual vials on 3 fixed shelves
- [ ] Tier determines vial appearance (Common→Divine escalating visuals)
- [ ] Wild Grove is 240x240 with 12 themed forage nodes
- [ ] Wild Grove densely decorated with fantasy elements
- [ ] Market refresh announces Rare+ stock to all players
- [ ] Daily Demand Board visible as physical display in Trading Post
- [ ] All zones feel cohesive, magical, and fantasy-themed
- [ ] No regressions to existing gameplay

## Dependencies

- Sprint 003 (brew VFX, evolution tiers)
- Sprint 004 (59 ingredients, visual archetypes)
- Sprint 005 (92 recipes, mutations)
- Sprint 006 (scoring, daily demand, announcements)
