# Sprint 004: Ingredient Market Overhaul — Full Catalog, 3D Previews, Freshness Economy, Divine Dual-Source

## Overview

The ingredient market is the engine of urgency — the 5-minute refresh cycle that makes players check back, the rare Mythic ingredient that makes them gasp, the visual feast that makes them screenshot. Right now it's 12 text labels in a dark box. The GDD defines 58 ingredients across 5 tiers, each with unique lore, elements, and per-ingredient rarity chances.

Sprint 004 expands the catalog to all 58 ingredients, gives each a visually distinct 3D identity rendered via ViewportFrame (not generic orbs — Dragon Scales are jagged red shards with fire particles, Moonpetals are translucent glowing flowers, Time Sand flows upward), introduces the Freshness system with real-time degradation, and adds per-ingredient market appearance rates. Divine ingredients are both ultra-rare market finds (0.1% chance) AND Robux-purchasable.

Every ingredient should feel like a treasure. Every market refresh should feel like a slot machine pull. Every rare appearance should generate a screenshot moment.

## Scope Anchors (Non-Negotiable)

1. **58 ingredients in catalog**: 15 Common, 14 Uncommon, 15 Rare, 12 Mythic, 2 Divine
2. **3D ViewportFrame previews** for every ingredient in the market GUI (mandatory, no 2D fallback)
3. **Per-ingredient `marketChance`** field — market generator rolls each ingredient individually
4. **Freshness system** with stack-based inventory, real-time degradation via Unix timestamps, FIFO consumption
5. **DataStore V2→V3 migration** — idempotent, preserves all existing progress
6. **Divine dual-source**: ultra-rare market (0.1%) AND Robux developer product purchase
7. **Affinity**: metadata + server hook points only (defer active gameplay modifiers)
8. **No regressions** to brewing, selling, foraging systems

## Use Cases

1. **Market FOMO**: Player opens market and sees a Phoenix Feather (12% chance, Rare) — a glowing red-gold feathered shape with fire particles. Only 1 in stock. Heart races. Buy immediately.
2. **Mythic appearance**: Market refreshes and a Starfall Shard appears (3% chance). Card glows rainbow. Global announcement fires. Player screenshots.
3. **Divine jackpot**: A Philosopher's Stone Fragment appears (0.1% chance). Server-wide announcement. Players rush to market. Only 1 in stock.
4. **Visual variety**: Scrolling through market shows mushrooms, crystals, feathers, scales, vials, flowers, bones, embers — every ingredient is a distinct 3D miniature.
5. **Freshness pressure**: Player has a Moonpetal at 60% freshness. Timer ticking. Must brew soon or value drops.
6. **Element identification**: Water ingredients have blue-tinted cards, Fire has orange-red, Shadow has purple-black. Instant visual sorting.
7. **Rarity hierarchy**: Common cards are simple. Uncommon shimmer. Rare glow gold. Mythic pulse rainbow. Divine radiate pure light.
8. **Robux Divine purchase**: Player buys Cosmic Ember via Robux shop. Appears in inventory as fresh stack with source="robux".

## Architecture

### Ingredient Metadata Schema

```lua
Ingredients.Data[id] = {
    id = string,
    name = string,
    tier = "Common" | "Uncommon" | "Rare" | "Mythic" | "Divine",
    element = "Fire" | "Water" | "Earth" | "Air" | "Shadow" | "Light",
    cost = number,
    description = string,
    -- NEW in Sprint 004:
    marketChance = number,       -- per-refresh appearance probability (0.0 - 1.0)
    affinity = "Harmonious" | "Volatile" | "Stable" | "Chaotic",
    freshness = {
        shelfLifeHours = number, -- hours until fully expired
    },
    visual = {
        archetype = string,      -- "mushroom", "crystal", "feather", "scale", etc.
        primaryColor = {r, g, b},
        secondaryColor = {r, g, b},
        material = string,       -- Enum.Material name
        emissive = boolean,      -- use Neon material
        particleColor = {r, g, b} | nil,
        particleRate = number,   -- 0 = none
    },
    acquisition = {
        market = boolean,
        forage = boolean,
        robuxProductId = number | nil,
    },
}
```

