---
name: refactoring
description: Safe refactoring with eval coverage as safety net. Auto-triggers for code cleanup, reducing duplication, improving structure, or restructuring code.
---

# Refactoring Skill

## When to Use
- Cleaning up code after feature is complete
- Reducing duplication (DRY)
- Improving code structure
- Simplifying complex logic

## CRITICAL: Evals Are Your Safety Net

```
╔══════════════════════════════════════════════════════════════╗
║  NEVER refactor without passing evals.                       ║
║  If evals fail after refactor, you broke behavior.           ║
║  Evals should NOT need to change during refactoring.         ║
╚══════════════════════════════════════════════════════════════╝
```

## Refactoring Process

### 1. Verify Baseline
```bash
# All evals must pass BEFORE refactoring
uv run python tools/run_evals.py --all
```

### 2. Make Small Changes
- One refactoring at a time
- Run evals after each change
- Commit when green

### 3. Common Refactorings

#### Extract Function
```python
# Before
def process(data):
    # validation code
    if not data:
        raise ValueError("...")
    # processing code
    result = ...

# After
def validate(data):
    if not data:
        raise ValueError("...")

def process(data):
    validate(data)
    result = ...
```

#### Remove Duplication
```python
# Before
def action_a():
    common_setup()
    specific_a()

def action_b():
    common_setup()  # Duplicate!
    specific_b()

# After
def with_setup(action):
    common_setup()
    action()
```

### 4. Verify After Each Change
```bash
# Evals must still pass
uv run python tools/run_evals.py --all
```

### 5. If Evals Fail
- Revert the change
- Understand why it broke behavior
- Try a different approach

## What to Avoid

- Changing behavior during refactoring
- Modifying evals to match refactored code
- Large multi-step refactorings without verification
- Refactoring untested code

## Output Format

```markdown
## Refactoring: [description]

### Before
[brief description of original structure]

### After
[brief description of new structure]

### Verification
- [ ] All evals pass
- [ ] No behavior change
- [ ] Code is cleaner
```
