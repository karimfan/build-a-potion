# Sprint 005: Brewing Mastery — Full Recipe Matrix, Mutation System, Advanced Brewing

## Overview

Brewing is the soul of Brew a Potion — but right now 47 of 59 ingredients produce nothing but Sludge. This sprint implements 75 discoverable recipes across all tiers, from simple Common salves to Divine elixirs worth 75,000 coins. Every recipe tells a story through its ingredients: Dragon Scale + Frozen Amber creates Volcanic Frost (fire meets ice), Void Essence + Angel Feather produces Eclipse Elixir (darkness meets light).

The Mutation System adds a gambling layer to every brew. Any potion can mutate into Glowing (2x), Bubbling (2.5x), Crystallized (3x), Shadow (4x), Rainbow (6x), or Golden (10x) variants. Mutation chance scales with ingredient quality — base 5% plus tier and freshness bonuses. A Golden Mythic potion worth 150,000 coins is the ultimate flex. This directly mirrors Grow a Garden's mutation system.

3-ingredient advanced recipes unlock at 10 total brews (Tier 1 evolution milestone), creating a clear early progression goal. 4-ingredient recipes are explicitly deferred to a future sprint.

## Scope Anchors (Non-Negotiable)

1. **75 discoverable recipes** across 5 tiers (30 Common, 20 Uncommon, 15 Rare, 8 Mythic, 2 Divine)
2. **Mutation system**: 6 variants with 2x-10x sell multipliers, 2-stage server-side roll
3. **Mutation chance formula**: base 5% + tier bonuses + freshness bonus (capped at 20%)
4. **3-ingredient recipes unlock at 10 brews** (Tier 1 evolution)
5. **Every ingredient** in at least 2 non-sludge recipes
6. **Recipe Book** with tier tabs, discovery progress, element-based hints
7. **Compound potion keys** with `__` separator for mutations (potionId__mutation)
8. **No timer changes** — keep Sprint 003 values
9. **4-ingredient recipes explicitly deferred**
10. **No regressions** to existing 15 recipes or core loop

## Full Recipe Matrix (75 Recipes)

### Common Tier (30 Recipes) — 2 Common Ingredients

| # | Ingredient A | Ingredient B | Potion | Value |
|---|-------------|-------------|--------|-------|
| 1 | mushroom | river_water | Healing Salve | 25 |
| 2 | fern_leaf | river_water | Growth Potion | 30 |
| 3 | fern_leaf | mushroom | Forest Remedy | 20 |
| 4 | charcoal_chunk | river_water | Purification Elixir | 18 |
| 5 | charcoal_chunk | fern_leaf | Smoke Bomb Tonic | 22 |
| 6 | dandelion_puff | mint_sprig | Breeze Tonic | 28 |
| 7 | dandelion_puff | river_water | Cloud Essence | 15 |
| 8 | clay_mud | pebble_dust | Stoneskin Salve | 20 |
| 9 | clay_mud | river_water | Mudslide Brew | 12 |
| 10 | honey_drop | mushroom | Sweet Salve | 35 |
| 11 | honey_drop | mint_sprig | Refreshment Draught | 30 |
| 12 | pebble_dust | river_water | Grit Potion | 15 |
| 13 | mint_sprig | river_water | Cool Spring Tonic | 22 |
| 14 | firefly_glow | honey_drop | Lantern Brew | 40 |
| 15 | firefly_glow | dandelion_puff | Float Light | 32 |
| 16 | snail_slime | mushroom | Sticky Remedy | 18 |
| 17 | snail_slime | clay_mud | Golem Paste | 25 |
| 18 | willow_bark | river_water | Willow Tea | 22 |
| 19 | willow_bark | fern_leaf | Bark Shield Potion | 28 |
| 20 | rainwater | mint_sprig | Dewfall Tonic | 20 |
| 21 | rainwater | mushroom | Rain Brew | 16 |
| 22 | acorn_cap | pebble_dust | Seed Bomb | 25 |
| 23 | acorn_cap | fern_leaf | Sprout Serum | 22 |
| 24 | cobweb_strand | snail_slime | Shadow Thread Tonic | 30 |
| 25 | cobweb_strand | charcoal_chunk | Smoke Web Potion | 28 |
| 26 | charcoal_chunk | honey_drop | Ember Syrup | 35 |
| 27 | firefly_glow | cobweb_strand | Glow Trap Brew | 38 |
| 28 | clay_mud | willow_bark | Earthen Wall Tonic | 24 |
| 29 | pebble_dust | snail_slime | Grinding Paste | 18 |
| 30 | rainwater | dandelion_puff | Windshower Potion | 20 |

