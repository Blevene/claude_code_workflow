#!/bin/bash
# PostToolUse Hook - Tracks file modifications for handoff generation
# Triggered by: Edit, Write, Bash
set -e

# Read input from stdin
INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // "unknown"')
TOOL_INPUT=$(echo "$INPUT" | jq -r '.tool_input // "{}"')
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "unknown"')

# Paths
# CLAUDE_PROJECT_DIR = user's project directory (for user files like ledgers)
# CLAUDE_PLUGIN_ROOT = plugin installation directory (for plugin scripts)
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"
TRACKING_FILE="$PROJECT_DIR/.claude/cache/session-$SESSION_ID-files.txt"

mkdir -p "$(dirname "$TRACKING_FILE")"

# Extract file path from tool input based on tool type
extract_file_path() {
    case "$TOOL_NAME" in
        Edit|Write|str_replace_editor)
            echo "$TOOL_INPUT" | jq -r '.file_path // .path // empty'
            ;;
        Read|view)
            # Don't track reads
            ;;
        Bash|bash)
            # Try to extract file paths from bash commands
            local cmd=$(echo "$TOOL_INPUT" | jq -r '.command // empty')
            # Look for common file-modifying patterns
            echo "$cmd" | grep -oE '(>|>>)\s*[^\s;|&]+' | sed 's/[>]\+\s*//' || true
            ;;
    esac
}

# Track the file
FILE_PATH=$(extract_file_path)
if [ -n "$FILE_PATH" ]; then
    echo "$(date -Iseconds) $TOOL_NAME $FILE_PATH" >> "$TRACKING_FILE"
fi

# Check if this is creating a handoff file (index it)
if echo "$FILE_PATH" | grep -qE 'thoughts/shared/handoffs/.*\.md$'; then
    # Could trigger artifact indexing here
    :
fi

# Always continue - this is an observation hook
# Exit code 0 with no output = success, continue normally
exit 0
