---
name: debugging
description: Debugging patterns and methodology - AUTO-TRIGGERS when debugging emerges naturally. For explicit structured debugging of a specific module, use /debug command instead.
---

# Debugging Skill

> **This skill auto-triggers** when debugging patterns emerge in conversation.
> For explicit, structured debugging of a specific failing eval, use `/debug <module>`.

## When This Auto-Triggers

- Discussion of bugs or unexpected behavior
- Mentioning errors or exceptions
- Questions about why code doesn't match spec
- Troubleshooting in progress

## SDD Debugging Principle

**Fix the implementation to match the spec, not the other way around.**

Only change the spec if:
- The spec was wrong (doesn't match requirements)
- Requirements have changed

## Debugging Approach

### 1. Understand the Expected Behavior
- Read the spec: `specs/module/SPEC-*.md`
- Check the eval: What behavior is being validated?
- Identify the gap between expected and actual

### 2. Reproduce the Issue
```bash
# Run specific eval
uv run python evals/module/eval_spec_001.py

# Run all evals for module
uv run python tools/run_evals.py --module module

# Run all evals with verbose output
uv run python tools/run_evals.py --all
```

### 3. Isolate the Problem

| Question | How to Check |
|----------|--------------|
| Is the spec correct? | Compare spec to original requirement |
| Is the eval correct? | Does it test what the spec says? |
| Is the implementation correct? | Does it match spec behavior? |

### 4. Trace the Execution
```python
# Add strategic print statements
print(f"DEBUG: input={input_data}")
print(f"DEBUG: state={current_state}")
print(f"DEBUG: output={result}")

# Or use debugger
import pdb; pdb.set_trace()
```

### 5. Form Hypotheses
- What could cause this behavior?
- What assumptions might be wrong?
- What edge cases weren't considered?
- Is this a property violation (hypothesis found counterexample)?

### 6. Test Hypotheses
- Add logging to verify assumptions
- Check boundary conditions
- Verify input/output at each step
- For property failures, examine the counterexample

### 7. Fix and Verify
- Fix the implementation (not the spec, unless spec is wrong)
- Run the failing eval to verify fix
- Run ALL evals to check for regression

## Debug Commands

```bash
# Run single eval file
uv run python evals/module/eval_spec_001.py

# Run evals for specific module
uv run python tools/run_evals.py --module auth

# Run all evals
uv run python tools/run_evals.py --all

# Check traceability for gaps
uv run python tools/traceability_tools.py check-gaps traceability_matrix.json

# Use /debug command
/debug module-name
```

## Common Failure Patterns

| Symptom | Likely Cause | Fix |
|---------|--------------|-----|
| Wrong output value | Logic error | Trace data flow, fix transformation |
| Exception thrown | Missing validation | Add boundary check |
| Timeout | Infinite loop | Check loop conditions |
| Flaky (sometimes passes) | Non-determinism | Remove randomness or fix race condition |
| Property violation | Edge case | Examine counterexample, fix logic |

## Output Format

```markdown
## Debug Report: [Issue]

### Failing Eval
- File: evals/module/eval_spec_001.py
- Method: eval_valid_input_succeeds
- Spec: SPEC-001

### Expected Behavior (from spec)
[What the spec says should happen]

### Actual Behavior
[What's actually happening]

### Root Cause
[Why it's happening - be specific]

### Fix Applied
- File: src/module/handler.py
- Change: [description of fix]

### Verification
- [ ] Failing eval now passes
- [ ] All module evals pass
- [ ] No regression in other modules
```

## Debugging Hypothesis Failures

When hypothesis finds a counterexample:

```
Falsifying example: eval_round_trip(value='特殊字符')
```

1. **Examine the counterexample** - What's special about this input?
2. **Reproduce manually** - Run with that specific input
3. **Identify the property violation** - Why does the property not hold?
4. **Fix the implementation** - Handle the edge case
5. **Re-run hypothesis** - It will try to find more counterexamples
