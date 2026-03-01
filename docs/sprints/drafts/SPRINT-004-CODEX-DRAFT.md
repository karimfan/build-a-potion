# Sprint 004: Ingredient Market Overhaul — Full Catalog, 3D Market Previews, Freshness Economy

## Overview

Sprint 004 expands the ingredient economy from a starter prototype into a scalable content system that matches the intended market fantasy: many ingredients, visually distinct identities, scarcity pressure, and meaningful timing decisions. The current game loop works, but ingredient depth is too shallow (12 ingredients, tier-bucket market rolls, no freshness/affinity metadata, text-heavy market presentation). This sprint addresses that gap directly.

The implementation focus is server-authoritative correctness with presentation upgrades on top: per-ingredient market odds, full ingredient metadata, freshness degradation persisted across sessions, and market UI that previews ingredients as 3D miniatures using `ViewportFrame`. This keeps gameplay integrity while creating the “check the market now” excitement needed for retention.

Interview findings are treated as hard requirements in this plan:
1. Market GUI uses 3D `ViewportFrame` ingredient previews.
2. Freshness ships now and includes DataStore schema migration V2→V3.
3. Divine ingredients are dual-sourced: ultra-rare market appearance (0.1% chance) and Robux purchase flow.

## Scope Anchors (Non-Negotiable)

1. **Canonical catalog in game data is 58 ingredients**: 15 Common, 14 Uncommon, 15 Rare, 12 Mythic, 2 Divine.
2. **Every market card has a 3D `ViewportFrame` preview**, not only text/icon rows.
3. **Freshness is server-authored and persisted** with real-time degradation using Unix timestamps.
4. **DataStore migration V2→V3 is idempotent** and preserves all existing player progress.
5. **Market generation uses per-ingredient appearance weights** (not only tier-level chance gates).
6. **Divine ingredients can enter inventory via both paths**:
   - ultra-rare market offer roll (`0.1%` appearance chance)
   - Robux purchase (developer product flow)
7. **No regressions** in buy/brew/sell/timed-brew progression from Sprints 001–003.

## Use Cases

1. **Market browsing with visual clarity**: Player opens market and immediately distinguishes ingredients by silhouette/shape/material in 3D previews, plus element tint and rarity glow.
2. **Urgency from freshness**: Player sees “Fresh 97%” on new stock and “Stale 22%” on old inventory, deciding whether to brew now or risk value loss.
3. **Rare hunt loop**: Player checks each 5-minute market refresh because specific Rare/Mythic ingredients have known low appearance rates.
4. **Divine jackpot moment**: A Divine ingredient appears in market as a `0.1%` event and triggers a high-visibility market announcement.
5. **Monetized fast path**: Another player obtains Divine ingredients through Robux purchase without replacing market rarity path.
6. **Offline freshness consistency**: Player leaves overnight and returns with correctly degraded freshness based on elapsed real time.
7. **Safe migration**: Existing players keep coins, inventory, brew stats, and active brew state while gaining freshness metadata automatically.

## Architecture

### Ingredient Metadata Expansion

```
Ingredients.Data[ingredientId] = {
  id,
  name,
  tier,
  element,
  cost,
  description,

  -- NEW
  marketChance = number,         -- per-refresh independent chance
  affinity = string,             -- hidden tag used by recipe/balance systems
  freshness = {
    decayPerHour = number,
    minimumEffectiveness = number,
  },
  visual = {
    archetype = string,          -- e.g. "mushroom", "scale", "crystal_shard"
    color = {r,g,b},
    material = string,
    emissive = number,
  },
  acquisition = {
    market = boolean,
    forage = boolean,
    robuxProductId = number|nil,
  }
}
```

Notes:
- `affinity` remains hidden from UI in this sprint; it is stored and used by server logic as extension-ready metadata.
- Visual archetype config drives both world model assembly and market `ViewportFrame` rendering.

### Market Generation Flow (Per-Ingredient Odds)

```
refreshMarket()
  -> Iterate ingredient catalog
  -> Roll ingredient-specific chance (marketChance)
  -> Apply tier caps/quotas to prevent overfilled high tiers
  -> Build Offer {ingredientId, price, stock, generatedAtUnix}
  -> Broadcast MarketRefresh state to clients
```

Controls:
- Common baseline always represented each refresh (floor guarantee).
- Uncommon/Rare/Mythic driven by per-ingredient chance values from config.
- Divine market path explicitly included at `0.001` probability per ingredient per refresh (0.1%).

### Freshness Model (Server-Authoritative)

```
Inventory entry (V3):
Ingredients[ingredientId] = {
  quantity = number,
  stacks = {
    {
      amount = number,
      acquiredUnix = number,
      expiresUnix = number,
      source = "market"|"forage"|"robux",
    }
  }
}

effectiveFreshness(now, stack):
  pct = clamp((stack.expiresUnix - now) / (stack.expiresUnix - stack.acquiredUnix), 0, 1)
```

