---
description: Create behavioral specification for a requirement
---

# Create Specification

Create a behavioral specification for `$ARGUMENTS`.

## What To Do

### 1. Gather Context

Read related artifacts:
- Design doc in `docs/design/`
- UX spec in `.design/` (if exists)
- Requirement in `traceability_matrix.json`

### 2. Create Spec Document

Create `specs/[module]/SPEC-001.md`:

```markdown
# SPEC-001: [Feature Name]

**REQ IDs:** $ARGUMENTS
**Status:** Draft
**Author:** spec-writer

## Overview
[What this feature does and why]

## Behavioral Specification

### Input
- **Type:** [data type]
- **Constraints:** [validation rules]
- **Examples:**
  ```json
  {"field": "value"}
  ```

### Expected Behavior

#### Happy Path
| Given | When | Then |
|-------|------|------|
| Valid input data | Process is called | Returns success response |
| User is authenticated | Action is taken | Operation succeeds |

#### Error Cases
| Given | When | Then |
|-------|------|------|
| Invalid input | Process is called | Returns validation error |
| Unauthorized user | Action is taken | Returns 401 error |

#### Edge Cases
| Given | When | Then |
|-------|------|------|
| Empty input | Process is called | Returns appropriate error |
| Max-length input | Process is called | Handles correctly |

### Output
- **Success:** [expected response format]
- **Error:** [error response format]

## Invariants

Properties that must ALWAYS hold:
- [Invariant 1 - e.g., "Output is never null"]
- [Invariant 2 - e.g., "State is consistent after operation"]

## Eval Criteria
- [ ] All happy path scenarios pass
- [ ] All error cases handled correctly
- [ ] All edge cases validated
- [ ] Invariants hold for any valid input
```

### 3. Create Eval Script

Create `evals/[module]/eval_spec_001.py` with evals for each behavior.

### 4. Update Traceability

```json
{
  "id": "$ARGUMENTS",
  "specs": ["specs/[module]/SPEC-001.md"],
  "evals": ["evals/[module]/eval_spec_001.py"]
}
```

### 5. Output Summary

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ SPECIFICATION CREATED
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Created:
- specs/[module]/SPEC-001.md
- evals/[module]/eval_spec_001.py

Behaviors Specified:
- Happy paths: [count]
- Error cases: [count]
- Edge cases: [count]
- Invariants: [count]

Traceability: Updated

Next steps:
1. @backend/@frontend: Implement to spec
2. Run evals: uv run python evals/[module]/eval_spec_001.py
```

$ARGUMENTS
