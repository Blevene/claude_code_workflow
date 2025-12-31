---
description: Process a PRD into requirements, design doc, and task breakdown
---

# Process PRD

Process the PRD at `$ARGUMENTS` and generate engineering artifacts.

## Steps

### 1. Read and Analyze PRD

Read the file and extract:
- Problem/opportunity
- User stories
- Requirements (functional and non-functional)
- Success metrics
- Constraints

### 2. Generate EARS Requirements

Add requirements to `traceability_matrix.json`:

```json
{
  "id": "REQ-001",
  "type": "functional",
  "priority": "high",
  "status": "proposed",
  "ears": "WHEN [trigger] THEN the system SHALL [response].",
  "risk_level": null,
  "governance_status": "not_reviewed",
  "tasks": [],
  "ux_artifacts": [],
  "arch_artifacts": [],
  "code": [],
  "tests": []
}
```

### 3. Create Design Document

Create `docs/design/[feature]-design.md` with architecture, APIs, data model.

### 4. Create Task Breakdown

Create `thoughts/shared/plans/plan-[feature].json` with TDD task pairs:
- Test task (owner: qa) BEFORE implementation task
- Implementation task depends on test task

Also create a copy at `planner_output.json` in root for quick access.

### 5. Output Summary

Report:
- Requirements extracted (REQ IDs)
- Design doc path
- Task count and TDD pairs
- Next steps: `/review-design`, `/tdd [module]`
