# SPEC-XXX: [Feature Name]

**REQ IDs:** REQ-XXX
**Status:** Draft | Approved
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
| Valid input | Process called | Returns success |
| User authenticated | Action taken | Operation succeeds |

#### Error Cases

| Given | When | Then |
|-------|------|------|
| Invalid input | Process called | Returns validation error |
| Unauthorized | Action taken | Returns 401 |

#### Edge Cases

| Given | When | Then |
|-------|------|------|
| Empty input | Process called | Returns appropriate error |
| Max-length input | Process called | Handles correctly |

### Output

- **Success:** [expected response format]
- **Error:** [error response format]

## Invariants

Properties that must ALWAYS hold:
- [Invariant 1]
- [Invariant 2]

## Eval Criteria

- [ ] All happy path scenarios pass
- [ ] All error cases handled correctly
- [ ] All edge cases validated
- [ ] Invariants hold for any valid input

