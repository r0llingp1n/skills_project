---
name: batch-scripts
user-invocable: true
description: Compose bash commands into shell scripts for single-approval execution
---

# Batch Scripts

Instead of running bash commands one at a time, compose them into executable shell scripts in `tmp/scripts/` so the user only has to approve once per block of operations.

## Instructions

1. Create the `tmp/scripts/` directory if it doesn't exist (`mkdir -p tmp/scripts/`)
2. When you need to run a sequence of bash commands, write them into a single shell script instead of executing them individually:
   - Name scripts descriptively: `tmp/scripts/<step>-<description>.sh` (e.g., `tmp/scripts/01-setup-deps.sh`)
   - Start every script with `#!/usr/bin/env bash` and `set -euo pipefail`
   - Add brief comments explaining each block of commands
3. Before writing any script, validate that it does **not** contain any of the following — refuse and explain if it does:
   - `git push --force`, `git push -f`, or any force-push variant
   - `rm -rf` or `rm -r` on paths outside the repo working tree
   - Deletion of non-git-tracked files (check with `git ls-files` first; untracked files need explicit user confirmation)
   - Deploy commands (`deploy`, `publish`, `release`, `kubectl apply`, `terraform apply`, `docker push`, etc.)
   - Destructive git operations: `git reset --hard`, `git clean -f`, `git checkout -- .`, `git restore .`
   - Network-facing side effects: HTTP requests that mutate state (POST/PUT/DELETE to production APIs)
4. Make the script executable with `chmod +x`
5. Present the full script content to the user and run it with `bash tmp/scripts/<name>.sh`
6. If a script fails, do **not** retry automatically — diagnose the failure and compose a fix script

## Safety rules

- Scripts may only create, modify, or delete files that are tracked by git or are inside the repo working tree
- Never force-push to any remote
- Never run deploy/publish/release commands
- When in doubt about whether an operation is destructive, ask the user before including it
- All scripts must use `set -euo pipefail` so failures are caught immediately
