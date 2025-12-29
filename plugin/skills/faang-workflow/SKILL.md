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

| Phase | Command | Action |
|-------|---------|--------|
| 1 | /design or /prd | Create design doc |
| 2 | /review-design | @overseer validates |
| 3 | /plan-sprint | Task breakdown |
| 4 | /ux-spec | UX specification |
| 5 | /tdd | Tests → Implementation |
| 6 | /pre-review | Final check |

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

### The Continuity Loop

```
Work → Context fills → /save-state → /clear → Ledger auto-loads → Continue
```

### Key Files

| File | Purpose |
|------|---------|
| `thoughts/ledgers/CONTINUITY_*.md` | Session state (survives /clear) |
| `thoughts/shared/handoffs/*.md` | Detailed session transfers |
| `thoughts/shared/plans/*.md` | Implementation plans |
| `traceability_matrix.json` | Requirement tracking |

## Enforcement

1. **No code without design doc** in `docs/design/`
2. **Tests before implementation** - @qa writes first
3. **Traceability** - Everything links to REQ-* IDs
4. **Loop prevention** - Escalate after 2-3 bounces
5. **Context management** - /save-state before /clear

## Quick Start

```bash
# Initialize project (first time)
./scripts/init-project.sh

# Process PRD
/prd requirements/feature.md

# Check status
/status

# Implement with TDD
/tdd module-name

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
- Tasks (T-*)
- UX artifacts (.design/)
- Architecture (docs/design/)
- Code (src/)
- Tests (tests/)
