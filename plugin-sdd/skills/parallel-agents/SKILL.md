---
name: parallel-agents
description: Guardrails for safe parallel agent spawning. Auto-triggers when spawning multiple agents.
triggers:
  - pattern: "@\\w+.*@\\w+"
    description: Multiple agents in same message
  - keywords: ["parallel", "simultaneously", "at the same time", "spawn both"]
---

# Parallel Agent Guardrails

## Quick Check Before Parallel Spawn

| Check | Safe? |
|-------|-------|
| Different file domains? | ✅ |
| No output dependencies? | ✅ |
| Max 2-3 agents? | ✅ |
| Shared context passed? | ✅ |

## Safe Parallel Patterns

### ✅ Different Modules
```
@backend implement auth API
@frontend implement dashboard UI
```
- Backend: `src/api/*`, `src/services/*`
- Frontend: `src/components/*`, `src/pages/*`
- No overlap = safe

### ✅ Different Features
```
@spec-writer write billing spec
@spec-writer write notifications spec  
```
- Billing: `specs/billing/*`
- Notifications: `specs/notifications/*`
- No overlap = safe

### ✅ Independent Tests
```
@backend run auth unit tests
@backend run billing unit tests
```
- Read-only operations
- No file modifications = safe

## Unsafe Patterns (Use Sequential)

### 🚫 Same Feature, Different Phases
```
@spec-writer write auth spec
@backend implement auth
```
**Why unsafe:** Backend needs spec-writer's output

**Fix:** Sequential
```
@spec-writer write auth spec
# Wait for completion
@backend implement auth per SPEC-AUTH-001
```

### 🚫 Same Files
```
@backend implement user service
@frontend implement user hooks
```
**Why unsafe:** Both may read/modify user-related files

**Fix:** Pass context, explicit scope
```
@backend implement user service
**Scope:** src/api/user.ts, src/services/user.ts ONLY

@frontend implement user hooks  
**Scope:** src/hooks/useUser.ts ONLY
**Context:** User API returns { id, name, email }
```

### 🚫 Review While Implementing
```
@backend implement feature X
@overseer review feature X
```
**Why unsafe:** Reviewer sees incomplete work

**Fix:** Sequential (implement → review)

## Context Passing Template

For ANY parallel spawn, pass shared context:

```
@[agent] [task]

**From design doc (don't re-read):**
- Key decision 1
- Key decision 2

**Your file scope:**
- src/specific/path.ts
- src/other/path.ts

**Other agents working on:**
- @other-agent: src/different/path.ts
```

## Detecting Conflicts

Signs of parallel agent conflict:
1. Multiple agents reading same design doc
2. Agent waiting for another's output
3. Merge conflicts in same file
4. Duplicate work on same feature

## Recovery

If parallel agents conflict:
1. Let current operations complete
2. Identify overlapping work
3. Reconcile manually or pick one
4. Continue sequentially for remainder

