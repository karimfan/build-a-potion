# Sprint 005: Brewing Mastery — Full Recipe Matrix, Mutation System, Multi-Ingredient Combos

## Overview

Brewing is the soul of Brew a Potion — but right now 47 of 59 ingredients produce nothing but Sludge. This sprint designs and implements 75 discoverable recipes across all tiers, from simple Common salves any new player can stumble into, to Mythic elixirs that require rare ingredients and create TikTok-worthy moments. Every recipe tells a story through its ingredients: combine Dragon Scale + Frozen Amber and you get Volcanic Frost (fire meets ice), mix Void Essence + Angel Feather for Eclipse Elixir (darkness meets light).

The Mutation System adds a layer of excitement to every brew. Any potion has a chance to mutate into a variant — Glowing, Bubbling, Crystallized, Shadow, Rainbow, or Golden — with sell value multiplied 2x-10x. This directly mirrors Grow a Garden's mutation system that drives billions of visits. A Golden Mythic potion is the ultimate flex.

This sprint also expands brewing from 2-ingredient combos to support 3-ingredient advanced recipes, adds the full mutation system, and enhances the Recipe Book to show discovered/undiscovered recipes with element-based hints.

## Scope Anchors (Non-Negotiable)

1. **75 discoverable recipes** across 5 tiers using all 59 ingredients
2. **Mutation system** with 6 variants and 2x-10x sell multipliers
3. **3-ingredient recipe support** unlocked at 10 brews (Tier 1 evolution milestone)
4. **Every ingredient participates** in at least 2 recipes
5. **Recipe Book enhancement** with discovery count, hints, tier filtering
6. **No regressions** to existing 15 recipes or core loop

## Recipe Design Philosophy

### Tier Rules
- **Common potions** (30 recipes): 2 Common ingredients. Easy to discover, low value. The "tutorial" recipes.
- **Uncommon potions** (20 recipes): 1 Uncommon + 1 Common, or 2 Uncommon ingredients. Medium value, require market luck.
- **Rare potions** (15 recipes): 1 Rare + 1 Uncommon, or 2 Rare ingredients, or 3-ingredient combos. High value, bragging rights.
- **Mythic potions** (8 recipes): 1 Mythic + 1 Rare, or 3-ingredient combos with Mythic. Extreme value, TikTok moments.
- **Divine potions** (2 recipes): Divine + Mythic ingredient. Legendary flex, screenshot-worthy.

### Element Synergy
- **Same element** combos tend to amplify (Fire+Fire = intense fire potion)
- **Opposing elements** create unique hybrid potions (Fire+Water = steam/frost)
- **Light+Shadow** combos produce the most dramatic effects (eclipse, twilight)

## Full Recipe Matrix (75 Recipes)

### Common Tier (30 Recipes) — 2 Common Ingredients

| # | Ingredient A | Ingredient B | Potion Name | Sell Value | Description |
|---|-------------|-------------|-------------|------------|-------------|
| 1 | Mushroom | River Water | Healing Salve | 25 | Soothes minor wounds |
| 2 | Fern Leaf | River Water | Growth Potion | 30 | Makes plants sprout |
| 3 | Fern Leaf | Mushroom | Forest Remedy | 20 | Natural forest cure |
| 4 | Charcoal Chunk | River Water | Purification Elixir | 18 | Cleanses impurities |
| 5 | Charcoal Chunk | Fern Leaf | Smoke Bomb Tonic | 22 | Creates a cloud of smoke |
| 6 | Dandelion Puff | Mint Sprig | Breeze Tonic | 28 | Grants feeling of lightness |
| 7 | Dandelion Puff | River Water | Cloud Essence | 15 | Fluffy, weightless liquid |
| 8 | Clay Mud | Pebble Dust | Stoneskin Salve | 20 | Hardens skin temporarily |
| 9 | Clay Mud | River Water | Mudslide Brew | 12 | Slippery but useful |
| 10 | Honey Drop | Mushroom | Sweet Salve | 35 | Tasty healing mixture |
| 11 | Honey Drop | Mint Sprig | Refreshment Draught | 30 | Instantly refreshing |
| 12 | Pebble Dust | River Water | Grit Potion | 15 | Makes you tougher |
| 13 | Mint Sprig | River Water | Cool Spring Tonic | 22 | Refreshing and crisp |
| 14 | Firefly Glow | Honey Drop | Lantern Brew | 40 | Glows for hours |
| 15 | Firefly Glow | Dandelion Puff | Float Light | 32 | Tiny floating lamp |
| 16 | Snail Slime | Mushroom | Sticky Remedy | 18 | Binds wounds together |
| 17 | Snail Slime | Clay Mud | Golem Paste | 25 | Animates small objects |
| 18 | Willow Bark | River Water | Willow Tea | 22 | Calming natural brew |
| 19 | Willow Bark | Fern Leaf | Bark Shield Potion | 28 | Tough woody defense |
| 20 | Rainwater | Mint Sprig | Dewfall Tonic | 20 | Purest refreshment |
| 21 | Rainwater | Mushroom | Rain Brew | 16 | Summons light drizzle |
| 22 | Acorn Cap | Pebble Dust | Seed Bomb | 25 | Explodes into plants |
| 23 | Acorn Cap | Fern Leaf | Sprout Serum | 22 | Accelerates growth |
| 24 | Cobweb Strand | Snail Slime | Shadow Thread Tonic | 30 | Creates shadow bindings |
| 25 | Cobweb Strand | Charcoal Chunk | Smoke Web Potion | 28 | Trapping smoke net |
| 26 | Charcoal Chunk | Honey Drop | Ember Syrup | 35 | Sweet and fiery |
| 27 | Firefly Glow | Cobweb Strand | Glow Trap Brew | 38 | Luminous web trap |
| 28 | Clay Mud | Willow Bark | Earthen Wall Tonic | 24 | Raises earth barrier |
| 29 | Pebble Dust | Snail Slime | Grinding Paste | 18 | Polishes anything |
| 30 | Rainwater | Dandelion Puff | Windshower Potion | 20 | Calls wind and rain |

