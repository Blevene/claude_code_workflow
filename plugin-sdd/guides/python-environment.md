# Python Environment Guide

## Critical Rule

```
╔══════════════════════════════════════════════════════════════╗
║  ALWAYS use uv for Python execution and dependencies.       ║
║  NEVER run python/pip/pytest directly - use uv run.         ║
╚══════════════════════════════════════════════════════════════╝
```

## Setup

```bash
# Check if .venv exists
ls -la .venv/

# If not, create it
uv venv

# Sync dependencies
uv sync
```

## Common Commands

| Task | Command |
|------|---------|
| Run evals | `uv run python tools/run_evals.py --all` |
| Run single eval | `uv run python evals/module/eval_spec_001.py` |
| Run Python script | `uv run python script.py` |
| Run pytest | `uv run pytest tests/ -v` |
| Sync dependencies | `uv sync` |
| Add dependency | `uv add package-name` |
| Add dev dependency | `uv add --dev package-name` |

## Why uv?

- Consistent virtual environment across sessions
- Faster dependency resolution
- Reproducible builds via lockfile
- No global Python pollution
