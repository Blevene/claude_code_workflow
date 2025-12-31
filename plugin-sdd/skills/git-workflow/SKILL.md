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

# Commit
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
- [ ] Commits are clean

### PR Commands

```bash
# Check evals pass
uv run python tools/run_evals.py --all

# Check traceability
uv run python tools/traceability_tools.py check-gaps traceability_matrix.json

# Create PR
gh pr create --title "feat: REQ-001 - description" --body "..."
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
```
