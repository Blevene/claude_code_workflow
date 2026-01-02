#!/bin/bash
# UserPromptSubmit Hook - Context warnings and skill activation hints
# Triggered by: every user message
set -e

# Read input from stdin
INPUT=$(cat)
USER_MESSAGE=$(echo "$INPUT" | jq -r '.prompt // .message // ""')
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "unknown"')

# Paths
# CLAUDE_PROJECT_DIR = user's project directory (for user files like ledgers)
# CLAUDE_PLUGIN_ROOT = plugin installation directory (for plugin scripts)
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"
CONTEXT_FILE="/tmp/claude-context-pct-$SESSION_ID.txt"

# Read context percentage if available (written by status line)
CONTEXT_PCT=0
if [ -f "$CONTEXT_FILE" ]; then
    CONTEXT_PCT=$(cat "$CONTEXT_FILE" 2>/dev/null || echo "0")
fi

# Build response
HINTS=""

# Context warnings based on usage
if [ "$CONTEXT_PCT" -ge 90 ]; then
    HINTS+="
🚨 CONTEXT CRITICAL ($CONTEXT_PCT%)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Run /save-state then /clear NOW!
Compaction is imminent and will degrade agent quality.
"
elif [ "$CONTEXT_PCT" -ge 80 ]; then
    HINTS+="
⚠️ CONTEXT WARNING ($CONTEXT_PCT%)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Recommend: /save-state then /clear soon.
"
elif [ "$CONTEXT_PCT" -ge 70 ]; then
    HINTS+="
📊 Context at $CONTEXT_PCT% - Consider saving state at next milestone.
"
fi

# Skill activation hints based on keywords
MESSAGE_LOWER=$(echo "$USER_MESSAGE" | tr '[:upper:]' '[:lower:]')

# FAANG workflow triggers
if echo "$MESSAGE_LOWER" | grep -qE '(implement|add feature|fix bug|code)'; then
    HINTS+="
💡 TDD workflow activated - write failing test FIRST
"
fi

if echo "$MESSAGE_LOWER" | grep -qE '(design|architect|api contract)'; then
    HINTS+="
💡 Use /design to create architecture document before implementation
"
fi

if echo "$MESSAGE_LOWER" | grep -qE '(done|wrap up|end session|stopping)'; then
    HINTS+="
💡 Use /handoff to create detailed session handoff
"
fi

if echo "$MESSAGE_LOWER" | grep -qE '(continue|resume|pick up|where were we)'; then
    HINTS+="
💡 Use /resume to load the latest handoff
"
fi

if echo "$MESSAGE_LOWER" | grep -qE '(before clear|save state|preserve)'; then
    HINTS+="
💡 Use /save-state to update continuity ledger
"
fi

# Output response
if [ -n "$HINTS" ]; then
    jq -n --arg hints "$HINTS" '{
        "continue": true,
        "hookSpecificOutput": {
            "hookEventName": "UserPromptSubmit",
            "additionalContext": $hints
        }
    }'
else
    # Exit code 0 with no output = success, continue normally
    exit 0
fi
