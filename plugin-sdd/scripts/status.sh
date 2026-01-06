#!/bin/bash
# StatusLine - Context monitoring for SDD workflow
# Shows: Context % | Git info | Current focus from ledger
# Critical: ⚠ 160K 80% | main U:6 | Current focus
#
# Inspired by Continuous-Claude-v2 status.sh

input=$(cat)

project_dir="${CLAUDE_PROJECT_DIR:-$(pwd)}"
cwd=$(echo "$input" | jq -r '.workspace.current_dir // ""' 2>/dev/null)
[[ -z "$cwd" || "$cwd" == "null" ]] && cwd="$project_dir"

# ─────────────────────────────────────────────────────────────────
# TOKENS - Context usage calculation
# ─────────────────────────────────────────────────────────────────
input_tokens=$(echo "$input" | jq -r '.context_window.current_usage.input_tokens // 0' 2>/dev/null)
cache_read=$(echo "$input" | jq -r '.context_window.current_usage.cache_read_input_tokens // 0' 2>/dev/null)
cache_creation=$(echo "$input" | jq -r '.context_window.current_usage.cache_creation_input_tokens // 0' 2>/dev/null)

# System overhead estimate (instructions, tools, etc.)
system_overhead=45000
total_tokens=$((input_tokens + cache_read + cache_creation + system_overhead))
context_size=$(echo "$input" | jq -r '.context_window.context_window_size // 200000' 2>/dev/null)

# Calculate percentage
context_pct=$((total_tokens * 100 / context_size))
[[ "$context_pct" -gt 100 ]] && context_pct=100

# Write context percentage for hooks to read
# Use session_id from input, fallback to PPID for uniqueness
session_id=$(echo "$input" | jq -r '.session_id // ""' 2>/dev/null)
[[ -z "$session_id" || "$session_id" == "null" ]] && session_id="$PPID"
echo "$context_pct" > "/tmp/claude-context-pct-${session_id}.txt"

# Format tokens as K with one decimal
token_display=$(awk "BEGIN {printf \"%.1fK\", $total_tokens/1000}")

