#!/bin/bash
# PostToolUse Hook - Tracks file modifications, detects loops, tracks build/test results
# Triggered by: Edit, Write, Bash, MultiEdit, str_replace_editor
#
# Features (inspired by Continuous-Claude-v2):
# - File modification tracking
# - Loop detection to prevent repetitive edits
# - Build/test pass/fail tracking
# - JSONL attempts logging for commit reasoning
# - Project structure detection

# Don't use set -e - we want to handle errors gracefully
# Redirect all stderr to /dev/null by default to prevent error output
exec 2>/dev/null

# Ensure clean exit on any failure
trap 'exit 0' ERR

# Read input from stdin (limit to prevent memory issues)
INPUT=$(head -c 100000)

# Verify jq is available
if ! command -v jq &>/dev/null; then
    exit 0
fi

# Parse input safely
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // "unknown"' 2>/dev/null) || exit 0
TOOL_INPUT=$(echo "$INPUT" | jq -r '.tool_input // "{}"' 2>/dev/null) || exit 0
TOOL_RESPONSE=$(echo "$INPUT" | jq -r '.tool_response // "{}"' 2>/dev/null) || exit 0
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "unknown"' 2>/dev/null) || exit 0

# Detect if we're in an automated/subagent context
# Loop detection only applies to automated contexts (subagents, background tasks)
# Interactive sessions have human oversight and don't need automated loop prevention
IS_AUTOMATED="false"

# Signal 1: Explicit env var (set by our workflow when spawning agents)
if [ "${CLAUDE_IS_SUBAGENT:-}" = "true" ] || [ "${CLAUDE_IS_SUBAGENT:-}" = "1" ]; then
    IS_AUTOMATED="true"
fi

# Signal 2: Permission mode from hook input
# dontAsk/bypassPermissions = automated execution without user prompts
# Our subagent configs should use these modes
if [ "$IS_AUTOMATED" != "true" ]; then
    PERMISSION_MODE=$(echo "$INPUT" | jq -r '.permission_mode // "default"' 2>/dev/null) || PERMISSION_MODE="default"
    case "$PERMISSION_MODE" in
        bypassPermissions)
            IS_AUTOMATED="true"
            ;;
    esac
fi

# Bail if we couldn't parse
[ -z "$TOOL_NAME" ] && exit 0

# Paths
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"
CACHE_DIR="$PROJECT_DIR/.claude/cache"
TRACKING_FILE="$CACHE_DIR/session-$SESSION_ID-files.txt"
LOOP_FILE="$CACHE_DIR/session-$SESSION_ID-loops.txt"
BUILD_FILE="$CACHE_DIR/session-$SESSION_ID-builds.txt"
DEDUP_FILE="$CACHE_DIR/session-$SESSION_ID-dedup.txt"

# Git-local reasoning paths (for /commit command)
GIT_CLAUDE_DIR="$PROJECT_DIR/.git/claude"

mkdir -p "$CACHE_DIR" 2>/dev/null || true

# ============================================
# DUPLICATE DETECTION (prevents double-firing)
# ============================================
# Create a hash of the input to detect duplicate calls
INPUT_HASH=$(echo "$TOOL_NAME:$TOOL_INPUT" | md5sum 2>/dev/null | cut -c1-16) || INPUT_HASH=""
if [ -n "$INPUT_HASH" ]; then
    LAST_HASH=$(cat "$DEDUP_FILE" 2>/dev/null) || LAST_HASH=""
    if [ "$INPUT_HASH" = "$LAST_HASH" ]; then
        # Duplicate call detected - skip processing
        exit 0
    fi
    echo "$INPUT_HASH" > "$DEDUP_FILE" 2>/dev/null || true
fi

# Get current branch for attempts file
get_attempts_file() {
    if [ -d "$PROJECT_DIR/.git" ]; then
        local branch=$(git -C "$PROJECT_DIR" branch --show-current 2>/dev/null || echo "unknown")
        local safe_branch=$(echo "$branch" | tr '/' '-')
        local attempts_dir="$GIT_CLAUDE_DIR/branches/$safe_branch"
        mkdir -p "$attempts_dir" 2>/dev/null || true
        echo "$attempts_dir/attempts.jsonl"
    else
        echo ""
    fi
}

