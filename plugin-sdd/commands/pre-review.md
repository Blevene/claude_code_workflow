---
description: Pre-submission validation - verify all evals pass and traceability complete
---

# Pre-Review Check

Perform pre-submission validation before PR.

## What To Do

### 1. Run All Evals

```bash
uv run python tools/run_evals.py --all
```

All evals must pass.

### 2. Check Traceability

```bash
uv run python tools/traceability_tools.py check-gaps traceability_matrix.json
```

Verify:
- All REQs have specs
- All REQs have evals
- All REQs have code
- All evals are passing

### 3. Run Linting (if configured)

```bash
uv run ruff check src/ --fix 2>/dev/null || echo "Ruff not configured"
uv run mypy src/ 2>/dev/null || echo "MyPy not configured"
```

### 4. Check Git Status

```bash
git status --short
git diff --stat
```

### 5. Verify Documentation

Check that design docs match implementation.

### 6. Output Summary

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 PRE-REVIEW CHECK
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

## Eval Status
- Total: [count]
- Passing: [count]
- Failing: [count]
Status: ✅ ALL PASS / ❌ FAILURES

## Traceability
- Requirements: [count]
- With specs: [count]
- With evals: [count]
- With code: [count]
- Gaps: [list or "none"]
Status: ✅ COMPLETE / ❌ GAPS FOUND

## Code Quality
- Linting: ✅ / ⚠️ warnings / ❌ errors
- Type checking: ✅ / ⚠️ / ❌

## Git Status
- Uncommitted: [count] files
- Unstaged: [count] files

## Overall
[✅ READY FOR PR / ❌ NOT READY]

## Actions Required
[List any issues to fix]

## Next Steps
[If ready]
- Create PR with /pr command
- Request @overseer final review

[If not ready]
- Fix failing evals
- Address traceability gaps
- Commit changes
```

$ARGUMENTS
