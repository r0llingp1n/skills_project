#!/usr/bin/env bash
# TeammateIdle gate: a lane editor may not go idle while its lane is unresolved.
#
# Exit 2 prevents the teammate going idle and shows stderr to it, so this turns
# "report a terminal state before stopping" from prose into enforcement.
#
# Two design constraints:
#
#   1. The event-specific payload fields for TeammateIdle are not documented, so
#      this reads the sprint LEDGER as its source of truth and treats every field
#      beyond the common ones (session_id, cwd, agent_id) as optional.
#
#   2. The nudge is itself BOUNDED. A hook that blocks idle forever would violate
#      the same invariant it exists to enforce, so each agent gets at most
#      MAX_NUDGES blocks per sprint; after that it is allowed to stop. Anything
#      unexpected fails OPEN — a broken hook must never wedge a session.

set -euo pipefail

MAX_NUDGES=2
input=$(cat)

# Exit 2 is the block signal and must propagate. Anything else — including the
# interpreter failing to start — fails OPEN, so a broken hook cannot wedge a
# session. `|| exit 0` would swallow the block along with the crash.
set +e
python3 - "$input" "$MAX_NUDGES" <<'PY'
import json, os, pathlib, sys

def allow():   sys.exit(0)

try:
    data = json.loads(sys.argv[1])
    max_nudges = int(sys.argv[2])
except Exception:
    allow()

project = os.environ.get("CLAUDE_PROJECT_DIR") or data.get("cwd") or "."
agent = data.get("agent_id") or data.get("agent_name") or "unknown"
sprints = pathlib.Path(project) / ".claude" / "sprints"
if not sprints.is_dir():
    allow()

# newest sprint by number
try:
    d = max((p for p in sprints.iterdir() if (p / "ledger.json").exists()),
            key=lambda p: int("".join(c for c in p.name if c.isdigit()) or 0))
    ledger = json.loads((d / "ledger.json").read_text())
except Exception:
    allow()

TERMINAL = {"green", "UNFINISHED", "TESTS FAILING", "BLOCKED"}
unresolved = [l for l in ledger.get("lanes", [])
              if l.get("status") not in TERMINAL]
if not unresolved:
    allow()

# Bound the nudging: never block the same agent more than max_nudges times.
counter = d / f".nudges-{''.join(c for c in agent if c.isalnum() or c in '-_')}"
try:
    n = int(counter.read_text().strip()) if counter.exists() else 0
except Exception:
    n = 0
if n >= max_nudges:
    allow()
try:
    counter.write_text(str(n + 1))
except OSError:
    allow()

lanes = ", ".join(f"lane-{l.get('lane')} ({l.get('status', 'no status')})"
                  for l in unresolved)
sys.stderr.write(
    f"Not idle yet — {len(unresolved)} lane(s) have no terminal state: {lanes}.\n\n"
    "Every lane must end in exactly one of: green, UNFINISHED, TESTS FAILING, "
    "BLOCKED. If your lane is done, record its status and its what/testing "
    "entries in the ledger. If you exhausted 5 review cycles, record UNFINISHED "
    "with the outstanding findings grouped by lens. If it is not your lane, say "
    "so and stop.\n\n"
    f"(nudge {n + 1} of {max_nudges} — after that you may stop regardless)\n"
)
sys.exit(2)
PY
rc=$?
[ "$rc" -eq 2 ] && exit 2
exit 0
