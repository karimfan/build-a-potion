# Sprint 005: Brewing Expansion - Full Recipe Matrix, Mutations, Tier-1 Advanced Brewing

## Overview

Sprint 005 turns brewing into a true discovery system by expanding from a tiny fixed recipe set to a broad launch matrix, while preserving the server-authoritative timed loop from Sprint 003 and the freshness/stack inventory model introduced in Sprint 004.

This sprint adds a complete recipe matrix (minimum 75 discoverable recipes), introduces mutation outcomes (Glowing, Bubbling, Crystallized, Shadow, Rainbow, Golden), and upgrades the cauldron flow to support advanced 3-ingredient recipes once the player reaches the Tier 1 evolution milestone (10 total brews). The outcome should be a deeper experiment-and-discover loop where every ingredient matters, failed brews still teach players, and rare discoveries create memorable reveal moments.

Interview decisions locked for this sprint:
- Mutation chance scales with ingredient quality using a base 5% plus tier/freshness bonuses.
- 3-ingredient recipes unlock at 10 total brews (same threshold as Tier 1 evolution).

## Scope Anchors (Non-Negotiable)

1. **75+ discoverable recipes** spanning Common, Uncommon, Rare, Mythic, Divine outcomes.
2. **Ingredient coverage guarantee**: every current ingredient participates in at least 2 non-sludge recipes.
3. **Mutation system shipped end-to-end**: 6 mutation types with value multipliers (2x-10x).
4. **Mutation formula uses interview decision**: base 5% + ingredient tier bonuses + freshness bonus.
5. **3-ingredient brewing unlocked at 10 brews**; before that, only 2-ingredient brewing is available.
6. **Recipe Book supports discovery progression and hints** for undiscovered entries.
7. **No regressions** to timed brewing lifecycle, persistence, buy/sell flow, or existing 15 recipes.

## Use Cases

1. **Early player progression**: Player with <10 total brews uses 2 ingredients only and discovers multiple Common recipes quickly.
2. **Tier-1 unlock moment**: At exactly 10 brews, player unlocks 3-ingredient slot and can attempt advanced recipes.
3. **Quality-driven excitement**: Player brews with Rare/Mythic ingredients and sees improved mutation odds.
4. **Freshness decision-making**: Player chooses fresher ingredients to improve mutation chance and output value.
5. **Recovery from failure**: Unknown combos produce Sludge, but player gets clear hinting in Recipe Book.
6. **Rare discovery celebration**: First-time Mythic/Divine recipe triggers enhanced reveal + announcement path.
7. **Mutation jackpot**: Player gets Golden mutation and receives clear UI callout and boosted sell value.
8. **Return-session continuity**: Existing profiles keep all discovered recipes and potion inventory intact after rollout.

## Architecture

### Recipe Keying and Lookup (2 and 3 Ingredients)

Use one canonical key format for variable-length recipes:

```lua
-- 2 ingredients: "id_a|id_b"
-- 3 ingredients: "id_a|id_b|id_c"
local function makeRecipeKey(ingredientIds)
    table.sort(ingredientIds)
    return table.concat(ingredientIds, "|")
end
```

Rules:
- Accept exactly 2 ingredients for all players.
- Accept 3 ingredients only if `BrewStats.TotalBrewed >= 10`.
- Reject 4 ingredients this sprint (explicitly deferred).
- Keep all existing 2-ingredient keys valid as-is.

### Mutation Roll Pipeline

Mutation computation occurs server-side when brew result is granted (claim time), not at brew start.

```lua
baseChance = 0.05
+ tierBonus (sum across used ingredients)
+ freshnessBonus (derived from blended freshness)

-- roll for whether mutation occurs
if random() <= totalMutationChance then
    -- weighted roll among 6 mutation types
end
```

Tier bonus proposal:
- Common: +0.0%
- Uncommon: +1.0%
- Rare: +2.0%
- Mythic: +3.0%
- Divine: +4.0%

Freshness bonus proposal:
- Average freshness >= 0.85: +1.0%
- Average freshness >= 0.65 and <0.85: +0.5%
- Otherwise: +0%

