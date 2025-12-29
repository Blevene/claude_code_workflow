#!/usr/bin/env python
"""Summarize agent logs under .claude/agent-logs/ for reviews/PRs."""

import argparse, json
from pathlib import Path
from typing import Dict, List

LOG_DIR = Path(".claude") / "agent-logs"

def iter_logs() -> List[Dict]:
    if not LOG_DIR.exists():
        return []
    events: List[Dict] = []
    for path in sorted(LOG_DIR.glob("*.jsonl")):
        for line in path.read_text(encoding="utf-8").splitlines():
            line = line.strip()
            if not line:
                continue
            try:
                events.append(json.loads(line))
            except json.JSONDecodeError:
                continue
    return events

def summarize(events: List[Dict]) -> Dict:
    by_agent: Dict[str, int] = {}
    checkpoints: List[Dict] = []
    for e in events:
        agent = e.get("agent", "unknown")
        by_agent[agent] = by_agent.get(agent, 0) + 1
        if e.get("kind") in {"checkpoint", "milestone"}:
            checkpoints.append(e)
    return {"by_agent": by_agent, "checkpoints": checkpoints}

def print_text(summary: Dict):
    print("Agent log summary:")
    print("  Events by agent:")
    for agent, count in sorted(summary["by_agent"].items()):
        print(f"    - {agent}: {count}")
    if summary["checkpoints"]:
        print("\n  Checkpoints:")
        for e in summary["checkpoints"]:
            ts = e.get("ts", "?")
            msg = e.get("message", "")
            agent = e.get("agent", "unknown")
            print(f"    - [{ts}] ({agent}) {msg}")

def print_markdown(summary: Dict):
    print("# Agent log summary\n")
    print("## Events by agent")
    for agent, count in sorted(summary["by_agent"].items()):
        print(f"- **{agent}**: {count}")
    if summary["checkpoints"]:
        print("\n## Checkpoints")
        for e in summary["checkpoints"]:
            ts = e.get("ts", "?")
            msg = e.get("message", "")
            agent = e.get("agent", "unknown")
            print(f"- `{ts}` – **{agent}** – {msg}")

def main():
    parser = argparse.ArgumentParser(description="Summarize agent logs for reviews/PRs.")
    parser.add_argument("--markdown", action="store_true", help="Emit markdown.")
    args = parser.parse_args()
    events = iter_logs()
    summary = summarize(events)
    if args.markdown:
        print_markdown(summary)
    else:
        print_text(summary)

if __name__ == "__main__":
    main()
