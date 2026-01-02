---
description: Create detailed session handoff for continuing work later
---

# /handoff - Create Session Handoff

**Use when ending a session or before long break.**

Creates a detailed handoff document with everything needed to resume work.

## What To Do

Create a handoff at:
`thoughts/shared/handoffs/<session-id>/handoff-<timestamp>.md`

## Handoff Format

```markdown
---
type: session-handoff
session_id: <session-id>
created: <ISO-timestamp>
phase: <FAANG-phase>
outcome: <SUCCEEDED|PARTIAL|IN_PROGRESS>
---

# Session Handoff

## Session Summary
<2-3 sentence overview of what was accomplished>

## Work Completed

### Features/Changes
- <Feature or change with file:line references>
- <Another change>

### Files Modified
| File | Changes | Status |
|------|---------|--------|
| `src/auth/login.ts` | Added validation | ✅ Tests pass |
| `tests/auth/test_login.py` | New test cases | ✅ |

### Tests
- Tests added: <count>
- Tests passing: <count>
- Coverage: <percent if known>

## Current State

### In Progress
- <What's actively being worked on>
- <Partial implementations>

### Blocked
- <Items waiting on input>
- <External dependencies>

### Ready for Next
- <Items queued up>
- <Logical next steps>

## Key Learnings

### What Worked
- <Approach that succeeded>

### What Didn't Work
- <Approach that failed and why>

### Patterns Discovered
- <Useful patterns found in codebase>

## Context for Resume

### Important Files
```
src/auth/login.ts:45-89       # Main login logic
tests/auth/test_login.py:12   # Key test case
docs/design/auth-design.md    # Design decisions
```

### Commands to Run
```bash
# Verify tests still pass (always use uv run)
uv run pytest tests/auth/ -v

# Check traceability
uv run python tools/traceability_tools.py check-gaps traceability_matrix.json
```

### Agent History
| Agent | Task | Status |
|-------|------|--------|
| @architect | Design doc | ✅ Complete |
| @qa | Test cases | ✅ Complete |
| @backend | Implementation | 🔄 In progress |

## Next Session Recommendations

1. <First thing to do>
2. <Second priority>
3. <If time permits>

## Traceability Update

Requirements covered: REQ-001, REQ-002
Requirements pending: REQ-003, REQ-004
Design docs: auth-design.md
Test coverage: 78%
```

## How To Create

1. Review session history (files modified, decisions made)
2. Check git status for uncommitted changes
3. Check traceability matrix for coverage
4. Document any partial work with exact file:line refs
5. List learnings (what worked, what didn't)
6. Provide clear next steps

## After Creating

Tell the user:
```
✅ Handoff created: thoughts/shared/handoffs/<session>/handoff-<timestamp>.md

To resume later: /resume
The SessionStart hook will load this automatically after /clear.
```

## Also Update Ledger (AUTOMATIC)

When creating a handoff, **ALWAYS** run the ledger update script first:

```bash
# This happens automatically via the hook, but can also be triggered manually:
# The update-ledger.sh script is called with trigger="handoff"
```

The ledger update is now automatic when:
- Any TDD agent completes (subagent-stop hook)
- Context compaction occurs (pre-compact hook)
- `/handoff` is executed (you must update ledger as first step)

**REQUIRED FIRST STEP:** Before writing the handoff file, ensure the continuity ledger is updated:

1. Check if ledger exists at `thoughts/ledgers/CONTINUITY_CLAUDE-*.md`
2. If not, create it with current project state
3. Update the "Completed" section with session accomplishments
4. Update "Current Phase" based on workflow progress
5. Update "Traceability Status" with artifact counts

Then proceed with creating the detailed handoff document.

$ARGUMENTS
