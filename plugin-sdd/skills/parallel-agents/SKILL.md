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

### ✅ Different Modules (Implementation)
```
@backend implement auth API
@frontend implement dashboard UI
```
- Backend: `src/api/*`, `src/services/*`
- Frontend: `src/components/*`, `src/pages/*`
- No overlap = safe

### ✅ Different Specs + Evals in Parallel
```
@spec-writer write SPEC-AUTH-001 + eval_login.py
@spec-writer write SPEC-AUTH-002 + eval_password_reset.py
@spec-writer write SPEC-BILLING-001 + eval_checkout.py
```
- Each agent writes ONE spec + its eval
- Different specs = no dependencies
- Can parallelize as many as needed (recommend max 3)

### ✅ Multiple SDD Triplets (Different Features)
```
# Feature A: auth
@spec-writer write auth spec + eval → @backend implement auth

# Feature B: billing (in parallel with A)
@spec-writer write billing spec + eval → @backend implement billing
```
- Each triplet is independent
- Different file domains
- Can run entire pipelines in parallel

### ✅ Backend + Frontend (Same Feature, After Spec)
```
# AFTER spec exists:
@backend implement auth API (src/api/auth/*)
@frontend implement auth UI (src/components/auth/*)
```
- Both implementing from SAME spec
- Different file domains
- Pass spec summary to both

### ✅ Independent Tests
```
@backend run auth unit tests
@backend run billing unit tests
```
- Read-only operations
- No file modifications = safe

## SDD Triplet: Sequential Within, Parallel Across

The SDD triplet (spec → impl → eval) is ALWAYS sequential for a single feature:

```
Feature A (sequential):
1. @spec-writer write spec + eval  ─┐
2. @backend implement              ─┼─ This is ONE triplet
3. Run evals                       ─┘

Feature B (sequential):
1. @spec-writer write spec + eval  ─┐
2. @frontend implement             ─┼─ This is ONE triplet
3. Run evals                       ─┘
```

**But Feature A and B can run in parallel!**

```
┌─────────────────────────────────────────────────────────┐
│  Feature A              │  Feature B                    │
│  ──────────             │  ──────────                   │
│  spec-writer ─────────► │  spec-writer ─────────►       │
│  @backend ────────────► │  @frontend ────────────►      │
│  run evals ───────────► │  run evals ───────────►       │
└─────────────────────────────────────────────────────────┘
        ↑ These two pipelines run IN PARALLEL
```

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

### 🚫 Same Spec and Its Eval in Parallel
```
@spec-writer write SPEC-AUTH-001
@spec-writer write eval for SPEC-AUTH-001
```
**Why unsafe:** The eval depends on THAT spec's content (behaviors, edge cases, invariants)

**Fix:** Same agent writes spec + its eval together
```
@spec-writer write SPEC-AUTH-001 + eval_login.py
```

### ✅ Different Specs + Their Evals in Parallel
```
@spec-writer write SPEC-AUTH-001 + eval_login.py
@spec-writer write SPEC-BILLING-001 + eval_checkout.py
```
**Why safe:** Each spec-eval pair is independent. No shared dependencies.

This is the recommended pattern for multiple features!

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