### Uncommon Tier (20 Recipes) — Uncommon+Common or Uncommon+Uncommon

| # | Ingredient A | Ingredient B | Potion | Value |
|---|-------------|-------------|--------|-------|
| 31 | moonpetal | honey_drop | Moonlight Nectar | 120 |
| 32 | moonpetal | cobweb_strand | Night Weaver Elixir | 140 |
| 33 | ember_root | charcoal_chunk | Flame Draught | 100 |
| 34 | ember_root | willow_bark | Smolder Salve | 90 |
| 35 | crystal_dust | pebble_dust | Diamond Dust Potion | 110 |
| 36 | crystal_dust | rainwater | Prismatic Elixir | 130 |
| 37 | frost_bloom | river_water | Permafrost Tonic | 100 |
| 38 | frost_bloom | mint_sprig | Arctic Breath Brew | 95 |
| 39 | thundermoss | dandelion_puff | Storm Bottle | 110 |
| 40 | thundermoss | pebble_dust | Lightning Rod Elixir | 90 |
| 41 | shadow_vine | cobweb_strand | Shadow Cloak Potion | 130 |
| 42 | shadow_vine | mushroom | Dark Growth Serum | 100 |
| 43 | sunstone_chip | firefly_glow | Solar Flare Tonic | 150 |
| 44 | sunstone_chip | charcoal_chunk | Magma Brew | 120 |
| 45 | dewdrop_pearl | snail_slime | Pearl Essence | 100 |
| 46 | iron_filings | clay_mud | Ironclad Tonic | 90 |
| 47 | pixie_wing | dandelion_puff | Fairy Flight Potion | 160 |
| 48 | glowshroom_cap | mushroom | Bioluminescence Brew | 120 |
| 49 | mermaid_scale | rainwater | Tidal Potion | 170 |
| 50 | nightshade_berry | honey_drop | Sweet Nightmare Elixir | 115 |

### Rare Tier (15 Recipes) — Rare+Uncommon, Rare+Rare, or 3-ingredient

| # | Ingredients | Potion | Value |
|---|-----------|--------|-------|
| 51 | dragon_scale + ember_root | Dragonheart Potion | 1200 |
| 52 | phoenix_feather + moonpetal | Rebirth Potion | 1500 |
| 53 | phoenix_feather + sunstone_chip | Solar Phoenix Elixir | 1800 |
| 54 | void_essence + shadow_vine | Abyssal Cloak Potion | 2000 |
| 55 | void_essence + nightshade_berry | Nightmare Fuel | 1600 |
| 56 | unicorn_tear + crystal_dust | Purification Supreme | 1800 |
| 57 | unicorn_tear + frost_bloom | Frozen Miracle | 2200 |
| 58 | stormglass_shard + thundermoss | Thunder God's Draught | 1500 |
| 59 | kraken_ink + mermaid_scale | Deep Sea Elixir | 1800 |
| 60 | lava_pearl + frozen_amber | Volcanic Frost | 2500 |
| 61 | ghost_orchid + cobweb_strand + moonpetal | Phantom Elixir | 2000 |
| 62 | titan_bone_dust + iron_filings | Titan Strength Brew | 1600 |
| 63 | basilisk_fang + snail_slime | Petrification Potion | 2000 |
| 64 | siren_song_echo + dewdrop_pearl | Enchantment Elixir | 1800 |
| 65 | eclipse_petal + celestial_dew | Twilight Serum | 2200 |

### Mythic Tier (8 Recipes) — Mythic+Rare or 3-ingredient with Mythic

| # | Ingredients | Potion | Value |
|---|-----------|--------|-------|
| 66 | starfall_shard + celestial_dew | Cosmic Elixir | 8000 |
| 67 | leviathan_tear + kraken_ink | Abyss Lord's Draught | 10000 |
| 68 | time_sand + stormglass_shard | Chrono Draught | 8500 |
| 69 | world_tree_bark + titan_bone_dust | Nature's Wrath | 9000 |
| 70 | demon_heart_ember + lava_pearl | Infernal Rage Potion | 12000 |
| 71 | abyssal_core + void_essence | Void Walker Elixir | 15000 |
| 72 | angel_feather + unicorn_tear + celestial_dew | Divine Grace | 12000 |
| 73 | primordial_flame + phoenix_feather | Eternal Flame Elixir | 13000 |

### Divine Tier (2 Recipes) — Divine + Mythic (3-ingredient)

| # | Ingredients | Potion | Value |
|---|-----------|--------|-------|
| 74 | philosophers_stone + world_tree_bark + primordial_flame | Transmutation Elixir | 50000 |
| 75 | cosmic_ember + starfall_shard + angel_feather | Wish Potion | 75000 |

