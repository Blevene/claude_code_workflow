---
description: Implement module to match existing behavioral specs. Assumes specs and evals already exist from /spec phase. DO NOT create new specs or evals.
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

## Prerequisites Check

**CRITICAL: Specs and evals must exist BEFORE implementation.**

1. **Verify Spec Exists**
   ```bash
   ls specs/$ARGUMENTS/SPEC-*.md || echo "ERROR: No specs found. Run /spec first."
   ```

2. **Verify Eval Exists**
   ```bash
   ls evals/$ARGUMENTS/eval_*.py || echo "WARNING: No evals found. Specs should include evals."
   ```

   **If evals are missing:** The spec phase should have created them. Check if `/spec` was run properly.

## Implementation Steps

### Step 1: Read the Spec

Read the behavioral specification:
```bash
# Find the relevant spec
ls -t specs/$ARGUMENTS/SPEC-*.md | head -1 | xargs cat
```

Understand the expected behaviors (Given/When/Then scenarios).

### Step 2: Implement to Spec

Create or modify `src/$ARGUMENTS/` to implement the behaviors defined in the spec.

**Key principle:** Implement the *what* (behavior), not the *how* (internal structure). The spec defines observable outcomes.

### Step 3: Run Existing Evals

Run the evals that were created with the spec:
```bash
# Run all evals for this module
uv run python tools/run_evals.py --module $ARGUMENTS

# Or run specific eval file
uv run python evals/$ARGUMENTS/eval_{component_name}.py
```

**Expected:** Evals should PASS after implementation.

### Step 4: Iterate Until Evals Pass

If evals fail:
- Fix the implementation (not the spec/eval)
- Re-run evals
- Repeat until all pass

### Step 5: Refactor (Optional)

Once evals pass, improve code quality while keeping evals green.

## Output

Report:
1. Spec file verified (path)
2. Eval file verified (path)
3. Implementation file path created/modified
4. Eval run results (should be PASSING)
5. Traceability update (link code to spec/eval)

**DO NOT create new specs or evals.** They should already exist from the `/spec` phase.

$ARGUMENTS
