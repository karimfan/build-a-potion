# Sprint 004: Ingredient Market Overhaul — Full Catalog, Visual Sorcery, Freshness & Affinity

## Overview

The ingredient market is the engine of urgency in Brew a Potion — the 5-minute refresh cycle that makes players check back, the rare Mythic ingredient that makes them gasp, the visual feast that makes them screenshot. Right now it's 12 text labels in a dark box. The GDD defines 58 ingredients across 5 tiers, each with unique lore, elements, and rarity chances. This sprint implements the full catalog with visually distinct, magical representations that make every ingredient feel like a treasure.

Every ingredient gets a unique visual identity built from Roblox primitives — not generic orbs. A Dragon Scale is a jagged red shard with fire particles. A Moonpetal is a translucent white flower that pulses with soft light. Time Sand is an hourglass shape with particles flowing upward. The market GUI transforms from a text list into a visual bazaar with element-colored cards, rarity glow borders, and animated ingredient previews.

This sprint also introduces two new ingredient properties from the GDD: **Freshness** (degrades over time, encouraging active play) and **Affinity** (hidden tag that influences brewing outcomes). Together with per-ingredient market appearance rates, these create the deep, urgent, FOMO-driven gathering loop that made Grow a Garden addictive.

## Scope Anchors (Non-Negotiable)

1. **All 58 ingredients** from the GDD are in the catalog, including 2 Divine (ultra-rare market finds at 0.1% AND Robux-purchasable)
2. **Each ingredient has a unique visual representation** — element-colored, rarity-appropriate, creatively designed
3. **Per-ingredient market appearance rates** match the GDD (not just per-tier)
4. **Freshness system** with time-based degradation
5. **Market GUI overhaul** with visual ingredient cards, element colors, rarity effects
6. **No regressions** to existing brewing, selling, foraging systems

## Use Cases

1. **Market FOMO moment**: Player opens market and sees a Phoenix Feather (Rare, 12% chance) — a glowing red-gold feathered shape with fire particles. Only 1 in stock. Heart races. Buy immediately.
2. **Mythic appearance**: Market refreshes and a Starfall Shard appears (3% chance). Entire card glows rainbow. Player screenshots and shares.
3. **Visual variety**: Scrolling through the market shows mushrooms, crystals, feathers, scales, vials, flowers, bones — every ingredient looks different and magical.
4. **Freshness pressure**: Player has a Moonpetal at 80% freshness. Timer ticking. Must brew soon or it degrades and loses value multiplier.
5. **Element identification**: Water ingredients have blue-tinted cards, Fire has orange-red, Shadow has purple-black. Instant visual sorting.
6. **Rarity excitement**: Common ingredients are simple and earthy. Uncommon shimmer. Rare glow intensely. Mythic have particle auras. The rarity IS the visual.

## Architecture

### Ingredient Visual System

Each ingredient gets a visual descriptor that defines how it's rendered:

```lua
VisualDescriptor = {
    shape = "sphere" | "crystal" | "leaf" | "feather" | "scale" | "vial" | "flower" | "dust" | "shard" | "bone" | "orb",
    primaryColor = Color3,
    secondaryColor = Color3,
    material = Enum.Material,
    emissive = boolean,        -- uses Neon material for glow
    particleColor = Color3?,   -- optional ambient particles
    particleRate = number?,    -- 0 = none
    scale = number,            -- relative size (0.5 - 2.0)
}
```

### Freshness System

```lua
-- Stored per ingredient instance in player inventory
IngredientInstance = {
    ingredientId = string,
    acquiredUnix = number,     -- os.time() when obtained
    freshness = number,        -- 1.0 (fresh) → 0.0 (expired)
}

-- Freshness decay: loses 10% per hour (real-time, even offline)
-- At freshness < 0.5: potion value multiplier halved
-- At freshness < 0.2: can only produce Sludge
-- Visual: ingredient card shows freshness bar, color shifts from green→yellow→red
```

### Affinity System

```lua
-- Hidden property per ingredient (not shown to player)
Affinity = "Harmonious" | "Volatile" | "Stable" | "Chaotic"

-- Affects brewing outcomes:
-- Harmonious + Harmonious = +10% sell value bonus
-- Volatile + Volatile = chance of mutation (future sprint)
-- Chaotic + anything = small chance of surprise discovery
-- Stable = no modifier (default safe)
```

### Market GUI Card Layout

