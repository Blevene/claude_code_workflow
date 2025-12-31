# Claude Code Workflow

**Enterprise-grade development workflows + Session continuity + Auto-invoked skills = Agents that don't degrade.**

A Claude Code plugin system that enforces disciplined development through coordinated multi-agent teams, with session continuity to prevent context degradation.

[![Version](https://img.shields.io/badge/version-2.1.0-blue.svg)](https://github.com/blevene/claude_code_workflow)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

---

## Two Plugins Available

| Plugin | Paradigm | Key Agent | Best For |
|--------|----------|-----------|----------|
| **`plugin-tdd/`** | Test-Driven Development | `@qa` writes tests first | Traditional testing workflows |
| **`plugin-sdd/`** | Spec-Driven Development | `@spec-writer` writes specs + evals first | Behavioral specifications |

**Recommendation:** Use `plugin-sdd/` for new projects. It emphasizes behavioral specifications and meaningful evals that validate *what* the system does, not *how* it does it.

---

## Table of Contents

- [The Problem This Solves](#the-problem-this-solves)
- [Core Principles (Shared)](#core-principles-shared)
- [Quick Start](#quick-start)
- [Plugin: TDD (plugin-tdd)](#plugin-tdd-plugin-tdd)
- [Plugin: SDD (plugin-sdd)](#plugin-sdd-plugin-sdd)
- [Continuity System](#continuity-system)
- [Python Environment](#python-environment)
- [Customization](#customization)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)

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

## Core Principles (Shared)

Both plugins share these principles:

### 1. Design First

No implementation without a design document in `docs/design/`. The workflow blocks coding until architecture is defined.

### 2. Full Traceability

Everything links via `traceability_matrix.json`:

```
REQ-001 (requirement)
  ├── docs/design/auth-design.md (architecture)
  ├── .design/REQ-001-ux.json (UX spec)
  ├── tasks: [T-001, T-002] (sprint tasks)
  ├── src/auth/login.py (code)
  └── specs/ or tests/ (validation)
```

### 3. Clear, Don't Compact

```
/save-state    # Updates ledger
/clear         # Fresh context
               # SessionStart hook loads ledger + handoff automatically
```

### 4. EARS Requirements

| Type | Template |
|------|----------|
| Event-driven | `WHEN <trigger> THEN the system SHALL <response>.` |
| State-driven | `WHILE <state> the system SHALL <response>.` |
| Unconditional | `The system SHALL <response>.` |
| Optional | `WHERE <condition>, the system SHALL <response>.` |

### 5. Python Environment

Always use `uv run` for Python execution - never run `python` or `pytest` directly.

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

**2. Choose your plugin and make hooks executable:**

```bash
# For SDD (recommended)
chmod +x plugin-sdd/hooks/*.sh
chmod +x plugin-sdd/scripts/*.sh

# For TDD
chmod +x plugin-tdd/hooks/*.sh
chmod +x plugin-tdd/scripts/*.sh
```

**3. Install the plugin (choose one method):**

#### Option A: Permanent Install (Recommended)

```bash
mkdir -p ~/.claude/plugins

# For SDD (recommended)
ln -s "$(pwd)/plugin-sdd" ~/.claude/plugins/claude-code-workflow

# OR for TDD
ln -s "$(pwd)/plugin-tdd" ~/.claude/plugins/claude-code-workflow
```

#### Option B: Per-Session

```bash
# For SDD
claude --plugin-dir ./plugin-sdd

# For TDD
claude --plugin-dir ./plugin-tdd
```

**4. Verify installation:**

Type `/help` - you should see commands under the `claude-code-workflow` namespace.

**5. Initialize a project:**

```bash
/init
```

---

## Plugin: TDD (plugin-tdd)

### Philosophy

Test-Driven Development: Write tests BEFORE implementation.

```
1. @qa writes tests → tests FAIL (RED)
2. @backend/@frontend implements → tests PASS (GREEN)
3. Refactor → tests still PASS
```

### What It Enforces

- ✅ **Design-first development** - No code without architecture docs
- ✅ **Test-driven development** - Tests written BEFORE implementation
- ✅ **Full traceability** - Requirements → Design → Code → Tests all linked
- ✅ **Governance checkpoints** - Risk assessment at each phase
- ✅ **Session continuity** - Ledgers and handoffs prevent agent degradation

### Components

| Component | Count | Purpose |
|-----------|-------|---------|
| **Agents** | 9 | @orchestrator, @pm, @planner, @architect, @ux, @frontend, @backend, **@qa**, @overseer |
| **Skills** | 9 | faang-workflow, code-review, debugging, git-workflow, refactoring, api-design, security-review, documentation, database |
| **Commands** | 13 | /init, /prd, /design, /review-design, /plan-sprint, /ux-spec, **/tdd**, /pre-review, /save-state, /handoff, /resume, /status, /test |
| **Hooks** | 5 | SessionStart, PreCompact, UserPromptSubmit, PostToolUse, SubagentStop |

### Workflow

```
/prd ──→ /review-design ──→ [/ux-spec] ──→ /tdd ──→ /pre-review
  │                             │
  └─ creates tasks              └─ optional (UI features only)
```

### Key Agent: @qa

The `@qa` agent writes pytest tests BEFORE any implementation:

```python
# tests/auth/test_login.py
class TestLogin:
    def test_valid_login_succeeds(self):
        """REQ-001: Test successful operation."""
        pytest.skip("Awaiting implementation")

    def test_invalid_password_fails(self):
        """REQ-001: Test validation."""
        pytest.skip("Awaiting implementation")
```

### Directory Structure

```
plugin-tdd/
├── .claude-plugin/
│   ├── plugin.json
│   └── settings.json
├── agents/
│   ├── orchestrator.md
│   ├── pm.md
│   ├── planner.md
│   ├── architect.md
│   ├── ux.md
│   ├── frontend.md
│   ├── backend.md
│   ├── qa.md              # TDD test writer
│   └── overseer.md
├── commands/
│   └── tdd.md             # TDD implementation command
├── skills/
│   └── faang-workflow/    # TDD workflow skill
├── hooks/
├── scripts/
├── tools/
│   └── run_tests_summarized.py
└── schemas/
```

---

## Plugin: SDD (plugin-sdd)

### Philosophy

Spec-Driven Development: Write behavioral specs and evals BEFORE implementation.

```
1. @spec-writer writes specs → defines expected behavior
2. @spec-writer creates evals → validation criteria
3. @backend/@frontend implements → code written to spec
4. Evals run → validate implementation matches spec
```

### Testing Philosophy

**Specs and evals encode requirements, not code structure.** They are contracts between human intent and machine implementation—they verify *what* the system does, not *how* it does it.

**The Litmus Test:** *"Could I completely rewrite the implementation using a different algorithm, and would these evals still pass?"* If yes, you've specified behavior. If no, you've coupled to implementation—rewrite the spec.

### What It Enforces

- ✅ **Design-first development** - No code without architecture docs
- ✅ **Spec-driven development** - Specs written BEFORE implementation
- ✅ **Behavioral validation** - Evals test behavior, not implementation
- ✅ **Full traceability** - Requirements → Design → Specs → Evals → Code
- ✅ **Governance checkpoints** - Risk assessment + sprint evaluation
- ✅ **Session continuity** - Ledgers and handoffs prevent agent degradation

### Components

| Component | Count | Purpose |
|-----------|-------|---------|
| **Agents** | 9 | @orchestrator, @pm, @planner, @architect, @ux, @frontend, @backend, **@spec-writer**, @overseer |
| **Skills** | 9 | sdd-workflow, code-review, debugging, git-workflow, refactoring, api-design, security-review, documentation, database |
| **Commands** | 14 | /init, /prd, /design, /review-design, /plan-sprint, /ux-spec, **/sdd**, **/spec**, **/eval**, /pre-review, /save-state, /handoff, /resume, /status |
| **Hooks** | 5 | SessionStart, PreCompact, UserPromptSubmit, PostToolUse, SubagentStop |
| **Schemas** | 4 | traceability_matrix, planner_task, **spec_schema**, **eval_result_schema** |

### Workflow

```
/prd ──→ /review-design ──→ [/ux-spec] ──→ /spec ──→ /sdd ──→ /eval ──→ /pre-review
  │                             │            │
  └─ creates tasks              │            └─ creates behavioral specs
                                └─ optional (UI features only)
```

### Key Agent: @spec-writer

The `@spec-writer` agent writes behavioral specs and evals BEFORE any implementation:

**Spec File (specs/auth/SPEC-001.md):**
```markdown
# SPEC-001: User Login

## Behavioral Specification

### Expected Behavior
1. WHEN valid credentials provided THEN session created
2. WHEN invalid password THEN generic error returned (no detail leak)
3. WHEN 5 failed attempts THEN account temporarily locked

## Eval Criteria
- [ ] Happy path produces expected output
- [ ] Error cases return appropriate errors
- [ ] Edge cases handled correctly
```

**Eval File (evals/auth/eval_spec_001.py):**
```python
@dataclass
class EvalResult:
    passed: bool
    spec_id: str
    description: str
    expected: Any
    actual: Any = None
    error: str = None

class SpecEval:
    spec_id = "SPEC-001"

    def eval_valid_login_succeeds(self) -> EvalResult:
        """Eval: Valid credentials create session."""
        # Given/When/Then behavioral test
        ...
```

### Key Commands

| Command | Description |
|---------|-------------|
| `/spec <REQ-ID>` | Create behavioral specification for requirement |
| `/sdd <module>` | Implement module to match specs |
| `/eval <module>` | Run evals to validate implementation |

### Directory Structure

```
plugin-sdd/
├── .claude-plugin/
│   ├── plugin.json
│   └── settings.json
├── agents/
│   ├── orchestrator.md
│   ├── pm.md
│   ├── planner.md
│   ├── architect.md
│   ├── ux.md
│   ├── frontend.md
│   ├── backend.md
│   ├── spec-writer.md     # SDD spec/eval writer
│   └── overseer.md        # Enhanced with sprint evaluation
├── commands/
│   ├── sdd.md             # SDD implementation command
│   ├── spec.md            # Create behavioral spec
│   └── eval.md            # Run evals
├── skills/
│   └── sdd-workflow/      # SDD workflow skill
├── hooks/
├── scripts/
├── tools/
│   └── run_evals.py       # Eval runner
└── schemas/
    ├── spec_schema.json
    └── eval_result_schema.json
```

### Sprint Evaluation (@overseer)

The `@overseer` agent in SDD evaluates completed sprints against PRD intent:

```markdown
## Sprint Evaluation: Sprint 1

### PRD Alignment Check
| PRD Goal | Delivered | Status |
|----------|-----------|--------|
| User login | Login flow implemented | ✓ aligned |
| Password reset | Not started | ✗ missed |

### Eval Summary
| Status | Count |
|--------|-------|
| All Passing | 5 |
| Partial | 1 |
| Failing | 0 |
```

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

> **IMPORTANT:** All `thoughts/` paths must be at the **project root**, never in subdirectories.

| File | Purpose |
|------|---------|
| `thoughts/ledgers/CONTINUITY_*.md` | Session state (survives `/clear`) |
| `thoughts/shared/handoffs/*.md` | Detailed session transfers |
| `thoughts/shared/plans/*.json` | Implementation plans |
| `traceability_matrix.json` | Requirement tracking |

---

## Python Environment

> **CRITICAL:** Both plugins enforce `uv` for all Python execution.

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

# Run tests (TDD)
uv run pytest tests/ -v

# Run evals (SDD)
uv run python tools/run_evals.py --all
```

---

## Customization

### Adding Commands

Create `plugin-{tdd,sdd}/commands/my-command.md`:

```markdown
---
description: What this command does
---

# My Command

Instructions for Claude...

Use $ARGUMENTS to capture user input.
```

### Adding Agents

Create `plugin-{tdd,sdd}/agents/my-agent.md`:

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

Create `plugin-{tdd,sdd}/skills/my-skill/SKILL.md`:

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
# Check plugin exists
ls ~/.claude/plugins/claude-code-workflow

# Or verify --plugin-dir path
claude --plugin-dir /path/to/plugin-sdd

# Type /help and look for claude-code-workflow namespace
```

### Hooks not running

```bash
# Make executable
chmod +x plugin-sdd/hooks/*.sh  # or plugin-tdd

# Verify jq
jq --version

# Test manually
echo '{"source":"startup"}' | plugin-sdd/hooks/session-start.sh
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
echo '{"source":"clear"}' | plugin-sdd/hooks/session-start.sh
```

---

## Contributing

1. Fork this repository
2. Create a feature branch
3. Make your changes
4. Test with `claude --plugin-dir /path/to/your/fork/plugin-sdd` (or plugin-tdd)
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
