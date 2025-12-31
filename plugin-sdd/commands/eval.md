---
description: Run evals to validate implementation matches specs
---

# Run Evals

Run evals for `$ARGUMENTS` to validate implementation.

## What To Do

### 1. Find Eval Files

```bash
ls evals/$ARGUMENTS/eval_*.py
```

### 2. Run Evals

```bash
# Run specific module evals
uv run python evals/$ARGUMENTS/eval_spec_001.py

# Or run all evals for module
uv run python tools/run_evals.py --module $ARGUMENTS

# Or run all evals
uv run python tools/run_evals.py --all
```

### 3. Interpret Results

```
╔══════════════════════════════════════════════════════════════╗
║  EVAL RESULTS                                                ║
╚══════════════════════════════════════════════════════════════╝

SPEC-001: [Feature Name]
  ✅ PASS: Happy path - valid input succeeds
  ✅ PASS: Error case - invalid input returns error
  ❌ FAIL: Edge case - empty input
      Expected: ValidationError
      Actual: None returned

Results: 2/3 passed
```

### 4. Handle Failures

If evals fail:
1. Check if spec is correct (behavior as intended?)
2. Check if implementation matches spec
3. Fix implementation, not the spec/eval (unless spec was wrong)

### 5. Update Traceability

After all evals pass:
```json
{
  "id": "REQ-001",
  "eval_status": "all_passing",
  "last_eval_run": "<timestamp>"
}
```

### 6. Output Summary

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📊 EVAL RESULTS: $ARGUMENTS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

## Summary
- Total: [count]
- Passed: [count]
- Failed: [count]

## Details

### SPEC-001
| Eval | Status | Notes |
|------|--------|-------|
| Happy path | ✅ PASS | |
| Error case | ✅ PASS | |
| Edge case | ❌ FAIL | See details above |

## Next Steps
[If all pass]
- @overseer: Review for approval
- Ready for PR

[If failures]
- @backend/@frontend: Fix implementation
- Re-run: /eval $ARGUMENTS
```

$ARGUMENTS
