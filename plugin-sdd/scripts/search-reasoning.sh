#!/bin/bash
# Search Reasoning - Search past commit reasoning for relevant content
#
# Usage: search-reasoning.sh <query> [options]
#
# Options:
#   --failed    Only show commits with failed attempts
#   --passed    Only show commits that passed first try
#   --limit N   Limit results (default: 10)
#
# This enables search over past reasoning to find:
# - Failed approaches that were tried before (avoid repeating)
# - Solutions that worked for similar problems (learn from)
# - Decisions and their rationale (understand context)
#
# Examples:
#   search-reasoning.sh "rate limiting"
#   search-reasoning.sh "authentication" --failed
#   search-reasoning.sh "ModuleNotFoundError"

QUERY=""
FILTER=""
LIMIT=10
GIT_CLAUDE_DIR=".git/claude"

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --failed)
            FILTER="failed"
            shift
            ;;
        --passed)
            FILTER="passed"
            shift
            ;;
        --limit)
            LIMIT="$2"
            shift 2
            ;;
        *)
            if [[ -z "$QUERY" ]]; then
                QUERY="$1"
            fi
            shift
            ;;
    esac
done

if [[ -z "$QUERY" ]]; then
    echo "Usage: search-reasoning.sh <query> [options]"
    echo ""
    echo "Options:"
    echo "  --failed    Only show commits with failed attempts"
    echo "  --passed    Only show commits that passed first try"
    echo "  --limit N   Limit results (default: 10)"
    echo ""
    echo "Examples:"
    echo "  search-reasoning.sh 'rate limiting'"
    echo "  search-reasoning.sh 'authentication' --failed"
    echo "  search-reasoning.sh 'ImportError' --limit 5"
    exit 1
fi

echo "🔍 Searching reasoning for: \"$QUERY\""
if [[ -n "$FILTER" ]]; then
    echo "   Filter: $FILTER attempts only"
fi
echo "==========================================="

# Check if any reasoning files exist
if ! ls "$GIT_CLAUDE_DIR/commits/"*/reasoning.md >/dev/null 2>&1; then
    echo ""
    echo "No reasoning files found."
    echo ""
    echo "Reasoning files are created when you use /commit after running builds."
    echo "They capture what was tried during development."
    echo ""
    echo "To start tracking reasoning:"
    echo "  1. Use /commit instead of git commit"
    echo "  2. Build/test attempts are automatically tracked"
    exit 0
fi

# Find all reasoning files and search
matches=""
if [[ "$FILTER" == "failed" ]]; then
    # Only files with "Failed attempts" section
    matches=$(grep -l "### Failed attempts" "$GIT_CLAUDE_DIR/commits/"*/reasoning.md 2>/dev/null | xargs grep -l -i "$QUERY" 2>/dev/null || echo "")
elif [[ "$FILTER" == "passed" ]]; then
    # Only files with "passed on first try"
    matches=$(grep -l "passed on first try" "$GIT_CLAUDE_DIR/commits/"*/reasoning.md 2>/dev/null | xargs grep -l -i "$QUERY" 2>/dev/null || echo "")
else
    matches=$(grep -l -i "$QUERY" "$GIT_CLAUDE_DIR/commits/"*/reasoning.md 2>/dev/null || echo "")
fi

if [[ -z "$matches" ]]; then
    echo ""
    echo "No matches found for: \"$QUERY\""
    if [[ -n "$FILTER" ]]; then
        echo "(with filter: $FILTER)"
    fi
    echo ""
    echo "Try different search terms or check available reasoning files:"
    echo "  ls $GIT_CLAUDE_DIR/commits/*/reasoning.md"
    exit 0
fi

echo ""

count=0
for file in $matches; do
    if [[ $count -ge $LIMIT ]]; then
        remaining=$(($(echo "$matches" | wc -w) - LIMIT))
        echo "... and $remaining more matches (use --limit to see more)"
        break
    fi

    commit_hash=$(basename "$(dirname "$file")")

    # Get commit info if available
    commit_msg=$(git log -1 --format="%s" "$commit_hash" 2>/dev/null || echo "Unknown commit")
    commit_date=$(git log -1 --format="%ci" "$commit_hash" 2>/dev/null | cut -d' ' -f1 || echo "Unknown date")
    commit_author=$(git log -1 --format="%an" "$commit_hash" 2>/dev/null || echo "Unknown")

    # Determine outcome
    outcome="?"
    if grep -q "### Failed attempts" "$file" 2>/dev/null; then
        outcome="✗→✓"  # Failed then passed
    elif grep -q "passed on first try" "$file" 2>/dev/null; then
        outcome="✓"    # Passed first try
    fi

    echo "## [$outcome] Commit \`${commit_hash:0:8}\` - $commit_date"
    echo "**$commit_msg** (by $commit_author)"
    echo ""

    # Show context around matches (2 lines before/after)
    grep -B 2 -A 2 -i --color=never "$QUERY" "$file" | head -30
    echo ""
    echo "---"
    echo ""

    count=$((count + 1))
done

total=$(echo "$matches" | wc -w | tr -d ' ')
echo "Found matches in $total reasoning file(s)."

# Suggest related searches
echo ""
echo "💡 Related searches:"
echo "  search-reasoning.sh '$QUERY' --failed   # Only failed attempts"
echo "  search-reasoning.sh '$QUERY' --passed   # Only first-try successes"

