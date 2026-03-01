# Sprint 001: Vertical Slice — Full World, Core Loop, Persistent Economy

## Overview

Sprint 001 establishes a playable, persistent vertical slice of Brew a Potion with the full day-one world footprint. A new player spawns into a magical village, navigates between four zones, buys ingredients from a rotating market, brews potions in a cauldron (or fails into Sludge), sells potions for coins, and keeps progress across sessions.

This sprint prioritizes architecture and systems correctness over breadth. We implement minimal but production-shaped versions of each system so later sprints add depth without rewrites. The core loop should close within 60–120 seconds of a player's first session.

The design philosophy mirrors the game design doc: "Get the loop right, get it live, and let real player data guide your iteration."

## Scope Anchors (Non-Negotiable)

These were confirmed during planning and are hard requirements:

1. **Full 4-zone map** exists and is traversable (Your Shop, Ingredient Market, Trading Post, Wild Grove)
2. **Marketplace models/art** used from day one (not graybox-only)
3. **Market stock rotates** on a strict 5-minute cadence with rarity-weighted selection
4. **DataStore persistence** for coins, inventory, and discovered recipes from day one

## Iterative Build Strategy (Future Sprints)

This sprint is the foundation. Here's how the full game emerges:

| Sprint | Theme | Adds |
|--------|-------|------|
| **001** | Vertical Slice | Full world, core loop, persistence, rotating market |
| **002** | Progression & Upgrades | Cauldron tiers, brew timers, storage expansion, mutation system |
| **003** | Recipe Depth & Discovery | Full recipe matrix (50+), discovery animations, recipe hints |
| **004** | Monetization | Gems currency, game passes, developer products, Daily Demand Board |
| **005** | Social Mechanics | Potion effects on players, gifting, ingredient stealing, shop visiting |
| **006** | Visual Polish & Audio | Particle effects, brewing animations, ambient sounds, weather |
| **007** | Live Ops & Retention | Daily login rewards, weekly content drops, leaderboards, events |
| **008** | Launch Prep | Analytics, exploit prevention, mobile/Xbox testing, soft launch |

Each sprint produces a playable increment. We can reorder, split, or merge based on feedback.

## Use Cases

1. **First minute comprehension**: A new player spawns in Your Shop, sees top-bar zone navigation, teleports to the market, buys ingredients, brews at cauldron, sells at trading post — all within 60 seconds.
2. **Persistent progression**: A returning player rejoins and retains coins, ingredient inventory, potion inventory, and discovered recipe book entries.
3. **Scarcity pressure**: A player waits for market refresh and sees stock change, including occasional uncommon offers.
4. **Failure path clarity**: A player submits an invalid combination and receives Sludge (worth 2 coins) with clear feedback.
5. **Recipe discovery payoff**: A player discovers a new valid combination — "New Recipe Discovered!" — permanently saved to their recipe book.
6. **Economy sanity**: Common recipes are profitable (Healing Salve sells for 25, ingredients cost 15 total), but scaling earnings requires discovering rarer recipes.
7. **Foraging alternative**: A player visits Wild Grove and collects free common ingredients by clicking glowing nodes, providing a zero-cost entry to brewing.

## Architecture

### High-Level Runtime Topology

