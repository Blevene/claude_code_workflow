---
globs: ["**/*.md", "**/*.py", "**/*.ts", "**/*.tsx"]
---

# Agent Orchestration Rules

When the user asks to implement something, use implementation agents to preserve main context.

## The Pattern

**Wrong - burns context:**
```
Main: Read files → Understand → Make edits → Report
      (2000+ tokens consumed in main context)
```

**Right - preserves context:**
```
Main: Spawn @backend("implement X per spec")
      ↓
Agent: Reads spec → Understands → Implements → Tests
      ↓
Main: Gets summary (~200 tokens)
```

## When to Use Agents

| Task Type | Use Agent? | Which Agent |
|-----------|------------|-------------|
| Write behavioral spec | Yes | `@spec-writer` |
| Multi-file implementation | Yes | `@backend` or `@frontend` |
| Following a plan phase | Yes | Appropriate specialist |
| New feature with tests | Yes | `@backend` + run evals |
| UX design work | Yes | `@ux` |
| Architecture decisions | Yes | `@architect` |
| Single-line fix | No | Do directly |
| Quick config change | No | Do directly |
| Running evals | No | Do directly |

## SDD Agent Workflow

```
@pm (requirements) 
  → @architect (design)
    → @spec-writer (specs + evals)
      → @backend/@frontend (implementation)
        → Run evals
          → @overseer (review)
```

## Key Insight

Agents read their own context. Don't read files in main chat just to understand what to pass to an agent—give them the task and they figure it out.

## Example Prompts

**For spec writing:**
```
@spec-writer Create behavioral specification for REQ-003 (user registration).

**Requirement:** Users must be able to register with email and password.
**Design doc:** docs/design/auth-design.md

When done, provide SPEC-ID and list of eval criteria.
```

**For implementation:**
```
@backend Implement the auth module to pass SPEC-001 evals.

**Spec location:** specs/auth/SPEC-001.md
**Eval location:** evals/auth/eval_spec_001.py

Run evals after implementation and report pass/fail status.
```

## When to Escalate to @orchestrator

- Task spans multiple domains (backend + frontend)
- Unclear which agent should own the work
- Agent reports being stuck or blocked
- Need to coordinate handoff between agents

## Trigger Words

When you see these, consider using an agent:
- "implement", "build", "create feature" → `@backend`/`@frontend`
- "write spec", "define behavior" → `@spec-writer`
- "design", "architect" → `@architect`
- "review", "evaluate" → `@overseer`
- "plan sprint", "break down" → `@planner`

## Agent Output Contract

All agents should end their work with:
1. Summary of what was done
2. Files created/modified
3. Eval status (if applicable)
4. Any blockers or open questions
5. Suggested next steps