Guardrails:
- Cap total mutation chance at a configured max (ex: 20%).
- Use a separate weighted roll table for mutation type distribution.

### Mutation Storage Compatibility

To avoid a new schema migration in this sprint, use compound potion keys:
- Normal: `healing_salve`
- Mutated: `healing_salve__golden`

Compatibility behavior:
- Existing systems that iterate `data.Potions` continue to work after parsing base potion ID.
- Economy sell logic resolves base potion config + mutation multiplier.
- UI shows mutation label as a suffix badge, not part of the display name source-of-truth.

### 10-Brew Unlock Coupling

Advanced brewing unlock uses the same milestone already established for Tier 1 cauldron evolution:
- Source of truth: `BrewStats.TotalBrewed`.
- Client receives unlock flag via active brew/state payload.
- UI shows locked slot state until threshold is met.

## Implementation Plan

### Phase 1: Recipe and Potion Data Expansion (~30%)

**Files:**
- `src/shared/Config/Recipes.lua`
- `src/shared/Config/Potions.lua`
- `src/shared/Config/Ingredients.lua` (read-only validation reference)

**Tasks:**
- [ ] Expand Recipes catalog to 75+ entries across tiers.
- [ ] Ensure all recipe keys are canonical sorted 2/3 ingredient keys.
- [ ] Expand Potions catalog entries to match new outputs.
- [ ] Keep all existing 15 recipe outputs intact (no renamed IDs).
- [ ] Add lightweight validation helper to assert:
  - Every recipe points to a valid potion ID.
  - Every ingredient appears in >=2 non-sludge recipes.
  - Tier distribution matches target ranges.

### Phase 2: Server Brewing Contract for 3rd Ingredient + Unlock Gate (~20%)

**Files:**
- `src/server/Services/BrewingService.lua`
- `src/shared/Config/Recipes.lua`

**Tasks:**
- [ ] Update `BrewPotion` to accept optional third ingredient.
- [ ] Validate ingredient ownership and FIFO consumption for 2 or 3 inputs.
- [ ] Enforce unlock gate: reject third ingredient when `TotalBrewed < 10`.
- [ ] Resolve recipe via shared canonical key helper.
- [ ] Keep existing timed state machine and claim flow unchanged.
- [ ] Add server responses for unlock state and user-facing rejection reasons.

### Phase 3: Mutation System + Economy Integration (~20%)

**Files:**
- `src/shared/Config/MutationTuning.lua` (new)
- `src/server/Services/BrewingService.lua`
- `src/server/Services/EconomyService.lua`
- `src/shared/Config/BrewTuning.lua`

**Tasks:**
- [ ] Add mutation tuning config (weights, multipliers, cap, bonuses).
- [ ] Implement mutation chance formula (base 5% + tier + freshness).
- [ ] Roll mutation on claim and produce final potion key.
- [ ] Apply mutation multiplier in sell pricing.
- [ ] Ensure non-mutated potions preserve existing sell values.
- [ ] Add optional server announcement hooks for Rainbow/Golden results.

### Phase 4: Client UX - 3rd Slot, Recipe Book, Mutation Presentation (~15%)

**Files:**
- `src/client/InteractionController.client.lua`
- `src/client/GameController.client.lua`
- `src/client/FeedbackController.client.lua`

**Tasks:**
- [ ] Add third ingredient slot UI with locked state until 10 brews.
- [ ] Show clear unlock CTA at 10-brew milestone.
- [ ] Update recipe book to display:
  - Discovery count (`x / total`)
  - Tier grouping/filtering
  - Hint text for undiscovered recipes
- [ ] Add mutation badges in result and inventory displays.
- [ ] Keep mobile layout usable with 3-slot cauldron controls.

### Phase 5: Discovery and Mutation Celebration Layer (~10%)

**Files:**
- `src/client/BrewVFXController.client.lua`
- `src/client/FeedbackController.client.lua`

**Tasks:**
- [ ] Add mutation-specific completion accents (lightweight, tier-aware).
- [ ] Increase celebration intensity for first-time Rare/Mythic/Divine discoveries.
- [ ] Add special announcement path for top outcomes (Divine, Golden, Rainbow).
- [ ] Keep VFX budgets bounded for lower-end/mobile clients.

