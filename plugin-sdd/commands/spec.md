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

Create `specs/[module]/SPEC-001.md`.

**Template:** Copy from `templates/spec-template.md`

Update: REQ IDs to `$ARGUMENTS`, feature name, behaviors (Given/When/Then).

### 3. Create Eval Script

Create `evals/[module]/eval_{component_name}.py` with evals for each behavior.

**NAMING CONVENTION (CRITICAL):**
```
evals/auth/eval_login.py           ✅ Component name - unique
evals/auth/eval_password_reset.py  ✅ Component name - unique  
evals/auth/eval_spec_001.py        ❌ Generic - causes pytest conflicts
```

Use descriptive component names, NOT generic spec IDs. This prevents pytest collection conflicts when multiple modules have evals.

### 4. Update Traceability

```json
{
  "id": "$ARGUMENTS",
  "specs": ["specs/[module]/SPEC-001.md"],
  "evals": ["evals/[module]/eval_{component_name}.py"]
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
