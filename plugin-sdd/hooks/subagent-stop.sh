#!/bin/bash
# SubagentStop Hook - Captures agent output and creates task handoffs
# Triggered by: when any subagent completes

# Don't use set -e - handle errors gracefully
# Redirect stderr to prevent error output
exec 2>/dev/null

# Ensure clean exit on any failure
trap 'exit 0' ERR

# Read input from stdin (limit size)
INPUT=$(head -c 500000)

# Verify jq is available
if ! command -v jq &>/dev/null; then
    exit 0
fi

# Parse input safely
AGENT_NAME=$(echo "$INPUT" | jq -r '.agent_name // "unknown"' 2>/dev/null) || exit 0
AGENT_OUTPUT=$(echo "$INPUT" | jq -r '.output // ""' 2>/dev/null | head -c 50000) || AGENT_OUTPUT=""
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "unknown"' 2>/dev/null) || exit 0
TASK_ID=$(echo "$INPUT" | jq -r '.task_id // ""' 2>/dev/null) || TASK_ID=""

# Paths
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"
PLUGIN_DIR="${CLAUDE_PLUGIN_ROOT:-$(dirname "$0")/..}"
HANDOFF_DIR="$PROJECT_DIR/thoughts/shared/handoffs/$SESSION_ID"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

mkdir -p "$HANDOFF_DIR"

# Create task handoff for the agent's work
create_task_handoff() {
    local handoff_file="$HANDOFF_DIR/task-${AGENT_NAME}-$TIMESTAMP.md"

    cat > "$handoff_file" << EOF
---
type: task-handoff
agent: $AGENT_NAME
session_id: $SESSION_ID
task_id: $TASK_ID
created: $(date -Iseconds)
---

# Task Handoff: $AGENT_NAME

## Agent: @$AGENT_NAME
Completed: $(date)
Task ID: $TASK_ID

## Summary

$AGENT_OUTPUT

## For Next Agent

The above work was completed by @$AGENT_NAME.
Review the changes and continue with the next task.

### Files Modified

Check \`.claude/cache/session-$SESSION_ID-files.txt\` for recent file activity.

### Continuation Points

- Review changes made by this agent
- Run evals to verify: \`uv run python tools/run_evals.py --all\`
- Check traceability: \`uv run python tools/traceability_tools.py check-gaps traceability_matrix.json\`

EOF

    echo "$handoff_file"
}

# Only create handoffs for our SDD agents
case "$AGENT_NAME" in
    pm|planner|architect|ux|frontend|backend|spec-writer|overseer|orchestrator)
        HANDOFF_FILE=$(create_task_handoff)
        
        # Auto-update continuity ledger alongside task handoff
        LEDGER_SCRIPT="$PLUGIN_DIR/hooks/update-ledger.sh"
        if [ -x "$LEDGER_SCRIPT" ]; then
            LEDGER_FILE=$("$LEDGER_SCRIPT" "subagent-stop" "$SESSION_ID" "$AGENT_NAME" "" "Task: $TASK_ID")
            echo "✅ @$AGENT_NAME completed. Handoff: $HANDOFF_FILE | Ledger: $LEDGER_FILE"
        else
            echo "✅ @$AGENT_NAME completed. Task handoff: $HANDOFF_FILE"
        fi
        exit 0
        ;;
    *)
        # Unknown agent, just continue - exit 0 to allow stop
        exit 0
        ;;
esac
