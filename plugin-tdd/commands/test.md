---
description: Verify the plugin is working correctly
---

# Plugin Health Check

Say "✅ Claude Code Workflow plugin is working!" and then show:

1. **Project Directory:** What directory are we in?
2. **Continuity Files:** Check for `thoughts/ledgers/` and `thoughts/shared/`
3. **Python Environment:** Is `uv` available? Does `.venv/` exist?
4. **Traceability:** Does `traceability_matrix.json` exist?

Quick status summary:
```bash
ls -la thoughts/ 2>/dev/null || echo "No thoughts/ directory - run init-project.sh"
ls -la .venv/ 2>/dev/null || echo "No .venv/ - run 'uv venv'"
ls traceability_matrix.json 2>/dev/null || echo "No traceability_matrix.json"
```
