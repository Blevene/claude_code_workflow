---
description: Show workflow status, gaps, and next recommended action
---

# Workflow Status

Check the current state of the FAANG development workflow.

## Checks

### 1. Design Documents
List files in `docs/design/`:
```bash
ls -la docs/design/*.md 2>/dev/null || echo "No design docs found"
```

### 2. Traceability Matrix
```bash
python .claude/tools/traceability_tools.py summary traceability_matrix.json --markdown
python .claude/tools/traceability_tools.py check-gaps traceability_matrix.json
```

### 3. Plan Status
Check if `planner_output.json` exists and is valid.

### 4. Test Coverage
```bash
pytest --cov=src --cov-report=term-missing 2>/dev/null || echo "Tests not configured"
```

## Output

```
## Workflow Status

### Phase Progress
| Phase | Status | Command |
|-------|--------|---------|
| 1. Design | ✓/✗ | /design |
| 2. Review | ✓/✗ | /review-design |
| 3. Planning | ✓/✗ | /plan-sprint |
| 4. TDD | ✓/✗ | /tdd |
| 5. Pre-review | ✓/✗ | /pre-review |

### Gaps Found
[list any missing artifacts]

### Recommended Next Action
[specific command to run]
```
