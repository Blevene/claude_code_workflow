#!/bin/bash
# StatusLine - Shows context usage, git status, and workflow focus
# Format: 45.2K 23% | main U:3 | Phase:IMPL | ✓ Tests pass → Add validation

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"
SESSION_ID="${CLAUDE_SESSION_ID:-unknown}"

# Get context info from Claude (if available via env)
TOKENS="${CLAUDE_CONTEXT_TOKENS:-0}"
PCT="${CLAUDE_CONTEXT_PCT:-0}"

# Write context % to temp file for hooks to read
echo "$PCT" > "/tmp/claude-context-pct-$SESSION_ID.txt" 2>/dev/null || true

# Format tokens
format_tokens() {
    local t=$1
    if [ "$t" -ge 1000000 ]; then
        printf "%.1fM" $(echo "$t / 1000000" | bc -l)
    elif [ "$t" -ge 1000 ]; then
        printf "%.1fK" $(echo "$t / 1000" | bc -l)
    else
        echo "$t"
    fi
}

# Color based on percentage
get_color() {
    local p=$1
    if [ "$p" -ge 80 ]; then
        echo "red"
    elif [ "$p" -ge 60 ]; then
        echo "yellow"
    else
        echo "green"
    fi
}

# Git info
GIT_BRANCH=""
GIT_STATUS=""
if [ -d "$PROJECT_DIR/.git" ]; then
    GIT_BRANCH=$(cd "$PROJECT_DIR" && git branch --show-current 2>/dev/null || echo "")
    STAGED=$(cd "$PROJECT_DIR" && git diff --cached --numstat 2>/dev/null | wc -l | tr -d ' ')
    UNSTAGED=$(cd "$PROJECT_DIR" && git diff --numstat 2>/dev/null | wc -l | tr -d ' ')
    UNTRACKED=$(cd "$PROJECT_DIR" && git ls-files --others --exclude-standard 2>/dev/null | wc -l | tr -d ' ')
    
    if [ "$STAGED" -gt 0 ] || [ "$UNSTAGED" -gt 0 ] || [ "$UNTRACKED" -gt 0 ]; then
        GIT_STATUS="S:$STAGED U:$UNSTAGED A:$UNTRACKED"
    fi
fi

# FAANG workflow phase (from ledger)
PHASE=""
LEDGER=$(ls -t "$PROJECT_DIR/thoughts/ledgers"/CONTINUITY_*.md 2>/dev/null | head -1)
if [ -f "$LEDGER" ]; then
    PHASE=$(grep -m1 "^## Current Phase" "$LEDGER" | sed 's/## Current Phase: //' || true)
    # Abbreviate phase
    case "$PHASE" in
        *REQUIREMENTS*|*REQ*) PHASE="REQ" ;;
        *DESIGN*) PHASE="DES" ;;
        *PLANNING*|*PLAN*) PHASE="PLN" ;;
        *IMPLEMENTATION*|*IMPL*) PHASE="IMP" ;;
        *REVIEW*) PHASE="REV" ;;
        *) PHASE="" ;;
    esac
fi

# Current focus (from ledger "Now:" section)
FOCUS=""
if [ -f "$LEDGER" ]; then
    FOCUS=$(awk '/^## Now/,/^## [^N]/' "$LEDGER" | grep -v "^##" | head -1 | sed 's/^- //' || true)
    # Truncate if too long
    if [ ${#FOCUS} -gt 30 ]; then
        FOCUS="${FOCUS:0:27}..."
    fi
fi

# Build status line
STATUS=""

# Context usage
if [ "$TOKENS" -gt 0 ]; then
    TOKEN_FMT=$(format_tokens "$TOKENS")
    STATUS+="$TOKEN_FMT $PCT%"
fi

# Git
if [ -n "$GIT_BRANCH" ]; then
    [ -n "$STATUS" ] && STATUS+=" | "
    STATUS+="$GIT_BRANCH"
    [ -n "$GIT_STATUS" ] && STATUS+=" $GIT_STATUS"
fi

# Phase
if [ -n "$PHASE" ]; then
    [ -n "$STATUS" ] && STATUS+=" | "
    STATUS+="Phase:$PHASE"
fi

# Focus
if [ -n "$FOCUS" ]; then
    [ -n "$STATUS" ] && STATUS+=" | "
    STATUS+="→ $FOCUS"
fi

# Critical warning
if [ "$PCT" -ge 80 ]; then
    STATUS+=" ⚠️"
fi

echo "$STATUS"
