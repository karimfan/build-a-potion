# Sprint 002 Merge Notes

## Claude Draft Strengths
- Detailed per-zone prop category tables with specific counts (shelves: 3-4, bottles: 5-8, etc.)
- Concrete task lists with specific Roblox implementation details (PointLight ranges, ParticleEmitter configs, SurfaceGui construction)
- Phase 0 cleanup pass correctly addresses broken IngredientMarket positioning and loose workspace models
- Ambient audio section with specific Sound object parameters (Volume, RollOffMaxDistance, Looped)
- Good zone-specific identity targets (cozy lab, bustling bazaar, golden hall, enchanted forest)

## Codex Draft Strengths
- Scope Anchors section as a first-class concept — makes hard requirements impossible to miss
- Environment Layering Model (Gameplay / Presentation / Validation) — excellent conceptual separation
- Boundary System Standard — formal 4-layer composition (base barrier → softener → overgrowth → gap handling)
- Exit Criteria Walkthrough — a concrete step-by-step acceptance test script
- Zone Identity Targets table with required visual language AND required audio per zone
- Phase 1 as explicit "World Audit + Guardrails" before any building begins

## Valid Critiques Accepted

1. **Boundary inconsistency (HIGH)**: Claude's draft still had WildGrove using "fallen logs, rock walls, dense bushes as natural perimeter (instead of fences)" — this violates the interview requirement for stone walls + hedges everywhere. **Fix: enforce stone+hedge+vine in WildGrove too, with natural elements as supplementary decoration only.**

2. **Density acceptance too subjective (HIGH)**: "No visible empty flat floor" needs measurement criteria. **Fix: adopt Codex's 6-camera-checkpoint approach per zone with 360-degree sweep.**

3. **Performance guardrails underspecified (HIGH)**: Maximum density without budgets is risky. **Fix: add per-zone performance budget targets.**

4. **Audio transition quality (MEDIUM)**: Claude's draft had rolloff specs but no cross-zone transition testing. **Fix: add explicit transition walk test.**

5. **Loose model disposition ambiguous (MEDIUM)**: **Fix: default policy — relocate into zones only if style-consistent; otherwise delete and insert fresh curated assets.**

## Critiques Rejected (with reasoning)

1. **"Execution ownership not clearly partitioned"**: For an environment art sprint executed via MCP tools in a single session, formal execution ownership partitioning adds overhead without value. The implementer is the same person for all phases.

2. **"Signage naming style guide needed"**: Over-engineering for this sprint scope. Signs will use plain descriptive text in a fantasy serif font. We can standardize further in a future UI polish sprint.

## Interview Refinements Applied

1. **Cozy cluttered**: Maximum density target is now a Scope Anchor in the final doc
2. **Stone walls + hedges + vine overgrowth**: Formalized as the Boundary System Standard; wooden fences explicitly excluded everywhere including WildGrove
3. **Ambient audio**: Full audio phase with per-zone sound specs and transition testing

## Final Decisions

- **Structure**: Adopt Codex's Scope Anchors, Environment Layering Model, Boundary System Standard, and Exit Criteria Walkthrough
- **Detail**: Keep Claude's per-zone prop category tables, specific Roblox implementation parameters, and detailed task lists
- **Phasing**: Hybrid — Codex's Phase 1 audit, then Claude's zone-by-zone passes (with Codex's density verification after each), then boundaries+signage+FX, then audio, then regression gate
- **Performance**: Add Codex's suggested per-zone budgets as guidelines (not hard blocks — this is a visual sprint, we'll iterate)
- **Boundaries**: Codex's 4-layer Boundary System Standard applied uniformly, including WildGrove
- **Audio**: Claude's specific Sound parameters merged with Codex's transition quality criteria
