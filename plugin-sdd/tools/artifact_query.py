#!/usr/bin/env python3
"""
Artifact Query Tool for SDD Plugin.

Search past work for relevant decisions, patterns, and approaches.

USAGE:
    uv run python tools/artifact_query.py "authentication OAuth"
    uv run python tools/artifact_query.py "implement agent" --outcome SUCCEEDED
    uv run python tools/artifact_query.py "API design" --type specs
    uv run python tools/artifact_query.py "login flow" --type handoffs --limit 10
"""

import argparse
import hashlib
import json
import sqlite3
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Optional


def get_db_path(custom_path: Optional[str] = None) -> Path:
    """Get the database path."""
    if custom_path:
        return Path(custom_path)
    return Path(".claude/cache/artifact-index/context.db")


def escape_fts5_query(query: str) -> str:
    """Escape FTS5 query to prevent syntax errors.
    
    Splits query into words and joins with OR for flexible matching.
    """
    words = query.split()
    quoted_words = [f'"{w.replace(chr(34), chr(34)+chr(34))}"' for w in words]
    return " OR ".join(quoted_words)


def search_handoffs(
    conn: sqlite3.Connection,
    query: str,
    outcome: Optional[str] = None,
    limit: int = 5
) -> List[Dict]:
    """Search handoffs using FTS5."""
    sql = """
        SELECT h.id, h.session_name, h.task_number, h.task_summary,
               h.what_worked, h.what_failed, h.key_decisions,
               h.outcome, h.file_path, h.created_at,
               handoffs_fts.rank as score
        FROM handoffs_fts
        JOIN handoffs h ON handoffs_fts.rowid = h.rowid
        WHERE handoffs_fts MATCH ?
    """
    params = [escape_fts5_query(query)]
    
    if outcome:
        sql += " AND h.outcome = ?"
        params.append(outcome)
    
    sql += " ORDER BY rank LIMIT ?"
    params.append(limit)
    
    cursor = conn.execute(sql, params)
    columns = [desc[0] for desc in cursor.description]
    return [dict(zip(columns, row)) for row in cursor.fetchall()]


def search_plans(
    conn: sqlite3.Connection,
    query: str,
    limit: int = 3
) -> List[Dict]:
    """Search plans using FTS5."""
    sql = """
        SELECT p.id, p.title, p.overview, p.approach, p.file_path, p.created_at,
               plans_fts.rank as score
        FROM plans_fts
        JOIN plans p ON plans_fts.rowid = p.rowid
        WHERE plans_fts MATCH ?
        ORDER BY rank LIMIT ?
    """
    cursor = conn.execute(sql, [escape_fts5_query(query), limit])
    columns = [desc[0] for desc in cursor.description]
    return [dict(zip(columns, row)) for row in cursor.fetchall()]


def search_specs(
    conn: sqlite3.Connection,
    query: str,
    limit: int = 5
) -> List[Dict]:
    """Search specs using FTS5."""
    sql = """
        SELECT s.id, s.spec_id, s.req_id, s.title, s.behavior_summary,
               s.has_eval, s.file_path, s.created_at,
               specs_fts.rank as score
        FROM specs_fts
        JOIN specs s ON specs_fts.rowid = s.rowid
        WHERE specs_fts MATCH ?
        ORDER BY rank LIMIT ?
    """
    cursor = conn.execute(sql, [escape_fts5_query(query), limit])
    columns = [desc[0] for desc in cursor.description]
    return [dict(zip(columns, row)) for row in cursor.fetchall()]


def search_continuity(
    conn: sqlite3.Connection,
    query: str,
    limit: int = 3
) -> List[Dict]:
    """Search continuity ledgers using FTS5."""
    sql = """
        SELECT c.id, c.session_name, c.goal, c.key_learnings, c.key_decisions,
               c.state_now, c.created_at,
               continuity_fts.rank as score
        FROM continuity_fts
        JOIN continuity c ON continuity_fts.rowid = c.rowid
        WHERE continuity_fts MATCH ?
        ORDER BY rank LIMIT ?
    """
    cursor = conn.execute(sql, [escape_fts5_query(query), limit])
    columns = [desc[0] for desc in cursor.description]
    return [dict(zip(columns, row)) for row in cursor.fetchall()]


def search_past_queries(
    conn: sqlite3.Connection,
    query: str,
    limit: int = 2
) -> List[Dict]:
    """Check if similar questions have been asked before."""
    sql = """
        SELECT q.id, q.question, q.answer, q.was_helpful, q.created_at,
               queries_fts.rank as score
        FROM queries_fts
        JOIN queries q ON queries_fts.rowid = q.rowid
        WHERE queries_fts MATCH ?
        ORDER BY rank LIMIT ?
    """
    cursor = conn.execute(sql, [escape_fts5_query(query), limit])
    columns = [desc[0] for desc in cursor.description]
    return [dict(zip(columns, row)) for row in cursor.fetchall()]


