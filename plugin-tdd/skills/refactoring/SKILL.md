---
name: refactoring
description: Safe code refactoring patterns with test verification. Auto-triggers for restructuring code, improving design, reducing duplication, or cleaning up technical debt. Always maintains test coverage.
---

# Refactoring Skill

## When to Use
- Reducing code duplication (DRY)
- Improving code organization
- Simplifying complex functions
- Extracting reusable components
- Addressing technical debt

## Golden Rules

1. **Tests MUST pass before AND after**
2. **One refactoring at a time**
3. **No behavior changes during refactor**
4. **Commit after each successful refactor**

## Refactoring Workflow

### 1. Verify Starting Point
```bash
# Run tests - they MUST pass
uv run pytest tests/ -v

# Check coverage
uv run pytest --cov=src tests/
```

### 2. Make Single Change
Apply ONE refactoring pattern:
- Extract Method
- Extract Class
- Rename
- Move
- Inline

### 3. Verify Tests Still Pass
```bash
uv run pytest tests/ -v
```

### 4. Commit
```bash
git add .
git commit -m "refactor: extract authentication logic to AuthService"
```

### 5. Repeat

## Common Refactorings

### Extract Method
**Before:**
```python
def process_order(order):
    # validate order
    if not order.items:
        raise ValueError("Empty order")
    if order.total < 0:
        raise ValueError("Invalid total")
    # ... rest of processing
```

**After:**
```python
def process_order(order):
    validate_order(order)
    # ... rest of processing

def validate_order(order):
    if not order.items:
        raise ValueError("Empty order")
    if order.total < 0:
        raise ValueError("Invalid total")
```

### Extract Class
When a class has too many responsibilities, extract cohesive functionality into a new class.

### Rename for Clarity
- Functions should describe what they do
- Variables should describe what they contain
- Classes should describe what they represent

### Remove Duplication
1. Identify duplicate code
2. Extract to shared function/class
3. Replace duplicates with calls to shared code

## Safety Checks

Before each refactor:
- [ ] Tests exist for affected code
- [ ] Tests are passing
- [ ] I understand what the code does

After each refactor:
- [ ] Tests still pass
- [ ] Behavior is unchanged
- [ ] Code is cleaner/clearer

## Anti-Patterns

❌ Refactoring and adding features simultaneously
❌ Large refactors without intermediate commits
❌ Refactoring untested code
❌ Changing behavior while "cleaning up"

## Output Format

```markdown
## Refactoring: [description]

### Before
[Code snippet or description]

### After  
[Code snippet or description]

### Verification
- Tests: ✅ All passing
- Coverage: Maintained/Improved
- Behavior: Unchanged

### Commit
`refactor: [description]`
```

