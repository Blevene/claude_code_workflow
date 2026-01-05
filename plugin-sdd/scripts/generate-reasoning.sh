#!/bin/bash
# Generate Reasoning - Creates commit-keyed reasoning from build attempts
#
# Usage: generate-reasoning.sh <commit-hash> [commit-message]
#
# Reads from branch-specific attempts file, writes to commit-keyed reasoning.
# Called by the /commit command after each commit to capture what was tried
# during development (build failures, fixes, etc.)
#
# Storage:
#   .git/claude/branches/{branch}/attempts.jsonl  - Input (cleared after)
#   .git/claude/commits/{hash}/reasoning.md       - Output (permanent)

set -e

COMMIT_HASH_INPUT="$1"
COMMIT_MSG="$2"
GIT_CLAUDE_DIR=".git/claude"

if [[ -z "$COMMIT_HASH_INPUT" ]]; then
    echo "Usage: generate-reasoning.sh <commit-hash> [commit-message]"
    echo ""
    echo "Generates reasoning.md from build attempts for the given commit."
    echo "Typically called automatically by /commit command."
    exit 1
fi

# Resolve to full hash for consistent storage
COMMIT_HASH=$(git rev-parse "$COMMIT_HASH_INPUT" 2>/dev/null)
if [[ -z "$COMMIT_HASH" ]]; then
    echo "Error: Could not resolve commit hash '$COMMIT_HASH_INPUT'"
    exit 1
fi

# Get commit message from git if not provided
if [[ -z "$COMMIT_MSG" ]]; then
    COMMIT_MSG=$(git log -1 --format="%s" "$COMMIT_HASH" 2>/dev/null || echo "Unknown commit message")
fi

# Get current branch
current_branch=$(git branch --show-current 2>/dev/null || echo "detached")
safe_branch=$(echo "$current_branch" | tr '/' '-')

# Paths
ATTEMPTS_FILE="$GIT_CLAUDE_DIR/branches/$safe_branch/attempts.jsonl"
OUTPUT_DIR="$GIT_CLAUDE_DIR/commits/$COMMIT_HASH"

mkdir -p "$OUTPUT_DIR"

# Start reasoning file
cat > "$OUTPUT_DIR/reasoning.md" << EOF
# Commit: ${COMMIT_HASH:0:8}

## Branch
$current_branch

## What was committed
$COMMIT_MSG

## What was tried
EOF

# Parse attempts and add to reasoning
if [[ -f "$ATTEMPTS_FILE" ]] && [[ -s "$ATTEMPTS_FILE" ]]; then
    # Extract failed attempts with error summaries
    failures=""
    while IFS= read -r line; do
        attempt_type=$(echo "$line" | jq -r '.type // empty' 2>/dev/null)
        if [[ "$attempt_type" == "build_fail" ]] || [[ "$attempt_type" == "test_fail" ]]; then
            cmd=$(echo "$line" | jq -r '.command // "unknown"' 2>/dev/null | cut -c1-50)
            error=$(echo "$line" | jq -r '.error // "unknown error"' 2>/dev/null | head -1 | cut -c1-100)
            build_type=$(echo "$line" | jq -r '.build_type // "build"' 2>/dev/null)
            failures+="- \`$cmd...\` ($build_type): $error"$'\n'
        fi
    done < "$ATTEMPTS_FILE"

    if [[ -n "$failures" ]]; then
        echo "" >> "$OUTPUT_DIR/reasoning.md"
        echo "### Failed attempts" >> "$OUTPUT_DIR/reasoning.md"
        echo "$failures" >> "$OUTPUT_DIR/reasoning.md"
    fi

    # Count attempts by type (use -c for compact output, one line per record)
    fail_count=$(jq -c 'select(.type == "build_fail" or .type == "test_fail")' "$ATTEMPTS_FILE" 2>/dev/null | wc -l | tr -d ' ')
    pass_count=$(jq -c 'select(.type == "build_pass" or .type == "test_pass")' "$ATTEMPTS_FILE" 2>/dev/null | wc -l | tr -d ' ')

    echo "" >> "$OUTPUT_DIR/reasoning.md"
    echo "### Summary" >> "$OUTPUT_DIR/reasoning.md"
    if [[ "$fail_count" -gt 0 ]]; then
        echo "Build passed after **$fail_count failed attempt(s)** and $pass_count successful build(s)." >> "$OUTPUT_DIR/reasoning.md"
    else
        echo "Build passed on first try ($pass_count successful build(s))." >> "$OUTPUT_DIR/reasoning.md"
    fi

    # Clear attempts for next feature (branch-specific)
    > "$ATTEMPTS_FILE"
else
    echo "" >> "$OUTPUT_DIR/reasoning.md"
    echo "_No build attempts recorded for this commit._" >> "$OUTPUT_DIR/reasoning.md"
fi

# Add files changed
echo "" >> "$OUTPUT_DIR/reasoning.md"
echo "## Files changed" >> "$OUTPUT_DIR/reasoning.md"
git diff-tree --no-commit-id --name-only -r "$COMMIT_HASH" 2>/dev/null | sed 's/^/- /' >> "$OUTPUT_DIR/reasoning.md" || echo "- (unable to determine files)" >> "$OUTPUT_DIR/reasoning.md"

# Add related specs/evals if any
SPECS_CHANGED=$(git diff-tree --no-commit-id --name-only -r "$COMMIT_HASH" 2>/dev/null | grep -E "^specs/.*\.md$" || true)
EVALS_CHANGED=$(git diff-tree --no-commit-id --name-only -r "$COMMIT_HASH" 2>/dev/null | grep -E "^evals/.*\.py$" || true)

if [[ -n "$SPECS_CHANGED" ]] || [[ -n "$EVALS_CHANGED" ]]; then
    echo "" >> "$OUTPUT_DIR/reasoning.md"
    echo "## SDD Artifacts" >> "$OUTPUT_DIR/reasoning.md"
    if [[ -n "$SPECS_CHANGED" ]]; then
        echo "### Specs modified" >> "$OUTPUT_DIR/reasoning.md"
        echo "$SPECS_CHANGED" | sed 's/^/- /' >> "$OUTPUT_DIR/reasoning.md"
    fi
    if [[ -n "$EVALS_CHANGED" ]]; then
        echo "### Evals modified" >> "$OUTPUT_DIR/reasoning.md"
        echo "$EVALS_CHANGED" | sed 's/^/- /' >> "$OUTPUT_DIR/reasoning.md"
    fi
fi

echo "✓ Reasoning saved to $OUTPUT_DIR/reasoning.md"

