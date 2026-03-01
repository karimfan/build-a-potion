# Sprint 004 Merge Notes

## Claude Draft Strengths
- Strong experiential framing and visual design guide for ingredients
- Creative ingredient shape templates (crystal, feather, scale, vial, flower, shard)
- Detailed market GUI card layout mockup
- Freshness and affinity system designs

## Codex Draft Strengths
- Rigorous stack-based freshness model with FIFO consumption
- Explicit Divine dual-source implementation tasks (market 0.1% + Robux ProcessReceipt)
- Per-ingredient `marketChance` field as mandatory data, not tier-range approximation
- IngredientViewportFactory as separate module for caching/reuse
- Clear V2→V3 migration contract with idempotent conversion rules

## Valid Critiques Accepted (All 7)
1. **58 vs 56 inconsistency**: Fixed. All sections now say 58 (15+14+15+12+2).
2. **Divine dual-source not implemented**: Added explicit phase for Divine market + Robux receipt.
3. **File paths wrong**: Rebased to `src/` layout.
4. **Freshness model ambiguous**: Locked to stack-based model with deterministic recompute from `acquiredUnix`/`expiresUnix`.
5. **Per-ingredient chance partial**: Every ingredient gets a `marketChance` field. Generator iterates and rolls per-ingredient.
6. **ViewportFrame weakened**: Made mandatory in DoD, no 2D fallback.
7. **Affinity overreaches**: Scoped to metadata + plumbing hooks only. No active gameplay modifiers this sprint.

## Interview Refinements Applied
1. 3D ViewportFrame previews: mandatory
2. Freshness system: full implementation with V3 migration
3. Divine: ultra-rare market (0.1%) AND Robux-purchasable

## Final Decisions
- **Freshness model**: Codex's stack-based approach with FIFO consumption
- **Visual system**: Claude's shape template + VisualDescriptor approach, rendered in ViewportFrame
- **Market generation**: Codex's per-ingredient iteration with `marketChance` field
- **Affinity**: Metadata + hooks only, defer active modifiers
- **Divine**: Codex's dual-source with ProcessReceipt handling
- **File layout**: All `src/` paths
