---
description: Show workflow status, continuity health, eval results, and next recommended action
---

# Workflow Status

Check the current state of the Spec-Driven Development workflow and continuity system.

## Checks

### 1. Continuity State
Check ledger and handoffs:
```bash
# Latest ledger
ls -t thoughts/ledgers/CONTINUITY_*.md 2>/dev/null | head -1 || echo "No ledger found"

# Latest handoff
find thoughts/shared/handoffs -name "*.md" -type f 2>/dev/null | xargs ls -t 2>/dev/null | head -1 || echo "No handoffs found"

# Active plan (check JSON first, then markdown)
ls -t thoughts/shared/plans/*.json 2>/dev/null | head -1 || \
ls -t thoughts/shared/plans/*.md 2>/dev/null | head -1 || echo "No active plan"
```

### 2. Design Documents
List files in `docs/design/`:
```bash
ls -la docs/design/*.md 2>/dev/null || echo "No design docs found"
```

### 3. Specs and Evals
```bash
# Count specs
find specs -name "SPEC-*.md" -type f 2>/dev/null | wc -l

# Count evals
find evals -name "eval_*.py" -type f 2>/dev/null | wc -l
```

### 4. Run Evals
```bash
uv run python tools/run_evals.py --all --summary 2>/dev/null || echo "Evals not configured"
```

### 5. Traceability Matrix
```bash
uv run python tools/traceability_tools.py summary traceability_matrix.json --markdown
uv run python tools/traceability_tools.py check-gaps traceability_matrix.json
```

### 6. Git Status
```bash
git status --short
```

## Output

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📊 SDD WORKFLOW STATUS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

## Continuity Health

| Item | Status |
|------|--------|
| Ledger | ✓ thoughts/ledgers/CONTINUITY_*.md |
| Last Handoff | [timestamp] |
| Active Plan | [plan name or none] |
| Context | [X]% - [green/yellow/red] |

## SDD Phase Progress

| Phase | Status | Command |
|-------|--------|---------|
| 1. Design | ✓/✗ | /design |
| 2. Review | ✓/✗ | /review-design |
| 3. Planning | ✓/✗ | /plan-sprint |
| 4. UX | ✓/✗ | /ux-spec |
| 5. Specs | ✓/✗ | /spec |
| 6. Implementation | ✓/✗ | /sdd |
| 7. Evals | ✓/✗ | /eval |
| 8. Pre-review | ✓/✗ | /pre-review |

## Traceability Summary

- Requirements: [count]
- With design: [count]
- With specs: [count]
- With evals: [count]
- With code: [count]

## Eval Status

| Status | Count |
|--------|-------|
| Passing | [count] |
| Failing | [count] |
| Pending | [count] |

## Gaps Found

[list any missing artifacts]

## Git Status

[uncommitted changes summary]

## Recommended Next Action

[specific command to run]

## Continuity Recommendation

[Based on context %, suggest /save-state + /clear if needed]
```

$ARGUMENTS
