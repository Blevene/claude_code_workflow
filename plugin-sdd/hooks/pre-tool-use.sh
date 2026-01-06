#!/bin/bash
# PreToolUse Hook - Tiered security guardrails for automated execution
# Inspired by: https://github.com/danielmiessler/Personal_AI_Infrastructure
#
# This is a CRITICAL safety layer for subagents running with permissionMode: dontAsk
# Uses tiered security model: BLOCK (exit 2) / WARN (log + allow) / ALLOW

exec 2>/dev/null
trap 'exit 0' ERR

INPUT=$(head -c 100000)

if ! command -v jq &>/dev/null; then
    exit 0
fi

TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // "unknown"' 2>/dev/null) || exit 0
TOOL_INPUT=$(echo "$INPUT" | jq -r '.tool_input // "{}"' 2>/dev/null) || exit 0
PERMISSION_MODE=$(echo "$INPUT" | jq -r '.permission_mode // "default"' 2>/dev/null) || exit 0
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "unknown"' 2>/dev/null) || exit 0

# Detect automated context
IS_AUTOMATED="false"
case "$PERMISSION_MODE" in
    dontAsk|bypassPermissions)
        IS_AUTOMATED="true"
        ;;
    *)
        if [ "${CLAUDE_IS_SUBAGENT:-}" = "true" ] || [ "${CLAUDE_IS_SUBAGENT:-}" = "1" ]; then
            IS_AUTOMATED="true"
        fi
        ;;
esac

# Interactive mode = human oversight, allow everything
if [ "$IS_AUTOMATED" != "true" ]; then
    exit 0
fi

# Security logging
LOG_DIR="${CLAUDE_PROJECT_DIR:-.}/.claude/logs"
mkdir -p "$LOG_DIR" 2>/dev/null
SECURITY_LOG="$LOG_DIR/security-events.log"

log_security_event() {
    local level="$1"
    local category="$2"
    local message="$3"
    local detail="$4"
    echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] [$level] [$category] $message | $detail" >> "$SECURITY_LOG" 2>/dev/null
}

block_command() {
    local category="$1"
    local reason="$2"
    local command="$3"
    
    log_security_event "BLOCK" "$category" "$reason" "${command:0:100}"
    
    # Exit code 2 = block in Claude Code
    echo "🚨 SECURITY BLOCK [$category]: $reason"
    echo "Command: ${command:0:100}..."
    exit 2
}

