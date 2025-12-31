---
name: onboarding
description: Brownfield repository onboarding - AUTO-TRIGGERS when user mentions existing codebase, legacy code, retrofitting specs, or adopting SDD in an established project. Guides gradual SDD adoption without disrupting existing work.
---

# Brownfield Onboarding Skill

> **This skill auto-triggers** when adopting SDD in an existing codebase.
> For greenfield projects, use `/init` directly.

## When This Auto-Triggers

- "I have an existing codebase..."
- "How do I add SDD to my project?"
- "Retrofitting specs to legacy code"
- "Adopting this workflow in an established repo"
- "Existing tests I want to convert"

## Onboarding Philosophy

**Don't boil the ocean.** Adopt SDD incrementally:

1. Initialize SDD structure alongside existing code
2. Start with NEW features (full SDD from day one)
3. Gradually retrofit specs to critical existing code
4. Convert tests to evals as you touch modules

## Step-by-Step Onboarding

### Phase 1: Initialize Structure (Non-Destructive)

```bash
# Run /init - creates SDD directories without touching existing code
/init

# This creates:
# - specs/           (empty, ready for specs)
# - evals/           (empty, ready for evals)
# - docs/design/     (for design docs)
# - thoughts/        (for continuity)
# - traceability_matrix.json
```

**Important:** This does NOT modify your existing `src/`, `tests/`, or other directories.

### Phase 2: Inventory Existing Code

Create an initial assessment:

```markdown
## Codebase Inventory

### Critical Modules (retrofit first)
| Module | Risk | Has Tests? | Priority |
|--------|------|------------|----------|
| auth/  | High | Yes        | P0       |
| payments/ | High | Partial | P0     |
| api/   | Medium | Yes      | P1       |

### New Features (full SDD)
- All new work follows /spec → /implement → /eval

### Low Priority (retrofit later)
- Utilities, helpers, internal tools
```

### Phase 3: Parallel Workflows

Run SDD alongside existing practices:

```
Existing Code:
  └── tests/ (keep running, don't delete)

New Code (SDD):
  └── specs/ → evals/ → src/

Retrofitted Code:
  └── Create spec from existing behavior
  └── Create eval that passes with current code
  └── Now spec protects the behavior
```

### Phase 4: Retrofit Critical Modules

For each critical module:

#### 4.1 Document Current Behavior

```markdown
# SPEC-001: Auth Login (Retrofitted)

**REQ IDs:** REQ-LEGACY-001
**Status:** Approved
**Retrofit:** true

## Overview
Documents EXISTING behavior of login system.

## Behavioral Specification

### Current Behavior (observed)
1. WHEN valid credentials THEN session created
2. WHEN invalid password THEN returns 401
3. WHEN account locked THEN returns 403

## Eval Criteria
- [ ] Matches current production behavior
- [ ] All existing tests still pass
```

#### 4.2 Create Eval That Passes NOW

```python
"""
Eval for SPEC-001 (Retrofitted)

This eval MUST PASS with the current implementation.
It documents existing behavior, not aspirational behavior.
"""
class SpecEval:
    spec_id = "SPEC-001"
    retrofit = True

    def eval_current_login_behavior(self) -> EvalResult:
        """Documents existing login behavior."""
        # This should pass with current code
        result = auth.login("valid_user", "valid_pass")
        return EvalResult(
            passed=result.success,
            spec_id=self.spec_id,
            description="Current login behavior",
            expected="session created",
            actual=str(result)
        )
```

#### 4.3 Update Traceability

```json
{
  "id": "REQ-LEGACY-001",
  "title": "User Authentication (Retrofitted)",
  "status": "approved",
  "retrofit": true,
  "specs": ["specs/auth/SPEC-001.md"],
  "evals": ["evals/auth/eval_spec_001.py"],
  "code": ["src/auth/login.py"],
  "tests": ["tests/auth/test_login.py"]
}
```

### Phase 5: Migrate Tests to Evals (Optional)

If you want to convert existing pytest tests:

| Test Pattern | Eval Equivalent |
|--------------|-----------------|
| `def test_X():` | `def eval_X() -> EvalResult:` |
| `assert result == expected` | `return EvalResult(passed=result==expected, ...)` |
| `pytest.raises(Error)` | Try/except returning EvalResult |

**Keep both during transition.** Delete tests only after evals are stable.

## Onboarding Commands

```bash
# Initialize (safe for existing repos)
/init

# Check what's missing
/check

# Check eval coverage
uv run python tools/eval_coverage.py

# Lint existing specs
uv run python tools/spec_linter.py

# View traceability gaps
uv run python tools/traceability_tools.py check-gaps traceability_matrix.json
```

## Traceability for Retrofitted Code

Use `retrofit: true` flag:

```json
{
  "id": "REQ-LEGACY-001",
  "retrofit": true,
  "original_tests": ["tests/auth/test_login.py"],
  "specs": ["specs/auth/SPEC-001.md"],
  "evals": ["evals/auth/eval_spec_001.py"]
}
```

## Common Brownfield Patterns

### Pattern: Existing Tests, No Specs

```
Current:  tests/module/test_*.py
Action:   Create specs/module/SPEC-*.md documenting what tests verify
Result:   Specs document intent, tests remain as-is
```

### Pattern: No Tests, No Specs

```
Current:  src/module/*.py (no tests)
Action:   1. Create spec documenting current behavior
          2. Create eval that passes with current code
          3. Now you have behavioral protection
```

### Pattern: Partial Coverage

```
Current:  Some tests, some gaps
Action:   1. Retrofit specs for tested code
          2. Create specs for untested critical paths
          3. Add evals for new specs
```

## What NOT To Do

1. **Don't delete existing tests** - Keep them until evals are proven stable
2. **Don't retrofit everything at once** - Prioritize by risk
3. **Don't change behavior while retrofitting** - Document AS-IS first
4. **Don't skip /init** - Even for existing repos

## Output Format

After onboarding assessment:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📦 BROWNFIELD ONBOARDING ASSESSMENT
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

## Codebase Analysis
- Source files: X
- Existing tests: Y
- Test coverage: Z%

## Recommended Approach
1. Run /init (non-destructive)
2. Retrofit these critical modules first:
   - auth/ (high risk, has tests)
   - payments/ (high risk, partial tests)
3. Apply full SDD to new features

## Next Steps
- /init
- Create SPEC-001 for auth module
- Run /check to verify setup

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```
