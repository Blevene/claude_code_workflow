---
globs: ["**/*"]
---

# Observe Before Editing

Before editing code to fix a bug, confirm what the system *actually produced*.

## Pattern

**Outputs don't lie. Code might. Check outputs first.**

## DO

1. **Check if expected files exist:**
   ```bash
   ls -la .claude/cache/
   ls -la thoughts/ledgers/
   ls -la specs/
   ls -la evals/
   ```

2. **Check eval results:**
   ```bash
   uv run python tools/run_evals.py --all
   ```

3. **Check logs for errors:**
   ```bash
   tail -50 .claude/cache/*.log 2>/dev/null || echo "No logs"
   ```

4. **Run the failing command manually to see actual error:**
   ```bash
   uv run python evals/module/eval_spec_001.py
   ```

5. **Only then edit code**

## DON'T

- ❌ Assume "the hook didn't run" without checking outputs
- ❌ Edit code based on what you *think* should happen
- ❌ Confuse project vs global paths (`.claude/` vs `~/.claude/`)
- ❌ Assume the error message points to the actual problem
- ❌ Make multiple changes before verifying the first one worked

## Common Path Confusion

| What | Project Path | Global Path |
|------|--------------|-------------|
| Cache | `.claude/cache/` | `~/.claude/cache/` |
| Hooks | Plugin `hooks/` | `~/.claude/hooks/` |
| Ledgers | `thoughts/ledgers/` | N/A (always project) |
| Handoffs | `thoughts/shared/handoffs/` | N/A (always project) |

## Before Fixing Failing Evals

1. **Read the actual error:**
   ```bash
   uv run python evals/auth/eval_spec_001.py 2>&1 | head -50
   ```

2. **Check if it's an import error vs logic error:**
   - Import error → Check `__init__.py`, module paths
   - Logic error → Check implementation matches spec

3. **Verify the spec is correct:**
   - Is the expected behavior clearly defined?
   - Does the eval actually test that behavior?

4. **Check if you're editing the right file:**
   - Error in `eval_spec_001.py` might be caused by `src/auth/login.py`
   - Trace the actual failure source

## The Observation Checklist

Before making ANY edit to fix a bug:

- [ ] I have seen the actual error output
- [ ] I have confirmed which file the error originates from
- [ ] I have checked that expected artifacts exist
- [ ] I understand WHY the current code produces this error
- [ ] I have a hypothesis for what will fix it
- [ ] I will verify my fix worked before moving on

## When Stuck in a Loop

If you've edited the same file 3+ times without success:

1. STOP editing
2. Run the full observation checklist above
3. Consider: Is the error actually in a DIFFERENT file?
4. Consider: Is this an environmental issue (paths, imports, dependencies)?
5. Escalate to `@orchestrator` with a structured report

