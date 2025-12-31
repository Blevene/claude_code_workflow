---
description: Structured debugging workflow for a specific failing eval - explicit invocation with detailed steps
---

# Debug Failing Evals

Investigate and fix failing evals for `$ARGUMENTS`.

> **Note:** Use this command when you have a specific module with failing evals.
> For general debugging patterns that auto-trigger, see the `debugging` skill.

## When to Use

- You ran `/eval` and it failed
- You have a specific module to debug
- You want structured step-by-step debugging guidance

## Debug Workflow

```
/eval fails → /debug → investigate → fix → /eval → (repeat until pass)
```

## What To Do

### 1. Identify the Failure

Run evals and capture the failure:

```bash
# Run evals for the module
uv run python tools/run_evals.py --module $ARGUMENTS

# Or run specific eval file
uv run python evals/$ARGUMENTS/eval_spec_001.py
```

### 2. Understand Expected vs Actual

Read the spec to understand what SHOULD happen:

```bash
# Find the spec
ls specs/$ARGUMENTS/SPEC-*.md

# Read the spec
cat specs/$ARGUMENTS/SPEC-001.md
```

Compare:
- **Expected:** What the spec defines
- **Actual:** What the eval reports

### 3. Isolate the Problem

Determine the root cause:

| Symptom | Likely Cause |
|---------|--------------|
| Wrong output value | Logic error in implementation |
| Exception thrown | Missing error handling or invalid state |
| Timeout | Infinite loop or performance issue |
| Flaky (sometimes passes) | Race condition or non-deterministic behavior |

### 4. Trace the Execution

Add strategic debug output:

```python
# In the implementation
print(f"DEBUG: input={input_data}")
print(f"DEBUG: state={current_state}")
print(f"DEBUG: output={result}")

# Or use debugger
import pdb; pdb.set_trace()
```

### 5. Fix the Implementation

**Important:** Fix the implementation to match the spec, NOT the other way around.

Only modify the spec if:
- The spec itself was wrong (doesn't match requirements)
- Requirements have changed

### 6. Verify the Fix

```bash
# Run the specific eval
uv run python evals/$ARGUMENTS/eval_spec_001.py

# Run all evals to check for regressions
uv run python tools/run_evals.py --all
```

### 7. Check for Regressions

Ensure the fix didn't break other behaviors:

```bash
# Run all evals
uv run python tools/run_evals.py --all

# Check traceability for related specs
uv run python tools/traceability_tools.py summary traceability_matrix.json
```

## Output Format

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔍 DEBUG REPORT: $ARGUMENTS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

## Failing Eval
- File: evals/$ARGUMENTS/eval_spec_001.py
- Eval: eval_valid_input_succeeds
- Spec: SPEC-001

## Expected Behavior (from spec)
[What the spec says should happen]

## Actual Behavior
[What's actually happening]

## Root Cause
[Why it's failing - be specific]

## Fix Applied
- File: src/$ARGUMENTS/module.py
- Change: [description of fix]

## Verification
- [ ] Failing eval now passes
- [ ] All related evals pass
- [ ] No regressions in other modules

## Next Steps
- /eval $ARGUMENTS (verify fix)
- /pre-review (if all passing)
```

## Common Patterns

### Wrong Output
```
Expected: {"status": "success"}
Actual: {"status": "pending"}
```
→ Check state transitions, ensure all conditions are met

### Missing Error Handling
```
Expected: ValidationError
Actual: None returned
```
→ Add validation logic at the boundary

### Property Violation
```
Hypothesis found: encode(decode(x)) != x for x="..."
```
→ Edge case in encoding logic, fix the transformation

$ARGUMENTS