```
┌─────────────────────────────┐
│ [Element Color BG]          │
│  🟢 Mushroom          x15  │
│  ┌──────┐                   │
│  │ 3D   │  Common | Earth   │
│  │ View │  10 coins         │
│  └──────┘  ████░░ Fresh     │
│            [BUY]            │
└─────────────────────────────┘
```

## Implementation Plan

### Phase 1: Full Ingredient Catalog (~25%)

**Files:**
- `ReplicatedStorage/Shared/Config/Ingredients` — Expand to 56 ingredients

**Tasks:**
- [ ] Add all 15 Common ingredients from GDD with correct costs, elements, descriptions
- [ ] Add all 14 Uncommon ingredients with per-ingredient market chance
- [ ] Add all 15 Rare ingredients with per-ingredient market chance
- [ ] Add all 12 Mythic ingredients with per-ingredient market chance
- [ ] Add visual descriptors to each ingredient (shape, colors, material, particles)
- [ ] Add affinity tags to each ingredient
- [ ] Add freshness decay rate per tier (Common: slow, Mythic: very slow)
- [ ] Add `marketChance` field to each ingredient for per-ingredient appearance rates

### Phase 2: Visual Ingredient Representations (~25%)

**Tasks:**
- [ ] Create ingredient visual renderer function: given a VisualDescriptor, creates a 3D model from Parts
- [ ] Implement 11 shape templates: sphere, crystal, leaf, feather, scale, vial, flower, dust, shard, bone, orb
- [ ] Each shape is built from 1-4 Roblox Parts with creative use of Shape, Material, Color, Neon
- [ ] Add rarity-scaled particle effects: Common=none, Uncommon=subtle shimmer, Rare=glow aura, Mythic=dramatic particles
- [ ] Add element-colored ambient light to Rare+ ingredients
- [ ] Create ViewportFrame-based ingredient preview for market GUI cards
- [ ] Test all 56 ingredients render correctly and look distinct

### Phase 3: Market Service Upgrade (~15%)

**Files:**
- `ServerScriptService/Services/MarketService` — Per-ingredient chance system
- `ReplicatedStorage/Shared/Config/MarketTuning` — Updated rules

**Tasks:**
- [ ] Replace tier-based offer generation with per-ingredient chance system
- [ ] Each refresh: iterate all ingredients, roll `marketChance` for each, add to offers if successful
- [ ] Common ingredients always appear (chance = 1.0)
- [ ] Uncommon: 50-60% per ingredient
- [ ] Rare: 10-15% per ingredient (GDD specific rates)
- [ ] Mythic: 1.5-3% per ingredient (GDD specific rates)
- [ ] Stock quantities: Common 10-20, Uncommon 3-8, Rare 1-2, Mythic 1
- [ ] Add global announcement when Mythic appears: "A [Mythic Name] has appeared in the market!"

### Phase 4: Market GUI Overhaul (~20%)

**Files:**
- `StarterPlayer/StarterPlayerScripts/GameController` — Market UI rendering
- `StarterGui/MarketGui` — Enhanced layout

**Tasks:**
- [ ] Redesign market item cards with element-colored backgrounds
- [ ] Add rarity border glow (Common=none, Uncommon=blue, Rare=gold, Mythic=rainbow pulse)
- [ ] Add ViewportFrame ingredient preview in each card (3D mini-model)
- [ ] Show freshness bar for ingredients already in inventory
- [ ] Add ingredient description tooltip on hover/tap
- [ ] Add rarity tier filter buttons (All / Common / Uncommon / Rare / Mythic)
- [ ] Add "RARE!" and "MYTHIC!" animated badges on special ingredients
- [ ] Improve refresh countdown timer with visual urgency (red when < 30s)
- [ ] Mobile-optimized card sizes with smooth scrolling

### Phase 5: Freshness System (~10%)

**Files:**
- `ServerScriptService/Services/PlayerDataService` — Schema V3 migration
- `ServerScriptService/Services/BrewingService` — Freshness affects brewing
- `ReplicatedStorage/Shared/Types` — DATASTORE_VERSION = 3

**Tasks:**
- [ ] Migrate inventory from `{ [id] = count }` to `{ [id] = { count, instances[] } }` for freshness tracking
- [ ] Or simpler: track freshness as average per ingredient stack, decaying over time
- [ ] Calculate freshness on each access: `freshness = max(0, 1 - (os.time() - acquiredUnix) / decaySeconds)`
- [ ] Freshness affects brew outcome: < 0.5 = halved value, < 0.2 = Sludge only
- [ ] Show freshness in inventory displays (CauldronGui ingredient grid, MarketGui "owned" indicator)
- [ ] V2→V3 DataStore migration: add acquiredUnix timestamps to existing inventory items

