---
description: Test-Driven Development - write tests FIRST then implement
---

# Test-Driven Development

Implement `$ARGUMENTS` using strict TDD methodology.

## CRITICAL RULES

**Write tests FIRST. Run them. They MUST fail. Then implement.**

```
╔══════════════════════════════════════════════════════════════╗
║  ALWAYS use uv for Python execution.                        ║
║  Commands: uv run pytest, uv run python, uv sync            ║
╚══════════════════════════════════════════════════════════════╝
```

## Environment Setup (FIRST!)

Before starting TDD, ensure the environment is ready:

```bash
# Verify venv exists (create if needed)
ls .venv/ || uv venv

# Sync dependencies (ensures pytest is available)
uv sync
```

## TDD Cycle

### Phase 1: RED - Write Failing Tests

Create `tests/$ARGUMENTS/test_$ARGUMENTS.py`:

```python
"""Tests for $ARGUMENTS - written BEFORE implementation."""
import pytest

class TestModule:
    def test_happy_path(self):
        """Test successful operation."""
        # Arrange, Act, Assert
        pytest.skip("Awaiting implementation")
    
    def test_error_case(self):
        """Test error handling."""
        pytest.skip("Awaiting implementation")
    
    def test_edge_case(self):
        """Test boundary conditions."""
        pytest.skip("Awaiting implementation")
```

Run tests - they should FAIL or SKIP:
```bash
uv run pytest tests/$ARGUMENTS/ -v
```

### Phase 2: GREEN - Implement to Pass

Create `src/$ARGUMENTS/$ARGUMENTS.py` with minimal code to pass tests.

Run tests - they should PASS:
```bash
uv run pytest tests/$ARGUMENTS/ -v
```

### Phase 3: REFACTOR

Improve code quality while keeping tests green.

## Output

Report:
1. Test file path created
2. Test run results (RED phase)
3. Implementation file path
4. Test run results (GREEN phase)
5. Traceability update needed
