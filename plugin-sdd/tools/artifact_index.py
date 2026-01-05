#!/usr/bin/env python3
"""
Artifact Index Builder for SDD Plugin.

Indexes handoffs, plans, specs, and continuity ledgers into SQLite for fast search.

USAGE:
    uv run python tools/artifact_index.py --all              # Index everything
    uv run python tools/artifact_index.py --handoffs         # Index handoffs only
    uv run python tools/artifact_index.py --specs            # Index specs only
    uv run python tools/artifact_index.py --plans            # Index plans only
    uv run python tools/artifact_index.py --continuity       # Index ledgers only
"""

import argparse
import hashlib
import json
import re
import sqlite3
from datetime import datetime
from pathlib import Path
from typing import Any, Dict, List, Optional


def get_db_path() -> Path:
    """Get the database path, creating directories if needed."""
    db_dir = Path(".claude/cache/artifact-index")
    db_dir.mkdir(parents=True, exist_ok=True)
    return db_dir / "context.db"


def init_db(db_path: Path) -> sqlite3.Connection:
    """Initialize the database with schema."""
    conn = sqlite3.connect(db_path)
    
    # Read and execute schema
    schema_path = Path(__file__).parent / "artifact_schema.sql"
    if schema_path.exists():
        schema = schema_path.read_text()
        conn.executescript(schema)
    else:
        print(f"Warning: Schema file not found at {schema_path}")
    
    return conn


def generate_id(content: str) -> str:
    """Generate a unique ID from content."""
    return hashlib.md5(content.encode()).hexdigest()[:12]


def parse_handoff(file_path: Path) -> Optional[Dict[str, Any]]:
    """Parse a handoff markdown file."""
    content = file_path.read_text()
    
    # Extract session name from path: thoughts/shared/handoffs/{session}/...
    parts = file_path.parts
    session_name = "unknown"
    if "handoffs" in parts:
        idx = parts.index("handoffs")
        if idx + 1 < len(parts):
            session_name = parts[idx + 1]
    
    # Parse frontmatter if present
    frontmatter = {}
    if content.startswith("---"):
        end = content.find("---", 3)
        if end != -1:
            fm_content = content[3:end].strip()
            for line in fm_content.split("\n"):
                if ":" in line:
                    key, value = line.split(":", 1)
                    frontmatter[key.strip()] = value.strip()
    
    # Extract task number from filename or frontmatter
    task_number = frontmatter.get("task_number")
    if not task_number:
        match = re.search(r"task[_-]?(\d+)", file_path.name, re.IGNORECASE)
        if match:
            task_number = int(match.group(1))
    
    # Extract sections
    def extract_section(header: str) -> Optional[str]:
        pattern = rf"##\s*{header}\s*\n(.*?)(?=\n##|\Z)"
        match = re.search(pattern, content, re.DOTALL | re.IGNORECASE)
        return match.group(1).strip() if match else None
    
    task_summary = extract_section("Summary|Task Summary|Overview")
    what_worked = extract_section("What Worked|Successes|Worked")
    what_failed = extract_section("What Failed|Failures|Issues|Problems")
    key_decisions = extract_section("Key Decisions|Decisions")
    
    # Extract files modified
    files_modified = []
    files_section = extract_section("Files Modified|Modified Files|Changes")
    if files_section:
        files_modified = re.findall(r"`([^`]+)`", files_section)
    
    # Determine outcome
    outcome = frontmatter.get("outcome", "UNKNOWN").upper()
    if outcome not in ("SUCCEEDED", "PARTIAL", "FAILED", "UNKNOWN"):
        outcome = "UNKNOWN"
    
    return {
        "id": generate_id(str(file_path) + content[:100]),
        "session_name": session_name,
        "task_number": task_number,
        "file_path": str(file_path),
        "task_summary": task_summary,
        "what_worked": what_worked,
        "what_failed": what_failed,
        "key_decisions": key_decisions,
        "files_modified": json.dumps(files_modified),
        "outcome": outcome,
    }


def parse_plan(file_path: Path) -> Optional[Dict[str, Any]]:
    """Parse a plan markdown or JSON file."""
    content = file_path.read_text()
    
    # Try JSON first
    if file_path.suffix == ".json":
        try:
            data = json.loads(content)
            return {
                "id": generate_id(str(file_path)),
                "title": data.get("title", file_path.stem),
                "file_path": str(file_path),
                "overview": data.get("overview", data.get("description", "")),
                "approach": data.get("approach", ""),
                "phases": json.dumps(data.get("phases", data.get("tasks", []))),
                "constraints": json.dumps(data.get("constraints", [])),
            }
        except json.JSONDecodeError:
            pass
    
    # Parse markdown
    title = file_path.stem
    title_match = re.search(r"^#\s+(.+)$", content, re.MULTILINE)
    if title_match:
        title = title_match.group(1)
    
    def extract_section(header: str) -> Optional[str]:
        pattern = rf"##\s*{header}\s*\n(.*?)(?=\n##|\Z)"
        match = re.search(pattern, content, re.DOTALL | re.IGNORECASE)
        return match.group(1).strip() if match else None
    
    return {
        "id": generate_id(str(file_path)),
        "title": title,
        "file_path": str(file_path),
        "overview": extract_section("Overview|Summary|Description"),
        "approach": extract_section("Approach|Strategy|Method"),
        "phases": json.dumps([]),  # Could parse phases if needed
        "constraints": json.dumps([]),
    }


