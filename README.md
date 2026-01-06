# Claude Code Workflow

**Enterprise-grade development workflows + Session continuity + Auto-invoked skills = Agents that don't degrade.**

A Claude Code plugin system that enforces disciplined development through coordinated multi-agent teams, with session continuity to prevent context degradation.

[![Version](https://img.shields.io/badge/version-2.4.0-blue.svg)](https://github.com/blevene/claude_code_workflow)
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
- [Changelog](#changelog)

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

#### Option A: Automated Install Script (Recommended for SDD)

```bash
# Run the installer - copies all components to ~/.claude/
/bin/bash install-sdd.sh
```

This installs hooks, scripts, rules, skills, agents, commands, schemas, templates, guides, and tools to `~/.claude/`. Works globally for all projects.

#### Option B: Permanent Install (Symlink)

```bash
mkdir -p ~/.claude/plugins

# For SDD
ln -s "$(pwd)/plugin-sdd" ~/.claude/plugins/claude-code-workflow

# OR for TDD
ln -s "$(pwd)/plugin-tdd" ~/.claude/plugins/claude-code-workflow
```

#### Option C: Per-Session

```bash
# For SDD
claude --plugin-dir ./plugin-sdd

# For TDD
claude --plugin-dir ./plugin-tdd
```

#### Option D: Manual Global Hook Installation

For system-wide hooks that run for all projects:

```bash
# Create directories
mkdir -p ~/.claude/{hooks,skills,agents,commands,schemas,templates,guides}

# Copy SDD components
cp plugin-sdd/hooks/*.sh ~/.claude/hooks/
cp -r plugin-sdd/skills/* ~/.claude/skills/
cp -r plugin-sdd/agents/* ~/.claude/agents/
cp -r plugin-sdd/commands/* ~/.claude/commands/

# Make hooks executable
chmod +x ~/.claude/hooks/*.sh
```

Then add to `~/.claude/settings.json`:

```json
{
  "statusLine": {
    "type": "command",
    "command": "$HOME/.claude/scripts/status.sh"
  },
  "hooks": {
    "SessionStart": [{ "matcher": "startup|resume|compact|clear", "hooks": [{ "type": "command", "command": "$HOME/.claude/hooks/session-start.sh", "timeout": 30 }] }],
    "PreCompact": [{ "matcher": "auto|manual", "hooks": [{ "type": "command", "command": "$HOME/.claude/hooks/pre-compact.sh", "timeout": 30 }] }],
    "UserPromptSubmit": [{ "hooks": [{ "type": "command", "command": "$HOME/.claude/hooks/user-prompt-submit.sh", "timeout": 10 }] }],
    "PostToolUse": [{ "matcher": "Edit|Write|MultiEdit|Bash|str_replace_editor", "hooks": [{ "type": "command", "command": "$HOME/.claude/hooks/post-tool-use.sh", "timeout": 10 }] }],
    "SubagentStop": [{ "hooks": [{ "type": "command", "command": "$HOME/.claude/hooks/subagent-stop.sh", "timeout": 15 }] }],
    "Stop": [{ "hooks": [{ "type": "command", "command": "$HOME/.claude/hooks/stop.sh", "timeout": 10 }] }],
    "SessionEnd": [{ "hooks": [{ "type": "command", "command": "$HOME/.claude/hooks/session-end.sh", "timeout": 15 }] }]
  }
}
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
| **Skills** | 14 | sdd-workflow, code-review, debugging, git-workflow, refactoring, api-design, security-review, documentation, database, onboarding, recall-reasoning, validate-implementation, validate-hooks, **parallel-agents** |
| **Commands** | 19 | /init, /prd, /design, /review-design, /plan-sprint, /ux-spec, /spec, /implement, /eval, /debug, /pre-review, /save-state, /handoff, /resume, **/resume-full**, /status, /check, /commit, /describe-pr |
| **Hooks** | 8 | **PreToolUse** (security), SessionStart, PreCompact, UserPromptSubmit, PostToolUse, SubagentStop, SessionEnd, Stop |
| **Rules** | 4 | continuity, agent-orchestration, observe-before-editing, idempotent-operations |
| **Schemas** | 4 | traceability_matrix, planner_task, spec_schema, eval_result_schema |
| **Scripts** | 5 | init-project.sh, status.sh, **generate-reasoning.sh**, **aggregate-reasoning.sh**, **search-reasoning.sh** |

### Workflow

```
/prd ──→ /review-design ──→ [/ux-spec] ──→ /spec ──→ /implement ──→ /eval ──→ /pre-review
  │                             │            │                        │
  └─ creates tasks              │            └─ creates specs         └─ if fails: /debug
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
| `/implement <module>` | Implement module to match specs |
| `/eval <module>` | Run evals to validate implementation |
| `/debug <module>` | Structured debugging for failing evals |
| `/check` | Plugin health check |

### Directory Structure

```
plugin-sdd/
├── .claude-plugin/
│   ├── plugin.json
│   └── settings.json
├── agents/                 # 9 specialized agents
│   ├── orchestrator.md
│   ├── pm.md
│   ├── planner.md
│   ├── architect.md
│   ├── ux.md
│   ├── frontend.md
│   ├── backend.md
│   ├── spec-writer.md      # SDD spec/eval writer
│   └── overseer.md         # Governance + sprint evaluation
├── commands/               # Explicit workflow commands
│   ├── implement.md        # Build to match specs
│   ├── spec.md             # Create behavioral spec
│   ├── eval.md             # Run evals
│   ├── debug.md            # Structured debugging
│   └── check.md            # Plugin health check
├── skills/                 # Auto-triggering capabilities
│   ├── sdd-workflow/       # Workflow coordination
│   ├── debugging/          # Debug patterns (auto-triggers)
│   ├── onboarding/         # Brownfield repo adoption
│   ├── recall-reasoning/   # Search past work for precedent
│   ├── validate-implementation/ # Pre-implementation checks
│   ├── validate-hooks/     # Hook debugging workflow
│   └── skill-rules.json    # Priority-based activation rules
├── guides/                 # Reference documentation
│   └── python-environment.md
├── templates/              # Reusable code templates
│   ├── eval-template.py
│   └── eval-property-template.py
├── hooks/                  # Lifecycle hooks (7 events)
│   ├── hooks.json          # Hook configuration
│   ├── session-start.sh    # Loads ledger, prunes entries
│   ├── pre-compact.sh      # Auto-handoff before compaction
│   ├── user-prompt-submit.sh # Skill activation
│   ├── post-tool-use.sh    # Loop + build/test tracking
│   ├── subagent-stop.sh    # Task handoffs
│   ├── session-end.sh      # Cleanup old files
│   ├── stop.sh             # Session summary + prompt
│   └── update-ledger.sh    # Shared ledger update utility
├── rules/                  # Claude behavior rules (4 files)
│   ├── continuity.md       # Ledger format + multi-phase tracking
│   ├── agent-orchestration.md # When to use subagents
│   ├── observe-before-editing.md # Debug discipline
│   └── idempotent-operations.md # Safe retry patterns
├── scripts/
│   ├── status.sh           # Status line (context %, git, focus)
│   └── init-project.sh     # Project initialization
├── tools/
│   ├── run_evals.py        # Run eval scripts
│   ├── traceability_tools.py  # Matrix management
│   ├── planner_tools.py    # Validate plan JSON
│   ├── eval_coverage.py    # Verify specs have evals
│   ├── spec_linter.py      # Validate spec format
│   ├── artifact_index.py   # Build artifact search index
│   ├── artifact_query.py   # Search past work
│   └── artifact_schema.sql # SQLite schema for index
└── schemas/
```

### Tools

| Tool | Command | Purpose |
|------|---------|---------|
| `run_evals.py` | `uv run python tools/run_evals.py --all` | Execute all eval scripts |
| `traceability_tools.py` | `uv run python tools/traceability_tools.py check-gaps ...` | Manage traceability matrix |
| `planner_tools.py` | `uv run python tools/planner_tools.py validate ...` | Validate plan JSON files |
| `eval_coverage.py` | `uv run python tools/eval_coverage.py` | Verify every spec has evals |
| `spec_linter.py` | `uv run python tools/spec_linter.py` | Validate spec format |
| `artifact_index.py` | `uv run python tools/artifact_index.py --all` | Index handoffs, specs, plans for recall |
| `artifact_query.py` | `uv run python tools/artifact_query.py "<query>"` | Search past work for precedent |

### Rules (v2.3.0+)

Rules are markdown files that guide Claude's behavior. They're loaded automatically based on glob patterns in their frontmatter.

| Rule | Triggers On | Purpose |
|------|-------------|---------|
| **continuity.md** | `thoughts/ledgers/CONTINUITY_*.md` | Ledger format with multi-phase checkbox tracking |
| **agent-orchestration.md** | `**/*.md`, `**/*.py`, `**/*.ts` | When to spawn subagents vs work directly |
| **observe-before-editing.md** | `**/*` | Check outputs before editing code to fix bugs |
| **idempotent-operations.md** | `**/*.sh`, `**/*.py`, `hooks/**/*` | Make operations safe to repeat |

**Key concepts from rules:**

- **Multi-phase checkboxes:** Use `[x]`, `[→]`, `[ ]` in ledgers for tracking
- **UNCONFIRMED prefix:** Mark uncertain info that needs verification after `/clear`
- **Observe first:** Before fixing bugs, confirm what the system *actually produced*
- **Agents preserve context:** Spawn `@backend` for multi-file work instead of burning main context
- **Idempotent operations:** Check before writing, use atomic operations

### Brownfield Onboarding

For existing codebases, the `onboarding` skill auto-triggers when discussing:
- "I have an existing codebase..."
- "How do I add SDD to my project?"
- "Retrofitting specs to legacy code"

Key principle: **Don't boil the ocean.** Adopt SDD incrementally—full SDD for new features, gradual retrofit for critical existing code.

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

### Skill & Command Triggers

The SDD plugin uses two trigger mechanisms:

| Type | Mechanism | Example |
|------|-----------|---------|
| **Commands** | Explicit invocation | `/implement auth` - user requests implementation |
| **Skills** | Auto-trigger on context | `debugging` skill activates when discussing bugs |

**sdd-workflow skill auto-triggers for:**
- PRD processing and design document creation
- Spec-to-implementation cycles
- Multi-agent handoffs between phases
- Session continuity (`/save-state`, `/handoff`, `/resume`)

**debugging skill auto-triggers for:**
- Discussion of bugs or unexpected behavior
- Mentioning errors or exceptions
- Questions about why code doesn't match spec

**recall-reasoning skill auto-triggers for:**
- "What did we do last time?"
- "Have we done this before?"
- Looking for patterns from past work
- Before implementing something similar to past sessions

**validate-implementation skill auto-triggers for:**
- "Is this approach current?"
- Before implementing with unfamiliar libraries
- Checking tech choices against best practices
- Validating plans before implementation

**validate-hooks skill auto-triggers for:**
- "Hook isn't firing"
- "Why didn't my hook run?"
- Debugging hook-related issues
- After modifying hook scripts

**Use `/debug <module>` for explicit, structured debugging of a specific failing eval.**

---

## Plugin Architecture

### Component Interaction Diagram

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              USER INTERACTION                                │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│   ┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐             │
│   │  /prd    │───▶│ /review- │───▶│  /spec   │───▶│/implement│──┐          │
│   │          │    │  design  │    │          │    │          │  │          │
│   └──────────┘    └──────────┘    └──────────┘    └──────────┘  │          │
│                                                                  ▼          │
│   ┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐             │
│   │  /check  │    │  /debug  │◀───│  /eval   │◀───│   pass?  │             │
│   │ (health) │    │ (if fail)│    │          │    │          │             │
│   └──────────┘    └──────────┘    └──────────┘    └────┬─────┘             │
│                         │                              │ yes               │
│                         ▼                              ▼                   │
│                   ┌──────────┐                  ┌──────────┐               │
│                   │   fix    │─────────────────▶│/pre-review│              │
│                   └──────────┘                  └──────────┘               │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────┐
│                              AGENT COORDINATION                              │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│   ┌─────────────┐                                                           │
│   │@orchestrator│◀─────────────── Routes work, manages handoffs             │
│   └──────┬──────┘                                                           │
│          │                                                                  │
│   ┌──────┴──────────────────────────────────────────────────────┐          │
│   │                                                              │          │
│   ▼              ▼              ▼              ▼                ▼          │
│ ┌────┐        ┌────┐        ┌────┐        ┌────┐          ┌────────┐       │
│ │@pm │        │@planner│    │@architect│  │@spec-writer│  │@overseer│      │
│ └────┘        └────┘        └────┘        └────┘          └────────┘       │
│   │              │              │              │                │          │
│   │ requirements │ tasks        │ design       │ specs+evals    │ governance│
│   ▼              ▼              ▼              ▼                ▼          │
│ ┌────┐        ┌────┐        ┌────┐        ┌────────────┐                   │
│ │@ux │        │@frontend│   │@backend│   │   evals/   │                    │
│ └────┘        └────┘        └────┘        └────────────┘                   │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────┐
│                              SKILL AUTO-TRIGGERS                             │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  User message ──▶ Pattern matching ──▶ Skill activation                    │
│                                                                             │
│  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐         │
│  │  sdd-workflow   │    │    debugging    │    │   code-review   │         │
│  ├─────────────────┤    ├─────────────────┤    ├─────────────────┤         │
│  │ PRD processing  │    │ Bug discussion  │    │ PR review       │         │
│  │ Spec cycles     │    │ Error mentions  │    │ Code quality    │         │
│  │ Agent handoffs  │    │ Troubleshooting │    │ Best practices  │         │
│  │ /save-state     │    │                 │    │                 │         │
│  └─────────────────┘    └─────────────────┘    └─────────────────┘         │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────┐
│                              HOOK LIFECYCLE                                  │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  SessionStart ──▶ UserPromptSubmit ──▶ PostToolUse ──▶ SubagentStop        │
│       │                  │                  │               │               │
│       ▼                  ▼                  ▼               ▼               │
│  Load ledger       Context check      Track edits      Create handoff      │
│  Load handoff      Skill hints        Loop detection   Update ledger       │
│  Prune old entries Build/test track                                         │
│                                                                             │
│  PreCompact (before context compaction)                                     │
│       │                                                                     │
│       ▼                                                                     │
│  Auto-save state, warn about degradation                                    │
│                                                                             │
│  SessionEnd (after session completes)     Stop (main agent finishes)       │
│       │                                        │                            │
│       ▼                                        ▼                            │
│  Cleanup old cache files                  Session summary                   │
│  Remove stale handoffs                    Prompt for handoff                │
│  Update ledger timestamp                  Show test results                 │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Data Flow

```
requirements/     docs/design/      specs/           src/              evals/
    PRD    ──────▶  Design   ──────▶  SPEC-*  ──────▶  Code  ◀────────  eval_*
     │                │                 │               │                 │
     └────────────────┴─────────────────┴───────────────┴─────────────────┘
                                        │
                                        ▼
                              traceability_matrix.json
```

---

## Continuity System

### How It Works

```
Work → Context fills → /save-state → /clear → Ledger auto-loads → Continue
```

### Auto-Ledger Updates (v2.2.0+)

The continuity ledger is now **automatically updated** alongside handoffs:

| Trigger | What Happens |
|---------|--------------|
| **Subagent completes** | Task handoff created + ledger updated |
| **Context compaction** | Auto-handoff created + ledger updated |
| **`/handoff` command** | Session handoff created + ledger updated |

This ensures the ledger stays current without requiring explicit `/save-state` calls. The ledger provides a compact, cumulative state for quick context reload, while handoffs provide detailed snapshots for deep recovery.

### Context Monitoring (v2.3.0+)

The **status line** displays real-time context usage and current focus:

```
45.2K 32% | main U:3 | 📋2/4 | Phase 2/5: Implement auth
```

Components:
- **45.2K 32%** - Token usage and percentage (green/yellow/red based on level)
- **main U:3** - Git branch + unstaged file count
- **📋2/4** - Specs/evals count
- **Phase 2/5: ...** - Current focus from ledger

The status line writes context percentage to `/tmp/claude-context-pct-$SESSION_ID.txt` for hooks to read.

### Context Thresholds

| Level | Status Line Color | Action |
|-------|-------------------|--------|
| **< 60%** | 🟢 Green | Normal work |
| **60-80%** | 🟡 Yellow | Plan handoff points |
| **≥ 80%** | 🔴 Red + ⚠ | **STOP** - `/save-state` then `/clear` NOW |

### Hooks

| Hook | When | What It Does |
|------|------|--------------|
| **SessionStart** | `/clear`, startup, resume | Loads ledger + handoff (light on startup, full on resume), prunes old entries |
| **PreCompact** | Before compaction | Creates auto-handoff + ledger update, blocks manual compact |
| **UserPromptSubmit** | Every message | Context warnings, **priority-based skill activation** via `skill-rules.json` |
| **PostToolUse** | After file edits/reads | Tracks modified files, **loop detection**, **build/test tracking** |
| **SubagentStop** | Agent completes | Creates task handoff + ledger update |
| **SessionEnd** | Session completes | Cleanup old cache files (>7 days), remove stale handoffs (>30 days), update ledger |
| **Stop** | Main agent finishes | Session summary (files modified, test results), prompts for handoff/save-state |

### Loop Detection (v2.2.0+)

The PostToolUse hook now detects when agents are stuck in repetitive patterns:

| Threshold | Action |
|-----------|--------|
| 3 ops on same file | ⚠️ Warning injected into context |
| 5 ops on same file | 🚨 Operation blocked, agent must change approach |

**Common loop causes and fixes:**

| Symptom | Cause | Fix |
|---------|-------|-----|
| pytest collection error | All files named `test_spec_001.py` | Use unique names per module |
| `ModuleNotFoundError` | Missing `__init__.py` | Add `__init__.py` to package dirs |
| Import collision | Duplicate module names | Rename files to be unique |
| Same error after fix | Wrong file being modified | Check actual error source |

When agents detect they're stuck, they should escalate to `@orchestrator` with a structured report instead of retrying.

### Build/Test Tracking (v2.3.0+)

The PostToolUse hook tracks build and test outcomes automatically:

| Command Pattern | Tracked As |
|-----------------|------------|
| `npm test`, `npm run test` | test |
| `pytest`, `python -m pytest` | test |
| `cargo test` | test |
| `go test` | test |
| `uv run python tools/run_evals.py` | test |
| `npm run build`, `cargo build` | build |

Results are stored in `.claude/cache/session-*-builds.txt` and summarized in the **Stop** hook.

### Skill Activation Rules (v2.3.0+)

The UserPromptSubmit hook now uses `skill-rules.json` for intelligent, priority-based skill and agent activation:

```json
{
  "skills": [
    {
      "name": "debugging",
      "priority": "CRITICAL",
      "keywords": ["bug", "error", "failing", "broken"],
      "intents": ["fix", "debug", "troubleshoot"],
      "actions": ["Use /debug <module> for structured debugging"]
    }
  ],
  "agents": [
    {
      "name": "@spec-writer",
      "priority": "RECOMMENDED",
      "keywords": ["spec", "requirement", "behavior"],
      "intents": ["create spec", "define behavior"]
    }
  ]
}
```

**Priority Levels:**
| Priority | Display | Meaning |
|----------|---------|---------|
| CRITICAL | 🚨 | Must use for this task |
| RECOMMENDED | ⭐ | Strongly suggested |
| SUGGESTED | 💡 | May be helpful |
| OPTIONAL | ℹ️ | Available if needed |

### Ledger Pruning (v2.3.0+)

The SessionStart hook now automatically prunes old ledger entries to prevent bloat:

- Removes "Session Ended" entries older than 24 hours
- Keeps only the last 10 agent task reports
- Runs automatically on startup/resume

### Startup vs Resume Behavior (v2.3.0+)

The SessionStart hook differentiates between fresh starts and resumed sessions:

| Source | Context Loaded |
|--------|----------------|
| `startup` | Light context (notifies ledger exists, no full load) |
| `resume`, `clear`, `compact` | Full context (ledger content + handoff summaries) |

This prevents overwhelming fresh sessions with old context while ensuring resumed sessions have full continuity.

### Key Files

> **IMPORTANT:** All `thoughts/` paths must be at the **project root**, never in subdirectories.

| File | Purpose |
|------|---------|
| `thoughts/ledgers/CONTINUITY_*.md` | Session state (survives `/clear`) |
| `thoughts/shared/handoffs/*.md` | Detailed session transfers |
| `thoughts/shared/plans/*.json` | Implementation plans |
| `traceability_matrix.json` | Requirement tracking |

---

## Commit Reasoning System (v2.4.0+)

Track what was tried during development, keyed to specific commits. Enables learning from past failures and auto-generating PR descriptions.

### How It Works

```
During Development:
  Build/test fails → post-tool-use.sh → attempts.jsonl (branch-keyed)

At Commit Time:
  /commit "message" → generate-reasoning.sh → reasoning.md (commit-keyed)

For PR Creation:
  /describe-pr → aggregate-reasoning.sh → "Approaches Tried" section
```

### Storage Structure

```
.git/claude/                              # Local, permanent, not committed
├── branches/
│   └── {branch}/
│       └── attempts.jsonl                # Build failures while working
└── commits/
    └── {hash}/
        └── reasoning.md                  # What was tried per commit
```

### Key Commands

| Command | Description |
|---------|-------------|
| `/commit <msg>` | Git commit + generate reasoning from attempts |
| `/describe-pr [base]` | Generate PR description with "Approaches Tried" section |

### Scripts

| Script | Usage | Purpose |
|--------|-------|---------|
| `generate-reasoning.sh` | `./scripts/generate-reasoning.sh <hash>` | Create reasoning.md from attempts |
| `aggregate-reasoning.sh` | `./scripts/aggregate-reasoning.sh main` | Collect all reasoning since base |
| `search-reasoning.sh` | `./scripts/search-reasoning.sh "query"` | Search past reasoning |

### Searching Past Reasoning

```bash
# General search
./plugin-sdd/scripts/search-reasoning.sh "authentication"

# Find failed attempts (patterns to AVOID)
./plugin-sdd/scripts/search-reasoning.sh "ImportError" --failed

# Find first-try successes (patterns that WORK)
./plugin-sdd/scripts/search-reasoning.sh "validation" --passed

# Limit results
./plugin-sdd/scripts/search-reasoning.sh "rate limiting" --limit 5
```

### Example Reasoning File

```markdown
# Commit: abc12345

## Branch
feature/REQ-001-login

## What was committed
feat: implement login validation

## What was tried

### Failed attempts
- `uv run pytest...` (pytest): ImportError: No module named 'auth'
- `uv run pytest...` (pytest): AssertionError: expected 200

### Summary
Build passed after **2 failed attempt(s)** and 1 successful build(s).

## Files changed
- src/auth/login.py
- specs/auth/SPEC-001.md
```

### Benefits

| Without Reasoning | With Reasoning |
|-------------------|----------------|
| Knowledge lost per session | Permanent, searchable history |
| Manual PR descriptions | Auto-generated "Approaches Tried" |
| Repeat same mistakes | Learn from past failures |
| No effort visibility | Build attempt counts per commit |

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

# Test hooks manually
echo '{"source":"startup"}' | plugin-sdd/hooks/session-start.sh
echo '{"source":"resume"}' | plugin-sdd/hooks/session-start.sh
echo '{"session_id":"test"}' | plugin-sdd/hooks/stop.sh
echo '{}' | plugin-sdd/hooks/session-end.sh
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

## Changelog

### v2.4.0 (January 2026)

- **Commit reasoning system**: Track build attempts per commit with `/commit` command
- **Optimized session resume**: Reduced context usage from ~20% to ~2% on `/clear`
- **New commands**: `/commit`, `/describe-pr`, `/resume-full` (full context when needed)
- **New scripts**: `generate-reasoning.sh`, `aggregate-reasoning.sh`, `search-reasoning.sh`
- **macOS compatibility**: All hooks now exclude `._*` resource fork files
- **JSONL attempts tracking**: PostToolUse logs detailed build failures to `.git/claude/`
- **Enhanced recall-reasoning skill**: Now also searches commit reasoning
- **Updated git-workflow skill**: Recommends `/commit` over `git commit`

### v2.3.0 (January 2026)

- **New hooks**: `SessionEnd` (cleanup) and `Stop` (session summary)
- **Build/test tracking**: PostToolUse tracks test pass/fail outcomes
- **Skill activation rules**: `skill-rules.json` for priority-based skill suggestions
- **Ledger pruning**: Auto-removes old entries to prevent bloat
- **Startup/resume differentiation**: Light context on startup, full on resume
- **Enhanced loop detection**: Better tracking with configurable thresholds
- **Context monitoring status line**: Real-time token usage, git info, and current focus
- **Behavior rules**: 4 rules adapted from Continuous-Claude-v2

### v2.2.0

- **Auto-ledger updates**: Ledger updated alongside handoffs automatically
- **Loop detection**: Warns/blocks repetitive file operations

### v2.1.0

- Initial release with TDD and SDD plugins

---

## Known Issues

- **Hook latency**: Some hooks may add 1-3 seconds as they process state
- **Large ledgers**: Very long sessions may create large ledger files (mitigated by ledger pruning in v2.3.0)

---

## License

MIT License - see [LICENSE](LICENSE) for details.

---

## Acknowledgments

- [Continuous-Claude-v2](https://github.com/parcadei/Continuous-Claude-v2) - Continuity patterns, ledger pruning, build/test tracking, skill activation, behavior rules
- [Claude Code](https://code.claude.com/docs) by Anthropic
- [EARS methodology](https://alistairmavin.com/ears/) for requirements
- FAANG engineering practices