### Phase 6: Regression and Balance Validation (~5%)

**Files:**
- `src/server/Services/BrewingService.lua`
- `src/server/Services/EconomyService.lua`
- `src/shared/Config/*.lua`

**Tasks:**
- [ ] Validate all legacy 2-ingredient recipes still resolve correctly.
- [ ] Validate 3-ingredient gating behavior pre/post 10 brews.
- [ ] Run deterministic simulation of mutation distribution and verify expected ranges.
- [ ] Confirm sell values = base value * mutation multiplier.
- [ ] Verify reconnect/claim behavior unchanged for timed brews.

## Files Summary

| File | Action | Purpose |
|------|--------|---------|
| `src/shared/Config/Recipes.lua` | Rewrite | 75+ canonical 2/3 ingredient recipes |
| `src/shared/Config/Potions.lua` | Expand | Potion outputs, tiers, sell values for recipe matrix |
| `src/shared/Config/MutationTuning.lua` | Create | Mutation probabilities, bonuses, multipliers |
| `src/shared/Config/BrewTuning.lua` | Modify | Mutation chance caps/bonus tuning constants |
| `src/server/Services/BrewingService.lua` | Modify | Optional 3rd ingredient, unlock gate, mutation roll |
| `src/server/Services/EconomyService.lua` | Modify | Mutation-aware sell pricing |
| `src/client/InteractionController.client.lua` | Modify | 3rd slot UX, recipe book updates, mutation display |
| `src/client/GameController.client.lua` | Modify | Inventory/render handling for mutation key suffixes |
| `src/client/FeedbackController.client.lua` | Modify | Discovery/mutation celebration messaging |
| `src/client/BrewVFXController.client.lua` | Modify | Mutation and rarity-tier completion accents |

## Definition of Done

- [ ] 75+ recipes implemented and discoverable.
- [ ] All current ingredients appear in at least 2 recipes.
- [ ] 3-ingredient recipes are locked before 10 brews and unlocked at/after 10 brews.
- [ ] Mutation chance follows exact formula: base 5% + quality/freshness bonuses.
- [ ] 6 mutation types apply correct value multipliers.
- [ ] Mutation results persist in inventory and render correctly in UI.
- [ ] Economy sell flow correctly prices mutated and non-mutated potions.
- [ ] Recipe Book shows progression and useful hints for undiscovered recipes.
- [ ] Legacy timed brewing and claim behavior remain intact.
- [ ] Existing 15 recipes remain valid (no regressions).
- [ ] Mobile UI remains functional with 3-slot cauldron layout.

## Risks & Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Recipe dataset errors (typos, missing IDs) | Medium | High | Add validation helpers and fail-fast checks in test script |
| Mutation key format breaks existing UI assumptions | Medium | High | Centralize parse/format helper and update all inventory readers |
| 3-slot UI crowding on mobile | Medium | Medium | Use progressive reveal and compact slot layout |
| Balance spikes from mutation + high-tier recipes | Medium | Medium | Cap mutation chance and tune multipliers with simulation |
| Increased server logic complexity in brew claim | Low | Medium | Keep mutation logic modular and unit-testable |

## Security Considerations

- Mutation and recipe resolution remain server-authoritative.
- Client cannot bypass 10-brew unlock gate for 3rd ingredient.
- Sell multiplier never trusted from client payloads.
- Remote validation keeps ingredient ownership and quantities authoritative.

## Dependencies

- Sprint 003 timed brewing lifecycle and evolution milestones.
- Sprint 004 freshness stack model and expanded ingredient catalog.
- Existing remotes and UI systems in `InteractionController`/`FeedbackController`.

## Open Questions

1. Should 4-ingredient recipes be staged for Sprint 006 behind a higher cauldron tier unlock?
2. Should weather-based mutation bonuses wait for a weather system sprint rather than placeholder hooks now?
3. Do we want global announcements for all Divine outputs or only first discovery / Golden+ variants?
