---
description: Create UX specification for a requirement
---

# UX Specification

Create a UX specification for: $ARGUMENTS

## Steps

### 1. Find Requirement

Look up the requirement in `traceability_matrix.json`.

### 2. Create UX Spec

Create `.design/$ARGUMENTS-ux.json`:

```json
{
  "requirement_id": "$ARGUMENTS",
  "summary": "[brief description]",
  "user_goals": ["[what user wants to accomplish]"],
  "screens": [
    {
      "id": "screen-1",
      "name": "[Screen Name]",
      "states": ["default", "loading", "error", "success", "empty"],
      "interactions": [
        {
          "trigger": "[user action]",
          "action": "[system response]",
          "next_state": "[resulting state]"
        }
      ]
    }
  ]
}
```

### 3. Create UX Summary

Create `.design/$ARGUMENTS-ux.md` with:
- User goal
- Main flow
- States description
- Key interactions

### 4. Update Traceability

Add UX artifacts to requirement in `traceability_matrix.json`:
```json
{
  "ux_artifacts": [".design/$ARGUMENTS-ux.json"]
}
```

### 5. Output

Report:
- Files created
- Screens and states defined
- Next steps for frontend implementation
