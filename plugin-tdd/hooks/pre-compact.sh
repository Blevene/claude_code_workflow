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
PLUGIN_DIR="${CLAUDE_PLUGIN_ROOT:-$(dirname "$0")/..}"
HANDOFF_DIR="$PROJECT_DIR/thoughts/shared/handoffs/$SESSION_ID"
LEDGER_DIR="$PROJECT_DIR/thoughts/ledgers"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

mkdir -p "$HANDOFF_DIR"
mkdir -p "$LEDGER_DIR"

# For manual compaction, block and prompt for ledger update
if [ "$TRIGGER" = "manual" ]; then
    # Exit code 2 blocks with stderr shown to user
    echo "⚠️ Manual compaction blocked. Please run /save-state first to update the continuity ledger, then use /clear instead of compact. This preserves full context fidelity." >&2
    exit 2
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
3. Use \`traceability_matrix.json\` to find gaps
4. Continue from the last known good state

## Files to Check

- \`thoughts/ledgers/CONTINUITY_*.md\` - Full state
- \`traceability_matrix.json\` - Requirement coverage
- \`docs/design/\` - Design documents
- \`tests/\` - Test status

EOF

    echo "$handoff_file"
}

HANDOFF_FILE=$(create_auto_handoff)

# Auto-update continuity ledger alongside auto-handoff
LEDGER_MSG=""
LEDGER_SCRIPT="$PLUGIN_DIR/hooks/update-ledger.sh"
if [ -x "$LEDGER_SCRIPT" ]; then
    LEDGER_FILE=$("$LEDGER_SCRIPT" "pre-compact" "$SESSION_ID" "" "" "Auto-save before compaction")
    LEDGER_MSG="📋 Ledger updated: $LEDGER_FILE"
fi

# Output JSON response - allow compaction to proceed
jq -n --arg handoff "$HANDOFF_FILE" --arg ledger "$LEDGER_MSG" '{
    "continue": true,
    "hookSpecificOutput": {
        "hookEventName": "PreCompact",
        "additionalContext": ("📦 Auto-handoff created before compaction:\n" + $handoff + "\n" + $ledger + "\n\nContext will be refreshed. Ledger will reload on next prompt.")
    }
}'
