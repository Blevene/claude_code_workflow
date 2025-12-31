---
name: debugging
description: Systematic debugging approach for finding and fixing issues. Auto-triggers for bug investigation, eval failures, error analysis, or troubleshooting.
---

# Debugging Skill

## When to Use
- Investigating bugs or unexpected behavior
- Analyzing eval failures
- Troubleshooting errors
- Understanding why code doesn't match spec

## Debugging Approach

### 1. Understand the Expected Behavior
- Check the spec: What SHOULD happen?
- Check the eval: What is being tested?
- Identify the gap between expected and actual

### 2. Reproduce the Issue
```bash
# Run specific eval
uv run python evals/module/eval_spec_001.py

# Run with verbose output
uv run pytest tests/ -v --tb=long
```

### 3. Isolate the Problem
- Is it a spec issue or implementation issue?
- Which specific behavior is failing?
- What's the minimal reproduction case?

### 4. Trace the Execution
```python
# Add strategic print statements
print(f"DEBUG: input={input_data}")
print(f"DEBUG: intermediate={result}")

# Or use debugger
import pdb; pdb.set_trace()
```

### 5. Form Hypotheses
- What could cause this behavior?
- What assumptions might be wrong?
- What edge cases weren't considered?

### 6. Test Hypotheses
- Add logging to verify assumptions
- Check boundary conditions
- Verify input/output at each step

### 7. Fix and Verify
- Fix the implementation (not the spec, unless spec is wrong)
- Run evals to verify fix
- Check for regression in other evals

## Debug Commands

```bash
# Run single eval with output
uv run python evals/module/eval_spec_001.py

# Run tests with full traceback
uv run pytest tests/module/ -v --tb=long

# Check for gaps
uv run python tools/traceability_tools.py check-gaps traceability_matrix.json
```

## Output Format

```markdown
## Debug Report: [Issue]

### Expected Behavior (from spec)
[What the spec says should happen]

### Actual Behavior
[What's actually happening]

### Root Cause
[Why it's happening]

### Fix Applied
[What was changed]

### Verification
- [ ] Eval now passes
- [ ] No regression in other evals
```
