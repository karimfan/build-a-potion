# Sprint 007: Zone Overhaul — Fantasy World, Potion Displays, Daily Demand, Expanded Wild Grove

## Overview

Sprint 007 transforms all 4 zones from functional spaces into immersive fantasy environments. The centerpiece is the **Potion Display System**: every time you brew a potion, a physical vial/bottle appears on your shop shelves. Your shop tells the story of your brewing journey — a shelf full of colorful, glowing potions is the ultimate flex. Rare and Mythic potions get elaborate displays with particle effects.

The **Wild Grove doubles in size** with dense fantasy decoration — enchanted trees, glowing pools, crystal formations, mysterious ruins. More forage nodes with better variety. The **Ingredient Market** gets a proper cozy market aesthetic with new-stock announcements. The **Trading Post** gets a physical Daily Demand Board and social hub energy.

## Scope Anchors

1. **Potion Display System** — brewed potions appear as visual vials on shop shelves
2. **Wild Grove 2x expansion** — 240x240 floor, 12+ forage nodes, dense fantasy decor
3. **Market refresh announcements** — server-wide notification when market restocks
4. **Daily Demand Board** — physical display in Trading Post zone
5. **Fantasy theme** throughout all zones — magical, bold, colorful

## Implementation Plan

### Phase 1: Potion Display System (~25%)

When a potion is brewed, a visual vial/bottle appears on a display shelf in YourShop.

**Mechanics:**
- Shop has 3 display shelves (left wall, right wall, back wall)
- Each shelf holds up to 10 potion displays
- Potion displays are colored vials matching the potion tier:
  - Common: simple glass vial, subtle color
  - Uncommon: glass vial with glow
  - Rare: ornate bottle with particle effect
  - Mythic: elaborate crystal bottle with aura
  - Divine: floating golden vial with dramatic particles
- Mutated potions have their mutation visual (Golden = gold material, Rainbow = color shift)
- Display persists across sessions (stored in player data)

**Files:**
- `src/server/Services/BrewingService.lua` — Add potion to display list on brew claim
- `src/client/PotionDisplayController.client.lua` (new) — Renders potion displays in shop
- `src/shared/Config/PotionDisplayTuning.lua` (new) — Display visual configs per tier
- `Workspace/Zones/YourShop` — Add 3 display shelf structures

**Tasks:**
- [ ] Create 3 display shelf Parts in YourShop (wooden shelves on walls)
- [ ] Create PotionDisplayTuning config with visual descriptor per tier
- [ ] Create PotionDisplayController that reads player's brewed potions and renders vials
- [ ] Each vial is a Part with Material/Color based on potion tier + ParticleEmitter for Rare+
- [ ] Add `PotionDisplays` array to player data (list of {potionId, mutation, brewedUnix})
- [ ] Cap at 30 displayed potions (3 shelves x 10 each)
- [ ] On brew claim, add to PotionDisplays and render new vial
- [ ] Mutation variants: Golden=Metal material, Rainbow=Neon cycling, Shadow=dark aura

### Phase 2: Wild Grove 2x Expansion (~25%)

Double the Wild Grove from 120x120 to 240x240 with dense fantasy decoration.

**Tasks:**
- [ ] Expand WildGrove floor from 120x120 to 240x240
- [ ] Update WildGrove SpawnPoint and boundaries for new size
- [ ] Add 6 more forage nodes (total 12) with themed pools:
  - Enchanted Mushroom Glade (mushroom, willow bark, snail slime)
  - Crystal Stream (river water, rainwater, dewdrop pearl)
  - Herb Garden (fern leaf, mint sprig, dandelion puff)
  - Shadow Nook (cobweb strand, charcoal chunk, nightshade berry)
  - Ancient Tree (acorn cap, willow bark, pebble dust)
  - Mystic Pool (honey drop, firefly glow, clay mud)
