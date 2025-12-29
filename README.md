# Claude Code Workflow

A Claude Code configuration that enforces enterprise-grade, test-driven development through a coordinated multi-agent team. Built for teams that want FAANG-level engineering discipline without the bureaucracy.

## What This Does

This plugin adds **9 specialized AI agents** and **8 slash commands** to Claude Code that enforce:

- **Design-first development** - No code without architecture docs
- **Test-driven development (TDD)** - Tests written BEFORE implementation
- **Full traceability** - Requirements → Design → Code → Tests all linked
- **Governance checkpoints** - Risk assessment at each phase

## Quick Start

### Prerequisites

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) v2.0+ installed
- macOS, Linux, or WSL

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

**3. Create a shell alias (required for persistence):**

Add this line to your `~/.zshrc` (or `~/.bashrc` for bash):

```bash
alias claude='claude --plugin-dir ~/.claude/plugins/claude_code_workflow'
```

**4. Reload your shell:**

```bash
source ~/.zshrc
```

**5. Verify installation:**

```bash
claude
```

Then type `/help` - you should see the claude_code_workflow commands listed.

> **Why the alias?** There's a [known bug](https://github.com/anthropics/claude-code/issues/12457) in Claude Code v2.x where locally installed plugins don't persist between sessions. The alias ensures your plugin loads every time.

## Commands

| Command | Description |
|---------|-------------|
| `/design <feature>` | Create a technical design document with architecture, API contracts, and data models |
| `/tdd <module>` | Implement a module using strict TDD (tests FIRST, then implementation) |
| `/prd <file>` | Process a PRD into EARS requirements, design doc, and task breakdown |
| `/review-design` | Validate design document completeness and assess risk level |
| `/plan-sprint` | Generate atomic task breakdown with TDD task pairing |
| `/pre-review` | Run pre-submission validation (lint, tests, debug code detection) |
| `/status` | Show workflow progress, gaps, and recommended next action |
| `/ux-spec <REQ-ID>` | Create UX specification with screens, states, and interactions |

## Agents

Invoke agents with `@agent-name` in your conversation:

| Agent | Role |
|-------|------|
| `@orchestrator` | Routes work between agents, prevents infinite loops, enforces phase gates |
| `@pm` | Owns EARS requirements, priorities, and acceptance criteria |
| `@planner` | Decomposes work into atomic tasks with TDD pairing |
| `@architect` | Creates design docs, API contracts, and architecture diagrams |
| `@ux` | Defines user flows, screens, states, and interactions |
| `@frontend` | Implements UI (AFTER tests exist) |
| `@backend` | Implements APIs and business logic (AFTER tests exist) |
| `@qa` | **Writes tests FIRST** - the TDD enforcer |
| `@overseer` | Governance, drift detection, and risk assessment |

## Workflow Example

```bash
# Start Claude with the plugin
claude

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

# 6. Pre-submission checks before PR
> /pre-review

# 7. Check overall status anytime
> /status
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

### 4. EARS Requirements

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
├── .claude-plugin/
│   └── plugin.json          # Plugin manifest (required)
├── commands/                 # Slash commands
│   ├── design.md
│   ├── tdd.md
│   ├── prd.md
│   ├── review-design.md
│   ├── plan-sprint.md
│   ├── pre-review.md
│   ├── status.md
│   └── ux-spec.md
├── agents/                   # Subagents
│   ├── orchestrator.md
│   ├── pm.md
│   ├── planner.md
│   ├── architect.md
│   ├── ux.md
│   ├── frontend.md
│   ├── backend.md
│   ├── qa.md
│   └── overseer.md
├── skills/                   # Auto-triggered skills
│   └── claude_code_workflow/
│       └── SKILL.md
├── tools/                    # Python utilities
│   ├── traceability_tools.py
│   ├── planner_tools.py
│   └── ...
├── schemas/                  # JSON validation schemas
│   ├── traceability_matrix_schema.json
│   └── planner_task_schema.json
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

## How You Work

Details on how this agent operates...
```

### Modifying Existing Commands/Agents

Simply edit the markdown files. Changes take effect on the next Claude Code session.

## Troubleshooting

### Commands not appearing in `/help`

1. Verify the alias is set:
   ```bash
   alias | grep claude
   ```

2. Make sure you're using the alias (not running `claude` directly from another path)

3. Check plugin structure:
   ```bash
   ls -la ~/.claude/plugins/claude_code_workflow/.claude-plugin/
   # Should show plugin.json
   ```

### "Unknown slash command" error

The plugin isn't loading. Try:

```bash
claude --plugin-dir ~/.claude/plugins/claude_code_workflow
```

If that works, your alias isn't set correctly.

### Agents not responding to @mentions

1. Check `/agents` to see if they're listed
2. Verify agent files have correct frontmatter with `name:` field

### Plugin loads but commands fail

Check the command markdown files have the required frontmatter:

```markdown
---
description: This field is required
---
```

## Known Issues

- **Plugin persistence bug**: Plugins installed via `/plugin install` don't persist between sessions. Use the alias workaround.
- **Slash command discovery**: Some versions of Claude Code v2.x have issues discovering commands from `.claude/commands/`. The plugin approach works around this.

## Contributing

1. Fork this repository
2. Create a feature branch
3. Make your changes
4. Test with `claude --plugin-dir /path/to/your/fork`
5. Submit a pull request

## License

MIT License - see [LICENSE](LICENSE) for details.

## Acknowledgments

- Built for use with [Claude Code](https://docs.anthropic.com/en/docs/claude-code) by Anthropic
- Inspired by FAANG engineering practices and the [EARS requirements methodology](https://alistairmavin.com/ears/)
