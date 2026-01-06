#!/bin/bash
# Stop Hook - Runs when Claude finishes responding (main agent, not subagent)
# Purpose: Update ledger, remind to create handoff, check for unsaved work
#
# Note: Does NOT run on user interrupt (Ctrl+C)
# Can block Claude from stopping with decision: "block" + reason

# Redirect stderr to prevent error output
exec 2>/dev/null

# Ensure clean exit on any failure (default to allow stop)
trap 'exit 0' ERR

# Verify jq is available
if ! command -v jq &>/dev/null; then
    exit 0
fi

# Read input from stdin
INPUT=$(head -c 50000 2>/dev/null)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "unknown"' 2>/dev/null) || SESSION_ID="unknown"
STOP_HOOK_ACTIVE=$(echo "$INPUT" | jq -r '.stop_hook_active // false' 2>/dev/null) || STOP_HOOK_ACTIVE="false"

# Paths
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"
PLUGIN_DIR="${CLAUDE_PLUGIN_ROOT:-$(dirname "$0")/..}"
CACHE_DIR="$PROJECT_DIR/.claude/cache"
TRACKING_FILE="$CACHE_DIR/session-$SESSION_ID-files.txt"
BUILD_FILE="$CACHE_DIR/session-$SESSION_ID-builds.txt"
LEDGER_DIR="$PROJECT_DIR/thoughts/ledgers"
HANDOFF_DIR="$PROJECT_DIR/thoughts/shared/handoffs"

# Prevent infinite loops - if stop hook already triggered continuation, don't block again
if [ "$STOP_HOOK_ACTIVE" = "true" ]; then
    exit 0
fi

# ============================================
# AUTO-UPDATE LEDGER (silent, non-blocking)
# ============================================
update_ledger_silent() {
    local ledger_script="$PLUGIN_DIR/hooks/update-ledger.sh"
    if [ -x "$ledger_script" ]; then
        "$ledger_script" "response-complete" "$SESSION_ID" "" "" "" 2>/dev/null || true
    fi
}

# Always update ledger when agent finishes responding
update_ledger_silent

# ============================================
# CHECK FOR UNSAVED WORK
# ============================================

# Count files modified this session
FILES_MODIFIED=0
if [ -f "$TRACKING_FILE" ]; then
    FILES_MODIFIED=$(wc -l < "$TRACKING_FILE" 2>/dev/null | tr -d ' ')
fi

# Count build/test results
BUILDS_PASSED=0
BUILDS_FAILED=0
TESTS_PASSED=0
TESTS_FAILED=0
if [ -f "$BUILD_FILE" ]; then
    BUILDS_PASSED=$(grep -c "|build|.*|pass" "$BUILD_FILE" 2>/dev/null | head -1 || echo "0")
    BUILDS_FAILED=$(grep -c "|build|.*|fail" "$BUILD_FILE" 2>/dev/null | head -1 || echo "0")
    TESTS_PASSED=$(grep -c "|test|.*|pass" "$BUILD_FILE" 2>/dev/null | head -1 || echo "0")
    TESTS_FAILED=$(grep -c "|test|.*|fail" "$BUILD_FILE" 2>/dev/null | head -1 || echo "0")
    # Ensure they're numbers
    [[ "$BUILDS_PASSED" =~ ^[0-9]+$ ]] || BUILDS_PASSED=0
    [[ "$BUILDS_FAILED" =~ ^[0-9]+$ ]] || BUILDS_FAILED=0
    [[ "$TESTS_PASSED" =~ ^[0-9]+$ ]] || TESTS_PASSED=0
    [[ "$TESTS_FAILED" =~ ^[0-9]+$ ]] || TESTS_FAILED=0
fi

# Check if ledger exists
HAS_LEDGER=false
if [ -d "$LEDGER_DIR" ]; then
    LEDGER_COUNT=$(ls "$LEDGER_DIR"/CONTINUITY_*.md 2>/dev/null | wc -l | tr -d ' ')
    if [ "$LEDGER_COUNT" -gt 0 ]; then
        HAS_LEDGER=true
    fi
fi

# Check for recent handoffs (within last hour)
RECENT_HANDOFF=false
if [ -d "$HANDOFF_DIR" ]; then
    # Find handoffs modified in the last 60 minutes
    RECENT=$(find "$HANDOFF_DIR" -name "*.md" -type f ! -name "._*" -mmin -60 2>/dev/null | head -1)
    if [ -n "$RECENT" ]; then
        RECENT_HANDOFF=true
    fi
fi

# ============================================
# DECIDE WHETHER TO REMIND
# ============================================

REMINDER=""
SHOULD_REMIND=false

# Significant work done but no recent handoff
if [ "$FILES_MODIFIED" -ge 5 ] && [ "$RECENT_HANDOFF" = "false" ]; then
    SHOULD_REMIND=true
    REMINDER+="
📝 SESSION SUMMARY
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Files modified: $FILES_MODIFIED
"
    if [ "$BUILDS_PASSED" -gt 0 ] || [ "$BUILDS_FAILED" -gt 0 ]; then
        REMINDER+="Builds: $BUILDS_PASSED passed, $BUILDS_FAILED failed\n"
    fi
    if [ "$TESTS_PASSED" -gt 0 ] || [ "$TESTS_FAILED" -gt 0 ]; then
        REMINDER+="Tests: $TESTS_PASSED passed, $TESTS_FAILED failed\n"
    fi
    REMINDER+="
💡 Consider running /handoff to save your progress
   or /save-state to update the continuity ledger.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
"
fi

# Tests failed - might want to document
if [ "$TESTS_FAILED" -gt 0 ] && [ "$RECENT_HANDOFF" = "false" ]; then
    if [ "$SHOULD_REMIND" = "false" ]; then
        SHOULD_REMIND=true
        REMINDER+="
⚠️ FAILING TESTS DETECTED
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Tests failed: $TESTS_FAILED

Consider documenting the issue before ending:
- /handoff to create a detailed handoff
- /save-state to update ledger with current status
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
"
    fi
fi

# No ledger exists and significant work done
if [ "$HAS_LEDGER" = "false" ] && [ "$FILES_MODIFIED" -ge 3 ]; then
    SHOULD_REMIND=true
    REMINDER+="
📋 NO CONTINUITY LEDGER
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
You've modified $FILES_MODIFIED files but have no ledger.

Run /sdd-init to set up continuity tracking for this project.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
"
fi

# ============================================
# OUTPUT
# ============================================

if [ "$SHOULD_REMIND" = "true" ] && [ -n "$REMINDER" ]; then
    # Don't block, just show reminder as system message
    jq -n --arg msg "$REMINDER" '{
        "continue": true,
        "systemMessage": $msg
    }'
else
    # No reminder needed, just continue
    exit 0
fi

