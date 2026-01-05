---
name: validate-hooks
description: Systematic hook debugging and validation workflow. Use when hooks aren't firing, producing wrong output, or behaving unexpectedly.
---

# Validate Hooks

Systematic workflow for debugging and validating Claude Code hooks. Use this when hooks aren't working as expected.

## When to Use

- "Hook isn't firing"
- "Hook produces wrong output"
- "SessionStart not loading ledger"
- "PostToolUse hook not triggering"
- "Why didn't my hook run?"
- After modifying hook scripts
- When setting up hooks in a new project

## Debug Workflow

### 1. Check Outputs First (Observe Before Editing)

Before changing code, verify what's actually happening:

```bash
# Check project cache for hook outputs
ls -la .claude/cache/

# Check for ledger files
ls -la thoughts/ledgers/

# Check for handoff files  
ls -la thoughts/shared/handoffs/

# Check for debug/error logs
cat .claude/cache/*.log 2>/dev/null
tail -20 .claude/cache/session-*.txt 2>/dev/null

# Also check global location (common mistake: wrong path)
ls -la ~/.claude/cache/ 2>/dev/null
```

### 2. Verify Hook Registration

Hooks must be registered in `settings.json`:

```bash
# Check project settings
cat .claude/settings.json 2>/dev/null | grep -A 20 '"hooks"'

# Check plugin settings  
cat plugin-sdd/.claude-plugin/settings.json | grep -A 30 '"hooks"'

# Check global settings (hooks merge from both)
cat ~/.claude/settings.json 2>/dev/null | grep -A 30 '"hooks"'
```

**Expected structure:**

```json
{
  "hooks": {
    "SessionStart": [{
      "matcher": "startup|resume|compact|clear",
      "hooks": [{ "type": "command", "command": "path/to/hook.sh", "timeout": 30 }]
    }],
    "PostToolUse": [{
      "matcher": "Edit|Write|MultiEdit|Bash",
      "hooks": [{ "type": "command", "command": "path/to/hook.sh", "timeout": 10 }]
    }]
  }
}
```

### 3. Check Hook Files Exist and Are Executable

```bash
# List hook files
ls -la plugin-sdd/hooks/*.sh

# Check if executable
file plugin-sdd/hooks/*.sh

# Make executable if needed
chmod +x plugin-sdd/hooks/*.sh
```

### 4. Test Hooks Manually

Test each hook with simulated input:

```bash
# SessionStart hook
echo '{"source":"startup"}' | plugin-sdd/hooks/session-start.sh
echo '{"source":"resume"}' | plugin-sdd/hooks/session-start.sh
echo '{"source":"clear"}' | plugin-sdd/hooks/session-start.sh

# PreCompact hook
echo '{"reason":"auto"}' | plugin-sdd/hooks/pre-compact.sh

# UserPromptSubmit hook
echo '{"prompt":"test message","session_id":"test-123"}' | plugin-sdd/hooks/user-prompt-submit.sh

# PostToolUse hook
echo '{"tool_name":"Write","tool_input":{"file_path":"test.md"},"session_id":"test-123"}' | plugin-sdd/hooks/post-tool-use.sh

# SubagentStop hook
echo '{"agent_type":"backend","task_id":"T-001","session_id":"test-123"}' | plugin-sdd/hooks/subagent-stop.sh

# Stop hook
echo '{"session_id":"test-123"}' | plugin-sdd/hooks/stop.sh

# SessionEnd hook
echo '{"session_id":"test-123","reason":"user"}' | plugin-sdd/hooks/session-end.sh
```

### 5. Check Dependencies

```bash
# Verify jq is installed (required for JSON parsing)
jq --version

# If missing, install:
# macOS: brew install jq
# Linux: apt install jq

# Verify other dependencies
which bash
which date
which grep
```

### 6. Check for Silent Failures

Common issues that fail silently:

**Missing shebang:**
```bash
# First line of script MUST be:
#!/bin/bash
```

**Wrong paths:**
```bash
# Check if paths in hooks are correct
grep -r "thoughts/" plugin-sdd/hooks/
grep -r "\.claude/" plugin-sdd/hooks/

# Ensure paths are relative to project root, not hook location
```

**Permission denied:**
```bash
# Check file permissions
ls -la plugin-sdd/hooks/

# Fix permissions
chmod +x plugin-sdd/hooks/*.sh
```

### 7. Add Debug Logging

Temporarily add logging to hooks:

```bash
# Add at start of hook script:
echo "[DEBUG $(date)] Hook started, input: $@" >> /tmp/hook-debug.log

# Add before critical operations:
echo "[DEBUG] About to process: $input" >> /tmp/hook-debug.log

# Check the log:
tail -f /tmp/hook-debug.log
```

## Common Issues

| Symptom | Likely Cause | Fix |
|---------|--------------|-----|
| Hook never runs | Not registered in settings.json | Add to correct event in settings |
| Hook runs but no output | Script error or wrong path | Test manually, add debug logging |
| Runs for wrong events | Matcher pattern incorrect | Check matcher regex |
| Works locally, not globally | Path issues | Use absolute paths or `$HOME` |
| Output not appearing | Writing to wrong location | Check output paths in script |
| Runs twice | Registered in both plugin + global | Remove duplicate |
| Timeout errors | Hook takes too long | Increase timeout or optimize |

## Hook Event Reference

| Event | When It Fires | Matcher Values |
|-------|---------------|----------------|
| **SessionStart** | Session begins | `startup`, `resume`, `compact`, `clear` |
| **PreCompact** | Before context compaction | `auto`, `manual` |
| **UserPromptSubmit** | User sends message | (no matcher needed) |
| **PostToolUse** | After tool execution | Tool names: `Edit`, `Write`, `Bash`, etc. |
| **SubagentStop** | Subagent completes | (no matcher needed) |
| **Stop** | Main agent finishes | (no matcher needed) |
| **SessionEnd** | Session ends | (no matcher needed) |

## Hook Input/Output Format

**Input:** Hooks receive JSON on stdin

```json
{
  "source": "startup",
  "session_id": "abc123",
  "tool_name": "Write",
  "tool_input": { "file_path": "..." }
}
```

**Output:** Hooks return JSON on stdout

```json
{
  "continue": true,
  "systemMessage": "Optional message to inject into context"
}
```

## Validation Checklist

Use this checklist when hooks aren't working:

- [ ] Hook file exists at specified path
- [ ] Hook file is executable (`chmod +x`)
- [ ] Hook has correct shebang (`#!/bin/bash`)
- [ ] Hook is registered in settings.json
- [ ] Matcher pattern is correct for event
- [ ] Dependencies available (`jq`, etc.)
- [ ] Paths are correct (relative to project root)
- [ ] Manual test produces expected output
- [ ] No syntax errors (run `bash -n hook.sh`)
- [ ] Timeout is sufficient for hook duration

## Quick Diagnostic Script

Run the validation script:

```bash
bash plugin-sdd/scripts/validate-hooks.sh
```

