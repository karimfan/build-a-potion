# Sprint 001: Vertical Slice Foundation - Full World, Core Loop, Persistent Economy

## Overview

Sprint 001 establishes a playable, persistent vertical slice of Brew a Potion with the full day-one world footprint. The objective is to ship a first-iteration experience that already feels like the intended game: players can move across all four zones, buy ingredients from a rotating market, brew recipes (or fail into sludge), sell results, and keep progress across sessions.

This sprint intentionally prioritizes architecture and systems correctness over breadth. The interview constraints are treated as hard requirements: (1) all 4 zones are present from day one, (2) marketplace models/art are used immediately, (3) market stock rotates every 5 minutes, and (4) DataStore persistence is included from day one. We will implement minimal but production-shaped versions of each system so later sprints can add depth without rewrites.

The resulting slice should be continuously playable in Studio: a new player can complete gather -> brew -> sell -> gather again within 60-120 seconds, while progression survives rejoin. This creates an immediate test bed for economy tuning, UX iteration, and future retention systems.

## Scope Anchors (Non-Negotiable)

- Full 4-zone map exists and is traversable in Sprint 001.
- Ingredient Market uses marketplace models/art from day one (not graybox-only).
- Market stock refreshes on a strict 5-minute cadence.
- Persistent player data (coins, inventory, discovered recipes) uses DataStore from day one.

## Use Cases

1. **First minute comprehension**: A new player spawns, sees top-bar zone navigation, teleports to market, buys ingredients, brews at cauldron, sells at trading post.
2. **Persistent progression**: A returning player rejoins and retains coins, ingredient inventory, and discovered recipe book entries.
3. **Scarcity pressure**: A player waits for market refresh and sees stock change, including occasional rarer offers.
4. **Failure path clarity**: A player submits an invalid combination and receives Sludge with clear feedback.
5. **Recipe discovery payoff**: A player discovers a new valid combination and it is permanently saved to recipe book.
6. **Economy sanity**: A player can profit from common recipes while still needing decisions to scale earnings.

## Architecture

### High-Level Runtime Topology

```text
Client (StarterPlayerScripts + StarterGui)
  -> UIController (market, brew, sell, recipe book, zone nav)
  -> InteractionController (prompt handling, local UX)
  -> ReplicatedStorage.Remotes (request/response)

Server (ServerScriptService)
  -> PlayerDataService (DataStore load/save/session cache)
  -> MarketService (5-minute stock generator + read API)
  -> BrewingService (recipe resolution + failure handling)
  -> EconomyService (buy/sell transaction rules)
  -> ZoneService (teleport endpoints + validation)

Shared (ReplicatedStorage)
  -> Config modules (ingredients, recipes, pricing, rarity)
  -> Type definitions/constants
  -> RemoteEvent/RemoteFunction instances

World (Workspace)
  -> Zone models: Shop, Market, TradingPost, WildGrove
  -> Interaction points: market NPC/stall, cauldron, sell counter
  -> Teleport pads + top-bar destinations
```

### Core Data Model (Server Authoritative)

```lua
PlayerState = {
  Version = 1,
  Coins = number,
  Ingredients = { [ingredientId] = quantity },
  Potions = { [potionId] = quantity },
  DiscoveredRecipes = { [recipeId] = true },
  LastLoginUnix = number,
}

MarketState = {
  RefreshUnix = number,
  Offers = {
    { ingredientId = string, price = number, stock = number },
    ...
  }
}
```

### Data Flow (Critical Loop)

```text
[Buy]
Client Buy Request
  -> EconomyService validates coins + offer stock
  -> Mutates session state
  -> Returns updated player snapshot

[Brew]
Client Brew Request (2-4 ingredient IDs)
  -> BrewingService validates ownership + consumes ingredients
  -> Recipe match? yes: create potion, mark discovered
                 no: create sludge
  -> Returns brew result + updated state

[Sell]
Client Sell Request (potion ID, qty)
  -> EconomyService validates inventory
  -> Credits coins
  -> Returns updated state

[Persist]
Autosave interval + PlayerRemoving + BindToClose
  -> PlayerDataService writes DataStore with retry/backoff
```

### World Layout (Day One)

- **Your Shop**: player spawn/default home area with cauldron and storage anchor.
- **Ingredient Market**: stylized marketplace assets, merchant interaction UI, rotating stock board.
- **Trading Post**: selling interface and simple demand board placeholder hook.
- **Wild Grove**: basic forage nodes for free common ingredients.

