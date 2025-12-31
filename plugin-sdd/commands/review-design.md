---
description: Review design document for completeness, risks, and spec readiness
---

# Review Design

Review design documents for completeness and risk assessment.

## What To Do

### 1. Find Design Documents

```bash
ls docs/design/*.md
```

### 2. Review Each Document

For each design doc, check:

#### Completeness
- [ ] Problem statement defined
- [ ] Requirements listed with EARS syntax
- [ ] Architecture documented
- [ ] API contracts defined
- [ ] Behavioral contracts defined (Given/When/Then)
- [ ] Data model specified
- [ ] Risks identified

#### Spec Readiness
- [ ] Behavioral contracts are testable
- [ ] Contracts follow Given/When/Then format
- [ ] Edge cases identified
- [ ] Error scenarios documented

### 3. Update Traceability

For each requirement:
- Add design doc to `arch_artifacts`
- Set initial risk_level
- Set governance_status

### 4. Output Review

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 DESIGN REVIEW COMPLETE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

## [Feature] Design

**Status:** Approved / Changes Requested
**Risk Level:** low / medium / high

### Completeness
- ✓ Problem statement
- ✓ Requirements (EARS)
- ✓ Architecture
- ✗ Missing: [what's missing]

### Spec Readiness
- ✓ Behavioral contracts defined
- [count] scenarios ready for specs

### Risks Identified
- [Risk 1]: [mitigation]
- [Risk 2]: [mitigation]

### Recommended Actions
1. [Action if changes requested]

### Next Steps
- /plan-sprint - Create task breakdown
- /implement [module] - Implement to match specs
```

## If Changes Requested

Route back to:
- @architect for missing architecture
- @pm for unclear requirements
- @ux for missing UX flows

$ARGUMENTS