### Freshness Model (Stack-Based, Server-Authoritative)

```lua
-- V3 Inventory: stack-based with timestamps
Ingredients = {
    [ingredientId] = {
        stacks = {
            { amount = number, acquiredUnix = number, expiresUnix = number, source = "market"|"forage"|"robux" },
            ...
        }
    }
}

-- Freshness is computed, not stored:
effectiveFreshness(now, stack) = clamp((stack.expiresUnix - now) / (stack.expiresUnix - stack.acquiredUnix), 0, 1)

-- Brewing consumes FIFO (oldest stacks first)
-- Freshness affects brew: < 0.5 = halved value, < 0.2 = Sludge bias
```

### DataStore Migration V2→V3

```
V2: Ingredients = { [id] = quantity }
V3: Ingredients = { [id] = { stacks = [{ amount, acquiredUnix, expiresUnix, source }] } }

Migration: numeric quantity → single stack with amount=N, acquiredUnix=os.time(),
           expiresUnix=os.time() + (shelfLifeHours * 3600), source="legacy"
```

### Market Generation (Per-Ingredient Odds)

```
refreshMarket():
    offers = []
    for each ingredient in catalog:
        if ingredient.acquisition.market and random() <= ingredient.marketChance:
            stock = tierStockRange(ingredient.tier)
            offers.append({ ingredientId, price, stock, generatedAtUnix })

    -- Tier floor: ensure at least 3 Common always appear
    -- Tier cap: max 2 Mythic, max 1 Divine per refresh
    broadcast(offers)

    -- Global announcement for Mythic/Divine appearances
```

### Market GUI Card Layout

```
┌───────────────────────────────────┐
│ [Element-Colored Background]       │
│ ┌─────────┐                        │
│ │ 3D View │  Dragon Scale     x1   │
│ │ Frame   │  Rare | Fire           │
│ │ (model) │  500 coins             │
│ └─────────┘  ████████░░ Fresh 85%  │
│              [ BUY ]               │
│  ✨ RARE! ✨                        │
└───────────────────────────────────┘
Rarity borders: Common=none, Uncommon=blue glow, Rare=gold glow, Mythic=rainbow pulse, Divine=white radiance
```

## Implementation Plan

### Phase 1: Full 58-Ingredient Catalog (~25%)

**Files:**
- `src/shared/Config/Ingredients.lua` — Expand from 12 to 58 entries with full metadata

**Tasks:**
- [ ] Add all 15 Common ingredients from GDD with: cost, element, description, marketChance=1.0, visual descriptor, affinity, freshness
- [ ] Add all 14 Uncommon ingredients with per-ingredient marketChance (0.50-0.60)
- [ ] Add all 15 Rare ingredients with per-ingredient marketChance (0.10-0.15 per GDD)
- [ ] Add all 12 Mythic ingredients with per-ingredient marketChance (0.015-0.03 per GDD)
- [ ] Add 2 Divine ingredients with marketChance=0.001, robuxProductId set
- [ ] Define visual archetype for each: mushroom, leaf, crystal, feather, scale, vial, flower, dust, shard, bone, orb, ember, fang, tear, silk
- [ ] Assign creative primaryColor/secondaryColor/material per ingredient (element-appropriate)
- [ ] Set affinity tags (Harmonious/Volatile/Stable/Chaotic) distributed across catalog
- [ ] Set freshness shelfLifeHours: Common=24h, Uncommon=18h, Rare=12h, Mythic=8h, Divine=48h
- [ ] Add `acquisition.forage` flags matching GDD (Common ingredients forageable)

### Phase 2: DataStore V3 Migration + Stack Inventory (~15%)

