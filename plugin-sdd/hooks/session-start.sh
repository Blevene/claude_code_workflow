#!/bin/bash
# SessionStart Hook - Loads continuity state after /clear or session start
# Triggered by: startup, resume, clear, compact
#
# OPTIMIZED for minimal context usage (~5% instead of ~20%)
# - Extracts only essential sections (Goal, Phase, Now)
# - Truncates handoffs to 1500 chars max
# - Removes redundant boilerplate
set -e

# Read input from stdin
INPUT=$(cat)
SOURCE=$(echo "$INPUT" | jq -r '.source // "startup"')
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "unknown"')

# Paths
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"
LEDGER_DIR="$PROJECT_DIR/thoughts/ledgers"
HANDOFF_DIR="$PROJECT_DIR/thoughts/shared/handoffs"
PLANS_DIR="$PROJECT_DIR/thoughts/shared/plans"

# Max chars for truncation
MAX_HANDOFF_CHARS=1500

# ============================================
# LEDGER PRUNING (prevents bloat)
# ============================================
prune_ledger() {
    local ledger="$1"
    if [ ! -f "$ledger" ]; then
        return
    fi
    
    local original_size=$(wc -c < "$ledger")
    local temp_file=$(mktemp)
    
    # Remove "Session Ended" entries
    sed '/^### Session Ended/,/^- Reason:/d' "$ledger" > "$temp_file"
    
    local new_size=$(wc -c < "$temp_file")
    if [ "$new_size" -lt "$original_size" ]; then
        mv "$temp_file" "$ledger"
    else
        rm -f "$temp_file"
    fi
}

# Find most recent ledger
find_latest_ledger() {
    if [ -d "$LEDGER_DIR" ]; then
        ls -t "$LEDGER_DIR"/CONTINUITY_*.md 2>/dev/null | head -1
    fi
}

# Find most recent handoff (exclude macOS resource forks)
find_latest_handoff() {
    if [ -d "$HANDOFF_DIR" ]; then
        find "$HANDOFF_DIR" -name "*.md" -type f ! -name "._*" 2>/dev/null | \
            xargs ls -t 2>/dev/null | head -1
    fi
}

