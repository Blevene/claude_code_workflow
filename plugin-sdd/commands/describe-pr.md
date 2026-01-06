---
description: Generate a PR description with auto-generated "Approaches Tried" section from commit reasoning.
---

# /describe-pr - Generate PR Description with Reasoning

Generate a comprehensive pull request description that includes an "Approaches Tried" section documenting what was attempted during development.

## Usage

```
/describe-pr [base-branch]
/describe-pr main
/describe-pr develop
```

Default base branch is `main` if not specified.

## What It Does

1. **Summarizes changes** from commits since base branch
2. **Aggregates reasoning** from all commits
3. **Generates PR description** in standard format
4. **Highlights SDD artifacts** (specs, evals) modified

## Process

### Step 1: Gather Information

Get current branch:
```bash
git branch --show-current
```

Get commit summary (use `main` or specify base branch):
```bash
git log main..HEAD --oneline
```

Get files changed:
```bash
git diff --stat main..HEAD
```

### Step 2: Aggregate Reasoning

```bash
# Generate "Approaches Tried" section
./plugin-sdd/scripts/aggregate-reasoning.sh "$BASE_BRANCH"
```

Or if globally installed:

```bash
$HOME/.claude/scripts/aggregate-reasoning.sh "$BASE_BRANCH"
```

### Step 3: Generate PR Description

Create a PR description following this template:

```markdown
## Summary

Brief description of what this PR accomplishes.

## Changes

### Features
- Feature 1: description
- Feature 2: description

### Fixes
- Fix 1: description

### Other
- Refactoring, docs, etc.

## SDD Artifacts

### Specs Added/Modified
- `specs/auth/SPEC-001.md` - Login validation spec

### Evals Added/Modified  
- `evals/auth/eval_spec_001.py` - Login validation eval

### Traceability
- REQ-001: Covered by SPEC-001, eval passing ✓

## Testing

```bash
# Run all evals
uv run python tools/run_evals.py --all

# Check traceability
uv run python tools/traceability_tools.py check-gaps traceability_matrix.json
```

## Approaches Tried

{output from aggregate-reasoning.sh}

## Checklist

- [ ] All evals pass
- [ ] Traceability updated
- [ ] No coverage gaps
- [ ] Code reviewed locally
- [ ] Commits are clean
```

### Step 4: Output

Present the complete PR description for the user to copy/paste or use with:

```bash
gh pr create --title "feat: REQ-001 - description" --body-file /tmp/pr-description.md
```

## Example Output

```markdown
## Summary

Implements user login validation with rate limiting as specified in REQ-001.

## Changes

### Features
- Login endpoint with credential validation
- Rate limiting (5 attempts per 15 minutes)
- Session token generation

## SDD Artifacts

### Specs Added/Modified
- `specs/auth/SPEC-001.md` - Login validation behavioral spec

### Evals Added/Modified
- `evals/auth/eval_spec_001.py` - 5 eval cases, all passing

### Traceability
- REQ-001: Covered by SPEC-001 ✓

## Testing

All evals pass:
```
$ uv run python tools/run_evals.py --all
5/5 evals passed
```

## Approaches Tried

### feat: implement login validation (`abc12345`) - 2026-01-02

### Failed attempts
- `uv run pytest...` (pytest): ImportError: No module named 'auth'
- `uv run pytest...` (pytest): AssertionError: expected 200, got 401

Build passed after **2 failed attempt(s)** and 1 successful build(s).

### fix: correct rate limit window (`def67890`) - 2026-01-02

Build passed on first try (1 successful build(s)).

---
*This section auto-generated from development session reasoning.*

## Checklist

- [x] All evals pass
- [x] Traceability updated
- [x] No coverage gaps
- [ ] Code reviewed locally
- [x] Commits are clean
```

## Benefits

| Without /describe-pr | With /describe-pr |
|---------------------|-------------------|
| Manual PR writing | Auto-generated structure |
| No development history | Full "Approaches Tried" section |
| Reviewers see only final code | Reviewers understand the journey |
| Lost knowledge | Preserved for future reference |

## Related Commands

- `/commit` - Create commits with reasoning tracking
- `/pre-review` - Final checks before PR

## Notes

- If no reasoning files exist, the "Approaches Tried" section will note this
- Reasoning files are created when using `/commit` instead of `git commit`
- You can still manually add context to the PR description

