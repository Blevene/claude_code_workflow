#!/usr/bin/env python
"""Generate a lightweight map of the repo for Claude Code."""

import argparse, json, os
from pathlib import Path
from typing import List, Dict

IGNORED_DIRS = {
    ".git", ".hg", ".svn", ".idea", ".vscode",
    ".venv", "venv", "node_modules",
    ".claude", ".design", ".pytest_cache",
    "__pycache__", "dist", "build", ".mypy_cache"
}

ENTRY_POINT_HINTS = {"main.py", "app.py", "index.ts", "index.js", "server.ts", "server.js"}
TEST_DIR_HINTS = {"tests", "test", "spec", "specs"}
TEST_FILE_PREFIXES = {"test_", "spec_"}
TEST_FILE_SUFFIXES = {"_test.py", "_spec.py", ".test.ts", ".test.js", ".spec.ts", ".spec.js"}

EXTENSION_LANG = {
    ".py": "python",
    ".ts": "typescript",
    ".tsx": "typescript-react",
    ".js": "javascript",
    ".jsx": "react",
    ".go": "go",
    ".rs": "rust",
    ".java": "java",
    ".kt": "kotlin",
    ".cs": "csharp",
}

def guess_language(path: Path) -> str:
    return EXTENSION_LANG.get(path.suffix, "unknown")

def is_test_file(path: Path) -> bool:
    name = path.name
    if any(name.startswith(p) for p in TEST_FILE_PREFIXES):
        return True
    if any(name.endswith(s) for s in TEST_FILE_SUFFIXES):
        return True
    if any(part.lower() in TEST_DIR_HINTS for part in path.parts):
        return True
    return False

def generate_repo_map(root: Path) -> Dict:
    modules: List[Dict] = []
    for dirpath, dirnames, filenames in os.walk(root):
        dirnames[:] = [d for d in dirnames if d not in IGNORED_DIRS]
        rel = Path(dirpath).relative_to(root)
        module_name = "root" if str(rel) == "." else str(rel)
        files = [Path(dirpath) / f for f in filenames]
        if not files:
            continue
        languages = {guess_language(f) for f in files if guess_language(f) != "unknown"}
        entry_points = [str(Path(dirpath) / f) for f in filenames if f in ENTRY_POINT_HINTS]
        tests = [str(f) for f in files if is_test_file(f)]
        modules.append({
            "name": module_name,
            "path": str(rel),
            "languages": sorted(languages),
            "entry_points": sorted(entry_points),
            "tests": sorted(tests),
            "file_count": len(files),
        })
    return {
        "root": str(root),
        "modules": sorted(modules, key=lambda m: m["path"]),
    }

def main():
    parser = argparse.ArgumentParser(description="Generate a lightweight repo map JSON.")
    parser.add_argument("--output", "-o", help="Output file path (defaults to stdout).")
    args = parser.parse_args()
    root = Path(".").resolve()
    data = generate_repo_map(root)
    text = json.dumps(data, indent=2)
    if args.output:
        Path(args.output).write_text(text, encoding="utf-8")
    else:
        print(text)

if __name__ == "__main__":
    main()