### Phase 6: Polish & Integration Testing (~5%)

**Tasks:**
- [ ] Verify all 56 ingredients appear in market with correct rates
- [ ] Verify each ingredient renders with distinct visual
- [ ] Test buying, brewing with new ingredients
- [ ] Test freshness decay and its effect on brewing
- [ ] Verify existing recipes still work
- [ ] Performance check: 56-ingredient catalog doesn't slow market refresh
- [ ] Mobile viewport check

## Ingredient Visual Design Guide

Here's the creative vision for how each ingredient type should look — NOT generic orbs:

| Ingredient | Shape | Visual Description |
|-----------|-------|-------------------|
| Mushroom | Rounded cap + stem | Brown cap, spotted, earthy material |
| Dragon Scale | Jagged diamond shard | Deep red, metallic, fire particles |
| Phoenix Feather | Long tapered feather | Gold-orange gradient, Neon glow, ember particles |
| Moonpetal | Delicate flower petals | Translucent white, soft pulse glow |
| Crystal Dust | Cluster of tiny crystals | Clear/prismatic, sparkle particles |
| Time Sand | Hourglass shape | Golden sand, particles flowing UPWARD |
| Void Essence | Swirling dark sphere | Black with purple edge glow, warps nearby light |
| Starfall Shard | Jagged meteor fragment | Iridescent rainbow, bright sparkle trail |
| Frozen Amber | Rough amber nugget | Golden-brown, transparent, ice particles |
| Ghost Orchid | Translucent flower | Phases between visible/invisible, eerie glow |
| Basilisk Fang | Curved tooth | Bone-white with green venom drip |
| Kraken Ink | Dark vial | Deep blue-black liquid, tentacle-like swirl |
| Angel Feather | Pure white feather | Bright white Neon, holy glow, rises slowly |

## Files Summary

| Location | Action | Purpose |
|----------|--------|---------|
| `ReplicatedStorage/Shared/Config/Ingredients` | Rewrite | Full 56-ingredient catalog with visuals, affinity, freshness |
| `ReplicatedStorage/Shared/Config/MarketTuning` | Modify | Per-ingredient chance system |
| `ReplicatedStorage/Shared/Types` | Modify | DATASTORE_VERSION=3, freshness constants |
| `ServerScriptService/Services/MarketService` | Modify | Per-ingredient offer generation |
| `ServerScriptService/Services/PlayerDataService` | Modify | V3 migration for freshness tracking |
| `ServerScriptService/Services/BrewingService` | Modify | Freshness affects brew outcomes |
| `StarterPlayer/StarterPlayerScripts/GameController` | Modify | Market UI card redesign |
| `StarterGui/MarketGui` | Modify | Enhanced layout with element colors |

## Definition of Done

- [ ] 58 ingredients in catalog (15 Common, 14 Uncommon, 15 Rare, 12 Mythic, 2 Divine)
- [ ] Each ingredient has unique visual representation (not generic orbs)
- [ ] Market GUI shows element-colored cards with rarity borders
- [ ] Per-ingredient market appearance rates match GDD
- [ ] Mythic ingredients get global announcement when appearing
- [ ] Freshness degrades over time and affects brewing outcomes
- [ ] Affinity tags present on all ingredients
- [ ] ViewportFrame or visual preview for each ingredient in market
- [ ] Existing recipes and gameplay still work
- [ ] Market refresh cycle maintains 5-minute cadence
- [ ] Mobile-friendly scrolling and card sizes

## Risks & Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| 56 ingredients overwhelms market UI | Medium | High | Add tier filter buttons, paginate if needed |
| Visual variety takes too long per ingredient | High | Medium | Create template shapes, reuse with color/material variations |
| DataStore migration for freshness is complex | Medium | High | Use simple stack-level freshness, not per-instance tracking |
| Per-ingredient chances make market too empty or too full | Medium | Medium | Test with Monte Carlo simulation of 100 refreshes |
| ViewportFrame performance on mobile | Medium | Medium | Fallback to 2D colored shapes if FPS drops |

## Dependencies

- Sprint 001 (market system, ingredients config)
- Sprint 003 (DataStore V2 schema — need V3 migration)
- GDD Section 2.1 ingredient table (source of truth for costs, elements, rates)

## Open Questions

1. How many new recipes should be added for the 46 new ingredients?
2. Should freshness decay rate differ between online and offline play?
3. What Robux price point for Divine ingredients (99? 199? 499?)?