```
Client (StarterPlayerScripts + StarterGui)
  ├── UIController (market, brew, sell, recipe book, HUD)
  ├── InteractionController (proximity prompts, GUI triggers)
  ├── ZoneNavController (top-bar zone buttons, teleport)
  └── ReplicatedStorage.Remotes (request/response)

Server (ServerScriptService)
  ├── Bootstrap (deterministic service init order)
  ├── PlayerDataService (DataStore load/save/session cache)
  ├── MarketService (5-min stock generator + broadcast)
  ├── BrewingService (recipe resolution + discovery tracking)
  ├── EconomyService (buy/sell transaction validation)
  └── ZoneService (teleport endpoints + validation)

Shared (ReplicatedStorage)
  ├── Config/
  │   ├── Ingredients (catalog: id, name, tier, cost, element)
  │   ├── Recipes (combination → potion mapping)
  │   ├── Potions (id, name, description, sell value, rarity)
  │   └── MarketTuning (rarity weights, stock ranges, refresh period)
  ├── Types (shared constants and enums)
  └── Remotes/ (RemoteEvents + RemoteFunctions)

World (Workspace)
  ├── Zones/
  │   ├── YourShop (spawn, cauldron, storage)
  │   ├── IngredientMarket (marketplace models, merchant stall)
  │   ├── TradingPost (sell counter, demand board placeholder)
  │   └── WildGrove (forage nodes, ambient nature)
  └── Teleport points + spawn location
```

### Core Data Model (Server Authoritative)

```lua
-- Player session state (cached in memory, persisted to DataStore)
PlayerState = {
    Version = 1,                              -- Schema version for migrations
    Coins = number,                           -- Starting: 100
    Ingredients = { [ingredientId] = quantity }, -- e.g., { mushroom = 3, river_water = 1 }
    Potions = { [potionId] = quantity },        -- e.g., { healing_salve = 2 }
    DiscoveredRecipes = { [recipeId] = true },  -- e.g., { healing_salve = true }
    LastLoginUnix = number,                    -- For future daily rewards
}

-- Global market state (shared per server, refreshes every 5 min)
MarketState = {
    RefreshTime = number,                     -- os.time() of next refresh
    Offers = {
        { ingredientId = string, price = number, stock = number },
        ...
    }
}
```

### Data Flow (Critical Loop)

```
[Buy]
Client clicks "Buy" in MarketGui
  → RemoteEvent:BuyIngredient(ingredientId, quantity)
  → EconomyService validates: coins >= cost, offer has stock
  → Deducts coins, decrements stock, adds ingredient to inventory
  → Returns updated player snapshot to client

[Brew]
Client selects 2 ingredients and clicks "Brew" in CauldronGui
  → RemoteFunction:BrewPotion(ingredientId1, ingredientId2)
  → BrewingService validates: player owns both ingredients
  → Consumes ingredients atomically
  → Looks up sorted pair in RecipeData
  → Match → creates potion, marks recipe as discovered
  → No match → creates Sludge
  → Returns { success, potionId, isNewDiscovery }

[Sell]
Client clicks "Sell" in SellGui
  → RemoteEvent:SellPotion(potionId, quantity)
  → EconomyService validates: player owns potion
  → Removes potion, credits coins (from PotionData sell value)
  → Returns updated player snapshot

[Forage]
Client clicks glowing node in Wild Grove
  → RemoteEvent:ForageNode(nodeId)
  → Server validates: node exists, not on cooldown for this player
  → Awards random common ingredient, starts cooldown
  → Returns { ingredientId, cooldownSeconds }

[Persist]
  → Autosave every 60 seconds (bounded to avoid throttling)
  → game.Players.PlayerRemoving → immediate save
  → game:BindToClose → drain all pending saves
  → Retry with exponential backoff on failure
```

## Implementation Plan

### Phase 1: Data Definitions & Persistent Infrastructure (~25%)

Set up the shared data modules and DataStore-backed player persistence.

**Files/Assets:**
- `ReplicatedStorage/Shared/Types` (ModuleScript) — Shared constants, enums
- `ReplicatedStorage/Shared/Config/Ingredients` (ModuleScript) — Ingredient catalog
- `ReplicatedStorage/Shared/Config/Recipes` (ModuleScript) — Recipe mappings
- `ReplicatedStorage/Shared/Config/Potions` (ModuleScript) — Potion catalog
- `ReplicatedStorage/Shared/Config/MarketTuning` (ModuleScript) — Rarity weights, refresh period
- `ReplicatedStorage/Remotes/` (Folder) — RemoteEvents and RemoteFunctions
- `ServerScriptService/Bootstrap` (Script) — Deterministic service startup
- `ServerScriptService/Services/PlayerDataService` (Script) — DataStore load/save/session cache

