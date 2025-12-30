---
name: git-workflow
description: Git best practices for commits, branches, and PRs. Auto-triggers for committing changes, creating PRs, managing branches, or preparing code for merge. Ensures clean git history.
---

# Git Workflow Skill

## When to Use
- Committing changes
- Creating branches
- Preparing pull requests
- Resolving conflicts
- Managing release branches

## Branch Naming

```
feature/REQ-001-user-authentication
bugfix/REQ-002-login-timeout
hotfix/critical-security-patch
chore/update-dependencies
```

## Commit Messages

### Format
```
type(scope): short description

Longer description if needed.

REQ-001, T-001
```

### Types
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation
- `style`: Formatting (no code change)
- `refactor`: Code restructure (no behavior change)
- `test`: Adding/fixing tests
- `chore`: Maintenance tasks

### Examples
```
feat(auth): add password reset flow

Implements REQ-003 password reset via email.
- Added reset token generation
- Email service integration
- Token expiry validation

REQ-003, T-012
```

## Pre-Commit Checklist

```bash
# 1. Check what's staged
git status
git diff --staged

# 2. Run tests
uv run pytest tests/ -v

# 3. Check for debug code
grep -rn "console.log\|print(\|debugger\|pdb\|TODO\|FIXME" src/

# 4. Check linting
ruff check . || flake8 .

# 5. Verify traceability
uv run python tools/traceability_tools.py check-gaps traceability_matrix.json
```

## PR Creation

```bash
# Create PR with gh CLI
gh pr create --title "feat(auth): add password reset" \
  --body "## Summary
Implements password reset flow (REQ-003).

## Changes
- Added reset token generation
- Email service integration
- Token expiry validation

## Testing
- [x] Unit tests pass
- [x] Integration tests pass
- [x] Manual testing completed

## Traceability
REQ-003, T-012"
```

## Conflict Resolution

1. Fetch latest changes:
   ```bash
   git fetch origin main
   ```

2. Rebase onto main:
   ```bash
   git rebase origin/main
   ```

3. For each conflict:
   - Understand BOTH changes
   - Keep the correct behavior
   - Run tests after resolving

4. Complete rebase:
   ```bash
   git rebase --continue
   ```

## Commands Reference

```bash
# Stage specific files
git add src/auth/reset.py tests/auth/test_reset.py

# Interactive staging
git add -p

# Amend last commit (before push)
git commit --amend

# View commit history
git log --oneline -20

# View file history
git log --follow -p -- src/auth/reset.py

# Stash work in progress
git stash push -m "WIP: reset flow"
git stash pop
```

## Output Format

When committing:
```markdown
## Commit Ready

**Branch:** feature/REQ-001-auth
**Files:** 3 modified, 1 added

**Pre-commit checks:**
- [x] Tests pass
- [x] No debug code
- [x] Linting clean
- [x] Traceability updated

**Suggested commit message:**
```
feat(auth): add password reset flow

REQ-003, T-012
```
```

