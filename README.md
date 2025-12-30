# Claude Code Workflow

**FAANG-style TDD workflow + Session continuity + Auto-invoked skills = Agents that don't degrade.**

A Claude Code plugin that enforces enterprise-grade, test-driven development through a coordinated multi-agent team, with session continuity to prevent context degradation.

[![Version](https://img.shields.io/badge/version-2.1.0-blue.svg)](https://github.com/blevene/claude_code_workflow)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

---

## Table of Contents

- [What This Does](#what-this-does)
- [The Problem This Solves](#the-problem-this-solves)
- [Core Principles](#core-principles)
- [Quick Start](#quick-start)
- [Workflow Example](#workflow-example)
- [Commands](#commands)
- [Agents](#agents)
- [Skills](#skills)
- [Continuity System](#continuity-system)
- [Python Environment](#python-environment)
- [Tools](#tools)
- [Directory Structure](#directory-structure)
- [Customization](#customization)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)

---

## What This Does

This plugin adds to Claude Code:

| Component | Count | Purpose |
|-----------|-------|---------|
| **Agents** | 9 | Specialized AI team members (@qa, @backend, @architect, etc.) |
| **Skills** | 9 | Auto-invoked expertise (debugging, code review, security, etc.) |
| **Commands** | 13 | Slash commands for workflow phases |
| **Hooks** | 5 | Lifecycle automation (continuity, context warnings) |

### What It Enforces

- ✅ **Design-first development** - No code without architecture docs
- ✅ **Test-driven development (TDD)** - Tests written BEFORE implementation  
- ✅ **Full traceability** - Requirements → Design → Code → Tests all linked
- ✅ **Governance checkpoints** - Risk assessment at each phase
- ✅ **Session continuity** - Ledgers and handoffs prevent agent degradation
- ✅ **Python environment** - Always uses `uv run` for consistent execution

---

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

---

## Core Principles

### 1. Design First

No implementation without a design document in `docs/design/`. The workflow blocks coding until architecture is defined.

### 2. Test-Driven Development

```
1. @qa writes tests → tests FAIL (RED)
2. @backend/@frontend implements → tests PASS (GREEN)  
3. Refactor → tests still PASS
```

### 3. Full Traceability

Everything links via `traceability_matrix.json`:

```
REQ-001 (requirement)
  ├── docs/design/auth-design.md (architecture)
  ├── .design/REQ-001-ux.json (UX spec)
  ├── tasks: [T-001, T-002] (sprint tasks)
  ├── src/auth/login.py (code)
  └── tests/auth/test_login.py (tests)
```

### 4. Clear, Don't Compact

```
/save-state    # Updates ledger
/clear         # Fresh context
               # SessionStart hook loads ledger + handoff automatically
```

### 5. EARS Requirements

| Type | Template |
|------|----------|
| Event-driven | `WHEN <trigger> THEN the system SHALL <response>.` |
| State-driven | `WHILE <state> the system SHALL <response>.` |
| Unconditional | `The system SHALL <response>.` |
| Optional | `WHERE <condition>, the system SHALL <response>.` |

---

## Quick Start

### Prerequisites

- [Claude Code](https://code.claude.com/docs) installed
- macOS, Linux, or WSL
- `jq` installed (`brew install jq` or `apt install jq`)
- `uv` installed (`curl -LsSf https://astral.sh/uv/install.sh | sh`)

### Installation

**1. Clone this repository:**

```bash
git clone https://github.com/blevene/claude_code_workflow.git
cd claude_code_workflow
```

**2. Make hooks executable:**

```bash
chmod +x plugin/hooks/*.sh
chmod +x plugin/scripts/*.sh
```

**3. Install the plugin (choose one method):**

#### Option A: Permanent Install (Recommended)

Copy the plugin to Claude's plugin directory:

```bash
# Create plugins directory if it doesn't exist
mkdir -p ~/.claude/plugins

# Copy plugin
cp -r plugin ~/.claude/plugins/claude-code-workflow

# Now just run claude normally - plugin loads automatically
claude
```

Or use a symlink (easier to update via git pull):

```bash
mkdir -p ~/.claude/plugins
ln -s "$(pwd)/plugin" ~/.claude/plugins/claude-code-workflow
```

#### Option B: Per-Session (for testing/development)

```bash
claude --plugin-dir ./plugin
```

Or create a shell alias:

```bash
# Add to ~/.zshrc or ~/.bashrc
alias claude-faang='claude --plugin-dir /path/to/claude_code_workflow/plugin'
```

**4. Verify installation:**

Type `/help` - you should see commands under the `claude-code-workflow` namespace.

### Initialize a Project

From within Claude Code (after running with `--plugin-dir`):

```bash
/init
```

Or directly from shell:

```bash
/path/to/claude_code_workflow/plugin/scripts/init-project.sh
```

This creates:

| Directory/File | Purpose |
|----------------|---------|
| `thoughts/ledgers/` | Continuity ledgers (survives `/clear`) |
| `thoughts/shared/handoffs/` | Session handoffs |
| `thoughts/shared/plans/` | Implementation plans |
| `traceability_matrix.json` | Requirement tracking |
| `.venv/` | Python virtual environment (via uv) |
| `pyproject.toml` | Python project configuration |

---

## Workflow Example

Here's a typical session using the FAANG workflow:

```bash
# Start Claude (if installed permanently, just run 'claude')
claude

# 0. Initialize project (first time only)
> /init

# 1. Process a PRD into requirements, design, and tasks
> /prd requirements/user-auth.md

# 2. Review the design for completeness
> /review-design

# 3. (Optional) Create UX spec for UI features
> /ux-spec REQ-001

# 4. Implement with TDD (tests first!)
> /tdd auth/login

# Context at 75% - save state before it degrades
> /save-state
> /clear

# Fresh context, ledger auto-loaded - continue
> /status
> /tdd auth/validation

# 5. Pre-submission checks before PR
> /pre-review

# End of session
> /handoff
```

**Note:** `/prd` creates tasks automatically, so `/plan-sprint` is only needed after `/design` (when you don't have a PRD).

### Workflow Phases

**With PRD (recommended):**
```
/prd ──→ /review-design ──→ [/ux-spec] ──→ /tdd ──→ /pre-review
  │                             │
  └─ creates tasks too          └─ optional (UI features only)
```

**Without PRD:**
```
/design ──→ /review-design ──→ /plan-sprint ──→ [/ux-spec] ──→ /tdd ──→ /pre-review
                                    │               │
                                    └─ required     └─ optional
```

**Backend-only (no UI):**
```
/prd ──→ /review-design ──→ /tdd ──→ /pre-review
```

---

## Commands

### Continuity Commands

| Command | Description |
|---------|-------------|
| `/save-state` | Update continuity ledger before `/clear` |
| `/handoff` | Create detailed session handoff for later |
| `/resume` | Load and review latest handoff |
| `/status` | Show workflow progress and health |

### Workflow Commands

| Command | Description |
|---------|-------------|
| `/init` | Initialize project directories, venv, and config |
| `/prd <file>` | Process PRD into EARS requirements + design + tasks |
| `/design <feature>` | Create design document (when no PRD exists) |
| `/review-design` | Validate design completeness and risk |
| `/plan-sprint` | Generate tasks (use after `/design`, not `/prd`) |
| `/ux-spec <REQ-ID>` | Create UX specification *(optional, for UI features)* |
| `/tdd <module>` | Implement with strict TDD (tests FIRST) |
| `/pre-review` | Pre-submission validation |
| `/test` | Verify plugin is working correctly |

---

## Agents

Nine specialized agents that Claude can delegate work to:

| Agent | Role | When Used |
|-------|------|-----------|
| `@orchestrator` | Routes work, manages continuity, prevents loops | Multi-agent workflows |
| `@pm` | EARS requirements, priorities, acceptance criteria | Project start |
| `@planner` | Task breakdown, dependencies, sprint planning | After design review |
| `@architect` | Design docs, API contracts, architecture | Before implementation |
| `@ux` | User flows, screens, states, interactions | Before frontend work |
| `@frontend` | UI implementation (AFTER tests exist) | UI development |
| `@backend` | APIs and business logic (AFTER tests exist) | Server-side work |
| `@qa` | **Writes tests FIRST** - TDD enforcer | Before any implementation |
| `@overseer` | Governance, risk assessment, drift detection | Reviews, pre-release |

### Agent Features

All agents:
- Are **continuity-aware** (check ledgers, warn about context)
- Use `model: inherit` for consistent behavior
- Include "MUST BE USED" triggers for auto-delegation
- Report handoff-ready summaries to @orchestrator

---

## Skills

Nine auto-invoked skills that Claude uses based on context:

| Skill | Auto-Triggers When |
|-------|-------------------|
| `faang-workflow` | Production features, PRDs, TDD, sprint planning |
| `code-review` | PR reviews, code quality checks, assessing changes |
| `debugging` | Fixing bugs, investigating errors, test failures |
| `git-workflow` | Committing, creating PRs, branch management |
| `refactoring` | Restructuring code, reducing duplication |
| `api-design` | Designing endpoints, API contracts |
| `security-review` | Security audits, vulnerability checks |
| `documentation` | Writing docs, READMEs, docstrings |
| `database` | Schema changes, migrations, queries |

### How Skills Work

Claude automatically invokes skills based on your request:

| You Say | Claude Uses |
|---------|-------------|
| "Review this PR" | `code-review` |
| "Fix this failing test" | `debugging` |
| "Commit these changes" | `git-workflow` |
| "Clean up this code" | `refactoring` |
| "Design the user API" | `api-design` |
| "Check for security issues" | `security-review` |
| "Document this function" | `documentation` |
| "Add a new database column" | `database` |

---

## Continuity System

### How It Works

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
| **SessionStart** | `/clear`, startup | Loads ledger + handoff + Python env check |
| **PreCompact** | Before compaction | Creates auto-handoff, blocks manual compact |
| **UserPromptSubmit** | Every message | Context warnings, skill hints |
| **PostToolUse** | After file edits | Tracks modified files |
| **SubagentStop** | Agent completes | Creates task handoff |

### Key Files

| File | Purpose |
|------|---------|
| `thoughts/ledgers/CONTINUITY_*.md` | Session state (survives `/clear`) |
| `thoughts/shared/handoffs/*.md` | Detailed session transfers |
| `thoughts/shared/plans/*.md` | Implementation plans |
| `traceability_matrix.json` | Requirement tracking |

---

## Python Environment

> **CRITICAL:** This workflow enforces `uv` for all Python execution.

### The Rule

```bash
# ✅ CORRECT - Always use uv run
uv run pytest tests/ -v
uv run python script.py

# ❌ WRONG - Never run directly  
pytest tests/           
python script.py
```

### Common Commands

```bash
# Create virtual environment
uv venv

# Sync dependencies
uv sync

# Add packages
uv add pytest requests

# Run tests
uv run pytest tests/ -v

# Run Python scripts
uv run python tools/traceability_tools.py check-gaps traceability_matrix.json
```

---

## Tools

Python utilities for validation and reporting:

```bash
# Traceability management
uv run python tools/traceability_tools.py init traceability_matrix.json
uv run python tools/traceability_tools.py validate traceability_matrix.json
uv run python tools/traceability_tools.py check-gaps traceability_matrix.json
uv run python tools/traceability_tools.py summary traceability_matrix.json --markdown

# Test runner with summary
uv run python tools/run_tests_summarized.py --cmd "uv run pytest tests/" --tail 40

# Plan validation
uv run python tools/planner_tools.py validate planner_output.json
```

---

## Directory Structure

```
claude_code_workflow/
├── plugin/
│   ├── .claude-plugin/
│   │   ├── plugin.json          # Plugin manifest
│   │   └── settings.json        # Status line config
│   │
│   ├── agents/                   # 9 specialized agents
│   │   ├── orchestrator.md      # Routes work, prevents loops
│   │   ├── pm.md                # Requirements owner
│   │   ├── planner.md           # Task breakdown
│   │   ├── architect.md         # Design & contracts
│   │   ├── ux.md                # User flows
│   │   ├── frontend.md          # UI implementation
│   │   ├── backend.md           # API implementation
│   │   ├── qa.md                # TDD test writer
│   │   └── overseer.md          # Governance & risk
│   │
│   ├── commands/                 # 13 slash commands
│   │   ├── init.md              # Project initialization
│   │   ├── save-state.md        # Update ledger
│   │   ├── handoff.md           # Session transfer
│   │   ├── resume.md            # Load handoff
│   │   ├── status.md            # Workflow health
│   │   ├── prd.md               # Process PRD
│   │   ├── design.md            # Create design doc
│   │   ├── review-design.md     # Validate design
│   │   ├── plan-sprint.md       # Task breakdown
│   │   ├── ux-spec.md           # UX specification (optional)
│   │   ├── tdd.md               # TDD implementation
│   │   ├── pre-review.md        # Pre-submission check
│   │   └── test.md              # Plugin health check
│   │
│   ├── skills/                   # 9 auto-invoked skills
│   │   ├── faang-workflow/      # Main orchestration
│   │   ├── code-review/         # PR & quality review
│   │   ├── debugging/           # Bug investigation
│   │   ├── git-workflow/        # Commits & PRs
│   │   ├── refactoring/         # Code restructuring
│   │   ├── api-design/          # REST/GraphQL patterns
│   │   ├── security-review/     # Vulnerability checks
│   │   ├── documentation/       # Docs & docstrings
│   │   └── database/            # Schema & migrations
│   │
│   ├── hooks/                    # 5 lifecycle hooks
│   │   ├── hooks.json           # Hook configuration
│   │   ├── session-start.sh     # Load continuity state
│   │   ├── pre-compact.sh       # Auto-handoff
│   │   ├── user-prompt-submit.sh # Context warnings
│   │   ├── post-tool-use.sh     # Track file changes
│   │   └── subagent-stop.sh     # Task handoffs
│   │
│   ├── scripts/
│   │   ├── init-project.sh      # Project setup
│   │   └── status.sh            # Status line
│   │
│   ├── tools/                    # Python utilities
│   │   ├── traceability_tools.py
│   │   ├── planner_tools.py
│   │   ├── run_tests_summarized.py
│   │   ├── repo_map.py
│   │   └── ...
│   │
│   └── schemas/
│       ├── planner_task_schema.json
│       └── traceability_matrix_schema.json
│
├── README.md
└── LICENSE
```

---

## Customization

### Adding Commands

Create `plugin/commands/my-command.md`:

```markdown
---
description: What this command does
---

# My Command

Instructions for Claude...

Use $ARGUMENTS to capture user input.
```

### Adding Agents

Create `plugin/agents/my-agent.md`:

```markdown
---
name: my-agent
description: What this agent does. Use PROACTIVELY when [trigger]. MUST BE USED for [requirement].
tools: Read, Write, Bash, Grep, Glob
model: inherit
---

# My Agent

You are the **My Agent** - your role description.

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

### Adding Skills

Create `plugin/skills/my-skill/SKILL.md`:

```markdown
---
name: my-skill
description: What this skill does. Auto-triggers for [contexts].
---

# My Skill

## When to Use

- Context 1
- Context 2

## Methodology

Step-by-step instructions...
```

---

## Troubleshooting

### Commands not appearing

```bash
# If using permanent install, check plugin exists
ls ~/.claude/plugins/claude-code-workflow

# If using --plugin-dir, verify path is correct
claude --plugin-dir /path/to/plugin

# Type /help and look for claude-code-workflow namespace
```

### Hooks not running

   ```bash
# Make executable
chmod +x plugin/hooks/*.sh

# Verify jq
jq --version

# Test manually
echo '{"source":"startup"}' | plugin/hooks/session-start.sh
```

### Python environment issues

   ```bash
# Verify uv
uv --version

# Recreate environment
rm -rf .venv
uv venv
uv sync

# Test
uv run pytest --version
   ```

### Ledger not loading after /clear

   ```bash
# Verify ledger exists
   ls thoughts/ledgers/CONTINUITY_*.md

# Test hook manually
echo '{"source":"clear"}' | plugin/hooks/session-start.sh
   ```

---

## Contributing

1. Fork this repository
2. Create a feature branch
3. Make your changes
4. Test with `claude --plugin-dir /path/to/your/fork/plugin` (or symlink to `~/.claude/plugins/`)
5. Submit a pull request

---

## Known Issues

- **Hook latency**: Some hooks may add 1-3 seconds as they process state
- **Large ledgers**: Very long sessions may create large ledger files

---

## License

MIT License - see [LICENSE](LICENSE) for details.

---

## Acknowledgments

- [Continuous-Claude-v2](https://github.com/parcadei/Continuous-Claude-v2) - Continuity patterns
- [Claude Code](https://code.claude.com/docs) by Anthropic
- [EARS methodology](https://alistairmavin.com/ears/) for requirements
- FAANG engineering practices