## Implementation Plan

### Phase 1: Foundation Contracts + Persistent Data (~25%)

**Files/Assets:**
- `ReplicatedStorage/Shared/Types.lua` - Shared shapes and constants.
- `ReplicatedStorage/Shared/Config/Ingredients.lua` - Ingredient definitions (tier, base cost).
- `ReplicatedStorage/Shared/Config/Recipes.lua` - Starter recipe table and result mapping.
- `ReplicatedStorage/Shared/Remotes/*` - Canonical remote endpoints.
- `ServerScriptService/Services/PlayerDataService.server.lua` - DataStore load/save/session cache.
- `ServerScriptService/Bootstrap.server.lua` - Service initialization order.

**Tasks:**
- [ ] Define canonical IDs and naming rules for ingredients, potions, recipes.
- [ ] Implement DataStore schema versioning and default profile bootstrap.
- [ ] Add autosave loop, on-leave save, and BindToClose drain path.
- [ ] Add retry/backoff and warning telemetry for save/load failures.
- [ ] Provide server API for read-only player snapshot replication.

### Phase 2: Market + Economy Transactions (~25%)

**Files/Assets:**
- `ServerScriptService/Services/MarketService.server.lua` - Offer generation + refresh schedule.
- `ServerScriptService/Services/EconomyService.server.lua` - Buy/sell validation and mutation.
- `ReplicatedStorage/Shared/Config/MarketTuning.lua` - Rarity weights, stock ranges, refresh period.
- `StarterGui/MarketGui` - Offer list and countdown timer.

**Tasks:**
- [ ] Implement global 5-minute market refresh scheduler.
- [ ] Generate offers using rarity-weighted pool and bounded random stock.
- [ ] Broadcast market updates to all clients.
- [ ] Implement buy flow with anti-negative checks and stock reservation.
- [ ] Implement sell flow for brewed inventory with deterministic payouts.

### Phase 3: Brewing + Discovery + Recipe Book (~25%)

**Files/Assets:**
- `ServerScriptService/Services/BrewingService.server.lua` - Input validation and recipe resolution.
- `ReplicatedStorage/Shared/Config/Potions.lua` - Potion definitions and sell values.
- `StarterGui/BrewGui` - Ingredient selection + brew result modal.
- `StarterGui/RecipeBookGui` - Discovered recipes view.

**Tasks:**
- [ ] Support 2-4 ingredient brew submission with ownership checks.
- [ ] Consume ingredients atomically before result allocation.
- [ ] Resolve known recipe -> potion OR fallback -> sludge.
- [ ] Persist discovery flag when first-time recipe is found.
- [ ] Return concise result payload for client VFX/UI feedback.

### Phase 4: Full 4-Zone World + Interaction UX (~20%)

**Files/Assets:**
- `Workspace/Zones/YourShop`
- `Workspace/Zones/IngredientMarket` (marketplace models/art integrated)
- `Workspace/Zones/TradingPost`
- `Workspace/Zones/WildGrove`
- `StarterPlayer/StarterPlayerScripts/ZoneNavigation.client.lua`
- `StarterGui/TopBarZoneNavGui`

**Tasks:**
- [ ] Block out and connect all four zones with teleport points.
- [ ] Integrate selected marketplace assets for market visual identity.
- [ ] Add interaction prompts for market, cauldron, sell counter, forage nodes.
- [ ] Implement top-bar zone navigation buttons (mobile-safe tap targets).
- [ ] Validate playability across PC + mobile viewport layouts.

### Phase 5: Hardening + Playtest Gate (~5%)

**Files/Assets:**
- `ServerScriptService/Tests/SmokeTests.server.lua` (or equivalent harness)
- `docs/sprints/SPRINT-001.md` (execution updates during implementation)

**Tasks:**
- [ ] Run scripted smoke path: new player -> loop completion -> rejoin persistence.
- [ ] Validate edge cases: insufficient funds, insufficient ingredients, sell-empty, datastore timeout fallback.
- [ ] Tune starter values so first profitable loop occurs quickly (<2 minutes).
- [ ] Capture known gaps deferred to Sprint 002.

## Suggested Starter Content (Sprint 001)

- Ingredients: 12 total
- Recipes: 15 valid outcomes + sludge fallback
- Potion tiers in scope: Common, Uncommon, Rare (no mythic/divine yet)
- Forage nodes: 6 nodes in Wild Grove (common-only drops)

