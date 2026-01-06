---
name: faang-workflow
description: FAANG multi-agent development workflow with session continuity. Auto-triggers for production features, PRDs, design docs, TDD, test-driven development, feature implementation, sprint planning, code review, requirements, or architecture. Coordinates @orchestrator, @pm, @planner, @architect, @ux, @frontend, @backend, @qa, @overseer agents. Prevents context degradation through ledgers and handoffs.
---

# FAANG Multi-Agent Workflow + Continuity

## Core Principles

> **Design first. Test first. Trace everything. Clear, don't compact.**

## Agent Team

| Agent | Role |
|-------|------|
| @orchestrator | Routes work, manages continuity, prevents loops |
| @pm | EARS requirements, priorities |
| @planner | Task breakdown, dependencies |
| @architect | Design, contracts |
| @ux | User flows, states |
| @frontend | UI implementation |
| @backend | API implementation |
| @qa | Tests FIRST |
| @overseer | Governance, risk |

## Workflow Phases

| Phase | Command | Action | Required? |
|-------|---------|--------|-----------|
| 1 | `/prd <file>` or `/design <feat>` | Create design doc | ✅ Yes |
| 2 | `/review-design` | @overseer validates | ✅ Yes |
| 3 | `/plan-sprint` | Task breakdown | Only after `/design` |
| 4 | `/ux-spec <REQ>` | UX specification | Only for UI features |
| 5 | `/tdd <module>` | Tests → Implementation | ✅ Yes |
| 6 | `/pre-review` | Final check | ✅ Yes |

### Typical Flows

**With PRD:**
```
/prd → /review-design → [/ux-spec] → /tdd → /pre-review
```

**Without PRD:**
```
/design → /review-design → /plan-sprint → [/ux-spec] → /tdd → /pre-review
```

**Backend-only:**
```
/prd → /review-design → /tdd → /pre-review  (skip /ux-spec)
```

## Continuity System (CRITICAL)

### Why This Matters

Context compaction degrades agent quality. After 2-3 compactions, agents hallucinate context. **Solution: Clear, don't compact.**

### Context Thresholds

| Level | Action |
|-------|--------|
| **< 60%** | Normal work |
| **60-70%** | Plan handoff points |
| **70-80%** | Complete task, /clear soon |
| **> 80%** | STOP - /clear NOW (ledger auto-saved) |

### Continuity Commands

| Command | When |
|---------|------|
| `/handoff` | End of session - detailed transfer doc |
| `/clear` | Fresh context (ledger auto-updated by hooks) |
| `/resume` | Start of session - load handoff |

### The Continuity Loop

```
Work → Context fills → /clear → Ledger auto-loads → Continue
```

### Key Files

> **IMPORTANT:** All paths below are relative to the **project root**, never in subdirectories.

| File | Purpose |
|------|---------|
| `thoughts/ledgers/CONTINUITY_*.md` | Session state (survives /clear) |
| `thoughts/shared/handoffs/*.md` | Detailed session transfers |
| `thoughts/shared/plans/*.json` | Implementation plans |
| `traceability_matrix.json` | Requirement tracking |

## Enforcement

1. **No code without design doc** in `docs/design/`
2. **Tests before implementation** - @qa writes first
3. **Traceability** - Everything links to REQ-* IDs
4. **Loop prevention** - Escalate after 2-3 bounces
5. **Context management** - /clear when needed (ledger auto-saved)
6. **Python environment** - Always use `uv run` for Python/pytest

## Python Environment (CRITICAL)

```
╔══════════════════════════════════════════════════════════════╗
║  ALWAYS use uv for Python execution and dependencies.       ║
║  NEVER run python/pip/pytest directly - use uv run.         ║
╚══════════════════════════════════════════════════════════════╝
```

| Task | Command |
|------|---------|
| Run tests | `uv run pytest tests/ -v` |
| Run Python | `uv run python script.py` |
| Sync deps | `uv sync` |
| Add package | `uv add <package>` |
| Create venv | `uv venv` |

## Quick Start

```bash
# Initialize project (first time - sets up venv too)
./scripts/init-project.sh

# Or manually set up Python environment
uv venv && uv sync

# Process PRD
/prd requirements/feature.md

# Check status
/status

# Implement with TDD (uses uv run pytest internally)
/tdd module-name

# Run tests manually
uv run pytest tests/ -v

# Before context fills (70%+)
/clear  # Ledger auto-saved by hooks

# Pre-PR check
/pre-review

# End of session
/handoff
```

## Traceability

All work tracked in `traceability_matrix.json`:
- Requirements (REQ-*)
- Tasks (T-*)
- UX artifacts (.design/)
- Architecture (docs/design/)
- Code (src/)
- Tests (tests/)