# ─────────────────────────────────────────────────────────────────
# GIT - Branch + S/U/A counts
# ─────────────────────────────────────────────────────────────────
git_info=""
if git -C "$cwd" rev-parse --git-dir > /dev/null 2>&1; then
    branch=$(git -C "$cwd" --no-optional-locks rev-parse --abbrev-ref HEAD 2>/dev/null)
    [[ ${#branch} -gt 12 ]] && branch="${branch:0:10}.."

    staged=$(git -C "$cwd" --no-optional-locks diff --cached --name-only 2>/dev/null | wc -l | tr -d ' ')
    unstaged=$(git -C "$cwd" --no-optional-locks diff --name-only 2>/dev/null | wc -l | tr -d ' ')
    added=$(git -C "$cwd" --no-optional-locks ls-files --others --exclude-standard 2>/dev/null | wc -l | tr -d ' ')

    counts=""
    [[ "$staged" -gt 0 ]] && counts="S:$staged"
    [[ "$unstaged" -gt 0 ]] && counts="${counts:+$counts }U:$unstaged"
    [[ "$added" -gt 0 ]] && counts="${counts:+$counts }A:$added"

    if [[ -n "$counts" ]]; then
        git_info="$branch \033[33m$counts\033[0m"
    else
        git_info="\033[32m$branch\033[0m"
    fi
fi

# ─────────────────────────────────────────────────────────────────
# CONTINUITY - Last done + Current focus from ledger
# ─────────────────────────────────────────────────────────────────
# Look for ledgers in thoughts/ledgers/ (SDD standard location)
ledger_dir="$project_dir/thoughts/ledgers"
ledger=""
if [[ -d "$ledger_dir" ]]; then
    ledger=$(ls -t "$ledger_dir"/CONTINUITY_*.md 2>/dev/null | head -1)
fi

last_done=""
now_focus=""
phase_info=""

if [[ -n "$ledger" && -f "$ledger" ]]; then
    # Check for multi-phase format with checkboxes
    # Look for [→] (in progress)
    in_progress=$(grep -E '^\s*-\s*\[→\]' "$ledger" 2>/dev/null | head -1 | sed 's/^[[:space:]]*-[[:space:]]*\[→\][[:space:]]*//')
    
    if [[ -n "$in_progress" ]]; then
        # Count completed phases
        completed=$(grep -cE '^\s*-\s*\[x\]' "$ledger" 2>/dev/null || echo "0")
        total=$(grep -cE '^\s*-\s*\[(x|→| )\]' "$ledger" 2>/dev/null || echo "0")
        
        if [[ "$total" -gt 0 ]]; then
            phase_info="Phase $((completed+1))/$total"
            now_focus="$in_progress"
        fi
    fi
    
    # Fallback to Done/Now format if no checkbox format found
    if [[ -z "$now_focus" ]]; then
        # Get the most recent "Done:" item
        last_done=$(grep -E '^\s*-\s*Done:' "$ledger" 2>/dev/null | \
            tail -1 | \
            sed 's/^[[:space:]]*-[[:space:]]*Done:[[:space:]]*//')
        [[ ${#last_done} -gt 20 ]] && last_done="${last_done:0:18}.."

        # Get "Now:" item
        now_focus=$(grep -E '^\s*-\s*Now:' "$ledger" 2>/dev/null | \
            sed 's/^[[:space:]]*-[[:space:]]*Now:[[:space:]]*//' | \
            head -1)
    fi
    
    # Truncate now_focus
    [[ ${#now_focus} -gt 30 ]] && now_focus="${now_focus:0:28}.."
fi

# Build continuity string
continuity=""
if [[ -n "$phase_info" && -n "$now_focus" ]]; then
    continuity="$phase_info: $now_focus"
elif [[ -n "$last_done" && -n "$now_focus" ]]; then
    continuity="✓ $last_done → $now_focus"
elif [[ -n "$now_focus" ]]; then
    continuity="$now_focus"
fi

# ─────────────────────────────────────────────────────────────────
# SDD STATUS - Specs and evals count
# ─────────────────────────────────────────────────────────────────
sdd_info=""
if [[ -d "$project_dir/specs" || -d "$project_dir/evals" ]]; then
    spec_count=$(find "$project_dir/specs" -name "SPEC-*.md" 2>/dev/null | wc -l | tr -d ' ')
    eval_count=$(find "$project_dir/evals" -name "eval_*.py" 2>/dev/null | wc -l | tr -d ' ')
    
    if [[ "$spec_count" -gt 0 || "$eval_count" -gt 0 ]]; then
        sdd_info="📋${spec_count}/${eval_count}"
    fi
fi

# ─────────────────────────────────────────────────────────────────
# OUTPUT - Contextual priority based on context usage
# ─────────────────────────────────────────────────────────────────
if [[ "$context_pct" -ge 80 ]]; then
    # CRITICAL - Red warning, context takes priority
    ctx_display="\033[31m⚠ ${token_display} ${context_pct}%\033[0m"
    output="$ctx_display"
    [[ -n "$git_info" ]] && output="$output | $git_info"
    [[ -n "$now_focus" ]] && output="$output | $now_focus"
    # Add urgent reminder
    output="$output | \033[31m/clear NOW\033[0m"
elif [[ "$context_pct" -ge 60 ]]; then
    # WARNING - Yellow context
    ctx_display="\033[33m${token_display} ${context_pct}%\033[0m"
    output="$ctx_display"
    [[ -n "$git_info" ]] && output="$output | $git_info"
    [[ -n "$sdd_info" ]] && output="$output | $sdd_info"
    [[ -n "$continuity" ]] && output="$output | $continuity"
else
    # NORMAL - Green, show full info
    ctx_display="\033[32m${token_display} ${context_pct}%\033[0m"
    output="$ctx_display"
    [[ -n "$git_info" ]] && output="$output | $git_info"
    [[ -n "$sdd_info" ]] && output="$output | $sdd_info"
    [[ -n "$continuity" ]] && output="$output | $continuity"
fi

echo -e "$output"
