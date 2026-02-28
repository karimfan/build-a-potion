---
description: Begin and complete the next incomplete sprint
---

## Task

Begin the next sprint. Follow these steps:

1. **Find the next incomplete sprint**
   - Run `python3 docs/sprints/ledger.py stats` to see sprint status
   - Identify the lowest-numbered sprint that is NOT completed
   - Read that sprint document: `docs/sprints/SPRINT-NNN.md`

2. **Mark sprint in progress**
   - Run `python3 docs/sprints/ledger.py start NNN`

3. **Complete the sprint**
   - Work through ALL items in the Definition of Done
   - Implement all required functionality per the sprint document
   - Run `cargo build` and `cargo test` to validate
   - Fix any build or test failures
   - Ensure all validation passes per repo standards

4. **Commit and push**
   - Stage all changes
   - Create a meaningful commit message summarizing the sprint work
   - Push to the remote repository

5. **Mark sprint completed**
   - Run `python3 docs/sprints/ledger.py complete NNN`
   - Commit the ledger update
   - Push the completion

