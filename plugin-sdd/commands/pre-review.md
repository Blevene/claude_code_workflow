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

### 3. Check Eval Coverage

```bash
uv run python tools/eval_coverage.py
```

Verify every spec has at least one eval.

### 4. Lint Specs

```bash
uv run python tools/spec_linter.py
```

Verify all specs have proper format (REQ IDs, WHEN/THEN, etc).

### 5. Run Code Linting (if configured)

```bash
uv run ruff check src/ --fix 2>/dev/null || echo "Ruff not configured"
uv run mypy src/ 2>/dev/null || echo "MyPy not configured"
```

### 6. Check Git Status

```bash
git status --short
git diff --stat
```

### 7. Verify Documentation

Check that design docs match implementation.

### 8. Output Summary

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

## Eval Coverage
- Specs: [count]
- Covered: [count]
- Uncovered: [list or "none"]
Status: ✅ FULL COVERAGE / ❌ GAPS FOUND

## Spec Quality
- Specs linted: [count]
- Errors: [count]
- Warnings: [count]
Status: ✅ VALID / ❌ ISSUES FOUND

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