Behavior:
- Freshness decays continuously with `os.time()`.
- Brewing consumes oldest stacks first (FIFO) to avoid abuse.
- Brew output value/potency multiplier uses consumed ingredient freshness snapshot.
- Expired stacks are still storable but produce minimum effectiveness (configurable) or sludge bias.

### DataStore Migration V2 → V3

```
V2 fields retained:
- Coins, Potions, DiscoveredRecipes, BrewStats, ActiveBrew

V3 adds/changes:
- Version = 3
- Ingredients: migrate numeric quantity -> stack container schema
- PurchaseHistory / DivineAcquisition flags (for entitlement consistency)
```

Migration contract:
- Idempotent and safe on repeated loads.
- Numeric `Ingredients[id]=N` converts to single default-freshness stack with `amount=N`.
- Active brew data remains untouched.

### Market UI Rendering (ViewportFrame)

```
MarketCard
  - ViewportFrame (ingredient miniature)
  - Name + Tier + Element
  - Freshness badge + decay state color
  - Price + Stock
  - Buy button
```

Client flow:
- For each market offer, build/reuse miniature model in `ViewportFrame` with dedicated `Camera`.
- Apply rarity glow border + element-tinted background.
- On low-end fallback, show simplified primitive composition but keep `ViewportFrame` contract.

### Divine Dual-Source Acquisition

```
Path A: Market roll (0.1%)
  MarketService emits Divine offer with tiny stock and premium price

Path B: Robux purchase
  MarketplaceService.ProcessReceipt -> EconomyService grant -> PlayerDataService persist
```

Consistency requirements:
- Both paths produce freshness stack entries with source labels.
- Fraud-safe grant path with idempotent receipt handling.

## Implementation Plan

### Phase 1: Catalog Canonicalization + Metadata Schema (~25%)

**Files:**
- `src/shared/Config/Ingredients.lua` - Expand to 58 canonical entries + new metadata
- `src/shared/Types.lua` - Add freshness/acquisition enums and constants
- `src/shared/Config/MarketTuning.lua` - Replace tier-only assumptions with per-ingredient helpers

**Tasks:**
- [ ] Normalize sprint 004 canonical ingredient set to 58 entries (15/14/15/12/2) and document IDs.
- [ ] Add metadata fields: `marketChance`, `affinity`, `freshness`, `visual`, `acquisition`.
- [ ] Define divine entries as market-enabled and Robux-enabled.
- [ ] Add shared constants: `DATASTORE_VERSION = 3`, default shelf-life, divine chance constant (`0.001`).
- [ ] Add helpers for filtering by tier, by acquisition source, and by roll-eligibility.

### Phase 2: DataStore V3 Migration + Freshness Persistence (~20%)

**Files:**
- `src/server/Services/PlayerDataService.lua` - V2→V3 migration, stack schema, timestamp logic

**Tasks:**
- [ ] Implement `getDefaultProfile()` V3 with stack-based ingredient inventory.
- [ ] Implement `migrateProfile()` path from V2 numeric inventory to V3 stacks.
- [ ] Ensure migration is idempotent and defensive for malformed profiles.
- [ ] Add freshness utility methods in service: stack merge/split, expiration clamp, FIFO consumption.
- [ ] Preserve all existing V2 systems (BrewStats/ActiveBrew) unchanged.
- [ ] Add targeted migration logging counters for validation in Studio test sessions.

### Phase 3: Market Generator Rewrite (Per-Ingredient Odds + Divine 0.1%) (~20%)

**Files:**
- `src/server/Services/MarketService.lua` - New offer generation algorithm
- `src/server/Services/EconomyService.lua` - Purchase validation for stack inventory writes

**Tasks:**
- [ ] Replace tier loop with ingredient loop using `marketChance` rolls.
- [ ] Enforce tier balancing constraints to avoid all-common/all-mythic outcomes.
- [ ] Add explicit divine gate at `0.1%` chance and low stock policy.
- [ ] Include `generatedAtUnix` in offers for freshness presentation.
- [ ] Update stock deduction and buy flows to write stack entries with source=`market`.
- [ ] Keep refresh cadence at 300 seconds and existing broadcast remote shape compatibility.

### Phase 4: Market GUI Overhaul with 3D ViewportFrame Previews (~20%)

**Files:**
- `src/client/GameController.client.lua` - Market card rendering rewrite
- `src/client/InteractionController.client.lua` - Keep market open/close integration stable
- `src/client/IngredientViewportFactory.client.lua` (new) - Build/cache miniature models and cameras

**Tasks:**
- [ ] Introduce card layout with `ViewportFrame`, rarity border, element tint, freshness badge.
- [ ] Build miniature generator from ingredient `visual` metadata (primitive-based assemblies).
- [ ] Cache/reuse viewport models to reduce GC churn and UI stutter.
- [ ] Add freshness text states (`Fresh`, `Stable`, `Stale`, `Expired`) with color mapping.
- [ ] Preserve mobile readability and scroll performance (virtualization if needed).
- [ ] Add defensive fallback when visual metadata is missing (placeholder silhouette still in viewport).

