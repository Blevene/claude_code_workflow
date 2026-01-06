---
description: Load FULL context from ledger, handoff, and plan - use when you need complete detail (costs more context)
---

# /resume-full - Full Context Resume

**Loads complete, untruncated context for complex situations.**

Use this when:
- You're in the middle of something complex
- The optimized resume isn't giving enough detail
- You need to see full handoff/ledger/plan content

⚠️ **Note:** This uses significantly more context (~20% vs ~2% for normal resume)

## What To Do

### 1. Load Full Ledger

Read the most recent ledger file:

```bash
ls -t thoughts/ledgers/CONTINUITY_*.md 2>/dev/null | grep -v "^\._" | head -1 | xargs cat
```

Present the ENTIRE ledger content including:
- Goal
- Current Phase
- Completed items
- Key Decisions
- Working Files
- Notes for Next Session

### 2. Load Full Handoff

Read the most recent handoff file:

```bash
find thoughts/shared/handoffs -name "*.md" -type f 2>/dev/null | xargs ls -t 2>/dev/null | grep -v "/\._" | head -1 | xargs cat
```

Present the ENTIRE handoff content including:
- Current State
- What Was Done
- What Worked / What Failed
- Next Steps
- Files Modified
- Blockers
- Notes

### 3. Load Full Plan (if exists)

Read the most recent plan:

```bash
ls -t thoughts/shared/plans/*.json thoughts/shared/plans/*.md 2>/dev/null | grep -v "^\._" | head -1 | xargs cat
```

### 4. Check Current State

```bash
git status
```

If eval tools exist in this project:
```bash
test -f tools/run_evals.py && uv run python tools/run_evals.py --all 2>/dev/null || echo "No evals configured"
```

If traceability tools exist:
```bash
test -f tools/traceability_tools.py && uv run python tools/traceability_tools.py check-gaps traceability_matrix.json 2>/dev/null || echo "No traceability configured"
```

### 5. Present Full Context

## Output Format

```markdown
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔄 FULL CONTEXT RESUME
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚠️ Full context loaded - higher context usage

## CONTINUITY LEDGER
[Full ledger content]

---

## LATEST HANDOFF
[Full handoff content]

---

## ACTIVE PLAN
[Full plan content]

---

## CURRENT STATE
- Git: [status]
- Evals: [pass/fail counts]
- Traceability: [coverage]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Ready with full context. Continue where you left off.
```

## When to Use

| Situation | Command |
|-----------|---------|
| Normal work | `/clear` (auto-loads optimized context) |
| Need more detail | `/resume-full` |
| Quick status | `/status` |
| Review handoff | `/resume` |

## Related Commands

- `/resume` - Standard resume (reads handoff, presents summary)
- `/status` - Quick workflow status check
- `/save-state` - Save current state before clearing

$ARGUMENTS

