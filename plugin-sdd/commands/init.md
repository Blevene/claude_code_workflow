---
description: Initialize project for Spec-Driven Development workflow - creates directories, venv, and config files
---

# Initialize Project

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
cat > traceability_matrix.json << EOF
{
  "meta": {
    "version": 1,
    "project": "$(basename $(pwd))",
    "created": "$(date -Iseconds)",
    "description": "Traceability matrix linking EARS requirements to specs, evals, design, and code."
  },
  "requirements": []
}
EOF
```

### 4. Update .gitignore

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
  ✓ .venv/                    - Python virtual environment
  ✓ pyproject.toml            - Python config
  ✓ traceability_matrix.json  - Requirement tracking

Next steps:
  1. /prd <file>    - Process a PRD
  2. /design <feat> - Or start with a design document
  3. /status        - Check workflow health
```

$ARGUMENTS