# === BASH COMMAND SECURITY ===
if [ "$TOOL_NAME" = "Bash" ] || [ "$TOOL_NAME" = "bash" ]; then
    CMD=$(echo "$TOOL_INPUT" | jq -r '.command // ""' 2>/dev/null) || CMD=""
    [ -z "$CMD" ] && exit 0
    
    # TIER 1: CATASTROPHIC - Always block
    if echo "$CMD" | grep -qEi 'rm\s+(-rf?|--recursive)\s+[/~]'; then
        block_command "CATASTROPHIC" "Recursive deletion of root/home" "$CMD"
    fi
    if echo "$CMD" | grep -qEi 'rm\s+(-rf?|--recursive)\s+\*'; then
        block_command "CATASTROPHIC" "Recursive deletion of all files" "$CMD"
    fi
    if echo "$CMD" | grep -qEi '>\s*/dev/sd[a-z]'; then
        block_command "CATASTROPHIC" "Direct disk overwrite" "$CMD"
    fi
    if echo "$CMD" | grep -qEi 'mkfs\.'; then
        block_command "CATASTROPHIC" "Filesystem format" "$CMD"
    fi
    if echo "$CMD" | grep -qEi 'dd\s+if=.*of=/dev'; then
        block_command "CATASTROPHIC" "dd to device" "$CMD"
    fi
    
    # TIER 2: REVERSE SHELLS - Always block
    if echo "$CMD" | grep -qEi 'bash\s+-i\s+>&\s*/dev/tcp'; then
        block_command "REVERSE_SHELL" "Bash reverse shell detected" "$CMD"
    fi
    if echo "$CMD" | grep -qEi 'nc\s+(-e|--exec)\s+/bin/(ba)?sh'; then
        block_command "REVERSE_SHELL" "Netcat shell detected" "$CMD"
    fi
    if echo "$CMD" | grep -qEi 'python.*socket.*connect'; then
        block_command "REVERSE_SHELL" "Python socket connection" "$CMD"
    fi
    if echo "$CMD" | grep -qEi 'perl.*socket.*connect'; then
        block_command "REVERSE_SHELL" "Perl socket connection" "$CMD"
    fi
    if echo "$CMD" | grep -qEi '\|\s*/bin/(ba)?sh'; then
        block_command "REVERSE_SHELL" "Pipe to shell" "$CMD"
    fi
    if echo "$CMD" | grep -qEi 'socat.*exec'; then
        block_command "REVERSE_SHELL" "Socat exec detected" "$CMD"
    fi
    
    # TIER 3: REMOTE CODE EXECUTION - Always block
    if echo "$CMD" | grep -qEi 'curl.*\|\s*(ba)?sh'; then
        block_command "RCE" "curl pipe to shell" "$CMD"
    fi
    if echo "$CMD" | grep -qEi 'wget.*\|\s*(ba)?sh'; then
        block_command "RCE" "wget pipe to shell" "$CMD"
    fi
    if echo "$CMD" | grep -qEi 'base64\s+-d.*\|\s*(ba)?sh'; then
        block_command "RCE" "Base64 decode to shell" "$CMD"
    fi
    if echo "$CMD" | grep -qEi 'curl.*(-o|--output).*&&.*chmod.*\+x'; then
        block_command "RCE" "Download and execute pattern" "$CMD"
    fi
    
    # TIER 4: PROMPT INJECTION - Block and log
    if echo "$CMD" | grep -qEi 'ignore\s+(all\s+)?previous\s+instructions'; then
        block_command "PROMPT_INJECTION" "Ignore instructions pattern" "$CMD"
    fi
    if echo "$CMD" | grep -qEi 'disregard\s+(all\s+)?prior\s+instructions'; then
        block_command "PROMPT_INJECTION" "Disregard instructions pattern" "$CMD"
    fi
    if echo "$CMD" | grep -qEi 'you\s+are\s+now\s+(in\s+)?[a-z]+\s+mode'; then
        block_command "PROMPT_INJECTION" "Mode change injection" "$CMD"
    fi
    if echo "$CMD" | grep -qEi 'system\s+prompt:'; then
        block_command "PROMPT_INJECTION" "System prompt injection" "$CMD"
    fi
    if echo "$CMD" | grep -qE '\[INST\]|<\|im_start\|>'; then
        block_command "PROMPT_INJECTION" "LLM injection markers" "$CMD"
    fi
    
    # TIER 5: DATA EXFILTRATION - Block
    if echo "$CMD" | grep -qEi 'curl.*(@|--upload-file)'; then
        block_command "EXFILTRATION" "File upload via curl" "$CMD"
    fi
    if echo "$CMD" | grep -qEi 'tar.*\|.*curl'; then
        block_command "EXFILTRATION" "Archive and send" "$CMD"
    fi
    if echo "$CMD" | grep -qEi 'zip.*\|.*(nc|curl|wget)'; then
        block_command "EXFILTRATION" "Compress and exfiltrate" "$CMD"
    fi
    
    # TIER 6: CREDENTIAL ACCESS - Block
    if echo "$CMD" | grep -qEi 'echo\s+\$\{?(ANTHROPIC|OPENAI|AWS|AZURE)_'; then
        block_command "CREDENTIAL_ACCESS" "API key echo" "$CMD"
    fi
    if echo "$CMD" | grep -qEi 'env\s*\|.*KEY'; then
        block_command "CREDENTIAL_ACCESS" "Environment key dump" "$CMD"
    fi
    if echo "$CMD" | grep -qEi 'cat.*(\.env|credentials|secrets)'; then
        block_command "CREDENTIAL_ACCESS" "Credential file read" "$CMD"
    fi
    
    # TIER 7: GIT DANGEROUS - Block for main/master
    if echo "$CMD" | grep -qEi 'git\s+push.*(-f|--force).*(main|master)'; then
        block_command "GIT_DANGEROUS" "Force push to protected branch" "$CMD"
    fi
    if echo "$CMD" | grep -qEi 'git\s+reset\s+--hard.*origin/(main|master)'; then
        block_command "GIT_DANGEROUS" "Hard reset to origin main/master" "$CMD"
    fi
    
    # TIER 8: PRIVILEGE ESCALATION - Block
    if echo "$CMD" | grep -qEi 'sudo\s+(su|bash|-i)'; then
        block_command "PRIVILEGE_ESCALATION" "Sudo shell access" "$CMD"
    fi
    if echo "$CMD" | grep -qEi 'chmod\s+(-R\s+)?777'; then
        block_command "PRIVILEGE_ESCALATION" "World-writable permissions" "$CMD"
    fi
    
    # TIER 9: SYSTEM MODIFICATION - Log and allow (warn)
    if echo "$CMD" | grep -qEi 'systemctl\s+(stop|disable)'; then
        log_security_event "WARN" "SYSTEM_MOD" "Service stop/disable" "${CMD:0:100}"
    fi
    if echo "$CMD" | grep -qEi 'sudo\s+'; then
        log_security_event "WARN" "SYSTEM_MOD" "Sudo usage" "${CMD:0:100}"
    fi
    
    # TIER 10: WORKFLOW PROTECTION - Block
    if echo "$CMD" | grep -qEi 'rm.*\.claude'; then
        block_command "WORKFLOW_PROTECTION" "Attempt to delete .claude config" "$CMD"
    fi
    if echo "$CMD" | grep -qEi 'rm.*thoughts'; then
        block_command "WORKFLOW_PROTECTION" "Attempt to delete thoughts directory" "$CMD"
    fi
    
    # All checks passed - allow the command
    exit 0
fi

# === WRITE/EDIT SECURITY ===
if [ "$TOOL_NAME" = "Write" ] || [ "$TOOL_NAME" = "Edit" ] || [ "$TOOL_NAME" = "str_replace_editor" ]; then
    FILE_PATH=$(echo "$TOOL_INPUT" | jq -r '.file_path // .path // ""' 2>/dev/null) || FILE_PATH=""
    
    # System paths - Block
    if echo "$FILE_PATH" | grep -qE '^/(etc|usr|bin|sbin|boot|root)/'; then
        block_command "WRITE_PROTECTION" "System path write" "$FILE_PATH"
    fi
    
    # Credential files - Block
    if echo "$FILE_PATH" | grep -qEi '(\.ssh/|\.gnupg/|\.aws/|id_rsa|id_ed25519|\.pem$)'; then
        block_command "WRITE_PROTECTION" "Credential file write" "$FILE_PATH"
    fi
    
    # Secret files - Block
    if echo "$FILE_PATH" | grep -qEi '(\.env$|\.env\.|credentials|secrets\.ya?ml)'; then
        block_command "WRITE_PROTECTION" "Secret file write" "$FILE_PATH"
    fi
    
    # All checks passed - allow the write
    exit 0
fi

# All checks passed
exit 0

