---
description: Update continuity ledger before /clear - preserves full context state
---

# /save-state - Update Continuity Ledger

**Run this BEFORE `/clear` to preserve context.**

## What To Do

Create or update the continuity ledger at:
`thoughts/ledgers/CONTINUITY_CLAUDE-<project>.md`

## Ledger Format

```markdown
---
project: <project-name>
updated: <ISO-timestamp>
session_id: <current-session>
---

# Continuity Ledger: <Project Name>

## Goal
<The overall objective we're working toward>

## Current Phase
<One of: REQUIREMENTS | DESIGN | PLANNING | SPEC_WRITING | IMPLEMENTATION | EVAL_VALIDATION | REVIEW>

## Constraints
- <Key constraints or rules>
- <Technical boundaries>
- <Timeline requirements>

## Completed
- [x] <Completed item with file references>
- [x] <Another completed item>

## Now
- <Current task in progress>
- <Immediate next step>

## Blocked / Parking Lot
- <Items waiting on external input>
- <Deferred decisions>

## Key Decisions
| Decision | Rationale | Date |
|----------|-----------|------|
| <What we decided> | <Why> | <When> |

## Working Files
- `path/to/file.ts` - <Brief description>
- `path/to/another.py` - <What this contains>

## Traceability Status
- Requirements: X defined
- Specs: Y created
- Evals: Z created, W passing
- Code: N files
- Gaps: <List any gaps>

## Notes for Next Session
<Anything Claude should know after /clear>
```

## How To Update

1. Read existing ledger if present
2. Update sections based on current session work:
   - Add completed items to "Completed"
   - Update "Now" with current focus
   - Add any new decisions to "Key Decisions"
   - Update "Working Files" with active files
   - Note any blockers
3. Set "Current Phase" based on workflow state
4. Update "Traceability Status" with current counts
5. Add timestamp to frontmatter

## After Saving

Tell the user:
```
✅ Ledger updated: thoughts/ledgers/CONTINUITY_CLAUDE-<project>.md

Ready for /clear. The SessionStart hook will reload this state.
```

## Integration with SDD Workflow

The ledger should reflect:
- Which SDD phase we're in (REQ → DES → PLN → SPEC → IMP → EVAL → REV)
- Traceability matrix status
- Which agents have contributed
- Eval status (passing/failing/pending)

$ARGUMENTS
