---
description: Create UX specification for a requirement (optional, for UI-heavy features)
---

# Create UX Specification

Create a UX specification for `$ARGUMENTS`.

## When To Use

Use this command for UI-heavy features that need:
- User flow documentation
- State diagrams
- Wireframes
- Interaction patterns

## What To Do

### 1. Create UX Spec JSON

Create `.design/$ARGUMENTS-ux.json`:

```json
{
  "requirement_id": "$ARGUMENTS",
  "title": "[Feature Name]",
  "created_by": "ux",
  "status": "Draft",
  "user_flow": {
    "entry_point": "[Where user starts]",
    "happy_path": [
      "Step 1",
      "Step 2",
      "Step 3"
    ],
    "error_paths": [
      {
        "trigger": "[Error condition]",
        "outcome": "[How to handle]"
      }
    ]
  },
  "states": [
    {
      "name": "idle",
      "description": "Initial state",
      "ui_elements": ["element1", "element2"]
    },
    {
      "name": "loading",
      "description": "Processing",
      "ui_elements": ["spinner"]
    },
    {
      "name": "success",
      "description": "Completed",
      "transition": "Redirect to next page"
    },
    {
      "name": "error",
      "description": "Failed",
      "ui_elements": ["error message", "retry button"]
    }
  ],
  "behavioral_hints": [
    "Given user on [page] When they [action] Then [outcome]",
    "Given user in [state] When they [action] Then [outcome]"
  ]
}
```

### 2. Create UI Mapping

Create `.design/$ARGUMENTS-ui-mapping.md`:

```markdown
# $ARGUMENTS UI Mapping

## Screen: [Name]

### Layout
```
┌─────────────────────────────┐
│         Header              │
├─────────────────────────────┤
│  [UI Element]               │
│  [UI Element]               │
│                             │
│       [ Button ]            │
└─────────────────────────────┘
```

### State Transitions
```
idle → loading → success
         ↓
       error → idle (retry)
```

### Accessibility
- [Requirements]

### Responsive Behavior
- Mobile: [behavior]
- Desktop: [behavior]
```

### 3. Update Traceability

Add UX artifacts to `traceability_matrix.json`:
```json
{
  "id": "$ARGUMENTS",
  "ux_artifacts": [
    ".design/$ARGUMENTS-ux.json",
    ".design/$ARGUMENTS-ui-mapping.md"
  ]
}
```

### 4. Output Summary

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ UX SPEC CREATED
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Created:
- .design/$ARGUMENTS-ux.json
- .design/$ARGUMENTS-ui-mapping.md

User Flow:
- Entry: [entry point]
- Happy path: [step count] steps
- Error paths: [count]

States: [count]
Behavioral Hints: [count] (for @spec-writer)

Traceability: Updated

Next steps:
1. @spec-writer: Use behavioral hints for specs
2. @frontend: Implement matching UX spec
```

$ARGUMENTS
