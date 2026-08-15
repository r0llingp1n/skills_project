#!/usr/bin/env bash
# TaskCompleted gate: a lane task may not be marked complete while its ledger
# entry still carries open Blocking findings and no terminal state.
#
# Exit 2 prevents completion and shows stderr, so a task cannot be closed out
# from under unresolved review findings — which is how an UNFINISHED lane would
# otherwise slip into /submit-pr looking finished.
#
# Like the TeammateIdle gate, this reads the LEDGER rather than the undocumented
# event payload, and fails OPEN on anything unexpected. It does not need a nudge
# counter: blocking a completion is not a loop, it just requires the ledger be
# brought up to date first.

set -euo pipefail

input=$(cat)

# Exit 2 is the block signal and must propagate. Anything else — including the
# interpreter failing to start — fails OPEN, so a broken hook cannot wedge a
# session. `|| exit 0` would swallow the block along with the crash.
set +e
python3 - "$input" <<'PY'
import json, os, pathlib, sys

def allow(): sys.exit(0)

try:
    data = json.loads(sys.argv[1])
except Exception:
    allow()

project = os.environ.get("CLAUDE_PROJECT_DIR") or data.get("cwd") or "."
sprints = pathlib.Path(project) / ".claude" / "sprints"
if not sprints.is_dir():
    allow()

try:
    d = max((p for p in sprints.iterdir() if (p / "ledger.json").exists()),
            key=lambda p: int("".join(c for c in p.name if c.isdigit()) or 0))
    ledger = json.loads((d / "ledger.json").read_text())
except Exception:
    allow()

# Which lane is this task about? The payload field names are undocumented, so
# match a lane number or branch appearing anywhere in the payload's text.
blob = json.dumps(data).lower()
TERMINAL = {"green", "UNFINISHED", "TESTS FAILING", "BLOCKED"}

offenders = []
for l in ledger.get("lanes", []):
    ident = [f"lane-{l.get('lane')}", str(l.get("branch", "")).lower()]
    if not any(i and i in blob for i in ident):
        continue
    if l.get("outstanding") and l.get("status") not in TERMINAL:
        offenders.append(l)

if not offenders:
    allow()

msg = []
for l in offenders:
    msg.append(f"lane-{l.get('lane')} status={l.get('status', 'unset')!r} "
               f"with {len(l['outstanding'])} open Blocking finding(s):")
    for o in l["outstanding"]:
        msg.append(f"  - {o.get('lens')} {o.get('file')}:{o.get('line')} — {o.get('finding')}")

sys.stderr.write(
    "Task not completed — the ledger still shows open Blocking findings for it.\n\n"
    + "\n".join(msg)
    + "\n\nEither resolve them and clear `outstanding`, or record the lane's "
      "terminal state (UNFINISHED with the findings kept) and complete the task "
      "then. A lane closed with findings still open reaches /submit-pr looking "
      "finished when it is not.\n"
)
sys.exit(2)
PY
rc=$?
[ "$rc" -eq 2 ] && exit 2
exit 0
