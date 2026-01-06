---
description: Initialize project for Spec-Driven Development workflow - creates directories, tools, venv, and config files
---

# /sdd-init - Initialize SDD Project

Set up the current directory for the Spec-Driven Development workflow.

## What This Creates

| Directory/File | Purpose |
|----------------|---------|
| `thoughts/ledgers/` | Continuity ledgers (survive `/clear`) |
| `thoughts/shared/handoffs/` | Session transfer documents |
| `thoughts/shared/plans/` | Implementation plans |
| `docs/design/` | Architecture documents |
| `.design/` | UX specifications |
| `specs/` | Behavioral specifications |
| `evals/` | Eval scripts for validation |
| `tools/` | SDD utility scripts |
| `traceability_matrix.json` | Requirement tracking |
| `.venv/` | Python virtual environment |
| `pyproject.toml` | Python project config |
| `.gitignore` | Git ignore patterns |

## Steps

### 1. Create Directory Structure

```bash
mkdir -p thoughts/ledgers
mkdir -p thoughts/shared/handoffs
mkdir -p thoughts/shared/plans
mkdir -p docs/design
mkdir -p .design
mkdir -p specs
mkdir -p evals
mkdir -p tools
mkdir -p src tests
```

### 2. Set Up Python Environment

```bash
# Create virtual environment
uv venv

# Create pyproject.toml if missing
cat > pyproject.toml << 'EOF'
[project]
name = "my-project"
version = "0.1.0"
description = "A project using Spec-Driven Development"
requires-python = ">=3.10"
dependencies = []

[tool.uv]
dev-dependencies = [
    "pytest>=7.0",
    "pytest-cov>=4.0",
    "pytest-mock>=3.0",
    "hypothesis>=6.0",
]

[tool.pytest.ini_options]
addopts = "--strict-markers"
testpaths = ["tests", "evals"]
python_classes = ["Test*", "Spec*", "PropertyEval*"]
EOF

# Sync dependencies
uv sync
```

### 3. Create Traceability Matrix

```bash
cat > traceability_matrix.json << 'EOF'
{
  "meta": {
    "version": 1,
    "project": "PROJECT_NAME",
    "created": "TIMESTAMP",
    "description": "Traceability matrix linking EARS requirements to specs, evals, design, and code."
  },
  "requirements": []
}
EOF
```

Update `PROJECT_NAME` and `TIMESTAMP` with actual values.

### 4. Install SDD Tools (Optional)

Copy utility scripts from plugin. Try global install first, then plugin directory:

```bash
test -d ~/.claude/tools && cp ~/.claude/tools/*.py tools/ 2>/dev/null || echo "Tools not found in ~/.claude/tools"
```

Or if using plugin directory:
```bash
test -d plugin-sdd/tools && cp plugin-sdd/tools/*.py tools/ 2>/dev/null || echo "Plugin tools not found"
```

**Tools installed:**
- `run_evals.py` - Execute all eval scripts
- `traceability_tools.py` - Manage traceability matrix
- `planner_tools.py` - Validate plan JSON files
- `artifact_index.py` - Index handoffs/specs for recall
- `artifact_query.py` - Search past work

### 5. Update .gitignore

Add Python and workflow patterns:
```
.venv/
__pycache__/
*.pyc
.pytest_cache/
.coverage
```

## Output

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ PROJECT INITIALIZED FOR SDD
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Created:
  ✓ thoughts/ledgers/         - For continuity
  ✓ thoughts/shared/handoffs/ - For session transfers
  ✓ thoughts/shared/plans/    - For implementation plans
  ✓ docs/design/              - For architecture docs
  ✓ .design/                  - For UX specs
  ✓ specs/                    - For behavioral specs
  ✓ evals/                    - For eval scripts
  ✓ tools/                    - SDD utility scripts
  ✓ .venv/                    - Python virtual environment
  ✓ pyproject.toml            - Python config
  ✓ traceability_matrix.json  - Requirement tracking

Next steps:
  1. /prd <file>    - Process a PRD
  2. /design <feat> - Or start with a design document
  3. /status        - Check workflow health
```

$ARGUMENTS
