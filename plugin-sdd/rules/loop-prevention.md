---
globs: ["**/*.py", "**/*.ts", "**/*.tsx", "**/*.js", "**/*.jsx"]
---

# Loop Prevention

Stop repeating failing actions. This rule applies to ALL agents.

## Recognition

You are **STUCK** if you've done any of these 3+ times:
- Modified the same file to fix the same error
- Run the same failing command expecting different results
- Re-read files trying to understand the same issue

## Action

```
╔══════════════════════════════════════════════════════════════╗
║  STOP. Do not make another edit to the same file.           ║
║  Repeating the same action expecting different results      ║
║  is the definition of insanity.                              ║
╚══════════════════════════════════════════════════════════════╝
```

**Diagnose:**
1. Is the error in THIS file, or somewhere else?
2. Is this environmental (imports, paths, `__init__.py`, naming)?
3. Am I fixing a symptom rather than root cause?

## Common Environmental Issues

| Symptom | Likely Cause | Fix |
|---------|--------------|-----|
| `ModuleNotFoundError` | Missing `__init__.py` | Add `__init__.py` to package dirs |
| Import/naming collision | Duplicate names | Rename to unique names |
| pytest collection error | Generic test names | Use `eval_{component}.py` not `eval_spec_001.py` |
| Type errors persist | Stale cache | Clear `.next/`, `node_modules/.cache`, `__pycache__` |
| Circular dependency | Architecture issue | Escalate to @architect |

## Escalation

After 2 failed attempts, **stop and escalate**:

```
## Stuck: [brief description]

**Error:** [exact message]
**Tried:** [what you attempted]  
**Hypothesis:** [what you think is wrong]
**Need:** [different approach, human input, etc.]
```

**For agents:** Escalate to @orchestrator
**For orchestrator:** Apply decision tree, never retry same approach

## Orchestrator Decision Tree

When receiving stuck escalations:

1. **Environmental?** → Fix env (paths, `__init__.py`, naming), not code
2. **Wrong file?** → Redirect to actual source
3. **Architecture?** → Route to @architect
4. **Unclear requirements?** → Route to @pm
5. **External dependency?** → Document blocker, move on

**Never send agent back to retry the same approach.**

