---
description: Generate or regenerate task breakdown with TDD pairing from design doc
---

# Sprint Planning

Generate an atomic task breakdown from the design document.

## When to Use

| Scenario | Action |
|----------|--------|
| After `/prd` | Usually not needed - `/prd` already creates tasks |
| After `/design` | **Use this** to create task breakdown |
| After design changes | **Use this** to regenerate tasks |
| Plan needs refinement | **Use this** to add/modify tasks |

## Steps

### 1. Read Design Doc

Find design doc in `docs/design/` or use: $ARGUMENTS

### 2. Create Task Breakdown

Create `planner_output.json`:

```json
{
  "meta": {
    "plan_version": 1,
    "summary": "Task breakdown for [feature]"
  },
  "tasks": [
    {
      "id": "T-001",
      "title": "Write tests for [component]",
      "owner_agent": "qa",
      "status": "todo",
      "depends_on": [],
      "related_stories": ["REQ-001"]
    },
    {
      "id": "T-002",
      "title": "Implement [component]",
      "owner_agent": "backend",
      "status": "todo",
      "depends_on": ["T-001"],
      "related_stories": ["REQ-001"]
    }
  ]
}
```

### 3. TDD Pairing Rule

**Every implementation task MUST have a preceding test task:**

- T-001 (qa: tests) → T-002 (backend: impl)
- T-003 (qa: tests) → T-004 (frontend: impl)

### 4. Update Traceability

Add task IDs to requirements in `traceability_matrix.json`.

### 5. Output

Report:
- Task count and TDD pairs
- Dependency graph
- Next steps: `/tdd [first-module]`
