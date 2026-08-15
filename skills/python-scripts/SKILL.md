---
name: python-scripts
user-invocable: true
description: Compose automation into small, idiomatic Python scripts for single-approval execution
---

# Python Scripts

Instead of running shell commands one at a time, compose them into small, idiomatic Python scripts in `/tmp/scripts/` so the user only has to approve once per block of operations.

## Instructions

**Shell and automation work goes through Python scripts.** This includes exploratory commands like listing files, searching code, and running `git` or `gh`. Do not run one-off shell commands; compose them into a script first. The one alternative is `/batch-scripts`, when the task is genuinely better expressed as shell — see Fallback below.

When you need to explore or search the codebase, write a single script that over-searches rather than asking permission for each command. Include response handling in the script (e.g., checking return codes, parsing output, conditional logic) so the script definitively answers your question in one run. It is always better to search more than necessary in one script than to run multiple small commands that each require approval.

1. Create the `/tmp/scripts/` directory if it doesn't exist
2. When you need to run **any** commands — whether a single search or a multi-step operation — write them into a Python script instead of executing them individually:
   - Name scripts descriptively: `/tmp/scripts/<step>-<description>.py` (e.g., `/tmp/scripts/01-setup-deps.py`)
   - Use only the standard library (`subprocess`, `pathlib`, `json`, `os`, `sys`, `shutil`, `re`, `glob`, etc.)
   - Use `subprocess.run(..., check=True)` for shell commands so failures are caught immediately
   - Keep scripts small, simple, and idiomatic — prefer straightforward procedural code over classes or abstractions
   - Add brief comments explaining each block
3. Before writing any script, validate that it does **not** contain any of the following — refuse and explain if it does:
   - `git push` in any form, `gh pr create`, `gh pr merge` — remote operations are
     reserved for `/submit-pr`, which only the user invokes, and a `PreToolUse` hook
     denies them elsewhere
   - `shutil.rmtree` or `rm -rf` on paths outside the repo working tree
   - Deletion of non-git-tracked files (check with `git ls-files` first; untracked files need explicit user confirmation)
   - Deploy commands (`deploy`, `publish`, `release`, `kubectl apply`, `terraform apply`, `docker push`, etc.)
   - Destructive git operations: `git reset --hard`, `git clean -f`, `git checkout -- .`, `git restore .`
   - Network-facing side effects: HTTP requests that mutate state (POST/PUT/DELETE to production APIs)
4. Make the script executable with `chmod +x`
5. Present the full script content to the user and run it with `python3 /tmp/scripts/<name>.py`
6. If a script fails, do **not** retry automatically — diagnose the failure and compose a fix script

## Safety rules

- Scripts may only create, modify, or delete files that are (a) tracked by git or
  inside the repo working tree, (b) inside `/tmp/scripts/`, or (c) inside a sprint
  worktree (`/tmp/sprint-<n>-lane-<k>/`). Anything else needs explicit confirmation.
  The `/tmp` exemptions matter: without them this rule forbids the script runner
  from writing its own scripts.
- Never force-push to any remote
- Never run deploy/publish/release commands
- When in doubt about whether an operation is destructive, ask the user before including it
- Always use `subprocess.run(..., check=True)` so failures are caught immediately

## Fallback

If this skill cannot satisfy the request (e.g., the task is better expressed as pure shell commands, or Python's standard library lacks needed functionality), fall through to `/batch-scripts` instead.