**Tasks:**
- [ ] Create Ingredients module with 12 starter ingredients (see content table below)
- [ ] Create Recipes module with 15 recipes + Sludge fallback
- [ ] Create Potions module with sell values and rarity tiers
- [ ] Create MarketTuning module (rarity weights, stock ranges, 300s refresh)
- [ ] Create RemoteEvents: BuyIngredient, BrewPotion, SellPotion, ForageNode, MarketRefresh
- [ ] Create RemoteFunctions: GetPlayerData, GetMarketOffers
- [ ] Build PlayerDataService with DataStore schema versioning (Version = 1)
- [ ] Implement default profile bootstrap (100 coins, empty inventory)
- [ ] Add autosave loop (60s interval), PlayerRemoving save, BindToClose drain
- [ ] Add retry/backoff on DataStore failures with warning output
- [ ] Build Bootstrap script for deterministic service initialization order

**Starter Ingredients (12):**

| ID | Name | Tier | Cost | Element |
|----|------|------|------|---------|
| mushroom | Mushroom | Common | 10 | Earth |
| fern_leaf | Fern Leaf | Common | 8 | Earth |
| river_water | River Water | Common | 5 | Water |
| ember_root | Ember Root | Common | 15 | Fire |
| fire_salt | Fire Salt | Common | 12 | Fire |
| dewdrop | Dewdrop | Common | 7 | Water |
| moss_clump | Moss Clump | Common | 6 | Earth |
| wind_blossom | Wind Blossom | Common | 9 | Air |
| crystal_dust | Crystal Dust | Uncommon | 50 | Light |
| moonpetal | Moonpetal | Uncommon | 60 | Shadow |
| dragon_scale | Dragon Scale | Rare | 300 | Fire |
| phoenix_feather | Phoenix Feather | Rare | 500 | Fire |

**Starter Recipes (15 + Sludge):**

| Ingredients (sorted) | Result | Sell Value | Tier |
|-----------------------|--------|------------|------|
| mushroom + river_water | Healing Salve | 25 | Common |
| fern_leaf + river_water | Growth Potion | 30 | Common |
| fern_leaf + mushroom | Forest Remedy | 20 | Common |
| dewdrop + river_water | Purification Elixir | 18 | Common |
| ember_root + fire_salt | Flame Draught | 45 | Common |
| moss_clump + wind_blossom | Breeze Tonic | 22 | Common |
| dewdrop + mushroom | Dew Brew | 28 | Common |
| fire_salt + wind_blossom | Spark Elixir | 35 | Common |
| crystal_dust + mushroom | Glow Potion | 90 | Uncommon |
| dewdrop + moonpetal | Night Vision Tonic | 120 | Uncommon |
| fire_salt + moonpetal | Shadow Flame Brew | 150 | Uncommon |
| crystal_dust + moonpetal | Starlight Serum | 200 | Uncommon |
| crystal_dust + ember_root | Fire Shield Elixir | 180 | Uncommon |
| dragon_scale + moonpetal | Dragonheart Potion | 1200 | Rare |
| moonpetal + phoenix_feather | Rebirth Potion | 1500 | Rare |
| *(any invalid combo)* | Sludge | 2 | — |

### Phase 2: Market System + Economy (~25%)

Build the rotating ingredient market and buy/sell transaction logic.

**Files/Assets:**
- `ServerScriptService/Services/MarketService` (Script) — Offer generation + 5-min refresh scheduler
- `ServerScriptService/Services/EconomyService` (Script) — Buy/sell validation and execution
- `StarterGui/MarketGui` (ScreenGui) — Offer list, prices, stock counts, refresh countdown
- `StarterGui/MarketGui/MarketController` (LocalScript) — Client buy logic
- `StarterGui/SellGui` (ScreenGui) — Potion sell interface
- `StarterGui/SellGui/SellController` (LocalScript) — Client sell logic

