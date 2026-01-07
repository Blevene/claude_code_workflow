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
phase: <SDD-phase>
outcome: <SUCCEEDED|PARTIAL|IN_PROGRESS>
git_commit: <current HEAD SHA - run `git rev-parse HEAD`>
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
| `src/auth/login.ts` | Added validation | ✅ Evals pass |
| `specs/auth/SPEC-001.md` | New spec | ✅ |
| `evals/auth/eval_spec_001.py` | New eval | ✅ |

### Specs & Evals
- Specs added: <count>
- Evals added: <count>
- Evals passing: <count>

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
specs/auth/SPEC-001.md         # Behavioral spec
evals/auth/eval_spec_001.py    # Eval script
src/auth/login.ts:45-89        # Main login logic
docs/design/auth-design.md     # Design decisions
```

### Commands to Run
```bash
# Verify evals still pass (always use uv run)
uv run python tools/run_evals.py --module auth

# Check traceability
uv run python tools/traceability_tools.py check-gaps traceability_matrix.json
```

### Agent History
| Agent | Task | Status |
|-------|------|--------|
| @architect | Design doc | ✅ Complete |
| @spec-writer | Specs + evals | ✅ Complete |
| @backend | Implementation | 🔄 In progress |

## Next Session Recommendations

1. <First thing to do>
2. <Second priority>
3. <If time permits>

## Traceability Update

Requirements covered: REQ-001, REQ-002
Requirements pending: REQ-003, REQ-004
Specs created: SPEC-001, SPEC-002
Evals passing: 8/10
```

## How To Create

1. **Capture git commit** - Run `git rev-parse HEAD` for the `git_commit` field
2. Review session history (files modified, decisions made)
3. Check git status for uncommitted changes
4. Check traceability matrix for coverage
5. Run evals to capture current state
6. Document any partial work with exact file:line refs
7. List learnings (what worked, what didn't)
8. Provide clear next steps

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
- Any SDD agent completes (subagent-stop hook)
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
