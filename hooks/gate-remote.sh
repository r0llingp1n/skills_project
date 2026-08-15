#!/usr/bin/env bash
# PreToolUse(Bash) gate: remote-mutating git/gh operations are reserved for the
# user-invoked /submit-pr skill.
#
# Sprint editors and reviewers work entirely locally. Pushing a branch or opening a
# pull request is a user decision, so this hook denies those commands unless
# /submit-pr has recorded the user's approval for THIS session.
#
# Approval marker: .claude/sprints/<n>/SUBMIT_APPROVED containing the session_id.
# /submit-pr writes it only after the user confirms the assembled PR body, and
# removes it once the PR is open.
#
# This stops drift, not a determined adversary: an agent with Bash could in
# principle write the marker itself. Drift is the actual failure mode here.

set -euo pipefail

input=$(cat)

python3 - "$input" <<'PY'
import json, os, re, sys, pathlib

try:
    data = json.loads(sys.argv[1])
except (json.JSONDecodeError, IndexError):
    sys.exit(0)  # unparseable input: stay out of the way

if data.get("tool_name") != "Bash":
    sys.exit(0)

command = (data.get("tool_input") or {}).get("command", "")

GATED = re.compile(
    r"""(?x)
    (^|[;&|]|\s)          # command start or a shell separator
    (
        git \s+ (-C \s+ \S+ \s+)? push        # git push, incl. -C <dir>
      | gh  \s+ pr  \s+ (create|merge|ready)  # opening or merging a PR
      | gh  \s+ release \s+ create
      | gh  \s+ api .* (-X|--method) \s* (POST|PUT|PATCH|DELETE)
    )
    """,
    re.IGNORECASE,
)

if not GATED.search(command):
    sys.exit(0)

# Look for an approval marker belonging to this session.
project = os.environ.get("CLAUDE_PROJECT_DIR") or data.get("cwd") or "."
session = data.get("session_id", "")
approved = False

sprints = pathlib.Path(project) / ".claude" / "sprints"
if session and sprints.is_dir():
    for marker in sprints.glob("*/SUBMIT_APPROVED"):
        try:
            if marker.read_text().strip() == session:
                approved = True
                break
        except OSError:
            continue

if approved:
    sys.exit(0)

reason = (
    "Remote operations are gated behind /submit-pr.\n\n"
    f"Blocked: {command.strip()[:200]}\n\n"
    "Sprints work entirely locally: lanes are merged into the sprint branch on "
    "this machine and nothing is pushed. Only the user runs /submit-pr, which "
    "confirms the pull request body and then pushes.\n\n"
    "If you are /submit-pr and reached this point, the user has not confirmed yet."
)

print(json.dumps({
    "hookSpecificOutput": {
        "permissionDecision": "deny",
    },
    "systemMessage": reason,
}))
PY