- [ ] Insert dense fantasy decoration:
  - Giant fantasy mushroom clusters (3-4 groups)
  - Crystal formations with colored glow
  - Ancient stone ruins/archways
  - Enchanted trees (pink, purple, blue-green)
  - Glowing pools/ponds with mist
  - Vine-covered rock formations
  - Firefly particle systems
  - Fairy light strings between trees
- [ ] Add ambient mystical fog across the expanded area
- [ ] Add mystical ambient lighting (colored spotlights in tree canopy)

### Phase 3: Market Refresh Announcements (~10%)

**Tasks:**
- [ ] On market refresh (every 5 min), fire GlobalAnnouncement with stock highlights
- [ ] Message format: "Market refreshed! New stock: [Rare Ingredient Name] and [X] more items!"
- [ ] Only announce if Rare+ ingredients appeared
- [ ] Show announcement banner for all players

### Phase 4: Daily Demand Board in Trading Post (~15%)

**Tasks:**
- [ ] Create a physical Demand Board in TradingPost zone (large wooden board with SurfaceGui)
- [ ] Board shows 3 demand potions with names, multipliers, and "HOT!" badges
- [ ] Board updates at UTC midnight (via DailyDemandService)
- [ ] Glowing frame around the board to attract attention
- [ ] When selling a demand potion, show bonus "+3x DEMAND BONUS!" feedback
- [ ] Add seating/social area near the board (benches, tables)

### Phase 5: Trading Post & Market Zone Polish (~15%)

**Tasks:**
- [ ] Trading Post:
  - Add treasure display shelves (show coin piles, gold props)
  - Add social seating area with benches and tables
  - Add warm fireplace/brazier
  - Improve lighting (golden/warm theme)
  - Add "Trading Post" sign with golden text
- [ ] Ingredient Market:
  - Add hanging herb bundles from stall roofs
  - Add colorful banner/awning decorations
  - Add NPC merchant figure (static model) at the stall
  - Add floating ingredient samples near stalls (visual only)
  - Improve lantern lighting (warm orange, more lanterns)

### Phase 6: Integration + Testing (~10%)

**Tasks:**
- [ ] Verify potion displays appear on brew and persist
- [ ] Verify Wild Grove expanded with all 12 forage nodes working
- [ ] Verify market announcements fire on refresh with Rare+ items
- [ ] Verify Daily Demand Board visible in Trading Post
- [ ] Walk through all 4 zones — visual quality check
- [ ] No regressions to buy/brew/sell/forage

## Files Summary

| File | Action | Purpose |
|------|--------|---------|
| `src/client/PotionDisplayController.client.lua` | Create | Render potion vials in shop |
| `src/shared/Config/PotionDisplayTuning.lua` | Create | Display visual configs per tier |
| `src/server/Services/BrewingService.lua` | Modify | Add to PotionDisplays on claim |
| `src/server/Services/MarketService.lua` | Modify | Fire announcement on refresh |
| `src/server/Services/DailyDemandService.lua` | Modify | Update TradingPost board |
| `Workspace/Zones/YourShop` | Modify | Add display shelves, wizard lair polish |
| `Workspace/Zones/WildGrove` | Modify | 2x expansion, dense fantasy decor |
| `Workspace/Zones/TradingPost` | Modify | Demand Board, social area |
| `Workspace/Zones/IngredientMarket` | Modify | Herbs, banners, NPC, lanterns |

## Definition of Done

- [ ] Brewed potions appear as visual vials on shop shelves
- [ ] Rare+ potions have glow/particle effects on display
- [ ] Wild Grove is 240x240 with 12 forage nodes
- [ ] Wild Grove is densely decorated with fantasy theme
- [ ] Market refresh triggers announcement for Rare+ stock
- [ ] Daily Demand Board visible in Trading Post as physical world object
- [ ] All 4 zones feel cohesive, magical, and fantasy-themed
- [ ] No regressions to existing gameplay
