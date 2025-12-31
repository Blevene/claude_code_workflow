---
description: Plugin health check - verify SDD plugin is correctly installed and configured
---

# Plugin Health Check

Verify the SDD plugin is correctly installed and configured.

## Checks

### 1. Directory Structure
```bash
echo "Checking directories..."
[ -d "thoughts/ledgers" ] && echo "✓ thoughts/ledgers/" || echo "✗ thoughts/ledgers/ missing"
[ -d "thoughts/shared/handoffs" ] && echo "✓ thoughts/shared/handoffs/" || echo "✗ thoughts/shared/handoffs/ missing"
[ -d "thoughts/shared/plans" ] && echo "✓ thoughts/shared/plans/" || echo "✗ thoughts/shared/plans/ missing"
[ -d "docs/design" ] && echo "✓ docs/design/" || echo "✗ docs/design/ missing"
[ -d ".design" ] && echo "✓ .design/" || echo "✗ .design/ missing"
[ -d "specs" ] && echo "✓ specs/" || echo "✗ specs/ missing"
[ -d "evals" ] && echo "✓ evals/" || echo "✗ evals/ missing"
```

### 2. Python Environment
```bash
echo "Checking Python environment..."
[ -d ".venv" ] && echo "✓ .venv/" || echo "✗ .venv/ missing - run: uv venv"
[ -f "pyproject.toml" ] && echo "✓ pyproject.toml" || echo "✗ pyproject.toml missing"
uv run python --version 2>/dev/null && echo "✓ uv run works" || echo "✗ uv run failed"
```

### 3. Traceability Matrix
```bash
echo "Checking traceability..."
[ -f "traceability_matrix.json" ] && echo "✓ traceability_matrix.json" || echo "✗ traceability_matrix.json missing"
```

### 4. Tools
```bash
echo "Checking tools..."
uv run python tools/traceability_tools.py --help 2>/dev/null && echo "✓ traceability_tools.py" || echo "✗ traceability_tools.py not available"
uv run python tools/run_evals.py --help 2>/dev/null && echo "✓ run_evals.py" || echo "✗ run_evals.py not available"
uv run python tools/eval_coverage.py --help 2>/dev/null && echo "✓ eval_coverage.py" || echo "✗ eval_coverage.py not available"
uv run python tools/spec_linter.py --help 2>/dev/null && echo "✓ spec_linter.py" || echo "✗ spec_linter.py not available"
```

## Output

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔍 SDD PLUGIN HEALTH CHECK
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

## Directory Structure
✓ thoughts/ledgers/
✓ thoughts/shared/handoffs/
✓ thoughts/shared/plans/
✓ docs/design/
✓ .design/
✓ specs/
✓ evals/

## Python Environment
✓ .venv/
✓ pyproject.toml
✓ uv run works

## Traceability
✓ traceability_matrix.json

## Tools
✓ traceability_tools.py
✓ run_evals.py
✓ eval_coverage.py
✓ spec_linter.py

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ PLUGIN HEALTHY
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[Or list what's missing and how to fix]

To initialize missing components: /init
```

$ARGUMENTS