### Phase 5: Brewing/Economy Freshness Effects + Affinity Hook (~10%)

**Files:**
- `src/server/Services/BrewingService.lua` - Consume freshest/oldest rules + multiplier application
- `src/shared/Config/BrewTuning.lua` - Freshness effect curve tuning

**Tasks:**
- [ ] Update ingredient consumption to pull FIFO stacks and compute blended freshness score.
- [ ] Apply freshness multiplier to potion value/output quality.
- [ ] Add minimum floor behavior for expired ingredients.
- [ ] Thread hidden `affinity` values into brew resolution hook points (no full affinity UI this sprint).
- [ ] Add debug instrumentation for freshness outcome calculations.

### Phase 6: Robux Divine Purchase Path (~5%)

**Files:**
- `src/server/Services/EconomyService.lua` - Product grant handling
- `src/server/Bootstrap.server.lua` - Ensure purchase handler service initialization if split out
- `src/shared/Config/Ingredients.lua` - Product ID mapping for divine entries

**Tasks:**
- [ ] Add developer product receipt handling for divine ingredient grants.
- [ ] Implement idempotent processing keyed by receipt/purchase ID.
- [ ] Grant V3 freshness stacks with source=`robux`.
- [ ] Add server validation and logging for failed grants.

## Files Summary

| File | Action | Purpose |
|------|--------|---------|
| `src/shared/Config/Ingredients.lua` | Modify | Expand to 58 ingredients + freshness/affinity/visual/acquisition metadata |
| `src/shared/Config/MarketTuning.lua` | Modify | Per-ingredient chance helpers, tier balancing knobs, divine constants |
| `src/shared/Config/BrewTuning.lua` | Modify | Freshness effect curve and expiry floor tuning |
| `src/shared/Types.lua` | Modify | DataStore V3 constants, freshness enums, acquisition source constants |
| `src/server/Services/PlayerDataService.lua` | Modify | V2→V3 migration and stack-based inventory persistence |
| `src/server/Services/MarketService.lua` | Modify | Per-ingredient offer rolls + divine 0.1% market chance |
| `src/server/Services/EconomyService.lua` | Modify | Market purchase stack writes + Robux grant processing |
| `src/server/Services/BrewingService.lua` | Modify | Freshness-aware ingredient consumption and output adjustments |
| `src/client/GameController.client.lua` | Modify | Market card UI overhaul with ViewportFrame previews |
| `src/client/InteractionController.client.lua` | Modify | Maintain market interaction compatibility with new card data |
| `src/client/IngredientViewportFactory.client.lua` | Create | Encapsulate viewport miniature generation and caching |

## Definition of Done

- [ ] `SPRINT-004` catalog contains exactly 58 configured ingredients (15/14/15/12/2).
- [ ] Market offers are generated with per-ingredient chance logic and maintain 5-minute refresh cadence.
- [ ] Divine ingredients can be acquired from both market (`0.1%` appearance) and Robux purchases.
- [ ] Market UI cards render 3D previews through `ViewportFrame` for all offers.
- [ ] Freshness decays correctly across offline time and affects brew outcomes.
- [ ] Player profiles migrate V2→V3 without loss of coins, potions, recipes, brew stats, or active brew.
- [ ] Existing buy/brew/sell/forage loops function without regressions.
- [ ] Server/client logs show no new critical errors during 30+ minute playtest.

## Risks & Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| V3 migration corrupts legacy ingredient counts | Medium | High | Idempotent migration + backup transform tests on sampled V2 fixtures |
| ViewportFrame rendering causes client perf drops on mobile | Medium | High | Cache miniatures, cap card count, simplify model complexity per tier |
| Per-ingredient odds produce sparse/unfun markets | Medium | Medium | Add tier floor guarantees and telemetry counters for appearance rates |
| Divine dual-source economy imbalance | Medium | Medium | Tight stock/price limits + product cooldown + monitor acquisition ratio |
| Freshness penalties feel punishing | Medium | Medium | Configure floor multiplier and surface clear freshness states in UI |

## Security Considerations

- All purchase and grant flows remain server-authoritative.
- `ProcessReceipt` path must be idempotent to prevent duplicate divine grants.
- Client never submits freshness values; server computes and persists freshness only.
- Market stock and divine appearance are generated server-side only.
- Remote validations enforce inventory ownership and positive quantities.

## Dependencies

- Builds on Sprint 001 market/economy foundations.
- Builds on Sprint 003 DataStore V2 and timed-brew schema.
- Requires Roblox `MarketplaceService` setup for divine developer products.
- Requires UI instance updates in Studio for market card container sizing (runtime-scripted creation acceptable).

## Open Questions

1. Should freshness primarily impact sell value, brew success odds, or both (recommended: both with soft floor)?
2. Should divine market offers trigger global broadcast immediately or only when purchased?
3. Should forage-acquired ingredients have longer shelf life than market purchases to reward exploration?