def format_results(results: Dict) -> str:
    """Format search results for display."""
    output = []
    
    # Past queries (compound learning)
    if results.get("past_queries"):
        output.append("## Previously Asked")
        for q in results["past_queries"]:
            question = q.get("question", "")[:100]
            answer = q.get("answer", "")[:200]
            output.append(f"- **Q:** {question}...")
            output.append(f"  **A:** {answer}...")
        output.append("")
    
    # Handoffs
    if results.get("handoffs"):
        output.append("## Relevant Handoffs")
        for h in results["handoffs"]:
            status_icon = {
                "SUCCEEDED": "✓",
                "PARTIAL": "◐",
                "FAILED": "✗"
            }.get(h.get("outcome"), "?")
            session = h.get("session_name", "unknown")
            task = h.get("task_number", "?")
            output.append(f"### {status_icon} {session}/task-{task}")
            
            summary = h.get("task_summary", "")[:200]
            output.append(f"**Summary:** {summary}")
            
            what_worked = h.get("what_worked")
            if what_worked:
                output.append(f"**What worked:** {what_worked[:200]}")
            
            what_failed = h.get("what_failed")
            if what_failed:
                output.append(f"**What failed:** {what_failed[:200]}")
            
            output.append(f"**File:** `{h.get('file_path', '')}`")
            output.append("")
    
    # Specs
    if results.get("specs"):
        output.append("## Relevant Specs")
        for s in results["specs"]:
            spec_id = s.get("spec_id", "SPEC-???")
            title = s.get("title", "Untitled")
            has_eval = "✓ eval" if s.get("has_eval") else "✗ no eval"
            output.append(f"### {spec_id}: {title} ({has_eval})")
            
            behavior = s.get("behavior_summary", "")[:200]
            if behavior:
                output.append(f"**Behavior:** {behavior}")
            
            output.append(f"**File:** `{s.get('file_path', '')}`")
            output.append("")
    
    # Plans
    if results.get("plans"):
        output.append("## Relevant Plans")
        for p in results["plans"]:
            title = p.get("title", "Untitled")
            output.append(f"### {title}")
            
            overview = p.get("overview", "")[:200]
            output.append(f"**Overview:** {overview}")
            output.append(f"**File:** `{p.get('file_path', '')}`")
            output.append("")
    
    # Continuity
    if results.get("continuity"):
        output.append("## Related Sessions")
        for c in results["continuity"]:
            session = c.get("session_name", "unknown")
            output.append(f"### Session: {session}")
            
            goal = c.get("goal", "")[:200]
            output.append(f"**Goal:** {goal}")
            
            key_learnings = c.get("key_learnings")
            if key_learnings:
                output.append(f"**Key learnings:** {key_learnings[:200]}")
            output.append("")
    
    if not any(results.values()):
        output.append("No relevant precedent found.")
        output.append("")
        output.append("**Tip:** Run `uv run python tools/artifact_index.py --all` to index existing artifacts.")
    
    return "\n".join(output)


def save_query(
    conn: sqlite3.Connection,
    question: str,
    answer: str,
    matches: Dict
):
    """Save query for compound learning."""
    query_id = hashlib.md5(
        f"{question}{datetime.now().isoformat()}".encode()
    ).hexdigest()[:12]
    
    conn.execute("""
        INSERT INTO queries (id, question, answer, handoffs_matched, plans_matched,
                           specs_matched, continuity_matched)
        VALUES (?, ?, ?, ?, ?, ?, ?)
    """, (
        query_id,
        question,
        answer,
        json.dumps([h["id"] for h in matches.get("handoffs", [])]),
        json.dumps([p["id"] for p in matches.get("plans", [])]),
        json.dumps([s["id"] for s in matches.get("specs", [])]),
        json.dumps([c["id"] for c in matches.get("continuity", [])]),
    ))
    conn.commit()


def main():
    """Main entry point."""
    parser = argparse.ArgumentParser(
        description="Search past work for relevant precedent"
    )
    parser.add_argument("query", nargs="*", help="Search query")
    parser.add_argument(
        "--type",
        choices=["handoffs", "plans", "specs", "continuity", "all"],
        default="all",
        help="Type of artifacts to search"
    )
    parser.add_argument(
        "--outcome",
        choices=["SUCCEEDED", "PARTIAL", "FAILED"],
        help="Filter handoffs by outcome"
    )
    parser.add_argument(
        "--limit",
        type=int,
        default=5,
        help="Maximum results per type"
    )
    parser.add_argument("--db", type=str, help="Custom database path")
    parser.add_argument(
        "--save",
        action="store_true",
        help="Save query for compound learning"
    )
    parser.add_argument(
        "--json",
        action="store_true",
        help="Output as JSON"
    )
    
    args = parser.parse_args()
    
    if not args.query:
        parser.print_help()
        return
    
    query = " ".join(args.query)
    
    db_path = get_db_path(args.db)
    if not db_path.exists():
        print(f"Database not found: {db_path}")
        print("Run: uv run python tools/artifact_index.py --all")
        return
    
    conn = sqlite3.connect(db_path)
    
    results = {}
    
    # Always check past queries first
    try:
        results["past_queries"] = search_past_queries(conn, query)
    except sqlite3.OperationalError:
        results["past_queries"] = []
    
    if args.type in ["handoffs", "all"]:
        try:
            results["handoffs"] = search_handoffs(
                conn, query, args.outcome, args.limit
            )
        except sqlite3.OperationalError:
            results["handoffs"] = []
    
    if args.type in ["specs", "all"]:
        try:
            results["specs"] = search_specs(conn, query, args.limit)
        except sqlite3.OperationalError:
            results["specs"] = []
    
    if args.type in ["plans", "all"]:
        try:
            results["plans"] = search_plans(conn, query, args.limit)
        except sqlite3.OperationalError:
            results["plans"] = []
    
    if args.type in ["continuity", "all"]:
        try:
            results["continuity"] = search_continuity(conn, query, args.limit)
        except sqlite3.OperationalError:
            results["continuity"] = []
    
    if args.json:
        print(json.dumps(results, indent=2, default=str))
    else:
        formatted = format_results(results)
        print(formatted)
        
        if args.save:
            save_query(conn, query, formatted, results)
            print("\n[Query saved for compound learning]")
    
    conn.close()


if __name__ == "__main__":
    main()