def parse_spec(file_path: Path) -> Optional[Dict[str, Any]]:
    """Parse a spec markdown file."""
    content = file_path.read_text()
    
    # Extract SPEC ID from filename or content
    spec_id = None
    match = re.search(r"SPEC-\d+", file_path.name, re.IGNORECASE)
    if match:
        spec_id = match.group(0).upper()
    else:
        match = re.search(r"#\s*(SPEC-\d+)", content, re.IGNORECASE)
        if match:
            spec_id = match.group(1).upper()
    
    if not spec_id:
        spec_id = f"SPEC-{generate_id(str(file_path))[:4]}"
    
    # Extract REQ ID if linked
    req_id = None
    req_match = re.search(r"REQ-\d+", content, re.IGNORECASE)
    if req_match:
        req_id = req_match.group(0).upper()
    
    # Extract title
    title = file_path.stem
    title_match = re.search(r"^#\s+(?:SPEC-\d+[:\s]*)?\s*(.+)$", content, re.MULTILINE)
    if title_match:
        title = title_match.group(1).strip()
    
    def extract_section(header: str) -> Optional[str]:
        pattern = rf"##\s*{header}\s*\n(.*?)(?=\n##|\Z)"
        match = re.search(pattern, content, re.DOTALL | re.IGNORECASE)
        return match.group(1).strip() if match else None
    
    # Extract expected behaviors (WHEN/THEN patterns)
    behaviors = re.findall(
        r"(?:WHEN|WHILE|WHERE|The system)\s+.+?(?:THEN|SHALL)\s+.+?(?:\.|$)",
        content,
        re.IGNORECASE
    )
    
    # Check for eval file
    eval_dir = file_path.parent.parent / "evals" / file_path.parent.name
    eval_path = eval_dir / f"eval_{spec_id.lower().replace('-', '_')}.py"
    has_eval = eval_path.exists()
    
    return {
        "id": generate_id(str(file_path)),
        "spec_id": spec_id,
        "req_id": req_id,
        "title": title,
        "file_path": str(file_path),
        "behavior_summary": extract_section("Behavioral Specification|Behavior|Summary"),
        "expected_behaviors": json.dumps(behaviors),
        "eval_criteria": json.dumps([]),
        "has_eval": has_eval,
        "eval_path": str(eval_path) if has_eval else None,
    }


def parse_continuity(file_path: Path) -> Optional[Dict[str, Any]]:
    """Parse a continuity ledger file."""
    content = file_path.read_text()
    
    # Extract session name from filename
    session_name = "unknown"
    match = re.search(r"CONTINUITY_(.+)\.md", file_path.name)
    if match:
        session_name = match.group(1)
    
    def extract_section(header: str) -> Optional[str]:
        pattern = rf"##\s*{header}\s*\n(.*?)(?=\n##|\Z)"
        match = re.search(pattern, content, re.DOTALL | re.IGNORECASE)
        return match.group(1).strip() if match else None
    
    # Extract checkboxes as done/now/next
    done_items = re.findall(r"\[x\]\s*(.+)", content, re.IGNORECASE)
    current_items = re.findall(r"\[→\]\s*(.+)", content)
    next_items = re.findall(r"\[ \]\s*(.+)", content)
    
    return {
        "id": generate_id(str(file_path) + content[:100]),
        "session_name": session_name,
        "goal": extract_section("Goal|Objective|Purpose"),
        "state_done": json.dumps(done_items),
        "state_now": "; ".join(current_items) if current_items else None,
        "state_next": json.dumps(next_items),
        "key_learnings": extract_section("Key Learnings|Learnings|Insights"),
        "key_decisions": extract_section("Key Decisions|Decisions"),
        "snapshot_reason": "manual",
    }


def index_handoffs(conn: sqlite3.Connection) -> int:
    """Index all handoff files."""
    count = 0
    handoff_dirs = [
        Path("thoughts/shared/handoffs"),
        Path("thoughts/handoffs"),
    ]
    
    for handoff_dir in handoff_dirs:
        if not handoff_dir.exists():
            continue
        
        for file_path in handoff_dir.rglob("*.md"):
            try:
                data = parse_handoff(file_path)
                if data:
                    conn.execute("""
                        INSERT OR REPLACE INTO handoffs 
                        (id, session_name, task_number, file_path, task_summary, 
                         what_worked, what_failed, key_decisions, files_modified, outcome)
                        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                    """, (
                        data["id"], data["session_name"], data["task_number"],
                        data["file_path"], data["task_summary"], data["what_worked"],
                        data["what_failed"], data["key_decisions"], data["files_modified"],
                        data["outcome"]
                    ))
                    count += 1
            except Exception as e:
                print(f"Error indexing {file_path}: {e}")
    
    conn.commit()
    return count


