---
globs: ["**/*"]
---

# Agent Safety Guardrails

Subagents run with `permissionMode: dontAsk` for efficiency. A PreToolUse hook enforces **tiered security**.

Inspired by [danielmiessler/Personal_AI_Infrastructure](https://github.com/danielmiessler/Personal_AI_Infrastructure).

## Security Tiers

| Tier | Category | Action | Examples |
|------|----------|--------|----------|
| 1 | **CATASTROPHIC** | 🚫 Block | `rm -rf /`, `mkfs`, `dd of=/dev/sda` |
| 2 | **REVERSE_SHELL** | 🚫 Block | `bash -i >& /dev/tcp`, `nc -e /bin/sh`, `socat exec` |
| 3 | **RCE** | 🚫 Block | `curl \| bash`, `base64 -d \| sh`, download+execute |
| 4 | **PROMPT_INJECTION** | 🚫 Block | "ignore previous instructions", `[INST]`, `<\|im_start\|>` |
| 5 | **EXFILTRATION** | 🚫 Block | `curl --upload-file`, `tar \| curl`, archive+send |
| 6 | **CREDENTIAL_ACCESS** | 🚫 Block | `echo $OPENAI_KEY`, `env \| grep KEY`, `cat .env` |
| 7 | **GIT_DANGEROUS** | 🚫 Block | `git push --force main`, `git reset --hard origin/main` |
| 8 | **PRIVILEGE_ESCALATION** | 🚫 Block | `sudo su`, `sudo bash`, `chmod 777` |
| 9 | **SYSTEM_MOD** | ⚠️ Log+Allow | `systemctl stop`, general `sudo` |
| 10 | **WORKFLOW_PROTECTION** | 🚫 Block | `rm .claude`, `rm thoughts/` |

## File Write Protection

Cannot write to:
- **System**: `/etc/`, `/usr/`, `/bin/`, `/sbin/`, `/boot/`, `/root/`
- **Credentials**: `~/.ssh/`, `~/.gnupg/`, `~/.aws/`, `*.pem`, `id_rsa`, `id_ed25519`
- **Secrets**: `.env`, `.env.*`, `credentials`, `secrets.yml`

## Security Logging

All blocked operations are logged to `.claude/logs/security-events.log` with:
- Timestamp, category, reason, command snippet

## If You Need a Blocked Operation

1. **Escalate to @orchestrator** explaining the specific need
2. Human operator can run in **interactive mode** (permission_mode: default)
3. Or temporarily use a dedicated human-supervised session

## Why This Exists

- **Defense in depth**: Even if agent prompt is manipulated, hooks block danger
- **Prompt injection protection**: Blocks attempts to override instructions
- **Credential safety**: Prevents accidental exposure of API keys/secrets
- **No human oversight**: Subagents with `dontAsk` can't ask for permission
- **Cost protection**: Prevents expensive token waste from destructive loops

