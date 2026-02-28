# Sprint Management

This directory contains sprint planning documents for development.

## Quick Reference

```bash
# View sprint stats
python3 docs/sprints/ledger.py stats

# List all sprints
python3 docs/sprints/ledger.py list

# List by status
python3 docs/sprints/ledger.py list --status completed

# Sync ledger from .md files (run after creating new sprints)
python3 docs/sprints/ledger.py sync

# Start a sprint
python3 docs/sprints/ledger.py start 018

# Complete a sprint
python3 docs/sprints/ledger.py complete 018

# Add a new sprint manually
python3 docs/sprints/ledger.py add 019 "Sprint Title"
```

## File Structure

```
docs/sprints/
├── README.md           # This file
├── ledger.tsv          # Sprint tracking database (TSV format)
├── ledger.py           # CLI tool for sprint management
├── SPRINT-001.md       # Sprint documents (zero-padded 3 digits)
├── SPRINT-002.md
└── ...
```

## Creating a New Sprint

1. **Determine the next sprint number**:
   ```bash
   ls docs/sprints/SPRINT-*.md | tail -1
   ```

2. **Create the sprint document**:
   ```bash
   # File: docs/sprints/SPRINT-NNN.md
   ```

3. **Use the standard template** (see below)

4. **Sync the ledger**:
   ```bash
   python3 docs/sprints/ledger.py sync
   ```

## Sprint Document Template

```markdown
# Sprint NNN: Title

## Overview

Brief description of the sprint goals and motivation.

## Use Cases

1. **Use case name**: Description
2. ...

## Architecture

Diagrams, component descriptions, data flow.

## Implementation Plan

### Phase 1: Name (~X%)

**Files:**
- `path/to/file.rs` - Description

**Tasks:**
- [ ] Task 1
- [ ] Task 2

### Phase 2: ...

## API Endpoints (if applicable)

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/path`  | POST   | Description |

## Files Summary

| File | Action | Purpose |
|------|--------|---------|
| `path/to/file` | Create/Modify | Description |

## Definition of Done

- [ ] Criterion 1
- [ ] Criterion 2
- [ ] Tests pass
- [ ] No compiler warnings

## Security Considerations

- Item 1
- Item 2

## Dependencies

- Sprint NNN (if any)
- External requirements

## References

- [Link](url)
```

## Sprint Statuses

| Status | Meaning |
|--------|---------|
| `planned` | Sprint is defined but not started |
| `in_progress` | Actively being worked on |
| `completed` | All Definition of Done items met |
| `skipped` | Decided not to implement |

## Conventions

### Naming
- Files: `SPRINT-NNN.md` (zero-padded 3 digits)
- Title format: `# Sprint NNN: Short Descriptive Title`

### Content
- **Overview**: 1-2 paragraphs explaining the "why"
- **Use Cases**: Concrete scenarios this sprint enables
- **Implementation Plan**: Break into phases with percentage estimates
- **Definition of Done**: Checkboxes for acceptance criteria
- **Files Summary**: Table of files to create/modify

### Lifecycle
1. Create sprint doc with status `planned`
2. Run `ledger.py sync` to add to ledger
3. When starting: `ledger.py start NNN`
4. When done: `ledger.py complete NNN`

### For AI Assistants

When asked to create a sprint:
1. Check the highest existing sprint number
2. Create `SPRINT-{N+1}.md` using the template
3. Run `python3 docs/sprints/ledger.py sync`
4. Update `ledger.py` status if starting immediately

When completing work:
1. Update the sprint document with results
2. Run `python3 docs/sprints/ledger.py complete NNN`
