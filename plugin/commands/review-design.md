---
description: Validate design document and assess risk level
---

# Review Design Document

Review the design document for completeness and assess risk.

## Steps

### 1. Find Design Doc

Look in `docs/design/` for the most recent design document, or use the path provided: $ARGUMENTS

### 2. Check Required Sections

Verify the document has:
- [ ] Executive Summary
- [ ] Problem Statement
- [ ] Goals and Non-Goals
- [ ] Architecture diagram
- [ ] API contracts with examples
- [ ] Data model
- [ ] Security considerations
- [ ] Testing strategy
- [ ] Rollout plan
- [ ] Rollback plan

### 3. Assess Risk

For each REQ referenced, assess:
- **risk_level**: low / medium / high
- **governance_status**: approved / changes_requested

### 4. Generate Review Questions

Ask questions a senior engineer would ask:
1. Scalability concerns?
2. Edge cases?
3. Security attack surface?
4. Operational debugging?
5. Dependency failures?

### 5. Output Report

```
## Design Review Results

**Status:** APPROVED / CHANGES REQUESTED

### Sections
[checklist with status]

### Risk Assessment
| REQ | Risk | Status |
|-----|------|--------|

### Issues to Address
- [list any issues]

### Next Steps
- If approved: `/plan-sprint`
- If changes needed: address issues, re-run `/review-design`
```
