---
name: debugging
description: Systematic debugging methodology for errors, test failures, and unexpected behavior. Auto-triggers for fixing bugs, investigating errors, debugging failures, or when tests fail unexpectedly. Use before making random changes.
---

# Debugging Skill

## When to Use
- Test failures with unclear cause
- Runtime errors or exceptions
- Unexpected behavior
- Performance issues
- Integration failures

## Debugging Methodology

### 1. Reproduce
```bash
# Isolate the failing test
uv run pytest tests/path/test_file.py::test_name -v

# Get full traceback
uv run pytest tests/ -v --tb=long
```

### 2. Understand the Error
- Read the FULL error message and stack trace
- Identify the exact line where failure occurs
- Check what values were expected vs actual

### 3. Form Hypothesis
Before changing code, state:
- "I believe the bug is caused by [X]"
- "This is because [evidence from error/code]"
- "I will verify by [specific action]"

### 4. Gather Evidence
```bash
# Check recent changes
git log --oneline -10
git diff HEAD~3

# Search for related code
grep -rn "function_name" src/

# Check if issue is new or regression
git bisect start
```

### 5. Minimal Fix
- Change ONE thing at a time
- Run tests after each change
- Revert if change doesn't help

### 6. Verify Fix
```bash
# Run the specific failing test
uv run pytest tests/path/test_file.py::test_name -v

# Run related tests
uv run pytest tests/path/ -v

# Run full suite to check for regressions
uv run pytest tests/ -v
```

## Common Patterns

### Import Errors
```bash
# Check module structure
ls -la src/module/
cat src/module/__init__.py
```

### Type Errors
- Check function signatures
- Verify return types
- Look for None returns

### Test Failures
- Check test fixtures
- Verify mock setup
- Look for state leakage between tests

## Anti-Patterns to Avoid

❌ Making multiple changes at once
❌ Guessing without reading the error
❌ Ignoring the stack trace
❌ Not running tests after changes
❌ "It works on my machine" assumptions

## Output Format

```markdown
## Debug Report: [issue]

### Error
[Exact error message]

### Root Cause
[What actually caused the issue]

### Evidence
[How you determined the cause]

### Fix Applied
[What was changed and why]

### Verification
[Test results showing fix works]

### Prevention
[How to prevent similar issues]
```

