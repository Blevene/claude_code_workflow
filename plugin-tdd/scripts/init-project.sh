#!/bin/bash
# init-project.sh - Initialize a project for FAANG Continuity workflow
set -e

echo "┌─────────────────────────────────────────────────────────────┐"
echo "│  FAANG Continuity - Project Initialization                  │"
echo "└─────────────────────────────────────────────────────────────┘"
echo ""
echo "This will create:"
echo "  • thoughts/ledgers/     - Continuity ledgers"
echo "  • thoughts/shared/      - Plans and handoffs"
echo "  • .claude/cache/        - Session tracking"
echo "  • docs/design/          - Design documents"
echo "  • traceability_matrix.json - Requirement tracking"
echo ""

PROJECT_DIR="${1:-.}"
cd "$PROJECT_DIR"

echo "Project: $(pwd)"
echo ""
read -p "Continue? [y/N] " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 1
fi

echo ""
echo "Creating directories..."

# Continuity directories
mkdir -p thoughts/ledgers
mkdir -p thoughts/shared/handoffs
mkdir -p thoughts/shared/plans
echo "✓ thoughts/ledgers/"
echo "✓ thoughts/shared/handoffs/"
echo "✓ thoughts/shared/plans/"

# Cache directory
mkdir -p .claude/cache
echo "✓ .claude/cache/"

# Design docs directory
mkdir -p docs/design
echo "✓ docs/design/"

# UX specs directory
mkdir -p .design
echo "✓ .design/"

# Tests directory (for TDD)
mkdir -p tests
echo "✓ tests/"

# Python virtual environment setup with uv
echo ""
echo "Setting up Python environment with uv..."

# Check if uv is available
if command -v uv &> /dev/null; then
    # Create virtual environment if it doesn't exist
    if [ ! -d ".venv" ]; then
        uv venv
        echo "✓ .venv/ (created with uv)"
    else
        echo "• .venv/ (already exists)"
    fi
    
    # Create pyproject.toml if it doesn't exist
    if [ ! -f "pyproject.toml" ]; then
        cat > pyproject.toml << 'PYPROJECT'
[project]
name = "PROJECT_NAME"
version = "0.1.0"
description = "Project description"
requires-python = ">=3.10"
dependencies = []

[project.optional-dependencies]
dev = [
    "pytest>=7.0",
    "pytest-cov>=4.0",
    "pytest-mock>=3.0",
]

[tool.pytest.ini_options]
testpaths = ["tests"]
python_files = ["test_*.py"]
python_classes = ["Test*"]
python_functions = ["test_*"]

[tool.uv]
dev-dependencies = [
    "pytest>=7.0",
    "pytest-cov>=4.0",
    "pytest-mock>=3.0",
]
PYPROJECT
        # Update with project name
        PROJECT_NAME=$(basename "$(pwd)")
        if [[ "$OSTYPE" == "darwin"* ]]; then
            sed -i '' "s/PROJECT_NAME/$PROJECT_NAME/g" pyproject.toml
        else
            sed -i "s/PROJECT_NAME/$PROJECT_NAME/g" pyproject.toml
        fi
        echo "✓ pyproject.toml"
    else
        echo "• pyproject.toml (already exists)"
    fi
    
    # Sync dependencies
    echo "Syncing Python dependencies..."
    uv sync 2>/dev/null || uv pip install pytest pytest-cov pytest-mock 2>/dev/null || true
    echo "✓ Python dependencies synced"
else
    echo "⚠ uv not found. Install with: curl -LsSf https://astral.sh/uv/install.sh | sh"
    echo "  Then re-run this script to set up Python environment."
fi

# Create initial traceability matrix
if [ ! -f traceability_matrix.json ]; then
    PROJECT_NAME=$(basename "$(pwd)")
    DATE=$(date -Iseconds)
    cat > traceability_matrix.json << EOF
{
  "meta": {
    "version": 1,
    "project": "$PROJECT_NAME",
    "created": "$DATE",
    "description": "Traceability matrix linking EARS requirements to tasks, design, code, and tests."
  },
  "requirements": []
}
EOF
    echo "✓ traceability_matrix.json"
else
    echo "• traceability_matrix.json (already exists)"
fi

# Create initial continuity ledger
PROJECT_NAME=$(basename "$(pwd)")
LEDGER_FILE="thoughts/ledgers/CONTINUITY_CLAUDE-${PROJECT_NAME}.md"
if [ ! -f "$LEDGER_FILE" ]; then
    cat > "$LEDGER_FILE" << EOF
---
project: $PROJECT_NAME
updated: $(date -Iseconds)
session_id: initial
---

# Continuity Ledger: $PROJECT_NAME

## Goal
[Describe the overall project goal]

## Current Phase
REQUIREMENTS

## Constraints
- [Add key constraints]

## Completed
- [x] Project initialized

## Now
- Define requirements
- Create initial design

## Blocked / Parking Lot
- None yet

## Key Decisions
| Decision | Rationale | Date |
|----------|-----------|------|
| Use FAANG workflow | Ensures quality and traceability | $(date +%Y-%m-%d) |

## Working Files
- \`traceability_matrix.json\` - Requirement tracking

## Traceability Status
- Requirements: 0 defined
- Design docs: 0 created
- Tests: 0%
- Gaps: Initial setup

## Notes for Next Session
Project initialized. Ready to begin requirements gathering.
EOF
    echo "✓ $LEDGER_FILE"
else
    echo "• $LEDGER_FILE (already exists)"
fi

# Update .gitignore
echo ""
echo "Updating .gitignore..."
touch .gitignore

add_to_gitignore() {
    if ! grep -qF "$1" .gitignore 2>/dev/null; then
        echo "$1" >> .gitignore
        echo "  + $1"
    fi
}

add_to_gitignore ".claude/cache/"
add_to_gitignore "thoughts/shared/handoffs/"
add_to_gitignore ".venv/"
add_to_gitignore "__pycache__/"
add_to_gitignore "*.pyc"
add_to_gitignore ".pytest_cache/"
# Note: keeping ledgers and plans in git can be useful

echo ""
echo "┌─────────────────────────────────────────────────────────────┐"
echo "│  ✓ Project initialized!                                     │"
echo "└─────────────────────────────────────────────────────────────┘"
echo ""
echo "Next steps:"
echo "  1. Start Claude: claude"
echo "  2. Process a PRD: /prd <file>"
echo "  3. Or create design: /design <feature>"
echo "  4. Check status: /status"
echo ""
echo "Continuity tips:"
echo "  • /clear when context fills (ledger auto-saved)"
echo "  • /handoff when ending session"
echo "  • Watch context % in status line"
echo ""
echo "Python environment:"
echo "  • Always use 'uv run' for Python/pytest"
echo "  • Sync deps: 'uv sync'"
echo "  • Add packages: 'uv add <package>'"
echo ""
