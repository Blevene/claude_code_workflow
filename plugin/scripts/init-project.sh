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

# Tests directory (for TDD)
mkdir -p tests
echo "✓ tests/"

# Create initial traceability matrix
if [ ! -f traceability_matrix.json ]; then
    cat > traceability_matrix.json << 'EOF'
{
  "metadata": {
    "project": "PROJECT_NAME",
    "created": "DATE",
    "version": "1.0.0"
  },
  "requirements": [],
  "traceability": {
    "requirements_to_design": {},
    "requirements_to_tasks": {},
    "requirements_to_tests": {},
    "requirements_to_code": {}
  },
  "coverage_summary": {
    "total_requirements": 0,
    "requirements_with_design": 0,
    "requirements_with_tests": 0,
    "requirements_with_code": 0
  }
}
EOF
    # Update with project name and date
    PROJECT_NAME=$(basename "$(pwd)")
    DATE=$(date -Iseconds)
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "s/PROJECT_NAME/$PROJECT_NAME/g" traceability_matrix.json
        sed -i '' "s/DATE/$DATE/g" traceability_matrix.json
    else
        sed -i "s/PROJECT_NAME/$PROJECT_NAME/g" traceability_matrix.json
        sed -i "s/DATE/$DATE/g" traceability_matrix.json
    fi
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
echo "  • /save-state before /clear"
echo "  • /handoff when ending session"
echo "  • Watch context % in status line"
echo ""
