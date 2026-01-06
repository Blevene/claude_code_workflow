---
description: Resume work from the latest handoff - loads context and continues
---

# /resume - Continue From Handoff

**Loads the latest handoff and prepares to continue work.**

## What To Do

1. **Find Latest Handoff**
   ```bash
   ls -t thoughts/shared/handoffs/*/handoff-*.md | head -1
   ```

2. **Read Handoff Content**
   - Load the full handoff document
   - Extract key sections: In Progress, Blocked, Next Steps

3. **Check Git Status**
   ```bash
   git status --short
   ```

4. **Extract Status From Handoff**
   - Eval status: Use the "Specs & Evals" section from handoff (don't re-run)
   - Traceability: Use the "Traceability Update" section from handoff
   - Important files: Check if files listed in handoff still exist

5. **If Files Changed Since Handoff**
   - If `git status` shows modified files not in handoff, suggest: "Files changed - consider running `/eval` to verify"
   - Don't auto-run evals - trust the handoff status unless code changed

6. **Present Resume Summary**

## Resume Summary Format

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔄 RESUMING FROM HANDOFF
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📋 Session: <previous-session-id>
📅 Handoff created: <timestamp>
📍 Phase: <SDD-phase>

## Where We Left Off
<Summary from handoff>

## In Progress
- <Item 1>
- <Item 2>

## Recommended Next Steps
1. <From handoff recommendations>
2. <Based on current state>

## Status (from handoff)
- Git: <clean/dirty with count>
- Evals: <from handoff - e.g. "8/10 passing">
- Traceability: <from handoff>

⚠️ If files changed since handoff, run /eval to verify
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Ready to continue. What would you like to work on?
```

## If No Handoff Found

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📭 NO HANDOFF FOUND
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

No handoff documents in thoughts/shared/handoffs/

Options:
- /status    - Check current workflow state
- /prd       - Start from a PRD
- /design    - Create a new design doc
```

## Integration Notes

- The SessionStart hook automatically loads ledger + handoff on /clear
- /resume is for explicitly reviewing handoff content mid-session
- Use when you want to see full handoff details, not just the summary

$ARGUMENTS
