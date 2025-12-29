#!/usr/bin/env python
"""Append a structured agent event to .claude/agent-logs/YYYY-MM-DD.jsonl."""

import argparse, json
from datetime import datetime
from pathlib import Path
from typing import Any, Dict

LOG_DIR = Path(".claude") / "agent-logs"

def log_event(agent: str, kind: str, message: str, tags: str | None = None, meta_json: str | None = None) -> Path:
    LOG_DIR.mkdir(parents=True, exist_ok=True)
    date = datetime.utcnow().strftime("%Y-%m-%d")
    path = LOG_DIR / f"agent-log-{date}.jsonl"
    event: Dict[str, Any] = {
        "ts": datetime.utcnow().isoformat() + "Z",
        "agent": agent,
        "kind": kind,
        "message": message
    }
    if tags:
        event["tags"] = [t.strip() for t in tags.split(",") if t.strip()]
    if meta_json:
        try:
            event["meta"] = json.loads(meta_json)
        except json.JSONDecodeError:
            event["meta"] = {"raw_meta": meta_json}
    with path.open("a", encoding="utf-8") as f:
        f.write(json.dumps(event) + "\n")
    return path

def main():
    parser = argparse.ArgumentParser(description="Log a structured agent event.")
    parser.add_argument("--agent", required=True, help="Logical agent name (e.g. planner, overseer, qa).")
    parser.add_argument("--kind", required=True, help="Event type (e.g. checkpoint, note, risk, decision).")
    parser.add_argument("--message", required=True, help="Short human-readable description.")
    parser.add_argument("--tags", help="Comma-separated tags (optional).")
    parser.add_argument("--meta", help="JSON string with extra metadata (optional).")
    args = parser.parse_args()
    path = log_event(args.agent, args.kind, args.message, args.tags, args.meta)
    print(f"[ok] logged event to {path}")

if __name__ == "__main__":
    main()
