#!/bin/bash
# PreCompact Hook - Creates auto-handoff before compaction
# Triggered by: auto (system compaction), manual (user requested)

# Don't use set -e globally - handle errors gracefully
# Redirect stderr to prevent error output (except for manual blocking)
exec 2>/dev/null

# Read input from stdin (limit size for safety)
INPUT=$(head -c 500000 2>/dev/null)

# Verify jq is available - if not, just exit cleanly
if ! command -v jq &>/dev/null; then
    exit 0
fi

# Parse input safely
TRIGGER=$(echo "$INPUT" | jq -r '.trigger // "auto"' 2>/dev/null) || TRIGGER="auto"
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "unknown"' 2>/dev/null) || SESSION_ID="unknown"
TRANSCRIPT=$(echo "$INPUT" | jq -r '.transcript // ""' 2>/dev/null | head -c 100000) || TRANSCRIPT=""

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
    # Re-enable stderr for blocking message
    exec 2>&1
    echo "⚠️ Manual compaction blocked. Please use /clear instead of compact. Ledger is auto-updated by hooks. This preserves full context fidelity."
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

    # Extract current phase and goal from ledger
    local current_phase=""
    local current_goal=""
    local now_doing=""
    local latest_ledger=$(ls -t "$LEDGER_DIR"/CONTINUITY_*.md 2>/dev/null | head -1)
    if [ -f "$latest_ledger" ]; then
        current_phase=$(grep -A1 "^## Current Phase" "$latest_ledger" 2>/dev/null | tail -1 | head -c 50 || echo "unknown")
        current_goal=$(grep -A1 "^## Goal" "$latest_ledger" 2>/dev/null | tail -1 | head -c 100 || echo "")
        now_doing=$(grep "^- Now:" "$latest_ledger" 2>/dev/null | head -1 | cut -d: -f2- | head -c 100 || echo "")
    fi

    # Get most recently modified files
    local recent_modified=""
    if [ -d "$PROJECT_DIR" ]; then
        recent_modified=$(find "$PROJECT_DIR" \( -name "*.py" -o -name "*.md" -o -name "*.ts" -o -name "*.tsx" \) ! -name "._*" 2>/dev/null | \
            xargs ls -t 2>/dev/null | head -5 | \
            xargs -I{} basename {} 2>/dev/null | tr '\n' ', ' || echo "")
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

## Current State
- **Phase:** $current_phase
- **Goal:** $current_goal
- **Was doing:** $now_doing

## Next Steps

1. **Review the ledger** at \`thoughts/ledgers/CONTINUITY_*.md\` for full context
2. **Check git status** to see what was being worked on
3. **Run evals** to verify current state: \`uv run python tools/run_evals.py --all\`
4. **Continue from the "Now" section** of the ledger

## Recent File Activity
\`\`\`
$recent_files
\`\`\`

## Recently Modified
$recent_modified

## Git Status
\`\`\`
$git_status
\`\`\`

## Files to Check

- \`thoughts/ledgers/CONTINUITY_*.md\` - Full state
- \`traceability_matrix.json\` - Requirement coverage
- \`specs/\` - Behavioral specifications
- \`evals/\` - Eval scripts

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

# Output JSON response - allow compaction to proceed with system message
MESSAGE="
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📦 CONTEXT COMPACTION - STATE SAVED
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✅ Auto-handoff created: $HANDOFF_FILE
$LEDGER_MSG

⚠️  AFTER COMPACTION:
1. Context will be compressed - some details may be lost
2. The ledger will auto-reload on your next message
3. Review the handoff above if you need to recover context

💡 TIP: Use /clear instead of letting context compact.
   Ledger auto-updated → /clear preserves full fidelity.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
"

jq -n --arg msg "$MESSAGE" '{
    "continue": true,
    "systemMessage": $msg
}'
