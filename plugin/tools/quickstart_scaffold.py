#!/usr/bin/env python
"""Quickstart scaffold for a new project using this Claude multi-agent kit.

Run this from the **project root** after copying `.claude/` into your repo:

    python .claude/tools/quickstart_scaffold.py
"""

import json
from pathlib import Path

def main():
    workspace = Path(".").resolve()

    # Ensure .design dirs
    design_dir = workspace / ".design"
    archive_dir = design_dir / "archive"
    archive_dir.mkdir(parents=True, exist_ok=True)
    print(f"[ok] ensured {design_dir} and {archive_dir}")

    # Create decision_log.json if missing
    decisions_path = workspace / "decision_log.json"
    if not decisions_path.exists():
        sample = {
            "decisions": [
                {
                    "id": "DEC-000",
                    "area": "example",
                    "summary": "Sample decision entry. Replace with real project decisions.",
                    "rationale": "Demonstrate decision log structure.",
                    "date": "2025-01-01"
                }
            ]
        }
        decisions_path.write_text(json.dumps(sample, indent=2), encoding="utf-8")
        print(f"[ok] wrote {decisions_path}")
    else:
        print(f"[skip] {decisions_path} already exists")

    print("[done] Claude multi-agent quickstart scaffold complete.")

if __name__ == "__main__":
    main()