**Files:**
- `src/server/Services/PlayerDataService.lua` — V2→V3 migration, stack schema
- `src/shared/Types.lua` — DATASTORE_VERSION=3, freshness constants

**Tasks:**
- [ ] Update DATASTORE_VERSION to 3
- [ ] Add V3 default profile with stack-based Ingredients
- [ ] Implement idempotent migration: V2 numeric `Ingredients[id]=N` → V3 stack with amount=N, fresh timestamps
- [ ] Preserve all V2 fields (Coins, Potions, DiscoveredRecipes, BrewStats, ActiveBrew)
- [ ] Add freshness utility: computeFreshness(stack, now), getOldestStack(stacks), consumeFIFO(stacks, amount)
- [ ] Add stack merge/split helpers for buy operations
- [ ] Force save on critical transitions (buy, brew consume)

### Phase 3: Market Service — Per-Ingredient Generation (~15%)

**Files:**
- `src/server/Services/MarketService.lua` — Rewrite offer generation
- `src/shared/Config/MarketTuning.lua` — Updated rules with tier floors/caps

**Tasks:**
- [ ] Replace tier-loop generation with per-ingredient iteration
- [ ] Roll `marketChance` for each ingredient independently
- [ ] Apply tier balancing: minimum 3 Common, max 2 Mythic, max 1 Divine per refresh
- [ ] Set stock quantities: Common 10-20, Uncommon 3-8, Rare 1-2, Mythic 1, Divine 1
- [ ] Include `generatedAtUnix` in offers for freshness start time
- [ ] Update buy flow to create V3 stack entries with source="market"
- [ ] Fire global announcement RemoteEvent when Mythic/Divine ingredient appears
- [ ] Keep 300-second refresh cadence

### Phase 4: 3D Ingredient Visual System + ViewportFrame (~20%)

**Files:**
- `src/client/IngredientVisualFactory.client.lua` (new) — Build 3D models from visual descriptors
- `src/client/GameController.client.lua` — Market UI card redesign

**Tasks:**
- [ ] Create IngredientVisualFactory module with `createModel(visualDescriptor)` function
- [ ] Implement 15 shape archetype builders using Roblox Parts:
  - mushroom: rounded cap + thin stem, earthy tones
  - crystal: cluster of angled wedge parts, prismatic
  - feather: elongated tapered part, gradient color
  - scale: flat diamond shard, metallic material
  - vial: cylinder with Ball top, Glass material
  - flower: 3-4 petal Parts around center, delicate
  - dust: cluster of tiny sphere Parts, sparkle particles
  - shard: jagged irregular wedge, Neon for rare
  - bone: cylindrical Part, Marble material, pale
  - orb: sphere with inner glow, mysterious
  - ember: rough sphere, ForceField material, fire particles
  - fang: curved cone, Marble with green tip accent
  - tear: teardrop sphere, Glass, blue shimmer
  - silk: flat flowing ribbon part, translucent
  - leaf: flat elliptical part, LeafyGrass material
- [ ] Add rarity particle effects: Uncommon=subtle shimmer, Rare=golden glow, Mythic=dramatic trail, Divine=holy radiance
- [ ] Create `renderInViewportFrame(ingredientId, viewportFrame)` — places model + Camera in ViewportFrame
- [ ] Cache built models to avoid recreating on every market refresh
- [ ] Redesign market cards with:
  - ViewportFrame (64x64 minimum) showing 3D model
  - Element-colored background tint
  - Rarity glow border (UIStroke with color animation for Mythic/Divine)
  - Name, tier, element, price, stock
  - Freshness bar (for owned ingredients)
  - Buy button
  - "RARE!" / "MYTHIC!" / "DIVINE!" animated badge
- [ ] Add tier filter buttons (All / Common / Uncommon / Rare+ )
- [ ] Refresh countdown with urgency color (red when < 30s)

### Phase 5: Freshness Integration (~10%)

