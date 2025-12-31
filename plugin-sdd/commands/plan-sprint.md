---
description: Generate task breakdown from design with SDD triplets (spec + impl + eval)
---

# Plan Sprint

Generate a task breakdown from the design document.

## What To Do

### 1. Read Design Document

Find and read the latest design doc:
```bash
ls -t docs/design/*.md | head -1
```

### 2. Create Task Plan

Create `thoughts/shared/plans/plan-[feature].json`:

```json
{
  "meta": {
    "plan_version": 1,
    "summary": "Implementation plan for [feature]",
    "open_questions": []
  },
  "tasks": [
    {
      "id": "T-001",
      "title": "Write specs for [module]",
      "owner_agent": "spec-writer",
      "status": "todo",
      "depends_on": [],
      "related_stories": ["REQ-001"],
      "notes": ["SDD: Write specs BEFORE implementation"]
    },
    {
      "id": "T-002",
      "title": "Implement [module]",
      "owner_agent": "backend",
      "status": "todo",
      "depends_on": ["T-001"],
      "related_stories": ["REQ-001"],
      "notes": ["Implement to match specs from T-001"]
    },
    {
      "id": "T-003",
      "title": "Run evals for [module]",
      "owner_agent": "spec-writer",
      "status": "todo",
      "depends_on": ["T-002"],
      "related_stories": ["REQ-001"],
      "notes": ["Validate implementation matches specs"]
    }
  ]
}
```

### 3. SDD Triplet Rule

**Every implementation MUST have:**
1. Spec task (before) - @spec-writer writes behavioral specs
2. Impl task (middle) - @backend/@frontend implements
3. Eval task (after) - @spec-writer validates with evals

### 4. Update Traceability

Add task IDs to requirements in `traceability_matrix.json`.

### 5. Output Summary

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 SPRINT PLAN CREATED
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

## Plan: [feature]

**Location:** thoughts/shared/plans/plan-[feature].json
**Tasks:** [count]
**SDD Triplets:** [count]

### Task Summary

| ID | Title | Owner | Depends On |
|----|-------|-------|------------|
| T-001 | Write specs for auth | spec-writer | - |
| T-002 | Implement auth | backend | T-001 |
| T-003 | Run evals for auth | spec-writer | T-002 |

### Requirements Coverage

- REQ-001: T-001, T-002, T-003
- REQ-002: T-004, T-005, T-006

### Next Steps
1. @spec-writer: Start with T-001
2. Run /sdd [module] to begin development
```

$ARGUMENTS
