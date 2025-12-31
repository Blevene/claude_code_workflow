---
name: documentation
description: Documentation best practices for specs, APIs, and code. Auto-triggers for writing docs, READMEs, docstrings, or technical documentation.
---

# Documentation Skill

## When to Use
- Writing or updating specifications
- Documenting APIs
- Adding code documentation
- Creating READMEs

## Documentation Types

### 1. Behavioral Specs
Primary documentation for SDD. Describes what the system DOES.

```markdown
# SPEC-001: Feature Name

## Overview
[Brief description]

## Behavioral Specification

### Expected Behavior
| Given | When | Then |
|-------|------|------|
| [precondition] | [action] | [outcome] |

### Invariants
- [Always true]
```

### 2. API Documentation

```markdown
## POST /api/resource

Create a new resource.

### Request
```json
{
  "field": "value"
}
```

### Response
- 201: Success
- 400: Validation error
```

### 3. Code Documentation

For complex logic only (not obvious code):

```python
def calculate_discount(order, user):
    """
    Calculate order discount based on user tier.

    Behavior (from SPEC-PRICING-001):
    - Gold tier: 20% discount
    - Silver tier: 10% discount
    - Bronze tier: 5% discount

    Args:
        order: Order with total_amount
        user: User with tier attribute

    Returns:
        Discount amount as Decimal
    """
```

### 4. README

```markdown
# Project Name

## Overview
[What this project does]

## Quick Start
```bash
# Setup
uv venv && uv sync

# Run evals
uv run python tools/run_evals.py --all
```

## Development
See `docs/` for detailed documentation.
```

## Documentation Best Practices

1. **Specs are primary** - Describe behavior, not implementation
2. **Keep it current** - Update when behavior changes
3. **Be specific** - Use Given/When/Then format
4. **Don't repeat code** - Document "why", not "what"
5. **Link to traceability** - Reference REQ-* and SPEC-* IDs

## Output Format

```markdown
## Documentation: [type]

### Created/Updated
- [file list]

### Traceability
- REQs documented: [list]
- SPECs documented: [list]
```