### Uncommon Tier (20 Recipes) — Uncommon+Common or Uncommon+Uncommon

| # | Ingredient A | Ingredient B | Potion Name | Sell Value | Description |
|---|-------------|-------------|-------------|------------|-------------|
| 31 | Moonpetal | Honey Drop | Moonlight Nectar | 120 | Glows silver, calms emotions |
| 32 | Moonpetal | Cobweb Strand | Night Weaver Elixir | 140 | See in complete darkness |
| 33 | Ember Root | Charcoal Chunk | Flame Draught | 100 | Burns from within |
| 34 | Ember Root | Willow Bark | Smolder Salve | 90 | Slow-burning healing |
| 35 | Crystal Dust | Pebble Dust | Diamond Dust Potion | 110 | Crystalline clarity |
| 36 | Crystal Dust | Rainwater | Prismatic Elixir | 130 | Refracts all light |
| 37 | Frost Bloom | River Water | Permafrost Tonic | 100 | Freezes anything it touches |
| 38 | Frost Bloom | Mint Sprig | Arctic Breath Brew | 95 | Breathe ice |
| 39 | Thundermoss | Dandelion Puff | Storm Bottle | 110 | Bottled thunderstorm |
| 40 | Thundermoss | Pebble Dust | Lightning Rod Elixir | 90 | Attracts electricity |
| 41 | Shadow Vine | Cobweb Strand | Shadow Cloak Potion | 130 | Become one with shadows |
| 42 | Shadow Vine | Mushroom | Dark Growth Serum | 100 | Grows shadow plants |
| 43 | Sunstone Chip | Firefly Glow | Solar Flare Tonic | 150 | Blindingly bright |
| 44 | Sunstone Chip | Charcoal Chunk | Magma Brew | 120 | Molten heat potion |
| 45 | Dewdrop Pearl | Snail Slime | Pearl Essence | 100 | Lustrous beauty potion |
| 46 | Iron Filings | Clay Mud | Ironclad Tonic | 90 | Metallic defense |
| 47 | Pixie Wing | Dandelion Puff | Fairy Flight Potion | 160 | Temporary levitation |
| 48 | Glowshroom Cap | Mushroom | Bioluminescence Brew | 120 | Skin glows for hours |
| 49 | Mermaid Scale | Rainwater | Tidal Potion | 170 | Control water currents |
| 50 | Nightshade Berry | Honey Drop | Sweet Nightmare Elixir | 115 | Vivid dream inducer |

### Rare Tier (15 Recipes) — Rare+Uncommon, Rare+Rare, or 3-ingredient