**Tasks:**
- [ ] Implement global 5-minute market refresh scheduler (server-side timer)
- [ ] Generate offers using rarity-weighted pool: Common (always, stock 10-20), Uncommon (60% chance, stock 3-8), Rare (15% chance, stock 1-2)
- [ ] Broadcast market updates to all clients via MarketRefresh RemoteEvent
- [ ] Build MarketGui: scrollable ingredient list with name, element color, price, stock count, "Buy" button, refresh countdown timer
- [ ] Build buy flow: validate coins >= cost, stock > 0, deduct coins, decrement stock, add ingredient
- [ ] Build SellGui: scrollable potion list with name, sell value, quantity, "Sell" button
- [ ] Build sell flow: validate player owns potion, remove potion, credit coins
- [ ] Show coin change feedback ("+25 coins" floating notification)
- [ ] Both GUIs open via ProximityPrompt on respective zone stations

### Phase 3: Brewing System + Recipe Book (~20%)

The heart of the game — combining ingredients in the cauldron.

**Files/Assets:**
- `ServerScriptService/Services/BrewingService` (Script) — Recipe resolution, discovery tracking
- `StarterGui/CauldronGui` (ScreenGui) — Ingredient selection, brew button, result display
- `StarterGui/CauldronGui/CauldronController` (LocalScript) — Client brewing logic
- `StarterGui/RecipeBookGui` (ScreenGui) — Discovered recipes viewer
- `StarterGui/RecipeBookGui/RecipeBookController` (LocalScript) — Client recipe book logic

**Tasks:**
- [ ] Build BrewingService: receive 2 ingredient IDs, sort alphabetically, look up in RecipeData
- [ ] Validate player owns both ingredients, consume atomically before result
- [ ] Match → create potion, check if first discovery, mark in DiscoveredRecipes
- [ ] No match → create Sludge (potionId: "sludge", sell value: 2)
- [ ] Return result payload: { success, potionId, potionName, isNewDiscovery }
- [ ] Build CauldronGui: show player's ingredients (grid), two selection slots, "Brew" button
- [ ] Show brief brew result: potion name + "New Recipe Discovered!" banner if first time
- [ ] Build RecipeBookGui: list of discovered recipes showing ingredients → potion name + value
- [ ] Undiscovered recipes show as "???" entries to tease completionist play
- [ ] RecipeBook accessible via a persistent button in HUD (no proximity prompt needed)

### Phase 4: Full 4-Zone World + Interaction UX (~20%)

Build the physical game world and wire up all interactions.

**Files/Assets:**
- `Workspace/Zones/YourShop` (Model) — Player home, cauldron, spawn point
- `Workspace/Zones/IngredientMarket` (Model) — Marketplace models, merchant stalls
- `Workspace/Zones/TradingPost` (Model) — Sell counter, demand board area
- `Workspace/Zones/WildGrove` (Model) — Nature area, forage nodes
- `StarterGui/TopBarNavGui` (ScreenGui) — Zone navigation buttons
- `StarterGui/HudGui` (ScreenGui) — Persistent coin counter, recipe book button
- `StarterPlayer/StarterPlayerScripts/InteractionController` (LocalScript) — Proximity prompts, GUI management
- `StarterPlayer/StarterPlayerScripts/ZoneNavController` (LocalScript) — Teleport logic
- `ServerScriptService/Services/ZoneService` (Script) — Teleport validation, forage node logic

