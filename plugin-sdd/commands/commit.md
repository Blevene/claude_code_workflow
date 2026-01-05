---
description: Commit changes with reasoning tracking. Wraps git commit and generates reasoning.md documenting what was tried.
---

# /commit - Reasoning-Aware Git Commit

Commit staged changes and automatically generate reasoning documentation capturing what was tried during development.

## Usage

```
/commit <message>
/commit "feat: implement login validation"
```

## What It Does

1. **Commits staged changes** using conventional commit format
2. **Generates reasoning.md** from tracked build/test attempts
3. **Clears attempt history** for next feature work
4. **Links to SDD artifacts** (specs, evals) if modified

## Process

### Step 1: Pre-Commit Checks

Before committing, verify:

```bash
# Check what's staged
git status

# Run evals to ensure they pass
uv run python tools/run_evals.py --all

# Check traceability if specs modified
uv run python tools/traceability_tools.py check-gaps traceability_matrix.json
```

### Step 2: Commit

Use conventional commit format with the provided $ARGUMENTS:

```bash
git commit -m "$ARGUMENTS"
```

**Commit Types:**
- `feat:` - New feature
- `fix:` - Bug fix  
- `spec:` - Specification changes
- `eval:` - Eval changes
- `refactor:` - Code refactoring
- `docs:` - Documentation
- `chore:` - Maintenance

### Step 3: Generate Reasoning

After successful commit, generate reasoning documentation:

```bash
# Get the commit hash
COMMIT_HASH=$(git rev-parse HEAD)

# Generate reasoning from attempts
$HOME/.claude/scripts/generate-reasoning.sh "$COMMIT_HASH" "$ARGUMENTS"
```

Or if using plugin directory:

```bash
COMMIT_HASH=$(git rev-parse HEAD)
./plugin-sdd/scripts/generate-reasoning.sh "$COMMIT_HASH" "$ARGUMENTS"
```

### Step 4: Report

Output a summary:

```markdown
## Commit Created

**Hash:** `{short_hash}`
**Message:** {commit_message}
**Branch:** {branch_name}

### Reasoning Generated
- Location: `.git/claude/commits/{hash}/reasoning.md`
- Build attempts: {count} failed, {count} passed
- Files changed: {count}

### SDD Artifacts
- Specs modified: {list or "none"}
- Evals modified: {list or "none"}
```

## Reasoning Output

The generated reasoning file captures:

```markdown
# Commit: abc12345

## Branch
feature/REQ-001-login

## What was committed
feat: implement login validation

## What was tried

### Failed attempts
- `uv run pytest...` (pytest): ImportError: No module named 'auth'
- `uv run pytest...` (pytest): AssertionError: expected 200

### Summary
Build passed after **2 failed attempt(s)** and 1 successful build(s).

## Files changed
- src/auth/login.py
- specs/auth/SPEC-001.md

## SDD Artifacts
### Specs modified
- specs/auth/SPEC-001.md
### Evals modified
- evals/auth/eval_spec_001.py
```

## Why Use /commit

| Regular `git commit` | `/commit` |
|---------------------|-----------|
| Just commits code | Commits + documents reasoning |
| No history of attempts | Captures failed approaches |
| Manual PR descriptions | Auto-generates "Approaches Tried" |
| Knowledge lost | Knowledge preserved for future |

## Related Commands

- `/describe-pr` - Generate PR description with reasoning from all commits
- `/save-state` - Save current session state to ledger
- `/handoff` - Create detailed session handoff

## Searching Past Reasoning

After using `/commit`, reasoning becomes searchable:

```bash
# Search for past approaches
./plugin-sdd/scripts/search-reasoning.sh "authentication"

# Find failed attempts (patterns to avoid)
./plugin-sdd/scripts/search-reasoning.sh "ImportError" --failed

# Find successful patterns
./plugin-sdd/scripts/search-reasoning.sh "validation" --passed
```