# Loop detection thresholds (tuned to reduce false positives)
SAME_FILE_WARN=5      # Warn after 5 writes to same file (was 3)
SAME_FILE_BLOCK=8     # Block after 8 writes (was 5)
RECENT_WINDOW=15      # Shorter window = less accumulation (was 20)

# ============================================
# CONTENT DEDUPLICATION (prevents wasteful duplicate writes)
# ============================================
# Tracks file content hashes to detect when same content is written multiple times
CONTENT_HASH_FILE="$CACHE_DIR/session-$SESSION_ID-content-hashes.txt"
DUPLICATE_WINDOW_SECS=30  # If same content written within 30s, warn

check_duplicate_write() {
    local file_path="$1"
    local content="$2"
    
    # Skip if no file path or content
    [ -z "$file_path" ] && return 1
    [ -z "$content" ] && return 1
    
    # Generate content hash
    local content_hash=$(echo "$content" | md5sum 2>/dev/null | cut -c1-32) || return 1
    local key="$file_path:$content_hash"
    local now=$(date +%s)
    
    # Check if we've seen this exact content for this file recently
    if [ -f "$CONTENT_HASH_FILE" ]; then
        local last_entry=$(grep "^$file_path:" "$CONTENT_HASH_FILE" 2>/dev/null | tail -1)
        if [ -n "$last_entry" ]; then
            local last_hash=$(echo "$last_entry" | cut -d: -f2)
            local last_time=$(echo "$last_entry" | cut -d: -f3)
            
            if [ "$last_hash" = "$content_hash" ]; then
                local elapsed=$((now - last_time))
                if [ "$elapsed" -lt "$DUPLICATE_WINDOW_SECS" ]; then
                    # Duplicate write detected!
                    return 0
                fi
            fi
        fi
    fi
    
    # Record this write
    echo "$file_path:$content_hash:$now" >> "$CONTENT_HASH_FILE"
    
    # Prune old entries (keep last 100)
    if [ -f "$CONTENT_HASH_FILE" ]; then
        tail -100 "$CONTENT_HASH_FILE" > "$CONTENT_HASH_FILE.tmp" 2>/dev/null && \
        mv "$CONTENT_HASH_FILE.tmp" "$CONTENT_HASH_FILE" 2>/dev/null || true
    fi
    
    return 1
}

# Files excluded from loop detection (legitimate high-churn workflow files)
is_excluded_from_loop_detection() {
    local file="$1"
    case "$file" in
        # Traceability matrix - updated after every spec/impl
        *traceability_matrix.json) return 0 ;;
        # Plan files - frequently updated during planning
        *thoughts/shared/plans/*) return 0 ;;
        # Ledger files - updated throughout session
        *thoughts/ledgers/*) return 0 ;;
        # Handoff files - updated during handoffs
        *thoughts/shared/handoffs/*) return 0 ;;
        # Cache files
        *.claude/cache/*) return 0 ;;
        *) return 1 ;;
    esac
}

# ============================================
# FILE PATH EXTRACTION
# ============================================
extract_file_path() {
    case "$TOOL_NAME" in
        Edit|Write|str_replace_editor|MultiEdit)
            echo "$TOOL_INPUT" | jq -r '.file_path // .path // empty' 2>/dev/null
            ;;
        Bash|bash)
            local cmd=$(echo "$TOOL_INPUT" | jq -r '.command // empty' 2>/dev/null)
            # Extract redirect target, but filter out /dev/null and other non-files
            local target=$(echo "$cmd" | grep -oE '(>|>>)\s*[^\s;|&]+' | sed 's/[>]\+\s*//' | head -1 2>/dev/null || true)
            # Skip /dev/null, /dev/stderr, /dev/stdout - these aren't real file writes
            case "$target" in
                /dev/null|/dev/stderr|/dev/stdout|"") ;;
                *) echo "$target" ;;
            esac
            ;;
        *)
            # Read operations and unknown tools - don't track for loop detection
            # Reading files repeatedly is normal behavior
            ;;
    esac
}