**Tasks:**
- [ ] Build Your Shop zone: cozy room with cauldron (ProximityPrompt → CauldronGui), warm lighting, spawn point
- [ ] Build Ingredient Market zone: marketplace models from Roblox marketplace, merchant stall (ProximityPrompt → MarketGui)
- [ ] Build Trading Post zone: sell counter (ProximityPrompt → SellGui), open area for future trading
- [ ] Build Wild Grove zone: nature area with 6 forageable nodes (glowing parts, ProximityPrompt → collect ingredient)
- [ ] Implement forage nodes: server validates, awards random common ingredient, 60s per-player cooldown
- [ ] Insert marketplace models for visual quality (cauldron, market stalls, furniture, nature elements)
- [ ] Build TopBarNavGui: 4 zone buttons at top of screen (mobile-safe tap targets, UDim2 scaling)
- [ ] Build ZoneNavController: clicking a zone button teleports player to that zone's spawn point
- [ ] Build HudGui: persistent coin counter (top-right), recipe book button (opens RecipeBookGui)
- [ ] Build InteractionController: manage ProximityPrompt triggers, ensure only one GUI open at a time
- [ ] Set warm ambient lighting (Lighting service: warm ColorShift, bloom, point lights near cauldron)

### Phase 5: Hardening + Playtest Gate (~10%)

Validate the full loop works end-to-end before declaring done.

**Tasks:**
- [ ] Run exit criteria demo script (see below) in Studio play mode
- [ ] Validate edge cases: insufficient coins, insufficient ingredients, sell with empty inventory, DataStore timeout fallback
- [ ] Verify economy: first profitable loop completes in < 2 minutes (buy 2 commons, brew, sell for profit)
- [ ] Verify DataStore: leave and rejoin, confirm coins/inventory/recipes persist
- [ ] Verify market refresh: wait 5 minutes, confirm stock changes and client UI updates
- [ ] Test on mobile viewport (narrow aspect ratio, touch-friendly buttons)
- [ ] Document known gaps deferred to Sprint 002

## Files Summary

| Location | Type | Purpose |
|----------|------|---------|
| `ServerScriptService/Bootstrap` | Script | Deterministic service startup order |
| `ServerScriptService/Services/PlayerDataService` | Script | DataStore load/save/session cache |
| `ServerScriptService/Services/MarketService` | Script | 5-minute rotating stock engine |
| `ServerScriptService/Services/EconomyService` | Script | Buy/sell transaction validation |
| `ServerScriptService/Services/BrewingService` | Script | Recipe resolution and brew outcomes |
| `ServerScriptService/Services/ZoneService` | Script | Teleport validation, forage node logic |
| `ReplicatedStorage/Shared/Types` | ModuleScript | Shared constants and enums |
| `ReplicatedStorage/Shared/Config/Ingredients` | ModuleScript | Ingredient catalog |
| `ReplicatedStorage/Shared/Config/Recipes` | ModuleScript | Recipe combination mappings |
| `ReplicatedStorage/Shared/Config/Potions` | ModuleScript | Potion definitions and sell values |
| `ReplicatedStorage/Shared/Config/MarketTuning` | ModuleScript | Rarity weights, stock ranges, refresh period |
| `ReplicatedStorage/Remotes/` | Folder | RemoteEvents and RemoteFunctions |
| `StarterGui/MarketGui` | ScreenGui + LocalScript | Market browse + buy interface |
| `StarterGui/CauldronGui` | ScreenGui + LocalScript | Brewing interaction interface |
| `StarterGui/SellGui` | ScreenGui + LocalScript | Potion selling interface |
| `StarterGui/RecipeBookGui` | ScreenGui + LocalScript | Discovered recipes viewer |
| `StarterGui/TopBarNavGui` | ScreenGui + LocalScript | Zone navigation buttons |
| `StarterGui/HudGui` | ScreenGui + LocalScript | Persistent coin counter + recipe book button |
| `StarterPlayer/StarterPlayerScripts/InteractionController` | LocalScript | Proximity prompts, GUI management |
| `StarterPlayer/StarterPlayerScripts/ZoneNavController` | LocalScript | Teleport logic |
| `Workspace/Zones/YourShop` | Model | Player home zone with cauldron |
| `Workspace/Zones/IngredientMarket` | Model | Marketplace with merchant stalls |
| `Workspace/Zones/TradingPost` | Model | Sell counter zone |
| `Workspace/Zones/WildGrove` | Model | Nature foraging zone |

