#!/bin/bash
# UserPromptSubmit Hook - Context warnings, skill activation, SDD workflow hints
# Triggered by: every user message
#
# Features (inspired by Continuous-Claude-v2):
# - Skill activation based on skill-rules.json patterns
# - Context percentage warnings
# - SDD workflow reminders

# Don't use set -e - we want to handle errors gracefully
# Redirect stderr to prevent error output
exec 2>/dev/null

# Ensure clean exit on any failure
trap 'exit 0' ERR

# Verify jq is available
if ! command -v jq &>/dev/null; then
    exit 0
fi

# Read input from stdin
INPUT=$(head -c 100000 2>/dev/null)
USER_MESSAGE=$(echo "$INPUT" | jq -r '.prompt // .message // ""' 2>/dev/null) || USER_MESSAGE=""

# Get session ID - use same fallback as status.sh to ensure file paths match
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // ""' 2>/dev/null)
[[ -z "$SESSION_ID" || "$SESSION_ID" == "null" ]] && SESSION_ID="$PPID"

# Paths
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"
PLUGIN_DIR="${CLAUDE_PLUGIN_ROOT:-$HOME/.claude}"
CONTEXT_FILE="/tmp/claude-context-pct-$SESSION_ID.txt"

# Try to find skill-rules.json
SKILL_RULES=""
if [ -f "$PROJECT_DIR/.claude/skills/skill-rules.json" ]; then
    SKILL_RULES="$PROJECT_DIR/.claude/skills/skill-rules.json"
elif [ -f "$PLUGIN_DIR/skills/skill-rules.json" ]; then
    SKILL_RULES="$PLUGIN_DIR/skills/skill-rules.json"
elif [ -f "$HOME/.claude/skills/skill-rules.json" ]; then
    SKILL_RULES="$HOME/.claude/skills/skill-rules.json"
fi

# Read context percentage if available
CONTEXT_PCT=0
if [ -f "$CONTEXT_FILE" ]; then
    CONTEXT_PCT=$(cat "$CONTEXT_FILE" 2>/dev/null | tr -d '[:space:]' || echo "0")
    # Ensure it's a number
    if ! [[ "$CONTEXT_PCT" =~ ^[0-9]+$ ]]; then
        CONTEXT_PCT=0
    fi
fi

# Build response
HINTS=""

# ============================================
# CONTEXT WARNINGS
# ============================================
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

# ============================================
# SKILL ACTIVATION (from skill-rules.json)
# ============================================
if [ -n "$SKILL_RULES" ] && [ -f "$SKILL_RULES" ]; then
    MESSAGE_LOWER=$(echo "$USER_MESSAGE" | tr '[:upper:]' '[:lower:]')
    
    MATCHED_SKILLS=""
    MATCHED_AGENTS=""
    
    # Check skills
    SKILL_NAMES=$(jq -r '.skills | keys[]' "$SKILL_RULES" 2>/dev/null)
    for skill in $SKILL_NAMES; do
        # Get keywords for this skill
        KEYWORDS=$(jq -r ".skills[\"$skill\"].promptTriggers.keywords // [] | .[]" "$SKILL_RULES" 2>/dev/null)
        PRIORITY=$(jq -r ".skills[\"$skill\"].priority // \"medium\"" "$SKILL_RULES" 2>/dev/null)
        
        for keyword in $KEYWORDS; do
            keyword_lower=$(echo "$keyword" | tr '[:upper:]' '[:lower:]')
            if echo "$MESSAGE_LOWER" | grep -q "$keyword_lower"; then
                case "$PRIORITY" in
                    critical) MATCHED_SKILLS+="⚠️ CRITICAL: $skill\n" ;;
                    high)     MATCHED_SKILLS+="📚 RECOMMENDED: $skill\n" ;;
                    medium)   MATCHED_SKILLS+="💡 SUGGESTED: $skill\n" ;;
                    low)      MATCHED_SKILLS+="📌 OPTIONAL: $skill\n" ;;
                esac
                break
            fi
        done
    done
    
    # Check agents
    AGENT_NAMES=$(jq -r '.agents | keys[]' "$SKILL_RULES" 2>/dev/null)
    for agent in $AGENT_NAMES; do
        KEYWORDS=$(jq -r ".agents[\"$agent\"].promptTriggers.keywords // [] | .[]" "$SKILL_RULES" 2>/dev/null)
        
        for keyword in $KEYWORDS; do
            keyword_lower=$(echo "$keyword" | tr '[:upper:]' '[:lower:]')
            if echo "$MESSAGE_LOWER" | grep -q "$keyword_lower"; then
                MATCHED_AGENTS+="🤖 @$agent\n"
                break
            fi
        done
    done
    
    # Output skill suggestions if found
    if [ -n "$MATCHED_SKILLS" ] || [ -n "$MATCHED_AGENTS" ]; then
        HINTS+="
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🎯 SKILL ACTIVATION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
"
        if [ -n "$MATCHED_SKILLS" ]; then
            HINTS+="$(echo -e "$MATCHED_SKILLS")"
        fi
        if [ -n "$MATCHED_AGENTS" ]; then
            HINTS+="
Recommended agents (token-efficient):
$(echo -e "$MATCHED_AGENTS")"
        fi
        HINTS+="
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
"
    fi
fi

# ============================================
# SDD WORKFLOW HINTS (fallback if no skill-rules)
# ============================================
if [ -z "$SKILL_RULES" ]; then
    MESSAGE_LOWER=$(echo "$USER_MESSAGE" | tr '[:upper:]' '[:lower:]')
    
    if echo "$MESSAGE_LOWER" | grep -qE '(implement|add feature|fix bug|code)'; then
        HINTS+="
💡 SDD workflow: write specs FIRST, then implement, then run evals
"
    fi
    
    if echo "$MESSAGE_LOWER" | grep -qE '(spec|specification|behavior)'; then
        HINTS+="
💡 Use /spec to create behavioral specification before implementation
"
    fi
    
    if echo "$MESSAGE_LOWER" | grep -qE '(eval|validate|check)'; then
        HINTS+="
💡 Run evals with: uv run python tools/run_evals.py --all
"
    fi
    
    if echo "$MESSAGE_LOWER" | grep -qE '(design|architect|api contract)'; then
        HINTS+="
💡 Use /design to create architecture document before implementation
"
    fi
fi

# Session management hints (always check these)
MESSAGE_LOWER=$(echo "$USER_MESSAGE" | tr '[:upper:]' '[:lower:]')

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

# ============================================
# OUTPUT
# ============================================
if [ -n "$HINTS" ]; then
    jq -n --arg hints "$HINTS" '{
        "continue": true,
        "systemMessage": $hints
    }'
else
    exit 0
fi