**Files:**
- `src/server/Services/BrewingService.lua` — Freshness-aware consumption
- `src/server/Services/EconomyService.lua` — Stack-aware buy/sell

**Tasks:**
- [ ] Update BrewingService ingredient consumption to use FIFO stacks
- [ ] Compute blended freshness of consumed ingredients
- [ ] Apply freshness multiplier to brew outcome value: fresh=1.0x, stale(<0.5)=0.5x, expired(<0.2)=Sludge bias
- [ ] Update EconomyService buy flow to create new stacks with fresh timestamps
- [ ] Update sell flow to handle stack-based potion inventory (if applicable)
- [ ] Show freshness in CauldronGui ingredient grid (color-coded: green/yellow/red)

### Phase 6: Divine Robux Purchase Path (~5%)

**Files:**
- `src/server/Services/EconomyService.lua` — ProcessReceipt handling
- `src/shared/Config/Ingredients.lua` — robuxProductId mapping

**Tasks:**
- [ ] Set up developer product IDs for Divine ingredients
- [ ] Implement `MarketplaceService.ProcessReceipt` handler for Divine purchases
- [ ] Idempotent receipt processing keyed by purchaseId
- [ ] Grant V3 freshness stack with source="robux" and extended shelf life (48h)
- [ ] Server validation and logging for purchase grants
- [ ] Notify client of purchase success

### Phase 7: Polish + Integration Testing (~10%)

**Tasks:**
- [ ] Verify all 58 ingredients in catalog with correct costs, elements, chances
- [ ] Verify each ingredient renders as distinct 3D model in ViewportFrame
- [ ] Run 100 simulated market refreshes — verify Mythic appears ~3% of time, Rare ~10-15%, Divine ~0.1%
- [ ] Test buying, brewing with new ingredients
- [ ] Test freshness: buy ingredient, wait, verify freshness degrades, affects brew outcome
- [ ] Test V2→V3 migration: create V2 profile, rejoin, verify stacks with correct timestamps
- [ ] Test Divine market appearance + global announcement
- [ ] Test Divine Robux purchase flow
- [ ] Verify existing recipes still work with original 12 ingredients
- [ ] Mobile viewport: cards readable, scrolling smooth, ViewportFrames render
- [ ] Performance: 58-ingredient catalog doesn't slow market refresh or GUI rendering

## Ingredient Visual Design Guide

| Ingredient | Archetype | Visual Description |
|-----------|-----------|-------------------|
| Mushroom | mushroom | Brown spotted cap, pale stem, earthy |
| Fern Leaf | leaf | Curled green frond, LeafyGrass material |
| River Water | vial | Blue glass vial, swirling water particles |
| Charcoal Chunk | ember | Dark rough sphere, orange ember glow |
| Dandelion Puff | flower | White fluffy sphere, tiny floating particles |
| Dragon Scale | scale | Jagged red diamond, metallic, fire sparks |
| Phoenix Feather | feather | Gold-orange gradient, Neon tip, ember trail |
| Void Essence | orb | Black sphere, purple edge glow, warps light |
| Moonpetal | flower | Translucent white petals, soft pulse glow |
| Crystal Dust | dust | Tiny prismatic cluster, sparkle particles |
| Time Sand | dust | Golden hourglass shape, particles flow UPWARD |
| Starfall Shard | shard | Iridescent rainbow, bright sparkle trail |
| Basilisk Fang | fang | Bone-white curved cone, green venom drip |
| Kraken Ink | vial | Dark blue-black liquid, tentacle swirl |
| Angel Feather | feather | Pure white, Neon glow, rises slowly |
| Frozen Amber | crystal | Golden-brown, transparent, ice particles |
| Ghost Orchid | flower | Phases visible/invisible, eerie green glow |
| Dreamweaver Silk | silk | Flowing purple ribbon, translucent shimmer |
| Demon Heart Ember | ember | Pulsing red-orange sphere, heartbeat glow |
| Philosopher's Stone | crystal | Deep red perfect gem, golden sparkle aura |
| Cosmic Ember | ember | White-hot core, star particle trail, heavenly glow |

