#!/bin/bash
# PostToolUse Hook - Tracks file modifications AND detects loop patterns
# Triggered by: Edit, Write, Bash, Read
set -e

# Read input from stdin
INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // "unknown"')
TOOL_INPUT=$(echo "$INPUT" | jq -r '.tool_input // "{}"')
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "unknown"')

# Paths
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"
CACHE_DIR="$PROJECT_DIR/.claude/cache"
TRACKING_FILE="$CACHE_DIR/session-$SESSION_ID-files.txt"
LOOP_FILE="$CACHE_DIR/session-$SESSION_ID-loops.txt"

mkdir -p "$CACHE_DIR"

# Loop detection thresholds
SAME_FILE_WARN=3      # Warn after 3 operations on same file
SAME_FILE_BLOCK=5     # Block after 5 operations on same file
RECENT_WINDOW=20      # Look at last 20 operations for pattern detection

# Extract file path from tool input based on tool type
extract_file_path() {
    case "$TOOL_NAME" in
        Edit|Write|str_replace_editor)
            echo "$TOOL_INPUT" | jq -r '.file_path // .path // empty'
            ;;
        Read|view|read_file)
            echo "$TOOL_INPUT" | jq -r '.file_path // .path // .target_file // empty'
            ;;
        Bash|bash)
            # Try to extract file paths from bash commands
            local cmd=$(echo "$TOOL_INPUT" | jq -r '.command // empty')
            # Look for common file-modifying patterns
            echo "$cmd" | grep -oE '(>|>>)\s*[^\s;|&]+' | sed 's/[>]\+\s*//' | head -1 || true
            ;;
    esac
}

# Count recent operations on a specific file
count_recent_file_ops() {
    local file="$1"
    if [ -f "$LOOP_FILE" ]; then
        tail -n "$RECENT_WINDOW" "$LOOP_FILE" | grep -c "$file" 2>/dev/null || echo "0"
    else
        echo "0"
    fi
}

# Detect repetitive patterns (same file, same operation type)
detect_loop_pattern() {
    local file="$1"
    local op="$2"
    
    if [ ! -f "$LOOP_FILE" ]; then
        return 1
    fi
    
    # Check for exact same operation repeated
    local recent_same=$(tail -n 5 "$LOOP_FILE" | grep -c "$op|$file" 2>/dev/null || echo "0")
    
    if [ "$recent_same" -ge 3 ]; then
        return 0  # Loop detected
    fi
    
    return 1
}

# Track the operation
FILE_PATH=$(extract_file_path)
TIMESTAMP=$(date -Iseconds)

if [ -n "$FILE_PATH" ]; then
    # Record to tracking file (for handoffs)
    echo "$TIMESTAMP $TOOL_NAME $FILE_PATH" >> "$TRACKING_FILE"
    
    # Record to loop detection file
    echo "$TIMESTAMP|$TOOL_NAME|$FILE_PATH" >> "$LOOP_FILE"
    
    # Count operations on this file
    FILE_OP_COUNT=$(count_recent_file_ops "$FILE_PATH")
    
    # Check for loop patterns
    LOOP_WARNING=""
    SHOULD_BLOCK=false
    
    if [ "$FILE_OP_COUNT" -ge "$SAME_FILE_BLOCK" ]; then
        LOOP_WARNING="
🚨 LOOP DETECTED - STOPPING
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
File: $FILE_PATH
Operations in last $RECENT_WINDOW actions: $FILE_OP_COUNT

You've operated on this file $FILE_OP_COUNT times recently.
This indicates you may be stuck in a loop.

REQUIRED ACTIONS:
1. STOP modifying this file
2. Analyze WHY the previous approach didn't work
3. Try a DIFFERENT approach or escalate to @orchestrator
4. If error persists, document it and move on

If the error is environmental (imports, paths, dependencies):
- Check for missing __init__.py files
- Check for naming collisions
- Check Python path configuration
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
"
        SHOULD_BLOCK=true
        
    elif [ "$FILE_OP_COUNT" -ge "$SAME_FILE_WARN" ]; then
        LOOP_WARNING="
⚠️ POTENTIAL LOOP WARNING
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
File: $FILE_PATH
Operations in last $RECENT_WINDOW actions: $FILE_OP_COUNT

You've touched this file $FILE_OP_COUNT times. If you're repeatedly:
- Reading then writing the same file
- Making similar edits that don't resolve the issue
- Re-running the same failing command

STOP and try a different approach. Consider:
1. Is the error actually in a DIFFERENT file?
2. Is this an environmental issue (paths, imports)?
3. Should you escalate to @orchestrator?
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
"
    fi
    
    # Also check for repetitive pattern (same exact operation)
    if detect_loop_pattern "$FILE_PATH" "$TOOL_NAME"; then
        if [ -z "$LOOP_WARNING" ]; then
            LOOP_WARNING="
⚠️ REPETITIVE PATTERN DETECTED
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Same operation ($TOOL_NAME) on same file ($FILE_PATH) repeated.
This suggests you're stuck. Try a different approach.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
"
        fi
    fi
    
    # Output warning if detected
    if [ -n "$LOOP_WARNING" ]; then
        if [ "$SHOULD_BLOCK" = true ]; then
            # Block the operation - exit 2 shows stderr to user
            echo "$LOOP_WARNING" >&2
            exit 2
        else
            # Warning only - continue but inject context
            jq -n --arg warning "$LOOP_WARNING" '{
                "continue": true,
                "hookSpecificOutput": {
                    "hookEventName": "PostToolUse",
                    "additionalContext": $warning
                }
            }'
            exit 0
        fi
    fi
fi

# Index test files
if echo "$FILE_PATH" | grep -qE 'tests/.*\.py$'; then
    :
fi

if echo "$FILE_PATH" | grep -qE 'thoughts/shared/handoffs/.*\.md$'; then
    :
fi

# Normal exit - continue without output
exit 0
