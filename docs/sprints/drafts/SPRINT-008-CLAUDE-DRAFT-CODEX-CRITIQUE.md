# Sprint 008 Claude Draft Critique (Codex)

## Overall Assessment

Claude’s draft is directionally strong: it honors the visual-only scope, preserves core object-name contracts at a high level, and gives concrete zone-by-zone execution details. It is more actionable than a generic art brief.

The main issues are contract precision and feasibility under current code coupling. Several requirements are underspecified or contradictory in ways that can silently break foraging/interaction behavior even if the rebuilt map looks good.

## Findings (Ordered by Severity)

### 1. Critical: Forage-node prompt contract is specified incorrectly

**Where:** Phase 6 task: “Each node: visible, has ProximityPrompt or is named correctly for ForageNodeFeedback to find.”

**Problem:** In the current client/server flow, name matching alone is not enough for functional foraging:
- `InteractionController.client.lua` sends `Remotes.ForageNode:FireServer(parent.Name)` only when a **ProximityPrompt is triggered** on a `ForageNode*` parent.
- `ForageNodeFeedback.client.lua` also listens to `ProximityPromptService.PromptTriggered`.

If a node is “named correctly” but lacks a prompt, interaction fails. This is a hard functional break against sprint success criteria.

**Required fix:** Replace “or” with a strict requirement: every `ForageNode_1..12` must have a working `ProximityPrompt` attached to the node part.

### 2. High: Rare forage spawn coordinates are hardcoded but map placement assumptions are not locked

**Where:** Architecture layout + WildGrove rebuild scope.

**Problem:** `ZoneService.lua` spawns rare nodes at absolute world coordinates (`x=-180..-80`, `z=-50..50`). The draft changes world layout substantially but does not require verifying that these coordinates remain inside reachable WildGrove bounds after rebuild.

This can yield “foraging works for common nodes but rare spawns appear outside intended play area,” violating success criteria.

**Required fix:** Add an explicit verification gate: rare spawn coordinates must land on reachable WildGrove ground after rebuild (or adjust world placement to preserve this).

### 3. High: Preserve list includes speculative object names not tied to known code contracts

**Where:** Phase 1 preserve list (`MarketStall_Left`, `MarketStall_Right`, `MarketStall_Back`, `BoardFrame_*`).

**Problem:** These names are not referenced in the current script contracts reviewed (`GameController`, `InteractionController`, `ZoneService`). Preserving speculative names increases teardown complexity and can protect legacy clutter that should be removed in a “nuclear” reset.

**Required fix:** Split preserve list into:
- **Hard-contract names** (script-required, non-negotiable).
- **Soft visuals** (keep only if present and stylistically useful).

### 4. High: “No script changes” plus “foraging must work” ignores current server fragility

**Where:** Overall scope statement + Definition of Done.

**Problem:** Current `ZoneService.lua` forage pool declaration appears malformed/duplicated around node pool construction (line region near `local NP=...`). Even if this is currently running in Studio due existing state, it is fragile and should be acknowledged as a risk for a sprint that depends on foraging reliability.

**Required fix:** At minimum, add a risk item and explicit runtime verification for all 12 node IDs and ingredient awards. If policy allows, include a narrowly scoped bugfix contingency.

### 5. Medium: WildGrove sizing overshoots requirement without costed justification

**Where:** Size rules and DoD (`300x300` vs `100x100`).

**Problem:** Requirement says WildGrove must be 3x area of any other zone. Draft chooses 9x area (3x each dimension), then asks if 300-500 parts is okay. This introduces traversal and fill-density risk not justified by gameplay goals.

**Required fix:** Either:
- keep 300x300 but add density/performance budget and traversal time targets, or
- reduce to a true 3x-area footprint (for example ~173x173 if baseline is 100x100).

### 6. Medium: Lighting plan is over-prescriptive globally and may conflict with zone identity

**Where:** Lighting rule + Phase 7 global values.

**Problem:** A single global lighting profile may flatten intended contrast between “Sunken Crypt” and “warm merchant hall.” The draft mixes strong per-zone theme goals with strict global settings.

**Required fix:** Keep global lighting stable/non-flicker, but push mood differences to local fixtures/material palettes and explicitly guard interaction readability.

### 7. Medium: Anti-climb rule lacks explicit exceptions matrix

**Where:** Anti-climb rule and many decor tasks.

**Problem:** Rule says non-wall decor above threshold should be non-collide, but plan introduces many assets (pillars, ruins, mushrooms, desks, boulders). Without an explicit prop-category matrix, teams can implement inconsistent collisions and reintroduce climb exploits.

**Required fix:** Add a collision policy table by prop category (`floor`, `boundary`, `waist-high interactable`, `shelf/bookcase`, `ceiling decor`, `foliage`, etc.) and test each category.

### 8. Medium: Verification is missing explicit object-name integrity audit

**Where:** Final verification tasks.

**Problem:** The sprint heavily depends on fixed names (`SpawnPoint`, `ForageNode_*`, `MarketStall`, `SellCounter`, `DailyDemandBoard`, cauldron parts), but verification steps do not include an explicit name-contract checklist.

**Required fix:** Add a final “contract audit” that confirms exact names/parents for all required anchors before gameplay tests.

### 9. Low: “Recipe book at grimoire lectern” is aspirational but not contract-backed

**Where:** Use cases (Brewer in shop).

**Problem:** There is no direct script linkage between world lectern object and recipe book access in reviewed client flow; recipe book is HUD button-driven. This can mislead scope expectations.

**Required fix:** Rephrase as thematic/environmental placement, not interaction contract.

### 10. Low: Open questions left unresolved despite strict scope request

**Where:** Open Questions section.

**Problem:** The sprint intent is explicit (“nuke and rebuild” with concrete constraints). Open questions about zone themes/boundary style should be converted into decisions in the plan to prevent execution drift.

**Required fix:** Convert open questions into default decisions with optional override notes.

## Strengths Worth Keeping

1. Clear zone-by-zone phasing with weighted effort and concrete build tasks.
2. Strong commitment to preserving gameplay logic and avoiding unnecessary Lua churn.
3. Good emphasis on terrain cleanup, anti-climb hardening, and final playtest pass.
4. Explicit Sunken Crypt treatment for YourShop rather than generic “dark fantasy.”

## Recommended Amendments Before Merge

1. Make ProximityPrompt on every forage node mandatory (no alternative path).
2. Add rare-node coordinate reachability gate tied to current `ZoneService` hardcoded spawn range.
3. Replace speculative preserve list entries with hard-contract list + optional visual keeps.
4. Add explicit contract-audit checklist for required object names and parents.
5. Add collision policy matrix by prop category and anti-climb test matrix.
6. Resolve WildGrove sizing with quantified density/performance targets.
7. Convert open questions into concrete defaults to avoid ambiguity during execution.

## Bottom Line

Claude’s draft is a strong starting point, but it is not yet safe enough for execution as written because it under-specifies critical interaction contracts and omits checks for current code coupling (especially forage prompt and rare spawn coordinate dependencies). With the amendments above, it can become sprint-ready.
