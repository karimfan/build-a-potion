# Sprint 008 Merge Notes

## Claude Draft Strengths
- Detailed zone-by-zone build tasks with specific coordinates, materials, and colors
- SVG-driven shop layout with all 8 elements mapped to positions
- Explicit CanCollide rules per element
- Interview results incorporated (distinct zone themes, natural edge boundaries)

## Codex Draft Strengths
- "Scope Anchors" section as non-negotiable invariants — cleaner framing
- "Preserve vs Rebuild Contract" with explicit interaction continuity section
- Separate phases for collision hardening and foraging reliability
- Better risk analysis tied to actual code contracts

## Valid Critiques Accepted

1. **CRITICAL: ProximityPrompt mandatory on all ForageNodes** — Codex is right. `InteractionController.client.lua` requires a ProximityPrompt trigger. Name alone is insufficient. Fixed in final.

2. **HIGH: Rare forage spawn coordinates** — ZoneService.lua uses hardcoded X/Z ranges. Must verify they land in rebuilt WildGrove. Added verification gate.

3. **HIGH: Trim preserve list** — Removed `MarketStall_Left/Right/Back` and `BoardFrame_*` from hard-contract list. Only script-referenced names are mandatory.

4. **MEDIUM: WildGrove sizing** — 300x300 is 9x area, not 3x. True 3x area = ~175x175. Corrected to 175x175 in final.

5. **MEDIUM: Collision policy matrix** — Added explicit prop-category table.

6. **MEDIUM: Name-contract audit** — Added as verification step.

7. **LOW: Grimoire lectern** — Rephrased as thematic, not interaction-contract.

## Critiques Rejected (with reasoning)

- **ZoneService fragility (Finding #4)**: The malformed code observation is noted as a risk but NOT a script fix in this sprint. The sprint scope is purely visual. If foraging fails during testing, we escalate as a separate hotfix.

- **Lighting over-prescriptive (Finding #6)**: Partially rejected. Global lighting DOES need stable defaults to prevent blown-out or pitch-black zones. Local fixtures handle mood. Both approaches can coexist.

## Interview Refinements Applied
- Zone themes: Distinct (Market = outdoor bazaar, TradingPost = warm merchant hall)
- Boundaries: Natural edges (hedges, trees, rocks, fences) instead of stone walls
- Open questions resolved and converted to decisions

## Final Decisions
- WildGrove: 175x175 studs (true 3x area vs 100x100 baseline)
- Other zones: 100x100 studs each
- Boundaries: Natural per zone theme (crypt=stone walls, market=hedges, trade=wood fence, grove=tree line)
- Every ForageNode MUST have ProximityPrompt child
- Performance budget: max ~400 parts per zone, ~600 for WildGrove
- Global lighting: stable non-flicker baseline; zone mood via local fixtures
