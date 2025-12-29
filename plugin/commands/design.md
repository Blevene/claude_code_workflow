---
description: Create a technical design document for a feature
---

# Create Design Document

Create a technical design document for: $ARGUMENTS

## Steps

1. Ask clarifying questions about the feature:
   - What problem does this solve?
   - Who are the users?
   - What are the constraints?

2. Create `docs/design/$ARGUMENTS-design.md` with:
   - Executive Summary
   - Problem Statement  
   - Goals and Non-Goals
   - Architecture diagram (Mermaid)
   - API contracts with examples
   - Data model
   - Security considerations
   - Testing strategy
   - Rollout plan

3. Add a requirement to `traceability_matrix.json`:
   ```json
   {
     "id": "REQ-001",
     "ears": "The system SHALL [requirement in EARS format]",
     "status": "proposed",
     "arch_artifacts": ["docs/design/$ARGUMENTS-design.md"]
   }
   ```

4. Report what was created and next steps.

**IMPORTANT:** Do NOT write any implementation code. Design document only.
