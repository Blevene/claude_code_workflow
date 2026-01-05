#!/bin/bash
# SessionEnd Hook - Update ledger and cleanup on session end
# Triggered by: clear, logout, prompt_input_exit, other

# Don't use set -e - handle errors gracefully
# Redirect stderr to prevent error output
exec 2>/dev/null

# Ensure clean exit on any failure
trap 'exit 0' ERR

# Verify jq is available
if ! command -v jq &>/dev/null; then
    exit 0
fi

# Read input from stdin
INPUT=$(head -c 50000 2>/dev/null)
REASON=$(echo "$INPUT" | jq -r '.reason // "other"' 2>/dev/null) || REASON="other"
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "unknown"' 2>/dev/null) || SESSION_ID="unknown"

# Paths
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"
PLUGIN_DIR="${CLAUDE_PLUGIN_ROOT:-$(dirname "$0")/..}"
LEDGER_DIR="$PROJECT_DIR/thoughts/ledgers"
CACHE_DIR="$PROJECT_DIR/.claude/cache"
TIMESTAMP=$(date -Iseconds)

# ============================================
# UPDATE CONTINUITY LEDGER
# ============================================
update_ledger() {
    local ledger_script="$PLUGIN_DIR/hooks/update-ledger.sh"
    if [ -x "$ledger_script" ]; then
        "$ledger_script" "session-end" "$SESSION_ID" "" "" "Session ended: $REASON" 2>/dev/null || true
    fi
}

# Clean up old cache files (older than 7 days)
cleanup_old_cache() {
    if [ -d "$CACHE_DIR" ]; then
        # Clean session files older than 7 days
        find "$CACHE_DIR" -name "session-*" -type f -mtime +7 -delete 2>/dev/null || true
        
        # Clean loop detection files older than 1 day
        find "$CACHE_DIR" -name "*-loops.txt" -type f -mtime +1 -delete 2>/dev/null || true
    fi
}

# Clean up old handoff files (older than 30 days, keep at least 10 most recent)
cleanup_old_handoffs() {
    local handoff_dir="$PROJECT_DIR/thoughts/shared/handoffs"
    if [ -d "$handoff_dir" ]; then
        # Count total handoff files
        local count=$(find "$handoff_dir" -name "*.md" -type f ! -name "._*" 2>/dev/null | wc -l)
        
        if [ "$count" -gt 10 ]; then
            # Delete files older than 30 days, but keep at least 10
            find "$handoff_dir" -name "*.md" -type f ! -name "._*" -mtime +30 2>/dev/null | \
                head -n $((count - 10)) | xargs rm -f 2>/dev/null || true
        fi
    fi
}

# Run tasks
update_ledger
cleanup_old_cache
cleanup_old_handoffs

# Output - SessionEnd doesn't need complex JSON, just exit 0
exit 0

