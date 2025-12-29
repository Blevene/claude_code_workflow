---
name: faang-workflow
description: FAANG multi-agent development workflow. Auto-triggers for production features, PRDs, design docs, TDD, test-driven development, feature implementation, sprint planning, code review, requirements, or architecture. Coordinates @orchestrator, @pm, @planner, @architect, @ux, @frontend, @backend, @qa, @overseer agents.
---

# FAANG Multi-Agent Workflow

## Core Principle

> **Design first. Test first. Trace everything.**

## Agent Team

| Agent | Role |
|-------|------|
| @orchestrator | Routes work, prevents loops |
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

## Enforcement

1. **No code without design doc** in `docs/design/`
2. **Tests before implementation** - @qa writes first
3. **Traceability** - Everything links to REQ-* IDs
4. **Loop prevention** - Escalate after 2-3 bounces

## Quick Start

```bash
# Process PRD
/prd requirements/feature.md

# Check status
/status

# Implement with TDD
/tdd module-name

# Pre-PR check
/pre-review
```

## Traceability

All work tracked in `traceability_matrix.json`:
- Requirements (REQ-*)
- Tasks (T-*)
- UX artifacts (.design/)
- Architecture (docs/design/)
- Code (src/)
- Tests (tests/)
