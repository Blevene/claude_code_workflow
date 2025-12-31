---
description: Spec-Driven Development - write specs FIRST then implement then run evals
---

# Spec-Driven Development

Implement `$ARGUMENTS` using strict SDD methodology.

## CRITICAL RULES

**Write specs FIRST. Then implement. Then run evals.**

```
╔══════════════════════════════════════════════════════════════╗
║  ALWAYS use uv for Python execution.                        ║
║  Commands: uv run pytest, uv run python, uv sync            ║
╚══════════════════════════════════════════════════════════════╝
```

## Environment Setup (FIRST!)

Before starting SDD, ensure the environment is ready:

```bash
# Verify venv exists (create if needed)
ls .venv/ || uv venv

# Sync dependencies (ensures pytest is available)
uv sync
```

## SDD Cycle

### Phase 1: SPEC - Write Behavioral Specifications

Create `specs/$ARGUMENTS/SPEC-001.md`:

```markdown
# SPEC-001: [Feature Name]

**REQ IDs:** REQ-001
**Status:** Draft

## Overview
[What this feature does and why]

## Behavioral Specification

### Input
- **Type:** [data type]
- **Constraints:** [validation rules]

### Expected Behavior
1. GIVEN [precondition] WHEN [action] THEN [outcome]
2. GIVEN [error condition] WHEN [action] THEN [error handling]

### Output
- **Success:** [expected response format]
- **Error:** [error response format]

## Eval Criteria
- [ ] Happy path produces expected output
- [ ] Error cases return appropriate errors
- [ ] Edge cases handled correctly
```

### Phase 2: EVAL - Create Eval Scripts

Create `evals/$ARGUMENTS/eval_spec_001.py`:

```python
"""Eval for SPEC-001 - written BEFORE implementation."""
from dataclasses import dataclass
from typing import Any

@dataclass
class EvalResult:
    passed: bool
    spec_id: str
    description: str
    expected: Any
    actual: Any = None
    error: str = None

class SpecEval:
    spec_id = "SPEC-001"

    def eval_happy_path(self) -> EvalResult:
        """Given valid input When processed Then returns expected output."""
        expected = {"result": "success"}
        # actual = module.process(input_data)  # Awaiting implementation
        return EvalResult(
            passed=False,
            spec_id=self.spec_id,
            description="Happy path",
            expected=expected,
            error="Awaiting implementation"
        )

    def eval_error_case(self) -> EvalResult:
        """Given invalid input When processed Then returns error."""
        # Awaiting implementation
        return EvalResult(
            passed=False,
            spec_id=self.spec_id,
            description="Error case",
            expected="ValidationError",
            error="Awaiting implementation"
        )

    def run_all(self) -> list[EvalResult]:
        return [
            self.eval_happy_path(),
            self.eval_error_case(),
        ]
```

Run evals - they should FAIL (awaiting implementation):
```bash
uv run python evals/$ARGUMENTS/eval_spec_001.py
```

### Phase 3: IMPLEMENT - Build to Spec

Create `src/$ARGUMENTS/$ARGUMENTS.py` implementing the behavior defined in specs.

Run evals - they should PASS:
```bash
uv run python evals/$ARGUMENTS/eval_spec_001.py
```

### Phase 4: REFACTOR

Improve code quality while keeping evals green.

## Output

Report:
1. Spec file path created
2. Eval file path created
3. Eval run results (PENDING phase)
4. Implementation file path
5. Eval run results (PASSING phase)
6. Traceability update needed

$ARGUMENTS