## Mutation System

### Mutation Types

| Mutation | Sell Multiplier | Visual Effect | Base Weight |
|----------|----------------|---------------|-------------|
| Glowing | 2x | Soft ambient glow | 40% of mutations |
| Bubbling | 2.5x | Constant bubbles | 25% |
| Crystallized | 3x | Crystal formations | 15% |
| Shadow | 4x | Dark dripping aura | 10% |
| Rainbow | 6x | Shifting prismatic colors | 7% |
| Golden | 10x | Pure gold sparkle trail | 3% |

### Mutation Chance Formula (2-Stage Roll)

```
Stage 1: Does mutation occur?
  totalChance = baseMutationChance (5%)
    + sum(tierBonus per ingredient)
    + freshnessBonus
  totalChance = min(totalChance, mutationCap)  -- cap at 20%

  Tier bonuses: Common +0%, Uncommon +1%, Rare +2%, Mythic +3%, Divine +4%
  Freshness bonus: avgFreshness >= 0.85 → +1%, >= 0.65 → +0.5%, else +0%

Stage 2: Which mutation? (weighted random from type table)
  Roll against normalized weights: Glowing 40, Bubbling 25, Crystallized 15, Shadow 10, Rainbow 7, Golden 3
```

### Mutation Storage

Compound keys with `__` separator:
- Normal: `healing_salve` → count
- Mutated: `healing_salve__golden` → count

Parser helper: `parsePotionKey(key)` → `{ baseId, mutation }`

### Global Announcements
- **Rainbow mutation**: Server-wide announcement
- **Golden mutation**: Server-wide announcement with special formatting
- **Divine recipe discovery**: Server-wide legendary announcement

## Architecture

### Recipe Lookup (2 and 3 Ingredients)

```lua
function Recipes.lookup(...)
    local ids = {...}
    table.sort(ids)
    local key = table.concat(ids, "|")
    return Recipes.Data[key]  -- returns potionId or nil (nil = sludge)
end
```

### 3-Ingredient Unlock Gate

```lua
-- In BrewingService, before accepting 3rd ingredient:
if #ingredients == 3 and data.BrewStats.TotalBrewed < 10 then
    return { success = false, error = "Unlock 3-ingredient brewing at 10 total brews!" }
end
```

### Brew Flow with Mutations

```
Client: Select 2-3 ingredients → Brew
  → Server: BrewPotion(ing1, ing2, [ing3])
     1. Validate ownership, 3-ingredient gate
     2. Consume ingredients (FIFO stacks)
     3. Resolve recipe → potionId (or sludge)
     4. Set ActiveBrew with timer (keep Sprint 003 timers)
     5. Return brew info

On Claim:
     6. Roll mutation (2-stage: occurs? → which type?)
     7. Generate final potion key (potionId or potionId__mutation)
     8. Grant to inventory
     9. Update stats, check discovery
     10. Fire announcements if applicable
     11. Return result with mutation info
```

## Implementation Plan

### Phase 1: Recipe + Potion Data Expansion (~30%)

**Files:**
- `src/shared/Config/Recipes.lua` — 75 recipes
- `src/shared/Config/Potions.lua` — 75 potions + sludge

**Tasks:**
- [ ] Add all 75 recipes with canonical sorted keys
- [ ] Add 60 new potion definitions to Potions.lua (keep existing 15)
- [ ] Support 2 and 3 ingredient keys in Recipes.lookup()
- [ ] Add validation helper: every ingredient in >=2 recipes, every recipe→valid potion
- [ ] Add Recipes.getRecipeCountByTier() helper

### Phase 2: Mutation System (~20%)

**Files:**
- `src/shared/Config/MutationTuning.lua` (new)
- `src/server/Services/BrewingService.lua`
- `src/server/Services/EconomyService.lua`

**Tasks:**
- [ ] Create MutationTuning config: 6 types, weights, multipliers, base chance, cap, tier bonuses
- [ ] Implement 2-stage mutation roll in BrewingService ClaimBrewResult
- [ ] Mutation chance = base + tierBonus + freshnessBonus, capped at 20%
- [ ] Generate compound potion key (potionId__mutation)
- [ ] Update EconomyService sell flow: parse compound key, apply base * multiplier
- [ ] Add parsePotionKey() helper to shared Types or Potions module
- [ ] Fire global announcements for Rainbow/Golden mutations

### Phase 3: 3-Ingredient Support + Unlock Gate (~15%)

**Files:**
- `src/server/Services/BrewingService.lua`
- `src/client/InteractionController.client.lua`

