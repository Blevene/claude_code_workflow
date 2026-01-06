---
name: sdd-workflow
description: Spec-Driven Development workflow coordination. Auto-triggers for PRD processing, spec-to-implementation cycles, multi-agent handoffs, or session continuity (/save-state, /handoff, /resume). Coordinates @orchestrator, @pm, @planner, @architect, @ux, @frontend, @backend, @spec-writer, @overseer agents.
---

# Spec-Driven Development Workflow + Continuity

## Core Principles

> **Design first. Spec first. Eval everything. Clear, don't compact.**

## Testing Philosophy

Specs and evals encode requirements, not code structure. They verify *what* the system does, not *how* it does it.

**The Litmus Test:** Could you completely rewrite the implementation using a different algorithm, and would these evals still pass? If yes, you've specified behavior. If no, rewrite the spec.

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
| @spec-writer | Specs FIRST, creates evals |
| @overseer | Governance, risk |

## Workflow Phases

| Phase | Command | Action | Required? |
|-------|---------|--------|-----------|
| 1 | `/prd <file>` or `/design <feat>` | Create design doc | Yes |
| 2 | `/review-design` | @overseer validates | Yes |
| 3 | `/plan-sprint` | Task breakdown | Only after `/design` |
| 4 | `/ux-spec <REQ>` | UX specification | Only for UI features |
| 5 | `/spec <REQ>` | Behavioral specs | Yes |
| 6 | `/implement <module>` | Build code to match specs | Yes |
| 7 | `/eval <module>` | Run evals to validate | Yes |
| 8 | `/pre-review` | Final check | Yes |

### Typical Flows

**With PRD:**
```
/prd -> /review-design -> [/ux-spec] -> /spec -> /implement -> /eval -> /pre-review
```

**Without PRD:**
```
/design -> /review-design -> /plan-sprint -> [/ux-spec] -> /spec -> /implement -> /eval -> /pre-review
```

**Backend-only:**
```
/prd -> /review-design -> /spec -> /implement -> /eval -> /pre-review
```

## SDD Cycle

```
1. @spec-writer writes specs + evals -> defines expected behavior
2. @backend/@frontend implements -> code written to spec
3. Evals run -> validate implementation matches spec
4. If evals fail -> debug and fix (see below)
```

## Parallelization Options

When multiple independent tasks are detected, **offer the choice**:

### Example Offer
```
📋 Parallelization Available

3 independent specs detected:
- SPEC-AUTH-001, SPEC-BILLING-001, SPEC-NOTIF-001

Options:
1. Parallel (faster, recommended)
2. Sequential (one at a time)

Which would you prefer?
```

### Safe to Parallelize
| Pattern | Parallel? |
|---------|-----------|
| Multiple specs (different features) | ✅ Offer |
| Backend + Frontend (after spec) | ✅ Offer |
| Single feature pipeline | ❌ Sequential |

### Guardrails
- Max 3 parallel agents
- Different file domains required
- Pass shared context to all
- No output dependencies

## Fix/Iterate Cycle

When evals fail, use this cycle:

```
/eval fails → /debug → investigate → fix → /eval → repeat until pass
```

| Step | Action | Command |
|------|--------|---------|
| 1 | Run evals | `/eval <module>` |
| 2 | If failing, debug | `/debug <module>` |
| 3 | Read spec | Check `specs/module/SPEC-*.md` |
| 4 | Compare expected vs actual | From eval output |
| 5 | Fix implementation | Edit code to match spec |
| 6 | Re-run evals | `/eval <module>` |
| 7 | Check regressions | `uv run python tools/run_evals.py --all` |

**Key principle:** Fix the implementation, not the spec (unless spec is wrong).

## Continuity System (CRITICAL)

### Why This Matters

Context compaction degrades agent quality. After 2-3 compactions, agents hallucinate context. **Solution: Clear, don't compact.**

### Context Thresholds

| Level | Action |
|-------|--------|
| **< 60%** | Normal work |
| **60-70%** | Plan handoff points |
| **70-80%** | Complete task, /save-state, /clear soon |
| **> 80%** | STOP - /save-state then /clear NOW |

### Continuity Commands

| Command | When |
|---------|------|
| `/save-state` | Before /clear - updates ledger |
| `/handoff` | End of session - detailed transfer doc |
| `/resume` | Start of session - load handoff |

### Key Files

> **IMPORTANT:** All paths below are relative to the **project root**, never in subdirectories.

| File | Purpose |
|------|---------|
| `thoughts/ledgers/CONTINUITY_*.md` | Session state (survives /clear) |
| `thoughts/shared/handoffs/*.md` | Detailed session transfers |
| `thoughts/shared/plans/*.json` | Implementation plans |
| `traceability_matrix.json` | Requirement tracking |
| `specs/` | Behavioral specifications |
| `evals/` | Eval scripts |

## Enforcement

1. **No code without design doc** in `docs/design/`
2. **Specs before implementation** - @spec-writer writes first
3. **Evals validate behavior** - Not implementation details
4. **Traceability** - Everything links to REQ-* and SPEC-* IDs
5. **Loop prevention** - Escalate after 2-3 bounces
6. **Context management** - /save-state before /clear
7. **Python environment** - Always use `uv run` for Python/pytest

## Python Environment (CRITICAL)

```
╔══════════════════════════════════════════════════════════════╗
║  ALWAYS use uv for Python execution and dependencies.       ║
║  NEVER run python/pip/pytest directly - use uv run.         ║
╚══════════════════════════════════════════════════════════════╝
```

| Task | Command |
|------|---------|
| Run evals | `uv run python tools/run_evals.py --all` |
| Run single eval | `uv run python evals/module/eval_spec_001.py` |
| Run Python | `uv run python script.py` |
| Sync deps | `uv sync` |

## Quick Start

```bash
# Initialize project
/sdd-init

# Verify plugin health
/check

# Process PRD
/prd requirements/feature.md

# Check status
/status

# Create specs
/spec REQ-001

# Implement to match specs
/implement module-name

# Run evals
/eval module-name

# If evals fail, debug
/debug module-name

# Before context fills (70%+)
/save-state
/clear

# Pre-PR check
/pre-review

# End of session
/handoff
```

## Traceability

All work tracked in `traceability_matrix.json`:
- Requirements (REQ-*)
- Specs (SPEC-*)
- Tasks (T-*)
- UX artifacts (.design/)
- Architecture (docs/design/)
- Code (src/)
- Evals (evals/)
