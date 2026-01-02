#!/bin/bash
# PreCompact Hook - Creates auto-handoff before compaction
# Triggered by: auto (system compaction), manual (user requested)
set -e

# Read input from stdin
INPUT=$(cat)
TRIGGER=$(echo "$INPUT" | jq -r '.trigger // "auto"')
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "unknown"')
TRANSCRIPT=$(echo "$INPUT" | jq -r '.transcript // ""')

# Paths
# CLAUDE_PROJECT_DIR = user's project directory (for user files like ledgers)
# CLAUDE_PLUGIN_ROOT = plugin installation directory (for plugin scripts)
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"
HANDOFF_DIR="$PROJECT_DIR/thoughts/shared/handoffs/$SESSION_ID"
LEDGER_DIR="$PROJECT_DIR/thoughts/ledgers"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

mkdir -p "$HANDOFF_DIR"
mkdir -p "$LEDGER_DIR"

# For manual compaction, block and prompt for ledger update
if [ "$TRIGGER" = "manual" ]; then
    jq -n '{
        "event": "PreCompact",
        "decision": "block",
        "reason": "⚠️ Manual compaction blocked.\n\nPlease run /save-state first to update the continuity ledger,\nthen use /clear instead of compact.\n\nThis preserves full context fidelity."
    }'
    exit 0
fi

# For auto compaction, create emergency handoff
create_auto_handoff() {
    local handoff_file="$HANDOFF_DIR/auto-handoff-$TIMESTAMP.md"

    # Extract recent tool calls from transcript if available
    local recent_files=""
    if [ -n "$TRANSCRIPT" ]; then
        recent_files=$(echo "$TRANSCRIPT" | grep -oE '(Edit|Write|Read)\s+[^\s]+' | tail -20 || true)
    fi

    # Find recent git changes
    local git_status=""
    if [ -d "$PROJECT_DIR/.git" ]; then
        git_status=$(cd "$PROJECT_DIR" && git status --short 2>/dev/null | head -20 || true)
    fi

    cat > "$handoff_file" << EOF
---
type: auto-handoff
session_id: $SESSION_ID
created: $(date -Iseconds)
trigger: context-compaction
---

# Auto-Handoff (Context Compaction)

**⚠️ This handoff was auto-generated before context compaction.**

## Session: $SESSION_ID
Generated: $(date)

## Recent File Activity
\`\`\`
$recent_files
\`\`\`

## Git Status
\`\`\`
$git_status
\`\`\`

## Recovery Instructions

1. Review this handoff and the continuity ledger
2. Check \`/status\` for workflow state
3. Run evals to check status: \`uv run python tools/run_evals.py --all\`
4. Use \`traceability_matrix.json\` to find gaps
5. Continue from the last known good state

## Files to Check

- \`thoughts/ledgers/CONTINUITY_*.md\` - Full state
- \`traceability_matrix.json\` - Requirement coverage
- \`specs/\` - Behavioral specifications
- \`evals/\` - Eval scripts
- \`docs/design/\` - Design documents

EOF

    echo "$handoff_file"
}

HANDOFF_FILE=$(create_auto_handoff)

# Output JSON response - allow compaction to proceed
jq -n --arg handoff "$HANDOFF_FILE" '{
    "event": "PreCompact",
    "continue": true,
    "hookSpecificOutput": {
        "additionalContext": ("📦 Auto-handoff created before compaction:\n" + $handoff + "\n\nContext will be refreshed. Ledger will reload on next prompt.")
    }
}'