# Check if this is a write operation (for loop detection)
is_write_operation() {
    case "$TOOL_NAME" in
        Edit|Write|str_replace_editor|MultiEdit)
            return 0
            ;;
        Bash|bash)
            # Check if bash command writes to a real file (not /dev/null)
            local cmd=$(echo "$TOOL_INPUT" | jq -r '.command // empty' 2>/dev/null)
            if echo "$cmd" | grep -qE '(>|>>)'; then
                # But skip if redirecting to /dev/null
                if echo "$cmd" | grep -qE '(>|>>)\s*/dev/(null|stderr|stdout)'; then
                    return 1
                fi
                return 0
            fi
            return 1
            ;;
        *)
            return 1
            ;;
    esac
}

# ============================================
# BUILD/TEST TRACKING (from Continuous-Claude-v2)
# ============================================
track_build_result() {
    local cmd="$1"
    local exit_code="$2"
    local output="$3"
    local timestamp=$(date -Iseconds)
    
    # Detect build/test commands
    local is_build=false
    local is_test=false
    local build_type=""
    
    case "$cmd" in
        *"npm run build"*|*"npm build"*|*"yarn build"*|*"pnpm build"*)
            is_build=true
            build_type="npm-build"
            ;;
        *"npm run test"*|*"npm test"*|*"yarn test"*|*"jest"*|*"vitest"*)
            is_test=true
            build_type="npm-test"
            ;;
        *"pytest"*|*"python -m pytest"*|*"uv run pytest"*)
            is_test=true
            build_type="pytest"
            ;;
        *"uv run python tools/run_evals"*|*"run_evals.py"*)
            is_test=true
            build_type="sdd-evals"
            ;;
        *"cargo build"*|*"cargo check"*)
            is_build=true
            build_type="cargo-build"
            ;;
        *"cargo test"*)
            is_test=true
            build_type="cargo-test"
            ;;
        *"go build"*)
            is_build=true
            build_type="go-build"
            ;;
        *"go test"*)
            is_test=true
            build_type="go-test"
            ;;
        *"tsc"*|*"npx tsc"*)
            is_build=true
            build_type="typescript"
            ;;
        *"make"*|*"cmake"*)
            is_build=true
            build_type="make"
            ;;
    esac
    
    if [ "$is_build" = true ] || [ "$is_test" = true ]; then
        local result="fail"
        if [ "$exit_code" = "0" ]; then
            result="pass"
        fi
        
        local entry_type="build"
        if [ "$is_test" = true ]; then
            entry_type="test"
        fi
        
        # Session-scoped tracking (for stop hook summary)
        echo "$timestamp|$entry_type|$build_type|$result" >> "$BUILD_FILE"
        
        # Branch-scoped JSONL tracking (for /commit reasoning)
        local attempts_file=$(get_attempts_file)
        if [ -n "$attempts_file" ]; then
            # Extract first line of error for JSONL (escape for JSON)
            local error_line=""
            if [ "$result" = "fail" ] && [ -n "$output" ]; then
                # Get last meaningful error line (skip empty lines)
                error_line=$(echo "$output" | grep -E "(Error|error|Exception|FAILED|failed|AssertionError)" | tail -1 | cut -c1-200 | tr '"' "'" | tr '\n' ' ')
            fi
            
            # Build JSONL entry
            if [ "$result" = "fail" ]; then
                jq -n -c \
                    --arg type "${entry_type}_fail" \
                    --arg timestamp "$timestamp" \
                    --arg command "$cmd" \
                    --arg build_type "$build_type" \
                    --arg error "$error_line" \
                    '{type: $type, timestamp: $timestamp, command: $command, build_type: $build_type, error: $error}' \
                    >> "$attempts_file" 2>/dev/null || true
            else
                jq -n -c \
                    --arg type "${entry_type}_pass" \
                    --arg timestamp "$timestamp" \
                    --arg command "$cmd" \
                    --arg build_type "$build_type" \
                    '{type: $type, timestamp: $timestamp, command: $command, build_type: $build_type}' \
                    >> "$attempts_file" 2>/dev/null || true
            fi
        fi
    fi
}

