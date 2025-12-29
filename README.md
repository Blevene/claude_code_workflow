# Claude Code Workflow

**FAANG-style TDD workflow + Session continuity = Agents that don't degrade.**

A Claude Code configuration that enforces enterprise-grade, test-driven development through a coordinated multi-agent team, with session continuity to prevent context degradation.

CONTINUITY INSPIRED BY https://github.com/parcadei/Continuous-Claude-v2

## What This Does

This plugin adds **9 specialized AI agents**, **11 slash commands**, and a **continuity system** to Claude Code that enforce:

- **Design-first development** - No code without architecture docs
- **Test-driven development (TDD)** - Tests written BEFORE implementation
- **Full traceability** - Requirements → Design → Code → Tests all linked
- **Governance checkpoints** - Risk assessment at each phase
- **Session continuity** - Ledgers and handoffs prevent agent degradation

## The Problem This Solves

When Claude Code runs low on context, it compacts (summarizes) the conversation. Each compaction is lossy:

```
Session Start: Full context, high signal
    ↓ work, work, work
Compaction 1: Some detail lost
    ↓ work, work, work  
Compaction 2: Context getting murky
    ↓ work, work, work
Compaction 3: Now working with compressed noise
    ↓ Agents start hallucinating context
```

**The Solution: Clear, don't compact.** Save state to a ledger, wipe context with `/clear`, resume fresh.

## Quick Start

### Prerequisites

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) v2.0+ installed
- macOS, Linux, or WSL
- `jq` installed (`brew install jq` or `apt install jq`)

### Installation

**1. Clone this repository:**

```bash
git clone https://github.com/blevene/claude_code_workflow.git
```

**2. Copy to Claude's plugins directory:**

```bash
mkdir -p ~/.claude/plugins
cp -r claude_code_workflow/plugin ~/.claude/plugins/claude_code_workflow
```

**3. Make hooks executable:**

```bash
chmod +x ~/.claude/plugins/claude_code_workflow/hooks/*.sh
chmod +x ~/.claude/plugins/claude_code_workflow/scripts/*.sh
```

**4. Create a shell alias (required for persistence):**

Add this line to your `~/.zshrc` (or `~/.bashrc` for bash):

```bash
alias claude='claude --plugin-dir ~/.claude/plugins/claude_code_workflow'
```

**5. Reload your shell:**

```bash
source ~/.zshrc
```

**6. Verify installation:**

```bash
claude
```

Then type `/help` - you should see the workflow commands listed.

> **Why the alias?** There's a [known bug](https://github.com/anthropics/claude-code/issues/12457) in Claude Code v2.x where locally installed plugins don't persist between sessions. The alias ensures your plugin loads every time.

### Initialize a Project

For each project, run the init script:

```bash
~/.claude/plugins/claude_code_workflow/scripts/init-project.sh
```

This creates:
- `thoughts/ledgers/` - Continuity ledgers
- `thoughts/shared/handoffs/` - Session handoffs
- `thoughts/shared/plans/` - Implementation plans
- `traceability_matrix.json` - Requirement tracking

## Commands

### Continuity Commands (NEW in v2)

| Command | Description |
|---------|-------------|
| `/save-state` | Update continuity ledger before `/clear` |
| `/handoff` | Create detailed session handoff for later |
| `/resume` | Load and review latest handoff |

### FAANG Workflow Commands

| Command | Description |
|---------|-------------|
| `/design <feature>` | Create a technical design document with architecture, API contracts, and data models |
| `/tdd <module>` | Implement a module using strict TDD (tests FIRST, then implementation) |
| `/prd <file>` | Process a PRD into EARS requirements, design doc, and task breakdown |
| `/review-design` | Validate design document completeness and assess risk level |
| `/plan-sprint` | Generate atomic task breakdown with TDD task pairing |
| `/pre-review` | Run pre-submission validation (lint, tests, debug code detection) |
| `/status` | Show workflow progress, continuity health, gaps, and recommended next action |
| `/ux-spec <REQ-ID>` | Create UX specification with screens, states, and interactions |

## Agents

Invoke agents with `@agent-name` in your conversation:

| Agent | Role |
|-------|------|
| `@orchestrator` | Routes work between agents, manages continuity, prevents infinite loops |
| `@pm` | Owns EARS requirements, priorities, and acceptance criteria |
| `@planner` | Decomposes work into atomic tasks with TDD pairing |
| `@architect` | Creates design docs, API contracts, and architecture diagrams |
| `@ux` | Defines user flows, screens, states, and interactions |
| `@frontend` | Implements UI (AFTER tests exist) |
| `@backend` | Implements APIs and business logic (AFTER tests exist) |
| `@qa` | **Writes tests FIRST** - the TDD enforcer |
| `@overseer` | Governance, drift detection, risk assessment, and continuity health |

All agents are **continuity-aware** - they check ledgers before starting, warn about context thresholds, and produce handoff-ready summaries.

## Continuity System

### The Problem

Context compaction degrades agent quality. After 2-3 compactions, agents hallucinate context.

### The Solution

```
Work → Context fills → /save-state → /clear → Ledger auto-loads → Continue
```

### Context Thresholds

| Level | Action |
|-------|--------|
| **< 60%** | Normal work |
| **60-70%** | Plan handoff points |
| **70-80%** | Complete task, `/save-state`, `/clear` soon |
| **> 80%** | STOP - `/save-state` then `/clear` NOW |

### Hooks

| Hook | When | What It Does |
|------|------|--------------|
| **SessionStart** | `/clear`, startup | Loads ledger + latest handoff into context |
| **PreCompact** | Before compaction | Creates auto-handoff, blocks manual compact |
| **UserPromptSubmit** | Every message | Shows context warnings, skill hints |
| **PostToolUse** | After file edits | Tracks modified files |
| **SubagentStop** | Agent completes | Creates task handoff |

### Key Files

| File | Purpose |
|------|---------|
| `thoughts/ledgers/CONTINUITY_*.md` | Session state (survives `/clear`) |
| `thoughts/shared/handoffs/*.md` | Detailed session transfers |
| `thoughts/shared/plans/*.md` | Implementation plans |
| `traceability_matrix.json` | Requirement tracking |

## Workflow Example

```bash
# Start Claude with the plugin
claude

# Initialize project (first time)
> # Run init-project.sh externally first

# 1. Process a PRD into requirements and design
> /prd requirements/user-auth.md

# 2. Review the design for completeness
> /review-design

# 3. Generate sprint tasks with TDD pairing
> /plan-sprint

# 4. Create UX spec for a requirement
> /ux-spec REQ-001

# 5. Implement with TDD (tests first!)
> /tdd auth/login

# Context at 75% - save state before it degrades
> /save-state
> /clear

# Fresh context, ledger auto-loaded - continue
> /status
> /tdd auth/validation

# 6. Pre-submission checks before PR
> /pre-review

# End of session
> /handoff
```

## Core Principles

### 1. Design First

No implementation begins without a design document in `docs/design/`. The `/design` command creates architecture docs with:

- Problem statement and goals
- Architecture diagram (Mermaid)
- API contracts with examples
- Data model
- Security considerations
- Rollout plan

### 2. Test-Driven Development

The `@qa` agent **always writes tests before implementation**:

```
1. @qa writes tests → tests FAIL (RED)
2. @backend/@frontend implements → tests PASS (GREEN)  
3. Refactor → tests still PASS
```

The `/tdd` command enforces this workflow automatically.

### 3. Traceability

Everything links together via `traceability_matrix.json`:

```
REQ-001 (requirement)
  ├── docs/design/auth-design.md (architecture)
  ├── .design/REQ-001-ux.json (UX spec)
  ├── tasks: [T-001, T-002] (sprint tasks)
  ├── src/auth/login.py (code)
  └── tests/auth/test_login.py (tests)
```

### 4. Clear, Don't Compact

When context fills up, save state and `/clear` instead of letting compaction degrade your agents:

```
/save-state    # Updates ledger
/clear         # Fresh context
               # SessionStart hook loads ledger + handoff automatically
```

### 5. EARS Requirements

Requirements use the EARS (Easy Approach to Requirements Syntax) format:

| Type | Template |
|------|----------|
| Event-driven | `WHEN <trigger> THEN the system SHALL <response>.` |
| State-driven | `WHILE <state> the system SHALL <response>.` |
| Unconditional | `The system SHALL <response>.` |
| Optional | `WHERE <condition>, the system SHALL <response>.` |

## Directory Structure

