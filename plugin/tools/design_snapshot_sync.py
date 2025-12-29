#!/usr/bin/env python
"""Manage .design snapshots for plan/ux/arch."""

import argparse, json
from pathlib import Path
from datetime import datetime
from typing import Any, List

DESIGN_DIR = Path(".design")
ARCHIVE_DIR = DESIGN_DIR / "archive"

def ensure_dirs():
    DESIGN_DIR.mkdir(parents=True, exist_ok=True)
    ARCHIVE_DIR.mkdir(parents=True, exist_ok=True)

def now_stamp() -> str:
    return datetime.now().strftime("%Y%m%d-%H%M%S")

def load_json(path: Path) -> Any:
    return json.loads(path.read_text(encoding="utf-8"))

def save_snapshot(kind: str, source: Path):
    ensure_dirs()
    if not source.exists():
        raise SystemExit(f"[error] source file does not exist: {source}")
    try:
        data = load_json(source)
    except json.JSONDecodeError as e:
        raise SystemExit(f"[error] invalid JSON: {source}: {e}")
    kind = kind.lower()
    if kind not in {"plan", "ux", "arch"}:
        raise SystemExit("kind must be one of: plan, ux, arch")
    latest = DESIGN_DIR / f"latest-{kind}.json"
    archive = ARCHIVE_DIR / f"{kind}-{now_stamp()}.json"
    if latest.exists():
        archive.write_text(latest.read_text(encoding="utf-8"), encoding="utf-8")
    latest.write_text(json.dumps(data, indent=2), encoding="utf-8")
    print(f"[ok] Updated {latest} and archived previous snapshot if present.")

def list_snapshots():
    ensure_dirs()
    print("Current snapshots under .design/:")
    for kind in ("plan", "ux", "arch"):
        latest = DESIGN_DIR / f"latest-{kind}.json"
        if latest.exists():
            print(f"  - latest-{kind}.json")
        else:
            print(f"  - latest-{kind}.json (missing)")
    print("\nArchive files:")
    if ARCHIVE_DIR.exists():
        for p in sorted(ARCHIVE_DIR.glob("*.json")):
            print(f"  - {p.name}")
    else:
        print("  (none)")

def flatten_keys(obj: Any, prefix: str = "") -> List[str]:
    keys: List[str] = []
    if isinstance(obj, dict):
        for k, v in obj.items():
            new_prefix = f"{prefix}.{k}" if prefix else k
            keys.extend(flatten_keys(v, new_prefix))
    elif isinstance(obj, list):
        for idx, v in enumerate(obj):
            new_prefix = f"{prefix}[{idx}]"
            keys.extend(flatten_keys(v, new_prefix))
    else:
        keys.append(prefix or "<root>")
    return keys

def diff_snapshot(kind: str, other_path: Path):
    ensure_dirs()
    kind = kind.lower()
    if kind not in {"plan", "ux", "arch"}:
        raise SystemExit("kind must be one of: plan, ux, arch")
    latest = DESIGN_DIR / f"latest-{kind}.json"
    if not latest.exists():
        raise SystemExit(f"[error] {latest} does not exist.")
    if not other_path.exists():
        raise SystemExit(f"[error] comparison file does not exist: {other_path}")
    cur = load_json(latest)
    old = load_json(other_path)
    cur_keys = set(flatten_keys(cur))
    old_keys = set(flatten_keys(old))
    added = sorted(cur_keys - old_keys)
    removed = sorted(old_keys - cur_keys)
    common = cur_keys & old_keys
    print(f"Diff between {latest} (current) and {other_path} (historical):\n")
    print(f"  - Keys only in current: {len(added)}")
    print(f"  - Keys only in historical: {len(removed)}")
    print(f"  - Keys in both: {len(common)}")
    max_show = 20
    if added:
        print("\n  Sample keys only in current:")
        for k in added[:max_show]:
            print(f"    + {k}")
        if len(added) > max_show:
            print(f"    ... ({len(added) - max_show} more)")
    if removed:
        print("\n  Sample keys only in historical:")
        for k in removed[:max_show]:
            print(f"    - {k}")
        if len(removed) > max_show:
            print(f"    ... ({len(removed) - max_show} more)")

def main():
    parser = argparse.ArgumentParser(description="Manage .design snapshots for plan/ux/arch.")
    sub = parser.add_subparsers(dest="command", required=True)
    p_save = sub.add_parser("save", help="Save a new snapshot")
    p_save.add_argument("kind")
    p_save.add_argument("source")
    p_save.set_defaults(func=lambda args: save_snapshot(args.kind, Path(args.source)))
    p_list = sub.add_parser("list", help="List snapshots and archive files")
    p_list.set_defaults(func=lambda args: list_snapshots())
    p_diff = sub.add_parser("diff", help="Diff latest snapshot vs historical")
    p_diff.add_argument("kind")
    p_diff.add_argument("other")
    p_diff.set_defaults(func=lambda args: diff_snapshot(args.kind, Path(args.other)))
    args = parser.parse_args()
    args.func(args)

if __name__ == "__main__":
    main()
