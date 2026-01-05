---
globs: ["thoughts/ledgers/CONTINUITY_*.md"]
---

# Continuity Ledger Rules

The ledger is the single source of truth for session state and multi-phase implementations.

## File Location

- Ledgers live in: `thoughts/ledgers/`
- Format: `thoughts/ledgers/CONTINUITY_CLAUDE-<session-name>.md`
- Use kebab-case for session name
- One ledger per active work stream

## Required Sections

1. **Goal** - Success criteria (what does "done" look like?)
2. **Constraints** - Technical requirements, patterns to follow
3. **Key Decisions** - Choices made with rationale
4. **State** - Done/Now/Next with checkboxes for multi-phase work
5. **Open Questions** - Mark uncertain items as UNCONFIRMED
6. **Working Set** - Files, branch, test commands

## State Section: Multi-Phase Format

For multi-phase implementations (common in SDD workflow), use checkboxes:

```markdown
## State
- Done:
  - [x] Phase 1: Write spec for auth module (SPEC-001)
  - [x] Phase 2: Create evals for SPEC-001
- Now: [→] Phase 3: Implement auth module to pass evals
- Next: Phase 4: Run evals, iterate until passing
- Remaining:
  - [ ] Phase 5: Integration tests
  - [ ] Phase 6: Documentation
```

**Checkbox states:**
- `[x]` = Completed
- `[→]` = In progress (current)
- `[ ]` = Pending

**Why checkboxes in files:** TodoWrite survives compaction, but the *understanding* around those todos degrades each time context is compressed. File-based checkboxes are never compressed—full fidelity preserved.

## SDD-Specific Tracking

Track specs and evals in the ledger:

```markdown
## Specs & Evals
| Spec ID | Status | Evals | Last Run |
|---------|--------|-------|----------|
| SPEC-001 | ✓ Written | 3/3 passing | 2026-01-02 |
| SPEC-002 | In Progress | 0/2 passing | - |
```

## Starting an Implementation

When implementing a plan with multiple phases:
1. Add all phases as checkboxes in State section
2. Mark current phase with `[→]`
3. Update checkboxes as you complete each phase
4. Run evals after each implementation phase

## When to Update

- After completing a phase (update checkbox immediately)
- After running evals (update pass/fail counts)
- Before `/clear` (always clear, never compact)
- When context usage >70%

## UNCONFIRMED Prefix

Mark uncertain information that needs verification after context reload:

```markdown
## Open Questions
- UNCONFIRMED: Does the auth middleware need updating?
- UNCONFIRMED: Is the database schema finalized?
```

## After Clear

1. Ledger loads automatically (SessionStart hook)
2. Find `[→]` to see current phase
3. Verify any UNCONFIRMED items
4. Run `uv run python tools/run_evals.py --all` to confirm state
5. Continue from where you left off with fresh context

## Integration with Handoffs

Ledger = cumulative state (compact, survives many clears)
Handoff = detailed snapshot (rich context for specific transition)

Use both:
- Update ledger continuously
- Create handoff before major transitions or end of session