# ============================================
# LOOP DETECTION
# ============================================
count_recent_file_ops() {
    local file="$1"
    if [ -f "$LOOP_FILE" ]; then
        tail -n "$RECENT_WINDOW" "$LOOP_FILE" 2>/dev/null | grep -cF "$file" 2>/dev/null || echo "0"
    else
        echo "0"
    fi
}

detect_loop_pattern() {
    local file="$1"
    local op="$2"
    
    if [ ! -f "$LOOP_FILE" ]; then
        return 1
    fi
    
    local recent_same=$(tail -n 5 "$LOOP_FILE" 2>/dev/null | grep -cF "$op|$file" 2>/dev/null || echo "0")
    
    if [ "$recent_same" -ge 3 ]; then
        return 0
    fi
    
    return 1
}

# ============================================
# MAIN LOGIC
# ============================================

# Handle Bash commands specially for build tracking
if [ "$TOOL_NAME" = "Bash" ] || [ "$TOOL_NAME" = "bash" ]; then
    CMD=$(echo "$TOOL_INPUT" | jq -r '.command // empty' 2>/dev/null) || CMD=""
    EXIT_CODE=$(echo "$TOOL_RESPONSE" | jq -r '.exit_code // .exitCode // "unknown"' 2>/dev/null) || EXIT_CODE="unknown"
    # Extract stdout/stderr for error capture (limit to prevent issues)
    CMD_OUTPUT=$(echo "$TOOL_RESPONSE" | jq -r '.stdout // .stderr // .output // ""' 2>/dev/null | tail -20) || CMD_OUTPUT=""
    
    if [ -n "$CMD" ]; then
        track_build_result "$CMD" "$EXIT_CODE" "$CMD_OUTPUT" || true
    fi
fi

# Track file operations (only for write operations)
FILE_PATH=$(extract_file_path)
TIMESTAMP=$(date -Iseconds)

# For Read operations, just track for handoffs but skip loop detection
if [ "$TOOL_NAME" = "Read" ] || [ "$TOOL_NAME" = "read_file" ] || [ "$TOOL_NAME" = "view" ]; then
    READ_PATH=$(echo "$TOOL_INPUT" | jq -r '.file_path // .path // .target_file // empty' 2>/dev/null)
    if [ -n "$READ_PATH" ]; then
        echo "$TIMESTAMP $TOOL_NAME $READ_PATH" >> "$TRACKING_FILE" 2>/dev/null || true
    fi
    # Don't apply loop detection to reads - reading files repeatedly is normal
    exit 0
fi

if [ -n "$FILE_PATH" ] && is_write_operation; then
    # Record to tracking file (for handoffs)
    echo "$TIMESTAMP $TOOL_NAME $FILE_PATH" >> "$TRACKING_FILE" 2>/dev/null || true
    
    # Record to loop detection file (only write operations)
    echo "$TIMESTAMP|$TOOL_NAME|$FILE_PATH" >> "$LOOP_FILE" 2>/dev/null || true
    
    # ============================================
    # PERIODIC LEDGER UPDATE (every 10 writes)
    # ============================================
    LEDGER_UPDATE_INTERVAL=10
    TOTAL_WRITES=$(wc -l < "$TRACKING_FILE" 2>/dev/null | tr -d ' ' || echo "0")
    if [ "$((TOTAL_WRITES % LEDGER_UPDATE_INTERVAL))" -eq 0 ] && [ "$TOTAL_WRITES" -gt 0 ]; then
        PLUGIN_DIR="${CLAUDE_PLUGIN_ROOT:-$(dirname "$0")/..}"
        LEDGER_SCRIPT="$PLUGIN_DIR/hooks/update-ledger.sh"
        if [ -x "$LEDGER_SCRIPT" ]; then
            "$LEDGER_SCRIPT" "periodic" "$SESSION_ID" "" "" "Auto-update after $TOTAL_WRITES file ops" 2>/dev/null || true
        fi
    fi
    
    # Skip loop detection for workflow files that are legitimately high-churn
    if is_excluded_from_loop_detection "$FILE_PATH"; then
        exit 0
    fi
    
    # Loop detection only runs for automated/subagent contexts
    # Interactive sessions have human oversight
    if [ "$IS_AUTOMATED" != "true" ]; then
        exit 0
    fi
    
    # ============================================
    # DUPLICATE CONTENT DETECTION
    # ============================================
    # Check if same content is being written to same file (indicates agent doesn't know write succeeded)
    WRITE_CONTENT=""
    case "$TOOL_NAME" in
        Write|str_replace_editor)
            WRITE_CONTENT=$(echo "$TOOL_INPUT" | jq -r '.content // .new_string // empty' 2>/dev/null | head -c 50000)
            ;;
        Edit)
            WRITE_CONTENT=$(echo "$TOOL_INPUT" | jq -r '.new_string // empty' 2>/dev/null | head -c 50000)
            ;;
    esac
    
    if [ -n "$WRITE_CONTENT" ] && check_duplicate_write "$FILE_PATH" "$WRITE_CONTENT"; then
        DUPE_WARNING="