| # | Ingredients | Potion Name | Sell Value | Description |
|---|-----------|-------------|------------|-------------|
| 51 | Dragon Scale + Ember Root | Dragonheart Potion | 1200 | Courage and power of a dragon |
| 52 | Phoenix Feather + Moonpetal | Rebirth Potion | 1500 | Legendary renewal elixir |
| 53 | Phoenix Feather + Sunstone Chip | Solar Phoenix Elixir | 1800 | Rebirth through sunfire |
| 54 | Void Essence + Shadow Vine | Abyssal Cloak Potion | 2000 | Complete shadow immersion |
| 55 | Void Essence + Nightshade Berry | Nightmare Fuel | 1600 | Weaponized darkness |
| 56 | Unicorn Tear + Crystal Dust | Purification Supreme | 1800 | Cures any ailment |
| 57 | Unicorn Tear + Frost Bloom | Frozen Miracle | 2200 | Time-stopping ice |
| 58 | Stormglass Shard + Thundermoss | Thunder God's Draught | 1500 | Command lightning |
| 59 | Kraken Ink + Mermaid Scale | Deep Sea Elixir | 1800 | Breathe underwater forever |
| 60 | Lava Pearl + Frozen Amber | Volcanic Frost | 2500 | Fire and ice collide |
| 61 | Ghost Orchid + Cobweb Strand + Moonpetal | Phantom Elixir | 2000 | Phase through walls |
| 62 | Titan Bone Dust + Iron Filings | Titan Strength Brew | 1600 | Colossal power |
| 63 | Basilisk Fang + Snail Slime | Petrification Potion | 2000 | Turns things to stone |
| 64 | Siren Song Echo + Dewdrop Pearl | Enchantment Elixir | 1800 | Irresistible charm |
| 65 | Eclipse Petal + Celestial Dew | Twilight Serum | 2200 | Power of the eclipse |

### Mythic Tier (8 Recipes) — Mythic+Rare or 3-ingredient with Mythic

| # | Ingredients | Potion Name | Sell Value | Description |
|---|-----------|-------------|------------|-------------|
| 66 | Starfall Shard + Celestial Dew | Cosmic Elixir | 8000 | Grants cosmic awareness |
| 67 | Leviathan Tear + Kraken Ink | Abyss Lord's Draught | 10000 | Command the deep seas |
| 68 | Time Sand + Stormglass Shard | Chrono Draught | 8500 | Slow time briefly |
| 69 | World Tree Bark + Titan Bone Dust | Nature's Wrath | 9000 | Earthquake in a bottle |
| 70 | Demon Heart Ember + Lava Pearl | Infernal Rage Potion | 12000 | Unstoppable fury |
| 71 | Abyssal Core + Void Essence | Void Walker Elixir | 15000 | Step between dimensions |
| 72 | Angel Feather + Unicorn Tear + Celestial Dew | Divine Grace | 12000 | Pure heavenly blessing |
| 73 | Primordial Flame + Phoenix Feather | Eternal Flame Elixir | 13000 | Fire that never dies |

### Divine Tier (2 Recipes) — Divine + Mythic

| # | Ingredients | Potion Name | Sell Value | Description |
|---|-----------|-------------|------------|-------------|
| 74 | Philosopher's Stone + World Tree Bark + Primordial Flame | Transmutation Elixir | 50000 | Transform any material |
| 75 | Cosmic Ember + Starfall Shard + Angel Feather | Wish Potion | 75000 | Grants one wish |

## Mutation System

### Mutation Types

| Mutation | Sell Multiplier | Visual Effect | Rarity |
|----------|----------------|---------------|--------|
| Glowing | 2x | Soft ambient glow around potion | 8% chance |
| Bubbling | 2.5x | Constantly producing bubbles | 6% chance |
| Crystallized | 3x | Crystal formations on surface | 4% chance |
| Shadow | 4x | Dark aura, dripping shadows | 3% chance |
| Rainbow | 6x | Shifting rainbow colors | 1.5% chance |
| Golden | 10x | Pure gold with sparkle trail | 0.5% chance |

### Mutation Rules
- Base mutation chance: 5% per brew
- Higher tier ingredients increase mutation chance (+1% per Uncommon, +2% per Rare, +3% per Mythic)
- Freshness > 0.8 adds +1% mutation chance
- Golden mutation is the "golden carrot" — a Golden Mythic potion is worth 150,000 coins
- Mutations are determined server-side at brew completion (not start)
- Mutations are visible in inventory and on the sell screen

### Data Model

