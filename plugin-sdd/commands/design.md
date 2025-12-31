---
description: Create a design document for a feature (when no PRD exists)
---

# Create Design Document

Create a design document for `$ARGUMENTS`.

## What To Do

### 1. Gather Context

Ask about:
- What problem does this solve?
- Who are the users?
- What are the constraints?
- What's the expected behavior?

### 2. Create Design Document

Create `docs/design/$ARGUMENTS-design.md`:

```markdown
# $ARGUMENTS - Design Document

**Author:** architect
**Status:** Draft
**Created:** <timestamp>

## Overview

### Problem Statement
[What problem this solves]

### Goals
- [Goal 1]
- [Goal 2]

### Non-Goals
- [What this won't do]

## Requirements

| ID | Type | Priority | EARS Statement |
|----|------|----------|----------------|
| REQ-001 | functional | high | WHEN [X] THEN the system SHALL [Y] |

## Architecture

### Components
[Describe key components]

### Data Model
[Define data structures]

### API Contracts
[Define endpoints and contracts]

## Behavioral Contracts (for @spec-writer)

| Scenario | Given | When | Then |
|----------|-------|------|------|
| Happy path | Valid input | Action taken | Expected outcome |
| Error case | Invalid input | Action taken | Error response |

## Risks & Mitigations

| Risk | Mitigation |
|------|------------|
| [Risk] | [How addressed] |

## Open Questions
- [Question 1]
```

### 3. Create Requirements in Traceability Matrix

Add requirements to `traceability_matrix.json`.

### 4. Output Summary

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ DESIGN DOCUMENT CREATED
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Created:
- docs/design/$ARGUMENTS-design.md
- REQ-001, REQ-002, ... in traceability_matrix.json

Next steps:
1. /review-design - Get @overseer review
2. /plan-sprint   - Create task breakdown
3. /sdd [module]  - Start spec-driven development
```

$ARGUMENTS
