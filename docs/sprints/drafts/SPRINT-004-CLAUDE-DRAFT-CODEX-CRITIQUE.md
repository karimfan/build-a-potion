# Critique: SPRINT-004-CLAUDE-DRAFT

## Findings (Ordered by Severity)

1. **Critical: Scope math is internally inconsistent (58 target vs 56 implementation)**
   - Reference: `SPRINT-004-CLAUDE-DRAFT.md:13`, `:96`, `:117`, `:170`, `:202`, `:229`, `:243`
   - Issue: The draft’s scope anchors/DoD require 58 ingredients (including Divine), but multiple implementation sections plan for 56 and explicitly frame “46 new ingredients.”
   - Why it matters: This will create execution drift and acceptance confusion; teams may ship the wrong catalog size.
   - Fix: Normalize all sections to one canonical count and explicitly include Divine entries in phase tasks and validation.

2. **Critical: Divine dual-source requirement is not implemented as work items**
   - Reference: `SPRINT-004-CLAUDE-DRAFT.md:13`, `:91-176`, `:241-245`
   - Issue: The requirement says Divine must be both ultra-rare market (`0.1%`) and Robux-purchasable, but implementation phases do not include Divine market roll logic, developer product IDs, `ProcessReceipt` handling, or anti-duplicate grant rules.
   - Why it matters: One of the key interview decisions is left as prose only; sprint execution can complete without meeting the requirement.
   - Fix: Add a dedicated phase (or explicit tasks) for Divine market roll + Robux receipt pipeline + idempotent grant persistence.

3. **High: Planned file paths don’t match this repository structure**
   - Reference: `SPRINT-004-CLAUDE-DRAFT.md:96`, `:122`, `:138`, `:155`, `:202-209`
   - Issue: The draft uses top-level Roblox service paths (`ReplicatedStorage/...`, `ServerScriptService/...`, `StarterPlayer/...`), while this repo’s source-of-truth code lives under `src/shared`, `src/server/Services`, and `src/client`.
   - Why it matters: Engineers following this plan will edit the wrong files or duplicate logic outside build inputs.
   - Fix: Rewrite files lists to concrete paths in `src/` (for example, `src/shared/Config/Ingredients.lua`, `src/server/Services/MarketService.lua`, `src/client/GameController.client.lua`).

4. **High: Freshness data model and migration plan is ambiguous and contradictory**
   - Reference: `SPRINT-004-CLAUDE-DRAFT.md:52-56`, `:160-162`, `:231`
   - Issue: The draft mixes per-instance freshness with optional “or simpler” stack average strategy, and stores both `acquiredUnix` and mutable `freshness` without defining source-of-truth. Migration details are underspecified.
   - Why it matters: Ambiguity here can cause non-deterministic behavior and difficult-to-debug persistence bugs during V2→V3 rollout.
   - Fix: Choose one canonical model (instance stacks or aggregated stacks), define deterministic recompute rules, and specify idempotent conversion from V2 numeric inventory.

5. **High: Per-ingredient chance requirement is only partially honored**
   - Reference: `SPRINT-004-CLAUDE-DRAFT.md:15`, `:126-132`
   - Issue: The draft promises GDD-specific per-ingredient rates, but tasks still rely on broad tier ranges (“Uncommon 50-60%, Rare 10-15%, Mythic 1.5-3%”) and omit explicit handling for ingredient-specific exceptions.
   - Why it matters: Tier-range fallback can flatten rarity identity and miss intended market distribution.
   - Fix: Require each ingredient record to carry `marketChance`; market generation should iterate records and roll that field directly.

6. **Medium: ViewportFrame requirement is weakened by fallback language**
   - Reference: `SPRINT-004-CLAUDE-DRAFT.md:220`, `:233`
   - Issue: DoD allows “ViewportFrame or visual preview,” and risk mitigation suggests fallback to 2D shapes.
   - Why it matters: Interview guidance was explicit: use 3D `ViewportFrame` previews in market GUI.
   - Fix: Make `ViewportFrame` mandatory in DoD; optimize performance via card virtualization/caching rather than changing preview modality.

7. **Medium: Affinity behavior scope likely overreaches sprint intent**
   - Reference: `SPRINT-004-CLAUDE-DRAFT.md:70-74`, `:163`
   - Issue: Draft introduces concrete affinity gameplay modifiers now (bonus values, mutation/surprise behavior) while also introducing freshness and large catalog expansion.
   - Why it matters: This increases balancing and testing load in an already high-scope sprint.
   - Fix: Scope affinity to metadata + plumbing hooks this sprint; defer active gameplay modifiers to follow-up balance sprint.

## What Claude Draft Does Well

- Strong experiential framing and clear market fantasy target.
- Includes `ViewportFrame` previews and visual variety as first-class outcomes.
- Correctly calls for DataStore V3 migration and freshness integration now (not deferred).
- Good attention to mobile UX and market-card readability.

## Recommended Revisions Before Merge

1. Resolve 58 vs 56 inconsistency everywhere (phases, tests, files summary, risk table, open questions).
2. Add explicit Divine implementation tasks: market `0.1%` path + Robux receipt handling + idempotent persistence.
3. Rebase all file references onto current `src/` layout.
4. Lock freshness model/migration to one concrete design with deterministic rules.
5. Enforce per-ingredient `marketChance` in data and generator logic.
6. Tighten DoD so `ViewportFrame` is mandatory, not optional.
7. Reduce affinity to hidden metadata and server hook points for this sprint.
