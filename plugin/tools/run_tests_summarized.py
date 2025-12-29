#!/usr/bin/env python
"""Run tests and emit a compact JSON summary."""

import argparse, json, subprocess
from pathlib import Path
from typing import List, Tuple

def run_command(cmd: str) -> Tuple[int, List[str]]:
    try:
        proc = subprocess.Popen(
            cmd, shell=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
        )
    except OSError as e:
        return 127, [f"Failed to start command: {e}"]
    lines: List[str] = []
    assert proc.stdout is not None
    for line in proc.stdout:
        lines.append(line.rstrip("\n"))
    proc.wait()
    return proc.returncode, lines

def summarize(returncode: int, lines: List[str], tail: int) -> dict:
    markers = ("FAIL", "ERROR", "E   ", "AssertionError", "FAILED")
    fail_lines = [ln for ln in lines if any(m in ln for m in markers)]
    tail_lines = lines[-tail:] if tail > 0 else []
    if returncode == 0 and not fail_lines:
        status = "pass"
        summary = "All tests passed (exit code 0, no failure markers)."
    else:
        status = "fail"
        summary = f"Tests exited with code {returncode} and {len(fail_lines)} line(s) with failure markers."
    return {
        "status": status,
        "exit_code": returncode,
        "failure_marker_lines": len(fail_lines),
        "tail_lines": tail_lines,
        "summary": summary,
    }

def main():
    parser = argparse.ArgumentParser(description="Run tests and produce a compact JSON summary.")
    parser.add_argument("--cmd", default="pytest", help="Test command to run (default: pytest).")
    parser.add_argument("--tail", type=int, default=30, help="Number of tail lines to include.")
    parser.add_argument("--output", "-o", help="Optional output file path for summary JSON.")
    args = parser.parse_args()
    code, lines = run_command(args.cmd)
    data = summarize(code, lines, args.tail)
    text = json.dumps(data, indent=2)
    if args.output:
        Path(args.output).write_text(text, encoding="utf-8")
    else:
        print(text)
    raise SystemExit(code)

if __name__ == "__main__":
    main()