**Tasks:**
- [ ] Update BrewPotion remote to accept optional 3rd ingredient
- [ ] Enforce unlock gate: reject 3rd ingredient if TotalBrewed < 10
- [ ] Update ingredient consumption for 3 ingredients (FIFO stacks)
- [ ] Add Slot 3 to CauldronGui (locked state with "Unlock at 10 brews" text)
- [ ] Show unlock celebration when player reaches 10 brews

### Phase 4: Recipe Book Enhancement (~15%)

**Files:**
- `src/client/InteractionController.client.lua`

**Tasks:**
- [ ] Show "X/75 Recipes Discovered" prominently
- [ ] Add tier tabs: All / Common / Uncommon / Rare / Mythic / Divine
- [ ] Discovered recipes: full info (ingredients, potion, value, tier)
- [ ] Undiscovered recipes: element-based hints ("??? = [Fire] + [Water]")
- [ ] Mutation discoveries tracked separately
- [ ] Per-tier completionist progress bar

### Phase 5: Discovery + Mutation VFX (~10%)

**Files:**
- `src/client/BrewVFXController.client.lua`
- `src/client/FeedbackController.client.lua`

**Tasks:**
- [ ] Mutation-specific completion VFX accents (glow / bubbles / crystals / dark / rainbow / gold)
- [ ] Rare+ discovery: bigger fireworks, banner, screen shake
- [ ] Mythic discovery: dramatic camera zoom, full-screen overlay
- [ ] Divine discovery: server-wide announcement, legendary animation
- [ ] Mutation badge in result card: "GOLDEN Healing Salve! (10x value!)"

### Phase 6: Validation (~5%)

**Tasks:**
- [ ] Run validation script: all 75 recipes resolve, all ingredients in >=2 recipes
- [ ] Verify 3-ingredient gate works pre/post 10 brews
- [ ] Simulate 10,000 mutation rolls, verify distribution matches weights
- [ ] Test sell values: base * mutation multiplier
- [ ] Verify existing 15 recipes still work
- [ ] Test compound key parsing in all inventory displays
- [ ] Mobile check: 3 slots fit, recipe book scrolls

## Files Summary

| File | Action | Purpose |
|------|--------|---------|
| `src/shared/Config/Recipes.lua` | Rewrite | 75 recipes with 2/3 ingredient support |
| `src/shared/Config/Potions.lua` | Rewrite | 75 potions + sludge with sell values |
| `src/shared/Config/MutationTuning.lua` | Create | Mutation types, weights, bonuses, cap |
| `src/server/Services/BrewingService.lua` | Modify | 3-ingredient support, mutation rolls, unlock gate |
| `src/server/Services/EconomyService.lua` | Modify | Compound key sell pricing |
| `src/client/InteractionController.client.lua` | Modify | 3rd slot, recipe book tabs, mutation display |
| `src/client/BrewVFXController.client.lua` | Modify | Mutation-specific VFX |
| `src/client/FeedbackController.client.lua` | Modify | Discovery/mutation celebration |

## Definition of Done

- [ ] 75 recipes discoverable across 5 tiers (30/20/15/8/2)
- [ ] Every ingredient in at least 2 non-sludge recipes (validated by script)
- [ ] 3-ingredient recipes locked before 10 brews, unlocked after
- [ ] 6 mutation types with correct weights and sell multipliers
- [ ] Mutation chance = base 5% + tier bonuses + freshness bonus (capped 20%)
- [ ] 2-stage mutation roll (occurs? → which type?)
- [ ] Compound potion keys work in inventory, sell, and display
- [ ] Rainbow/Golden mutations trigger global announcements
- [ ] Recipe Book shows X/75 progress with tier tabs and element hints
- [ ] Existing 15 recipes still work (no regressions)
- [ ] Sell values = base * mutation multiplier
- [ ] Sprint 003 brew timers unchanged
- [ ] Mobile UI works with 3 ingredient slots

## Risks & Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| 75 recipes = lots of data entry | High | Medium | Batch script creation, systematic naming |
| Compound keys break existing inventory UI | Medium | High | parsePotionKey() helper, update all readers |
| Mutation math stacking too high | Medium | Medium | Hard cap at 20%, test with simulation |
| Recipe ID typos cause silent Sludge | Medium | High | Validation script as hard gate |
| 3-slot UI crowding on mobile | Medium | Medium | Progressive reveal, compact layout |

## Security Considerations

- Mutation rolls are server-side only (client cannot influence)
- 3-ingredient unlock gate server-enforced
- Sell multiplier computed server-side from compound key
- Recipe resolution server-authoritative

## Dependencies

- Sprint 003 (timed brewing, evolution milestones)
- Sprint 004 (59-ingredient catalog, freshness stacks)