```
claude_code_workflow/
├── plugin/
│   ├── .claude-plugin/
│   │   ├── plugin.json       # Plugin manifest
│   │   └── settings.json     # Hook registrations
│   ├── hooks/                # Lifecycle hooks
│   │   ├── session-start.sh
│   │   ├── pre-compact.sh
│   │   ├── user-prompt-submit.sh
│   │   ├── post-tool-use.sh
│   │   └── subagent-stop.sh
│   ├── scripts/
│   │   ├── init-project.sh   # Project initialization
│   │   └── status.sh         # Status line
│   ├── commands/             # Slash commands
│   │   ├── save-state.md     # NEW: Update ledger
│   │   ├── handoff.md        # NEW: Session transfer
│   │   ├── resume.md         # NEW: Load handoff
│   │   ├── design.md
│   │   ├── tdd.md
│   │   └── ...
│   ├── agents/               # Subagents (continuity-aware)
│   │   ├── orchestrator.md
│   │   ├── qa.md
│   │   └── ...
│   ├── skills/
│   │   └── faang-workflow/
│   │       └── SKILL.md
│   ├── tools/                # Python utilities
│   │   └── traceability_tools.py
│   └── schemas/              # JSON validation schemas
└── README.md
```

## Tools

Python utilities for validation and reporting:

```bash
# Initialize traceability matrix
python ~/.claude/plugins/claude_code_workflow/tools/traceability_tools.py init traceability_matrix.json

# Validate traceability
python ~/.claude/plugins/claude_code_workflow/tools/traceability_tools.py validate traceability_matrix.json

# Check for gaps (missing tests, design, etc.)
python ~/.claude/plugins/claude_code_workflow/tools/traceability_tools.py check-gaps traceability_matrix.json

# Get summary
python ~/.claude/plugins/claude_code_workflow/tools/traceability_tools.py summary traceability_matrix.json --markdown
```

## Customization

### Adding New Commands

Create a markdown file in `commands/`:

```markdown
---
description: Your command description here
---

# Command Title

Instructions for Claude...

Use $ARGUMENTS to capture user input.
```

### Adding New Agents

Create a markdown file in `agents/`:

```markdown
---
name: agent-name
description: What this agent does
tools: Read, Write, Bash, Grep, Glob
---

# Agent Title

You are the **Agent Name** - your role description.

## Responsibilities

1. First responsibility
2. Second responsibility

## Continuity Awareness

### Before Starting
1. Check thoughts/ledgers/CONTINUITY_*.md
2. Check thoughts/shared/handoffs/

### At Task Completion
Report to @orchestrator with handoff-ready summary.
```

### Modifying Hooks

Hooks are bash scripts in `hooks/`. They receive JSON on stdin and output JSON:

```bash
#!/bin/bash
INPUT=$(cat)
# Process input...
echo '{"continue": true}'
```

## Troubleshooting

### Commands not appearing in `/help`

1. Verify the alias is set:
   ```bash
   alias | grep claude
   ```

2. Check plugin structure:
   ```bash
   ls -la ~/.claude/plugins/claude_code_workflow/.claude-plugin/
   ```

### Hooks not running

1. Make them executable:
   ```bash
   chmod +x ~/.claude/plugins/claude_code_workflow/hooks/*.sh
   ```

2. Verify `jq` is installed:
   ```bash
   jq --version
   ```

### Ledger not loading after /clear

1. Verify ledger exists:
   ```bash
   ls thoughts/ledgers/CONTINUITY_*.md
   ```

2. Test hook manually:
   ```bash
   echo '{"source":"clear"}' | ./hooks/session-start.sh
   ```

## Known Issues

- **Plugin persistence bug**: Plugins installed via `/plugin install` don't persist between sessions. Use the alias workaround.
- **Hook latency**: Some hooks (especially SessionEnd) may add 1-3 seconds as they finalize state.

## Contributing

1. Fork this repository
2. Create a feature branch
3. Make your changes
4. Test with `claude --plugin-dir /path/to/your/fork/plugin`
5. Submit a pull request

## License

MIT License - see [LICENSE](LICENSE) for details.

## Acknowledgments

- [Continuous-Claude-v2](https://github.com/parcadei/Continuous-Claude-v2) - Continuity patterns and inspiration
- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) by Anthropic
- FAANG engineering practices
- [EARS requirements methodology](https://alistairmavin.com/ears/)