## Files Summary

| File | Action | Purpose |
|------|--------|---------|
| `src/shared/Config/Ingredients.lua` | Rewrite | 58 ingredients with full metadata |
| `src/shared/Config/MarketTuning.lua` | Modify | Per-ingredient tier floors/caps |
| `src/shared/Config/BrewTuning.lua` | Modify | Freshness effect curve |
| `src/shared/Types.lua` | Modify | DATASTORE_VERSION=3 |
| `src/server/Services/PlayerDataService.lua` | Modify | V3 migration, stack inventory |
| `src/server/Services/MarketService.lua` | Modify | Per-ingredient offer generation |
| `src/server/Services/EconomyService.lua` | Modify | Stack-aware buy + Robux ProcessReceipt |
| `src/server/Services/BrewingService.lua` | Modify | FIFO freshness consumption |
| `src/client/GameController.client.lua` | Modify | Market card redesign with ViewportFrame |
| `src/client/IngredientVisualFactory.client.lua` | Create | 3D model builder from visual descriptors |

## Definition of Done

- [ ] 58 ingredients in catalog (15/14/15/12/2) with correct GDD costs, elements, chances
- [ ] Every ingredient has a unique 3D visual rendered via ViewportFrame (mandatory)
- [ ] Market uses per-ingredient `marketChance` rolls (not tier-bucket)
- [ ] Tier balancing: min 3 Common, max 2 Mythic, max 1 Divine per refresh
- [ ] Global announcement when Mythic/Divine appears in market
- [ ] Freshness degrades via stack timestamps (real-time, including offline)
- [ ] Freshness < 0.5 halves brew value; < 0.2 produces Sludge bias
- [ ] FIFO consumption (oldest stacks brewed first)
- [ ] V2→V3 DataStore migration is idempotent and preserves all data
- [ ] Divine ingredients acquirable via market (0.1%) AND Robux purchase
- [ ] Robux purchase uses idempotent ProcessReceipt handling
- [ ] Affinity metadata present on all ingredients (no active modifiers this sprint)
- [ ] Existing 12-ingredient recipes still work
- [ ] Market GUI has element-colored cards, rarity borders, tier filters
- [ ] Mobile-friendly cards and scrolling
- [ ] No regressions to brew/sell/forage flows

## Risks & Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| 58 ingredients overwhelms market UI | Medium | High | Tier filter buttons, max ~15 offers per refresh |
| ViewportFrame perf on mobile | Medium | High | Cache models, cap visible cards, simplify low-tier models |
| V3 migration corrupts inventory | Medium | Critical | Idempotent migration, numeric→stack with fresh timestamps |
| Per-ingredient chances produce empty/overfull markets | Medium | Medium | Tier floors (min 3 Common) and caps (max 2 Mythic) |
| Visual variety takes too long per ingredient | High | Medium | Template archetype system — 15 shapes, reuse with color/material swaps |
| Divine Robux handling has edge cases | Medium | High | Idempotent receipt keying, server validation, logging |

## Security Considerations

- Market generation is server-only. Client cannot influence offers or stock.
- Freshness computed server-side from timestamps. Client never submits freshness values.
- ProcessReceipt is idempotent — duplicate purchases don't grant double.
- Per-ingredient marketChance values live in server-authoritative config.
- Stack inventory mutations are atomic on server.

## Dependencies

- Sprint 001 (market system, economy service)
- Sprint 003 (DataStore V2 schema)
- GDD Section 2.1 (source of truth for ingredients, costs, elements, rates)
- Roblox MarketplaceService for Divine Robux purchases

## Open Questions

1. How many new recipes should be added for the 46 new ingredients?
2. Should freshness decay rate differ between online and offline play?
3. What Robux price point for Divine ingredients (99? 199? 499)?
4. Should foraged ingredients have longer shelf life than market purchases?