def index_plans(conn: sqlite3.Connection) -> int:
    """Index all plan files."""
    count = 0
    plan_dirs = [
        Path("thoughts/shared/plans"),
        Path("thoughts/plans"),
        Path("docs/design"),
    ]
    
    for plan_dir in plan_dirs:
        if not plan_dir.exists():
            continue
        
        for file_path in plan_dir.rglob("*.md"):
            try:
                data = parse_plan(file_path)
                if data:
                    conn.execute("""
                        INSERT OR REPLACE INTO plans
                        (id, title, file_path, overview, approach, phases, constraints)
                        VALUES (?, ?, ?, ?, ?, ?, ?)
                    """, (
                        data["id"], data["title"], data["file_path"],
                        data["overview"], data["approach"], data["phases"],
                        data["constraints"]
                    ))
                    count += 1
            except Exception as e:
                print(f"Error indexing {file_path}: {e}")
        
        # Also check JSON files
        for file_path in plan_dir.rglob("*.json"):
            try:
                data = parse_plan(file_path)
                if data:
                    conn.execute("""
                        INSERT OR REPLACE INTO plans
                        (id, title, file_path, overview, approach, phases, constraints)
                        VALUES (?, ?, ?, ?, ?, ?, ?)
                    """, (
                        data["id"], data["title"], data["file_path"],
                        data["overview"], data["approach"], data["phases"],
                        data["constraints"]
                    ))
                    count += 1
            except Exception as e:
                print(f"Error indexing {file_path}: {e}")
    
    conn.commit()
    return count


def index_specs(conn: sqlite3.Connection) -> int:
    """Index all spec files."""
    count = 0
    specs_dir = Path("specs")
    
    if not specs_dir.exists():
        return 0
    
    for file_path in specs_dir.rglob("*.md"):
        try:
            data = parse_spec(file_path)
            if data:
                conn.execute("""
                    INSERT OR REPLACE INTO specs
                    (id, spec_id, req_id, title, file_path, behavior_summary,
                     expected_behaviors, eval_criteria, has_eval, eval_path)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                """, (
                    data["id"], data["spec_id"], data["req_id"], data["title"],
                    data["file_path"], data["behavior_summary"],
                    data["expected_behaviors"], data["eval_criteria"],
                    data["has_eval"], data["eval_path"]
                ))
                count += 1
        except Exception as e:
            print(f"Error indexing {file_path}: {e}")
    
    conn.commit()
    return count


def index_continuity(conn: sqlite3.Connection) -> int:
    """Index all continuity ledger files."""
    count = 0
    ledger_dirs = [
        Path("thoughts/ledgers"),
        Path("."),
    ]
    
    for ledger_dir in ledger_dirs:
        if not ledger_dir.exists():
            continue
        
        for file_path in ledger_dir.glob("CONTINUITY_*.md"):
            try:
                data = parse_continuity(file_path)
                if data:
                    conn.execute("""
                        INSERT OR REPLACE INTO continuity
                        (id, session_name, goal, state_done, state_now, state_next,
                         key_learnings, key_decisions, snapshot_reason)
                        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
                    """, (
                        data["id"], data["session_name"], data["goal"],
                        data["state_done"], data["state_now"], data["state_next"],
                        data["key_learnings"], data["key_decisions"],
                        data["snapshot_reason"]
                    ))
                    count += 1
            except Exception as e:
                print(f"Error indexing {file_path}: {e}")
    
    conn.commit()
    return count


def main():
    """Main entry point."""
    parser = argparse.ArgumentParser(
        description="Index artifacts for recall-reasoning"
    )
    parser.add_argument("--all", action="store_true", help="Index everything")
    parser.add_argument("--handoffs", action="store_true", help="Index handoffs")
    parser.add_argument("--plans", action="store_true", help="Index plans")
    parser.add_argument("--specs", action="store_true", help="Index specs")
    parser.add_argument("--continuity", action="store_true", help="Index ledgers")
    parser.add_argument("--db", type=str, help="Custom database path")
    
    args = parser.parse_args()
    
    # Default to --all if nothing specified
    if not any([args.all, args.handoffs, args.plans, args.specs, args.continuity]):
        args.all = True
    
    db_path = Path(args.db) if args.db else get_db_path()
    conn = init_db(db_path)
    
    print(f"Indexing to: {db_path}")
    
    if args.all or args.handoffs:
        count = index_handoffs(conn)
        print(f"  Handoffs: {count} indexed")
    
    if args.all or args.plans:
        count = index_plans(conn)
        print(f"  Plans: {count} indexed")
    
    if args.all or args.specs:
        count = index_specs(conn)
        print(f"  Specs: {count} indexed")
    
    if args.all or args.continuity:
        count = index_continuity(conn)
        print(f"  Continuity: {count} indexed")
    
    conn.close()
    print("Done!")


if __name__ == "__main__":
    main()

