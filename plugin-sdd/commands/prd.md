---
description: Process a PRD into requirements, design doc, specs, and task breakdown
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
  "specs": [],
  "evals": [],
  "code": []
}
```

### 3. Create Design Document

Create `docs/design/[feature]-design.md` with architecture, APIs, data model.

Include behavioral contracts for @spec-writer:
```markdown
## Behavioral Contracts

| Scenario | Given | When | Then |
|----------|-------|------|------|
| Valid input | User provides valid data | Submits form | Returns success |
| Invalid input | User provides invalid data | Submits form | Returns validation error |
```

### 4. Create Task Breakdown

Create `thoughts/shared/plans/plan-[feature].json` with SDD task triplets:
- Spec task (owner: spec-writer) BEFORE implementation task
- Implementation task depends on spec task
- Eval task (owner: spec-writer) depends on implementation task

Also create a copy at `planner_output.json` in root for quick access.

### 5. Output Summary

Report:
- Requirements extracted (REQ IDs)
- Design doc path
- Task count and SDD triplets (spec + impl + eval)
- Next steps: `/review-design`, `/implement [module]`

$ARGUMENTS
