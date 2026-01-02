#!/bin/bash
# SubagentStop Hook - Captures agent output and creates task handoffs
# Triggered by: when any subagent completes
set -e

# Read input from stdin
INPUT=$(cat)
AGENT_NAME=$(echo "$INPUT" | jq -r '.agent_name // "unknown"')
AGENT_OUTPUT=$(echo "$INPUT" | jq -r '.output // ""')
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "unknown"')
TASK_ID=$(echo "$INPUT" | jq -r '.task_id // ""')

# Paths
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"
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
        # Output message for verbose mode, exit 0 to allow stop
        echo "✅ @$AGENT_NAME completed. Task handoff: $HANDOFF_FILE"
        exit 0
        ;;
    *)
        # Unknown agent, just continue - exit 0 to allow stop
        exit 0
        ;;
esac
