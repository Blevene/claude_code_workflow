---
description: Show workflow status, continuity health, gaps, and next recommended action
---

# Workflow Status

Check the current state of the FAANG development workflow and continuity system.

## Checks

### 1. Continuity State
Check ledger and handoffs:
```bash
# Latest ledger
ls -t thoughts/ledgers/CONTINUITY_*.md 2>/dev/null | head -1 || echo "No ledger found"

# Latest handoff
find thoughts/shared/handoffs -name "*.md" -type f 2>/dev/null | xargs ls -t 2>/dev/null | head -1 || echo "No handoffs found"

# Active plan
ls -t thoughts/shared/plans/*.md 2>/dev/null | head -1 || echo "No active plan"
```

### 2. Design Documents
List files in `docs/design/`:
```bash
ls -la docs/design/*.md 2>/dev/null || echo "No design docs found"
```

### 3. Traceability Matrix
```bash
uv run python tools/traceability_tools.py summary traceability_matrix.json --markdown
uv run python tools/traceability_tools.py check-gaps traceability_matrix.json
```

### 4. Plan Status
Check if plans exist in `thoughts/shared/plans/`.

### 5. Test Coverage
```bash
uv run pytest --cov=src --cov-report=term-missing 2>/dev/null || echo "Tests not configured"
```

### 6. Git Status
```bash
git status --short
```

## Output

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📊 WORKFLOW STATUS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

## Continuity Health

| Item | Status |
|------|--------|
| Ledger | ✓ thoughts/ledgers/CONTINUITY_*.md |
| Last Handoff | [timestamp] |
| Active Plan | [plan name or none] |
| Context | [X]% - [green/yellow/red] |

## FAANG Phase Progress

| Phase | Status | Command |
|-------|--------|---------|
| 1. Design | ✓/✗ | /design |
| 2. Review | ✓/✗ | /review-design |
| 3. Planning | ✓/✗ | /plan-sprint |
| 4. UX | ✓/✗ | /ux-spec |
| 5. TDD | ✓/✗ | /tdd |
| 6. Pre-review | ✓/✗ | /pre-review |

## Traceability Summary

- Requirements: [count]
- With design: [count]
- With tests: [count]
- With code: [count]

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