```lua
-- Potion inventory with mutation support
Potions = {
    [potionId] = {
        { mutation = nil, count = 1 },        -- normal
        { mutation = "Golden", count = 1 },   -- mutated
    }
}

-- Or simpler: potionId_mutation as compound key
Potions = {
    ["healing_salve"] = 3,
    ["healing_salve_golden"] = 1,
    ["dragonheart_potion_rainbow"] = 1,
}
```

## Architecture

### Recipe Lookup (Supports 2 and 3 Ingredients)

```lua
-- Key format: sorted ingredient IDs joined by "|"
-- 2 ingredients: "ingredient_a|ingredient_b"
-- 3 ingredients: "ingredient_a|ingredient_b|ingredient_c"

Recipes.lookup = function(...)
    local ids = {...}
    table.sort(ids)
    local key = table.concat(ids, "|")
    return Recipes.Data[key]
end
```

### Brew Flow Update

```
Client: Select 2-3 ingredients → Click Brew
  → Server: BrewPotion(ingredient1, ingredient2, [ingredient3])
     1. Validate ingredients owned
     2. Consume ingredients (FIFO stacks)
     3. Resolve recipe (2 or 3 ingredient lookup)
     4. Roll mutation chance
     5. Set ActiveBrew with timer
     6. Return brew info + mutation preview (hidden until completion)

On Claim:
     7. Grant potion (with mutation if rolled)
     8. Update stats
     9. Discovery + mutation celebration VFX
```

### CauldronGui Update

```
┌─────────────────────────┐
│     CAULDRON             │
│                          │
│  [Slot 1] + [Slot 2]    │
│        + [Slot 3]        │  ← Optional 3rd slot
│                          │
│  Your Ingredients:       │
│  [grid of ingredients]   │
│                          │
│      [ BREW ]            │
└─────────────────────────┘
```

## Implementation Plan

### Phase 1: Full Recipe Matrix + Expanded Potions Catalog (~30%)

**Files:**
- `src/shared/Config/Recipes.lua` — 75 recipes (up from 15)
- `src/shared/Config/Potions.lua` — 75 potions (up from 16)

**Tasks:**
- [ ] Add all 30 Common recipes
- [ ] Add all 20 Uncommon recipes
- [ ] Add all 15 Rare recipes (including 3-ingredient ones)
- [ ] Add all 8 Mythic recipes (including 3-ingredient ones)
- [ ] Add 2 Divine recipes (3-ingredient)
- [ ] Add corresponding 60 new potion definitions to Potions.lua
- [ ] Update Recipes.lookup() to support 2 and 3 ingredient keys
- [ ] Add Recipes.getRecipeCountByTier() helper
- [ ] Verify every ingredient appears in at least 2 recipes

### Phase 2: Mutation System (~20%)

**Files:**
- `src/shared/Config/MutationTuning.lua` (new) — Mutation types, chances, multipliers
- `src/server/Services/BrewingService.lua` — Mutation roll at brew completion
- `src/shared/Config/Potions.lua` — Add mutation metadata

**Tasks:**
- [ ] Create MutationTuning config with 6 mutation types, base chances, and sell multipliers
- [ ] Add mutation roll logic to BrewingService ClaimBrewResult
- [ ] Mutation chance = baseMutationChance + ingredientTierBonus + freshnessBonus
- [ ] Store mutation in brew result and player inventory
- [ ] Update potion inventory to track mutations (compound key: potionId_mutation)
- [ ] Add mutation to sell value calculation in EconomyService
- [ ] Global announcement for Rainbow and Golden mutations

### Phase 3: 3-Ingredient Support (~15%)

**Files:**
- `src/server/Services/BrewingService.lua` — Support optional 3rd ingredient
- `src/client/InteractionController.client.lua` — Add 3rd ingredient slot to CauldronGui

**Tasks:**
- [ ] Update BrewPotion remote to accept optional 3rd ingredient
- [ ] Update ingredient validation and consumption for 3 ingredients
- [ ] Add Slot 3 to CauldronGui (optional, appears when 2 slots filled)
- [ ] Update freshness calculation for 3-ingredient average
- [ ] Recipe lookup with sorted 3-ingredient key

### Phase 4: Recipe Book Enhancement (~15%)

**Files:**
- `src/client/InteractionController.client.lua` — Recipe book UI overhaul

**Tasks:**
- [ ] Show total discovery count prominently (e.g., "12/75 Recipes Discovered")
- [ ] Organize recipes by tier tabs (Common / Uncommon / Rare / Mythic / Divine)
- [ ] Discovered recipes show full info: ingredients, potion name, sell value, tier
- [ ] Undiscovered recipes show element hints: "??? = [Fire] + [Water]"
- [ ] Add "completionist" progress bar per tier
- [ ] Mutation discoveries show separately (e.g., "Golden Healing Salve")