## Files Summary

| File/Path | Action | Purpose |
|---|---|---|
| `ServerScriptService/Bootstrap.server.lua` | Create | Deterministic service startup |
| `ServerScriptService/Services/PlayerDataService.server.lua` | Create | Persistent player profile management |
| `ServerScriptService/Services/MarketService.server.lua` | Create | 5-minute rotating stock engine |
| `ServerScriptService/Services/EconomyService.server.lua` | Create | Buy/sell transaction integrity |
| `ServerScriptService/Services/BrewingService.server.lua` | Create | Recipe resolution and brew outcomes |
| `ReplicatedStorage/Shared/Types.lua` | Create | Shared contracts/constants |
| `ReplicatedStorage/Shared/Config/Ingredients.lua` | Create | Ingredient catalog |
| `ReplicatedStorage/Shared/Config/Recipes.lua` | Create | Recipe mapping |
| `ReplicatedStorage/Shared/Config/Potions.lua` | Create | Potion value definitions |
| `ReplicatedStorage/Shared/Config/MarketTuning.lua` | Create | Rarity and stock tuning knobs |
| `ReplicatedStorage/Shared/Remotes/*` | Create | Client/server communication surface |
| `StarterGui/MarketGui` | Create | Market browse + buy UX |
| `StarterGui/BrewGui` | Create | Brew interaction UX |
| `StarterGui/RecipeBookGui` | Create | Discovery retention UX |
| `StarterGui/TopBarZoneNavGui` | Create | Zone navigation controls |
| `StarterPlayer/StarterPlayerScripts/ZoneNavigation.client.lua` | Create | Teleport + nav client logic |
| `Workspace/Zones/*` | Create/Populate | Full four-zone world content |

## Definition of Done

- [ ] Player can complete gather -> brew -> sell -> gather loop in one session.
- [ ] All four zones exist, are accessible, and have working interactions.
- [ ] Ingredient Market uses marketplace models/art (not primitive placeholders only).
- [ ] Market stock refreshes every 5 minutes and visibly updates for connected clients.
- [ ] DataStore persistence works for coins, inventory, and discovered recipes across rejoin.
- [ ] Invalid brew combinations produce sludge without breaking state.
- [ ] Economy validations prevent negative currency, negative stock, and duplicate sell payout.
- [ ] Mobile UI remains usable for market/brew/sell/nav flows.
- [ ] Basic smoke tests executed and pass in Studio play mode.

## Risks & Mitigations

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| DataStore throttling or transient failures | Medium | High | Session cache, retry/backoff, bounded save cadence, graceful degradation |
| Scope overload from full 4-zone requirement | High | Medium | Keep each zone mechanically minimal while preserving full footprint |
| Marketplace assets cause inconsistent collisions/performance | Medium | Medium | Curate low-poly assets, normalize collisions, run quick perf check on mobile |
| Economy exploit via remote spam | Medium | High | Server-authoritative validation, rate limiting, idempotent transaction checks |
| Recipe table errors create dead-end progression | Medium | Medium | Include guaranteed profitable starter recipes and test matrix |

## Security Considerations

- All economy and inventory mutations are server-authoritative.
- Remotes accept IDs only; server resolves authoritative definitions and pricing.
- Apply per-player rate limits/cooldowns on buy/brew/sell remotes.
- Reject malformed payloads and log suspicious request patterns.
- Never trust client countdown timers for market refresh or brew completion.

## Dependencies

- No sprint dependencies (Sprint 001).
- Roblox DataStoreService available in target environment.
- Marketplace assets selected/licensed and imported into place.

## Open Questions

1. Should market stock be globally shared per server (recommended) or individualized per player?
2. Should Wild Grove foraging drops be timer-based respawns or per-node random cooldowns?
3. Do we want starter coins fixed (e.g., 100) or scaled by first-session tutorial completion?
4. Should recipe book reveal full ingredient combos once discovered, or partial hint format?

## Exit Criteria Demo Script

1. Join as new player and confirm spawn in Your Shop.
2. Open top bar and visit Ingredient Market.
3. Purchase at least two ingredients.
4. Brew valid recipe and receive potion.
5. Brew invalid recipe and receive sludge.
6. Sell potion at Trading Post and verify coin gain.
7. Visit Wild Grove and collect at least one forage ingredient.
8. Leave/rejoin and verify persisted coins, inventory, and discovered recipe entry.