## Definition of Done

- [ ] Player spawns in Your Shop and can see the cauldron
- [ ] Top-bar navigation allows teleporting between all 4 zones
- [ ] All 4 zones have distinct environments with marketplace models/art
- [ ] Ingredient Market shows rotating stock with prices, quantities, and refresh countdown
- [ ] Market stock refreshes every 5 minutes with rarity-weighted selection visible to all players
- [ ] Player can buy ingredients (coins deducted, ingredient added to inventory)
- [ ] Cauldron GUI allows selecting 2 ingredients and brewing
- [ ] Valid combinations produce the correct potion; invalid combinations produce Sludge
- [ ] "New Recipe Discovered!" feedback on first-time discovery
- [ ] Recipe Book shows discovered recipes and "???" for undiscovered
- [ ] Sell counter allows selling potions for coins
- [ ] HUD shows current coin balance, updates in real-time
- [ ] Wild Grove has forageable nodes that award free common ingredients with cooldowns
- [ ] Economy is positive-sum for common recipes (e.g., Healing Salve 25 > Mushroom 10 + River Water 5)
- [ ] DataStore persistence: coins, inventory, and discovered recipes survive rejoin
- [ ] All transactions are server-authoritative (no client-side cheating)
- [ ] Works in Roblox Studio play mode
- [ ] Full loop completes in under 2 minutes for a new player

## Exit Criteria Demo Script

1. Join as new player → confirm spawn in Your Shop with 100 coins
2. Open top bar → teleport to Ingredient Market
3. Purchase Mushroom (10 coins) and River Water (5 coins) → verify 85 coins remaining
4. Teleport to Your Shop → interact with cauldron
5. Select Mushroom + River Water → click Brew → receive Healing Salve + "New Recipe Discovered!"
6. Select two random ingredients → click Brew → receive Sludge
7. Teleport to Trading Post → sell Healing Salve → verify +25 coins (110 total)
8. Teleport to Wild Grove → click forage node → receive free ingredient
9. Open Recipe Book → see Healing Salve and Sludge as discovered, others as "???"
10. Leave game → rejoin → verify coins = 110, Sludge in inventory, Healing Salve recipe discovered
11. Wait for market refresh → verify stock changes and countdown resets

## Risks & Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| DataStore throttling or transient failures | Medium | High | Session cache, retry/backoff, bounded 60s save cadence, graceful degradation |
| Scope overload from full 4-zone + persistence | High | Medium | Keep each zone mechanically minimal; functional over pretty |
| Marketplace assets cause collisions/perf issues | Medium | Medium | Curate low-poly assets, normalize collisions, test on mobile |
| Economy exploit via remote spam | Medium | High | Server-authoritative validation, cooldowns on remotes |
| Recipe table errors create dead-end progression | Medium | Medium | Guaranteed profitable starter recipes, test all 15 combos |
| MCP code injection brittle for large scripts | Medium | High | Build incrementally, test each module before moving to next |

## Security Considerations

- All economy and inventory mutations are server-authoritative
- Remotes accept IDs only; server resolves definitions and pricing from authoritative Config modules
- Per-player cooldowns on buy/brew/sell/forage remotes to prevent spam
- Reject malformed payloads and log suspicious request patterns
- Never trust client-side timers for market refresh or brew state
- DataStore writes use session cache → periodic flush pattern (not per-transaction writes)

## Dependencies

- No sprint dependencies (Sprint 001, greenfield)
- Roblox DataStoreService available in target Studio environment
- Roblox Creator Marketplace for model assets (cauldron, furniture, nature elements)

## Open Questions

1. Should market stock be globally shared per server (recommended) or individualized per player?
2. Should Wild Grove forage drops use fixed respawn timers (60s) or random cooldowns (30-90s)?
3. Should the recipe book reveal full ingredient combos once discovered, or show a partial hint format?
4. Starting coins: fixed 100, or adjusted based on future playtesting?
