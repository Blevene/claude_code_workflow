---
globs: ["**/*.md", "**/*.py", "**/*.ts", "**/*.tsx"]
---

# Agent Orchestration Rules

When the user asks to implement something, use implementation agents to preserve main context.

## Parallel Agents: Guardrails

Parallel spawning is allowed **when agents work on independent domains**.

### ✅ SAFE to Parallelize

```
# Different modules, different files - OK
@backend implement auth API
@frontend implement dashboard UI
# Backend touches src/api/*, Frontend touches src/components/*
```

```
# Different specs for different features - OK
@spec-writer write spec for auth module
@spec-writer write spec for billing module
# Each works in separate specs/* directories
```

### 🚫 UNSAFE to Parallelize

```
# Same feature, same files - WRONG
@backend implement auth
@spec-writer write auth spec
@overseer review auth
# All 3 read docs/design/auth-design.md = 3x context waste
```

```
# Dependencies between agents - WRONG
@spec-writer write user-registration spec
@backend implement user-registration  
# Backend needs the spec that spec-writer is creating!
```

### Guardrails for Parallel Agents

| Rule | Why |
|------|-----|
| **Different file domains** | Agents must not read same files |
| **No dependencies** | Agent B can't need Agent A's output |
| **Max 2-3 parallel** | More causes context explosion |
| **Pass shared context** | Read design docs once, pass to all |

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

## Pass Context, Don't Make Agents Re-Read

**🚫 WRONG - agents all read same files:**
```
@backend implement the API endpoints
# Agent reads: design.md, spec.md, existing code...

@frontend implement the UI
# Agent ALSO reads: design.md, spec.md, existing code...
```

**✅ RIGHT - pass context in prompt:**
```
@backend implement the API endpoints
**Key context from design:**
- Auth uses JWT tokens, 24h expiry
- Rate limit: 100 req/min
- Database: PostgreSQL with Prisma
**Spec:** SPEC-AUTH-001
**Files to modify:** src/api/auth.ts, src/middleware/auth.ts
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

## Multi-Agent Work → Use @orchestrator

For any work that needs multiple agents:

```
@orchestrator Implement [feature] following SDD workflow.
**Design doc:** docs/design/[feature]-design.md
**Requirements:** [list key requirements]
```

The orchestrator will:
1. Read context ONCE
2. Spawn agents SEQUENTIALLY
3. Pass context TO each agent (not make them re-read)
4. Coordinate handoffs between agents
5. Report final status

## SDD Triplet Pattern (Sequential)

```
1. @spec-writer (writes spec)
   ↓ completes, returns SPEC-ID
2. @backend/@frontend (implements)
   ↓ completes, returns file list
3. Run evals (validates)
   ↓ pass/fail
4. @overseer (reviews if needed)
```

**NEVER run these in parallel!**

## Key Insight

Give agents specific context in their prompt. Each file read by an agent costs tokens—if you already have the info, pass it.

## Example Prompts

**For spec writing:**
```
@spec-writer Create behavioral specification for REQ-003 (user registration).

**Requirement:** Users must be able to register with email and password.
**Key design decisions:**
- Use bcrypt for password hashing
- Email verification required
- Rate limit: 5 registrations per IP per hour

When done, provide SPEC-ID and list of eval criteria.
```

**For implementation:**
```
@backend Implement the auth module to pass SPEC-001 evals.

**From spec (key behaviors):**
- POST /register returns 201 on success
- Returns 400 if email already exists
- Returns 429 if rate limited

**Files to create/modify:**
- src/api/auth.ts
- src/middleware/rateLimit.ts

Run evals after implementation and report pass/fail status.
```

## When to Escalate to @orchestrator

- Task spans multiple domains (backend + frontend)
- Unclear which agent should own the work
- Agent reports being stuck or blocked
- Need to coordinate handoff between agents
- **Any multi-agent workflow** (prevents parallel thrashing)

## Trigger Words

When you see these, consider using an agent:
- "implement", "build", "create feature" → `@backend`/`@frontend`
- "write spec", "define behavior" → `@spec-writer`
- "design", "architect" → `@architect`
- "review", "evaluate" → `@overseer`
- "plan sprint", "break down" → `@planner`
- "implement [multiple things]" → `@orchestrator`

## Agent Output Contract

All agents should end their work with:
1. Summary of what was done
2. Files created/modified
3. Eval status (if applicable)
4. Any blockers or open questions
5. Suggested next steps

