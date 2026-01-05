---
description: Implement module to match behavioral specs - the core SDD build phase
---

# Implement Module

Implement `$ARGUMENTS` to match its behavioral specifications.

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

Create `specs/$ARGUMENTS/SPEC-001.md`.

**Template:** Copy from `templates/spec-template.md`

### Phase 2: EVAL - Create Eval Scripts

Create `evals/$ARGUMENTS/eval_{component_name}.py`.

**Template:** Copy from `templates/eval-template.py`

**Naming:** Use descriptive names (`eval_login.py`), NOT generic (`eval_spec_001.py`).

Run evals - they should FAIL (awaiting implementation):
```bash
uv run python evals/$ARGUMENTS/eval_{component_name}.py
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