### Phase 5: Enhanced Discovery + Mutation VFX (~15%)

**Files:**
- `src/client/BrewVFXController.client.lua` — Mutation-specific completion VFX
- `src/client/InteractionController.client.lua` — Discovery celebration UI

**Tasks:**
- [ ] Different completion VFX per mutation type:
  - Glowing: soft expanding glow
  - Bubbling: bubble cascade
  - Crystallized: crystal burst
  - Shadow: dark implosion
  - Rainbow: prismatic light show
  - Golden: gold explosion with coin particles
- [ ] Rare recipe discovery: bigger fireworks, screen shake, banner
- [ ] Mythic recipe discovery: dramatic camera zoom, music sting, full-screen overlay
- [ ] Divine recipe discovery: server-wide announcement, legendary animation
- [ ] Mutation result shown in claim UI: "GOLDEN Healing Salve! (10x value!)"

### Phase 6: Brew Timer Updates (~5%)

**Tasks:**
- [ ] Update brew timers per GDD: Common 60-90s, Uncommon 90-120s, Rare 120-300s, Mythic 300-600s, Divine 600s
- [ ] Timer shown in UI reflects actual potion tier (not just ingredient rarity)
- [ ] Higher-tier outcomes have proportionally longer timers

### Phase 7: Integration Testing (~5%)

**Tasks:**
- [ ] Verify all 75 recipes produce correct potions
- [ ] Verify 3-ingredient recipes work
- [ ] Test mutation system: run 1000 simulated brews, verify mutation distribution
- [ ] Test sell values with mutations (base * mutation_multiplier)
- [ ] Verify recipe book shows correct discovered/undiscovered counts
- [ ] Test all existing 15 recipes still work
- [ ] Mobile check: 3 ingredient slots fit on screen

## Files Summary

| File | Action | Purpose |
|------|--------|---------|
| `src/shared/Config/Recipes.lua` | Rewrite | 75 recipes with 2 and 3 ingredient support |
| `src/shared/Config/Potions.lua` | Rewrite | 75+ potions with sell values and descriptions |
| `src/shared/Config/MutationTuning.lua` | Create | 6 mutation types, chances, multipliers |
| `src/shared/Config/BrewTuning.lua` | Modify | Updated tier-based brew timers |
| `src/server/Services/BrewingService.lua` | Modify | 3-ingredient support, mutation rolls |
| `src/server/Services/EconomyService.lua` | Modify | Mutation-aware sell values |
| `src/client/InteractionController.client.lua` | Modify | 3rd slot, recipe book tabs, mutation display |
| `src/client/BrewVFXController.client.lua` | Modify | Mutation-specific completion VFX |

## Definition of Done

- [ ] 75 recipes in catalog across 5 tiers (30/20/15/8/2)
- [ ] Every ingredient participates in at least 2 recipes
- [ ] 3-ingredient recipes work for Rare+ tier
- [ ] Mutation system with 6 variants and correct sell multipliers
- [ ] Mutation chance scales with ingredient tier and freshness
- [ ] Golden and Rainbow mutations trigger global announcements
- [ ] Recipe book shows discovery progress by tier with element hints
- [ ] Discovery VFX appropriate for potion tier
- [ ] Mutation VFX distinct per mutation type
- [ ] Existing 15 recipes still work correctly
- [ ] Brew timers match potion tier
- [ ] All potions sellable with correct base + mutation values

## Risks & Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| 75 recipes is a lot of data entry | High | Medium | Use systematic naming, batch creation scripts |
| 3-ingredient recipe lookup complexity | Medium | Medium | Sorted key concatenation, same pattern as 2-ingredient |
| Mutation compound keys bloat inventory | Medium | Low | Use simple string suffix (potionId_mutation) |
| Recipe balance issues (some too easy/hard) | Medium | Medium | Playtest and tune sell values; weekly recipe additions |
| Recipe book UI cluttered with 75 entries | Medium | Medium | Tier tabs + pagination + search |

## Open Questions

1. Should mutation chance be affected by weather/time of day (future feature)?
2. Should 4-ingredient recipes be reserved for a future "Master Cauldron" upgrade?
3. Should recipe hints be element-based ("Fire + Water = ???") or ingredient-count based ("2 ingredients, one Common")?
