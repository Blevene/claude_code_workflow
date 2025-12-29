#!/bin/bash
# SessionStart Hook - Loads continuity state after /clear or session start
# Triggered by: startup, resume, clear, compact
set -e

# Read input from stdin
INPUT=$(cat)
SOURCE=$(echo "$INPUT" | jq -r '.source // "startup"')
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "unknown"')

# Paths
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"
LEDGER_DIR="$PROJECT_DIR/thoughts/ledgers"
HANDOFF_DIR="$PROJECT_DIR/thoughts/shared/handoffs"
PLANS_DIR="$PROJECT_DIR/thoughts/shared/plans"

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

# Find active plan
find_active_plan() {
    if [ -d "$PLANS_DIR" ]; then
        ls -t "$PLANS_DIR"/*.md 2>/dev/null | head -1
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
        "additionalContext": $ctx
    }
}'