⚠️ DUPLICATE WRITE DETECTED
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
File: $FILE_PATH

You just wrote IDENTICAL content to this file within the last 30 seconds.
This suggests your previous write may have succeeded but you didn't notice.

CHECK: Did the file already contain this content? If so, no need to rewrite.
VERIFY: Run 'cat $FILE_PATH | head -20' to confirm the content is there.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
"
        printf '{"continue":true,"systemMessage":"%s"}\n' "$(echo "$DUPE_WARNING" | tr '\n' ' ' | sed 's/\\/\\\\/g; s/"/\\"/g')"
        exit 0
    fi
    
    # Count WRITE operations on this file (automated context only)
    FILE_OP_COUNT=$(count_recent_file_ops "$FILE_PATH")
    
    # Check for loop patterns
    LOOP_WARNING=""
    SHOULD_BLOCK=false
    
    if [ "$FILE_OP_COUNT" -ge "$SAME_FILE_BLOCK" ]; then
        LOOP_WARNING="
🚨 LOOP DETECTED - STOPPING
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
File: $FILE_PATH
Write operations in last $RECENT_WINDOW actions: $FILE_OP_COUNT

You've modified this file $FILE_OP_COUNT times recently.
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
Write operations in last $RECENT_WINDOW actions: $FILE_OP_COUNT

You've modified this file $FILE_OP_COUNT times. If you're repeatedly:
- Making similar edits that don't resolve the issue
- Re-running the same failing command

STOP and try a different approach. Consider:
1. Is the error actually in a DIFFERENT file?
2. Is this an environmental issue (paths, imports)?
3. Should you escalate to @orchestrator?
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
"
    fi
    
    # Also check for repetitive pattern
    if detect_loop_pattern "$FILE_PATH" "$TOOL_NAME"; then
        if [ -z "$LOOP_WARNING" ]; then
            LOOP_WARNING="
⚠️ REPETITIVE PATTERN DETECTED
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Same write operation ($TOOL_NAME) on same file ($FILE_PATH) repeated.
This suggests you're stuck. Try a different approach.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
"
        fi
    fi
    
    # Output warning if detected
    if [ -n "$LOOP_WARNING" ]; then
        if [ "$SHOULD_BLOCK" = true ]; then
            # Re-enable stderr just for this message
            exec 2>&1
            echo "$LOOP_WARNING"
            exit 2
        else
            # Non-blocking warning - output JSON to stdout
            # Use printf for safer output, escape backslashes first then quotes for valid JSON
            printf '{"continue":true,"systemMessage":"%s"}\n' "$(echo "$LOOP_WARNING" | tr '\n' ' ' | sed 's/\\/\\\\/g; s/"/\\"/g')"
            exit 0
        fi
    fi
fi

# Normal exit - continue without output (MUST exit 0)
exit 0
