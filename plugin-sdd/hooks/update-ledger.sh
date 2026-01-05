#!/bin/bash
# Shared ledger update helper - called by other hooks to maintain continuity ledger
# Usage: ./update-ledger.sh <trigger> <session_id> [agent_name] [phase] [notes]

# Don't use set -e - handle errors gracefully
# Redirect stderr to prevent error output
exec 2>/dev/null

# Ensure clean exit on any failure
trap 'exit 0' ERR

TRIGGER="${1:-auto}"
SESSION_ID="${2:-unknown}"
AGENT_NAME="${3:-}"
PHASE="${4:-}"
NOTES="${5:-}"

# Paths
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"
LEDGER_DIR="$PROJECT_DIR/thoughts/ledgers"
SPECS_DIR="$PROJECT_DIR/specs"
EVALS_DIR="$PROJECT_DIR/evals"
DESIGN_DIR="$PROJECT_DIR/docs/design"
HANDOFF_DIR="$PROJECT_DIR/thoughts/shared/handoffs"

mkdir -p "$LEDGER_DIR"

# Derive project name from directory
PROJECT_NAME=$(basename "$PROJECT_DIR" | tr '[:lower:]' '[:upper:]' | tr '-' '_')
LEDGER_FILE="$LEDGER_DIR/CONTINUITY_CLAUDE-${PROJECT_NAME}.md"
TIMESTAMP=$(date -Iseconds)

# Count artifacts
count_specs() {
    find "$SPECS_DIR" -name "SPEC-*.md" -type f ! -name "._*" 2>/dev/null | wc -l | tr -d ' '
}

count_evals() {
    find "$EVALS_DIR" -name "eval_*.py" -type f 2>/dev/null | wc -l | tr -d ' '
}

count_designs() {
    find "$DESIGN_DIR" -name "*.md" -type f ! -name "._*" 2>/dev/null | wc -l | tr -d ' '
}

count_handoffs() {
    find "$HANDOFF_DIR" -name "*.md" -type f ! -name "._*" 2>/dev/null | wc -l | tr -d ' '
}

# Get recent git changes
get_git_status() {
    if [ -d "$PROJECT_DIR/.git" ]; then
        cd "$PROJECT_DIR" && git status --short 2>/dev/null | head -10 || echo "No git changes"
    else
        echo "Not a git repository"
    fi
}

# Detect current phase from artifacts
detect_phase() {
    local specs=$(count_specs)
    local evals=$(count_evals)
    local designs=$(count_designs)
    
    # Use provided phase if available
    if [ -n "$PHASE" ]; then
        echo "$PHASE"
        return
    fi
    
    # Infer from artifacts
    if [ "$evals" -gt 0 ] && [ "$specs" -gt 0 ]; then
        echo "EVAL_VALIDATION"
    elif [ "$specs" -gt 0 ]; then
        echo "IMPLEMENTATION"
    elif [ "$designs" -gt 0 ]; then
        echo "SPEC_WRITING"
    else
        echo "REQUIREMENTS"
    fi
}

# Read existing ledger sections (preserve user content)
read_existing_section() {
    local section="$1"
    local file="$2"
    if [ -f "$file" ]; then
        awk -v section="$section" '
            $0 ~ "^## " section {found=1; next}
            /^## / && found {found=0}
            found {print}
        ' "$file" | head -20
    fi
}

# Build or update the ledger
CURRENT_PHASE=$(detect_phase)
SPECS_COUNT=$(count_specs)
EVALS_COUNT=$(count_evals)
DESIGNS_COUNT=$(count_designs)
HANDOFFS_COUNT=$(count_handoffs)
GIT_STATUS=$(get_git_status)

# Preserve existing goal/constraints if ledger exists
EXISTING_GOAL=""
EXISTING_CONSTRAINTS=""
EXISTING_COMPLETED=""
EXISTING_DECISIONS=""
if [ -f "$LEDGER_FILE" ]; then
    EXISTING_GOAL=$(read_existing_section "Goal" "$LEDGER_FILE")
    EXISTING_CONSTRAINTS=$(read_existing_section "Constraints" "$LEDGER_FILE")
    EXISTING_COMPLETED=$(read_existing_section "Completed" "$LEDGER_FILE")
    EXISTING_DECISIONS=$(read_existing_section "Key Decisions" "$LEDGER_FILE")
fi

# Set defaults for empty sections
[ -z "$EXISTING_GOAL" ] && EXISTING_GOAL="<Set via /prd or /design command>"
[ -z "$EXISTING_CONSTRAINTS" ] && EXISTING_CONSTRAINTS="- <Define project constraints>"

# Build activity log entry
ACTIVITY_ENTRY=""
if [ -n "$AGENT_NAME" ]; then
    ACTIVITY_ENTRY="- [$TIMESTAMP] @$AGENT_NAME completed task ($TRIGGER)"
elif [ "$TRIGGER" = "pre-compact" ]; then
    ACTIVITY_ENTRY="- [$TIMESTAMP] Auto-save before context compaction"
elif [ "$TRIGGER" = "handoff" ]; then
    ACTIVITY_ENTRY="- [$TIMESTAMP] Session handoff created"
else
    ACTIVITY_ENTRY="- [$TIMESTAMP] Ledger updated ($TRIGGER)"
fi

# Append to completed if we have an agent
if [ -n "$AGENT_NAME" ] && [ -n "$EXISTING_COMPLETED" ]; then
    EXISTING_COMPLETED="$EXISTING_COMPLETED
$ACTIVITY_ENTRY"
elif [ -n "$AGENT_NAME" ]; then
    EXISTING_COMPLETED="$ACTIVITY_ENTRY"
fi

# Write the ledger
cat > "$LEDGER_FILE" << EOF
---
project: $PROJECT_NAME
updated: $TIMESTAMP
session_id: $SESSION_ID
auto_updated: true
trigger: $TRIGGER
---

# Continuity Ledger: $PROJECT_NAME

## Goal
$EXISTING_GOAL

## Current Phase
$CURRENT_PHASE

## Constraints
$EXISTING_CONSTRAINTS

## Completed
$EXISTING_COMPLETED

## Now
- Last activity: $TRIGGER $([ -n "$AGENT_NAME" ] && echo "by @$AGENT_NAME")
- Session: $SESSION_ID
$([ -n "$NOTES" ] && echo "- Notes: $NOTES")

## Blocked / Parking Lot
- <Items waiting on external input>

## Key Decisions
$EXISTING_DECISIONS

## Working Files (Recent Git Changes)
\`\`\`
$GIT_STATUS
\`\`\`

## Traceability Status
- Design docs: $DESIGNS_COUNT
- Specs: $SPECS_COUNT  
- Evals: $EVALS_COUNT
- Handoffs: $HANDOFFS_COUNT

## Notes for Next Session
- Ledger auto-updated on: $TRIGGER
- Review recent handoffs in thoughts/shared/handoffs/
- Run /status for full workflow state
EOF

echo "$LEDGER_FILE"

