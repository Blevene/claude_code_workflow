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

3. **Check Current State**
   ```bash
   # Git status
   git status --short
   
   # Run tests
   pytest --tb=no -q 2>/dev/null || echo "Tests need attention"
   
   # Check traceability gaps
   python tools/traceability_tools.py check-gaps traceability_matrix.json 2>/dev/null || true
   ```

4. **Verify Files Still Exist**
   - Check that "Important Files" from handoff exist
   - Note any files that have changed since handoff

5. **Present Resume Summary**

## Resume Summary Format

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔄 RESUMING FROM HANDOFF
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📋 Session: <previous-session-id>
📅 Handoff created: <timestamp>
📍 Phase: <FAANG-phase>

## Where We Left Off
<Summary from handoff>

## In Progress
- <Item 1>
- <Item 2>

## Recommended Next Steps
1. <From handoff recommendations>
2. <Based on current state>

## Quick Status
- Git: <clean/dirty with count>
- Tests: <passing/failing>
- Traceability: <coverage %>

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
