#!/bin/bash
# SessionStart Hook - Loads continuity state after /clear or session start
# Triggered by: startup, resume, clear, compact
set -e

# Read input from stdin
INPUT=$(cat)
SOURCE=$(echo "$INPUT" | jq -r '.source // "startup"')
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "unknown"')

# Paths
# CLAUDE_PROJECT_DIR = user's project directory (for user files like ledgers)
# CLAUDE_PLUGIN_ROOT = plugin installation directory (for plugin scripts)
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"
LEDGER_DIR="$PROJECT_DIR/thoughts/ledgers"
HANDOFF_DIR="$PROJECT_DIR/thoughts/shared/handoffs"
PLANS_DIR="$PROJECT_DIR/thoughts/shared/plans"
SPECS_DIR="$PROJECT_DIR/specs"
EVALS_DIR="$PROJECT_DIR/evals"

# Find most recent ledger
find_latest_ledger() {
    if [ -d "$LEDGER_DIR" ]; then
        ls -t "$LEDGER_DIR"/CONTINUITY_*.md 2>/dev/null | head -1
    fi
}

# Find most recent handoff
find_latest_handoff() {
    if [ -d "$HANDOFF_DIR" ]; then
        find "$HANDOFF_DIR" -name "*.md" -type f 2>/dev/null | \
            xargs ls -t 2>/dev/null | head -1
    fi
}

# Find active plan (check both .json and .md formats)
find_active_plan() {
    if [ -d "$PLANS_DIR" ]; then
        # Prefer JSON plans, fall back to markdown
        ls -t "$PLANS_DIR"/*.json 2>/dev/null | head -1 || \
        ls -t "$PLANS_DIR"/*.md 2>/dev/null | head -1
    fi
}

# Count specs and evals
count_specs() {
    if [ -d "$SPECS_DIR" ]; then
        find "$SPECS_DIR" -name "SPEC-*.md" -type f 2>/dev/null | wc -l
    else
        echo "0"
    fi
}

count_evals() {
    if [ -d "$EVALS_DIR" ]; then
        find "$EVALS_DIR" -name "eval_*.py" -type f 2>/dev/null | wc -l
    else
        echo "0"
    fi
}

# Extract key sections from ledger
extract_ledger_context() {
    local ledger="$1"
    if [ -f "$ledger" ]; then
        # Extract Goal, Current Phase, Now sections
        awk '
            /^## Goal/,/^## [^G]/ { if (!/^## [^G]/) print }
            /^## Current Phase/,/^## [^C]/ { if (!/^## [^C]/) print }
            /^## Now/,/^## [^N]/ { if (!/^## [^N]/) print }
            /^## Completed/,/^## [^C]/ { if (!/^## [^C]/) print }
            /^## Key Decisions/,/^## [^K]/ { if (!/^## [^K]/) print }
        ' "$ledger"
    fi
}

# Build context to inject
CONTEXT=""

# Check Python environment status
check_python_env() {
    local env_status=""

    # Check if uv is available
    if command -v uv &> /dev/null; then
        env_status+="✓ uv available"
    else
        env_status+="⚠ uv NOT found - install: curl -LsSf https://astral.sh/uv/install.sh | sh"
        echo "$env_status"
        return
    fi

    # Check if .venv exists
    if [ -d "$PROJECT_DIR/.venv" ]; then
        env_status+="\n✓ .venv/ exists"
    else
        env_status+="\n⚠ .venv/ missing - run: uv venv"
    fi

    # Check for pyproject.toml or requirements.txt
    if [ -f "$PROJECT_DIR/pyproject.toml" ]; then
        env_status+="\n✓ pyproject.toml found"
    elif [ -f "$PROJECT_DIR/requirements.txt" ]; then
        env_status+="\n✓ requirements.txt found"
    else
        env_status+="\n• No pyproject.toml or requirements.txt"
    fi

    echo -e "$env_status"
}

# Get Python environment status
PYTHON_ENV_STATUS=$(check_python_env)
SPECS_COUNT=$(count_specs)
EVALS_COUNT=$(count_evals)

CONTEXT+="
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🐍 PYTHON ENVIRONMENT
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
$PYTHON_ENV_STATUS

⚠️  REMINDER: Always use 'uv run' for Python execution:
   • Evals:  uv run python tools/run_evals.py --all
   • Single: uv run python evals/module/eval_spec_001.py
   • Code:   uv run python script.py
   • Deps:   uv sync

📋 SDD STATUS: $SPECS_COUNT specs, $EVALS_COUNT evals
"

# Load ledger
LEDGER=$(find_latest_ledger)
if [ -n "$LEDGER" ] && [ -f "$LEDGER" ]; then
    LEDGER_CONTENT=$(extract_ledger_context "$LEDGER")
    CONTEXT+="
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 CONTINUITY LEDGER ($(basename "$LEDGER"))
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
$LEDGER_CONTENT
"
fi

# Load handoff
HANDOFF=$(find_latest_handoff)
if [ -n "$HANDOFF" ] && [ -f "$HANDOFF" ]; then
    HANDOFF_PREVIEW=$(head -100 "$HANDOFF")
    CONTEXT+="
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🤝 LATEST HANDOFF ($(basename "$HANDOFF"))
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
$HANDOFF_PREVIEW
"
fi

# Load active plan
PLAN=$(find_active_plan)
if [ -n "$PLAN" ] && [ -f "$PLAN" ]; then
    PLAN_SUMMARY=$(head -50 "$PLAN")
    CONTEXT+="
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📝 ACTIVE PLAN ($(basename "$PLAN"))
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
$PLAN_SUMMARY
"
fi

# If nothing found, provide guidance
if [ -z "$CONTEXT" ]; then
    CONTEXT="
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🆕 FRESH SESSION - No continuity state found
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Available commands:
  /prd <file>     - Start from a PRD
  /design <feat>  - Create design document
  /spec <REQ>     - Create behavioral spec
  /status         - Check workflow status

Continuity tips:
  - Use /save-state before /clear to preserve context
  - Use /handoff when ending a session
  - Use /resume to continue from a handoff
"
fi

# Output JSON response
jq -n --arg ctx "$CONTEXT" '{
    "continue": true,
    "hookSpecificOutput": {
        "hookEventName": "SessionStart",
        "additionalContext": $ctx
    }
}'