# Find active plan
find_active_plan() {
    if [ -d "$PLANS_DIR" ]; then
        ls -t "$PLANS_DIR"/*.json 2>/dev/null | head -1 || \
        ls -t "$PLANS_DIR"/*.md 2>/dev/null | head -1
    fi
}

# ============================================
# OPTIMIZED EXTRACTION FUNCTIONS
# ============================================

# Extract minimal ledger summary: Goal + Phase + Now only (~10 lines)
extract_ledger_summary() {
    local ledger="$1"
    if [ ! -f "$ledger" ]; then
        return
    fi
    
    local goal=""
    local phase=""
    local now=""
    
    # Get goal (first content line after ## Goal)
    goal=$(awk '/^## Goal/{getline; if(!/^##/ && !/^$/) print; exit}' "$ledger")
    
    # Get phase
    phase=$(awk '/^## Current Phase/{getline; if(!/^##/) print; exit}' "$ledger")
    
    # Get Now section (up to 3 lines)
    now=$(awk '/^## Now/,/^## [^N]/' "$ledger" | grep -v "^## " | head -3)
    
    echo "Goal: ${goal:-<not set>}"
    echo "Phase: ${phase:-UNKNOWN}"
    if [ -n "$now" ]; then
        echo "Now:"
        echo "$now"
    fi
}

# Extract one-line summary from ledger
extract_ledger_oneliner() {
    local ledger="$1"
    if [ -f "$ledger" ]; then
        local goal=$(grep -A1 "^## Goal" "$ledger" 2>/dev/null | tail -1 | head -c 50)
        local phase=$(grep -A1 "^## Current Phase" "$ledger" 2>/dev/null | tail -1 | head -c 20)
        echo "${goal:-No goal}... | ${phase:-?}"
    fi
}

# Extract truncated handoff with Next Steps priority (~1500 chars max)
extract_handoff_truncated() {
    local handoff="$1"
    if [ ! -f "$handoff" ]; then
        return
    fi
    
    local content=""
    local filename=$(basename "$handoff")
    
    # Extract Current State if present (for auto-handoffs)
    local current_state=$(awk '/^## Current State/,/^## [^C]/' "$handoff" | head -6)
    
    # Extract Next Steps (priority)
    local next_steps=$(awk '/^## Next Steps/,/^## [^N]/' "$handoff" | head -10)
    if [ -z "$next_steps" ]; then
        next_steps=$(awk '/^## Immediate Next/,/^## /' "$handoff" | head -10)
    fi
    if [ -z "$next_steps" ]; then
        next_steps=$(awk '/^## TODO/,/^## /' "$handoff" | head -10)
    fi
    
    # Extract What Was Done (summary)
    local what_done=$(awk '/^## What Was Done/,/^## /' "$handoff" | head -5)
    
    # Build truncated content
    if [ -n "$current_state" ]; then
        content+="$current_state"$'\n'
    fi
    if [ -n "$next_steps" ]; then
        content+="$next_steps"$'\n'
    fi
    if [ -n "$what_done" ]; then
        content+="$what_done"$'\n'
    fi
    
    # If nothing extracted, get first part of file
    if [ -z "$content" ]; then
        content=$(head -20 "$handoff")
    fi
    
    # Truncate to max chars
    echo "$content" | head -c "$MAX_HANDOFF_CHARS"
    
    local content_len=${#content}
    if [ "$content_len" -gt "$MAX_HANDOFF_CHARS" ]; then
        echo ""
        echo "[... truncated, run 'cat $handoff' for full content]"
    fi
}

# Extract plan summary: title + current task only (~5 lines)
extract_plan_summary() {
    local plan="$1"
    if [ ! -f "$plan" ]; then
        return
    fi
    
    local filename=$(basename "$plan")
    
    if [[ "$filename" == *.json ]]; then
        # JSON plan - extract title and first in-progress task
        local title=$(jq -r '.title // .name // "Untitled"' "$plan" 2>/dev/null)
        local current_task=$(jq -r '.tasks[]? | select(.status == "in_progress" or .status == "pending") | .description' "$plan" 2>/dev/null | head -1)
        echo "Plan: $title"
        if [ -n "$current_task" ]; then
            echo "Current: $current_task"
        fi
    else
        # Markdown plan - extract first heading and first unchecked item
        local title=$(grep -m1 "^# " "$plan" 2>/dev/null | sed 's/^# //')
        local current_task=$(grep -m1 "^\- \[ \]" "$plan" 2>/dev/null | sed 's/^- \[ \] //')
        echo "Plan: ${title:-$filename}"
        if [ -n "$current_task" ]; then
            echo "Current: $current_task"
        fi
    fi
}

# ============================================
# MAIN LOGIC
# ============================================

CONTEXT=""
LEDGER=$(find_latest_ledger)

# Prune ledger on every session start
if [ -n "$LEDGER" ] && [ -f "$LEDGER" ]; then
    prune_ledger "$LEDGER"
fi

case "$SOURCE" in
    startup)
        # STARTUP: Minimal notification only
        if [ -n "$LEDGER" ] && [ -f "$LEDGER" ]; then
            LEDGER_NAME=$(basename "$LEDGER" .md | sed 's/CONTINUITY_CLAUDE-//')
            ONELINER=$(extract_ledger_oneliner "$LEDGER")
            
            HANDOFF=$(find_latest_handoff)
            HANDOFF_INFO=""
            if [ -n "$HANDOFF" ] && [ -f "$HANDOFF" ]; then
                HANDOFF_INFO=" | Handoff: $(basename "$HANDOFF")"
            fi
            
            CONTEXT="📋 $LEDGER_NAME: $ONELINER$HANDOFF_INFO
💡 Use /resume for full context"
        fi
        ;;
        
    resume|clear|compact)
        # RESUME/CLEAR/COMPACT: Optimized context loading
        CONTEXT="🔄 Resumed ($SOURCE). Continue from where you left off."
        
        # Load ledger SUMMARY (not full content)
        if [ -n "$LEDGER" ] && [ -f "$LEDGER" ]; then
            LEDGER_SUMMARY=$(extract_ledger_summary "$LEDGER")
            CONTEXT+="

📋 LEDGER
$LEDGER_SUMMARY"
        fi
        
        # Load TRUNCATED handoff with Next Steps
        HANDOFF=$(find_latest_handoff)
        if [ -n "$HANDOFF" ] && [ -f "$HANDOFF" ]; then
            HANDOFF_TRUNCATED=$(extract_handoff_truncated "$HANDOFF")
            CONTEXT+="

🤝 HANDOFF ($(basename "$HANDOFF"))
$HANDOFF_TRUNCATED"
        fi
        
        # Load plan SUMMARY only
        PLAN=$(find_active_plan)
        if [ -n "$PLAN" ] && [ -f "$PLAN" ]; then
            PLAN_SUMMARY=$(extract_plan_summary "$PLAN")
            CONTEXT+="

📝 $PLAN_SUMMARY"
        fi
        
        # Add continuation prompt (minimal)
        CONTEXT+="

▶️ Pick up the next task and continue."
        ;;
esac

# If nothing found, minimal guidance
if [ -z "$CONTEXT" ]; then
    CONTEXT="🆕 Fresh session. Use /prd, /design, or /spec to start."
fi

# Output JSON response
jq -n --arg ctx "$CONTEXT" '{
    "continue": true,
    "hookSpecificOutput": {
        "hookEventName": "SessionStart",
        "additionalContext": $ctx
    }
}'
