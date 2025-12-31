---
description: Pre-submission validation before code review
---

# Pre-Review Validation

Run validation checks before submitting code for review.

## Checks to Run

### 1. Linting
```bash
ruff check . || flake8 . || echo "No Python linter found"
```

### 2. Tests
```bash
uv run pytest --cov=src -v
```

### 3. Debug Code Detection

Search for debug statements that shouldn't be committed:
- `print(` statements (outside tests)
- `console.log`
- `debugger`
- `import pdb`
- `breakpoint()`

### 4. TODO/FIXME Check

Find unresolved items:
```bash
grep -rn "TODO\|FIXME\|XXX\|HACK" src/
```

### 5. Traceability Gaps

```bash
uv run python tools/traceability_tools.py check-gaps traceability_matrix.json
```

## Output Report

```
## Pre-Review Results

| Check | Status |
|-------|--------|
| Linting | ✓/✗ |
| Tests | ✓/✗ (X passed) |
| Debug code | ✓/✗ |
| TODOs | X found |
| Traceability | ✓/✗ |

### Issues Found
[list any issues]

### Verdict: READY / NOT READY

### PR Description Template
[generate if ready]
```
