---
name: git-workflow
description: Git workflow best practices for commits, branches, and PRs. Auto-triggers for committing changes, creating PRs, branch management, or version control operations.
---

# Git Workflow Skill

## When to Use
- Committing changes
- Creating pull requests
- Managing branches
- Resolving conflicts

## Commit Best Practices

### Use /commit for Reasoning-Aware Commits

**RECOMMENDED:** Use `/commit` instead of `git commit` to automatically capture development reasoning:

```
/commit "feat: add login validation"
```

This:
1. Commits your changes with the message
2. Generates `reasoning.md` documenting what was tried
3. Captures failed build attempts for PR documentation
4. Enables cross-session learning via `search-reasoning.sh`

### Commit Message Format
```
<type>: <description>

[optional body]

[optional footer]
```

Types:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation
- `spec`: Specification changes
- `eval`: Eval changes
- `refactor`: Code refactoring
- `test`: Test changes
- `chore`: Maintenance

### Before Committing

```bash
# Check status
git status

# Run evals to verify
uv run python tools/run_evals.py --all

# Stage changes
git add <files>

# Commit with reasoning (RECOMMENDED)
/commit "feat: add login validation"

# Or traditional commit (no reasoning captured)
git commit -m "feat: add login validation"
```

## Branch Strategy

```
main
├── develop
│   ├── feature/REQ-001-login
│   ├── feature/REQ-002-dashboard
│   └── fix/SPEC-003-validation
```

### Branch Naming
- `feature/REQ-XXX-description` - New features
- `fix/SPEC-XXX-description` - Bug fixes
- `docs/description` - Documentation
- `refactor/description` - Refactoring

## Pull Request Checklist

Before creating PR:
- [ ] All evals pass
- [ ] Traceability updated
- [ ] No gaps in coverage
- [ ] Code reviewed locally
- [ ] Commits are clean (using /commit)

### PR Commands

**RECOMMENDED:** Use `/describe-pr` to auto-generate PR description with "Approaches Tried" section:

```
/describe-pr main
```

This generates a complete PR description including:
- Summary of changes
- SDD artifacts modified
- **Approaches Tried** - auto-generated from commit reasoning

### Manual PR Creation

```bash
# Check evals pass
uv run python tools/run_evals.py --all

# Check traceability
uv run python tools/traceability_tools.py check-gaps traceability_matrix.json

# Generate reasoning summary
./plugin-sdd/scripts/aggregate-reasoning.sh main

# Create PR
gh pr create --title "feat: REQ-001 - description" --body-file /tmp/pr-description.md
```

## Searching Past Reasoning

Before implementing something, search what was tried before:

```bash
# Find approaches that worked
./plugin-sdd/scripts/search-reasoning.sh "authentication" --passed

# Find approaches that failed (avoid repeating)
./plugin-sdd/scripts/search-reasoning.sh "rate limiting" --failed

# General search
./plugin-sdd/scripts/search-reasoning.sh "validation"
```

## Output Format

```markdown
## Git Operation: [type]

### Changes
- [file changes summary]

### Evals Status
- Passing: X/Y

### Traceability
- REQs covered: [list]
- SPECs covered: [list]

### Reasoning
- Commit hash: [hash]
- Build attempts: X failed, Y passed
```
