---
name: update-docs
user-invocable: true
description: Update project documentation to reflect recent changes
---

# Update Docs

Scan recent changes and update documentation accordingly.

## Usage

```
/update-docs
/update-docs issue-42-add-login-page
/update-docs --since v1.2.0
```

## Instructions

All shell commands in this skill must be composed into scripts following `.claude/commands/batch-scripts.md` — write them to `tmp/scripts/`, validate safety, and run as a single script per block.

1. Compose a script to determine the scope of changes:
   - If a branch is provided, diff against main: `git diff main...<branch> --name-only`
   - If `--since <ref>` is provided, diff from that ref: `git diff <ref>...HEAD --name-only`
   - If no argument, use the last 10 commits: `git diff HEAD~10 --name-only`
2. Read the changed source files to understand what was added or modified
3. Identify existing docs by scanning for: `README.md`, `docs/`, `CHANGELOG.md`, `API.md`, wiki references
4. Spawn a Task subagent with `subagent_type: "general-purpose"` to update docs. The prompt should instruct it to:
   - Update README if new features, dependencies, or setup steps were added
   - Update API docs if endpoints, functions, or interfaces changed
   - Add CHANGELOG entries for user-facing changes (follow Keep a Changelog format if a CHANGELOG exists)
   - Update inline doc comments only if public API signatures changed
   - Do NOT create new doc files unless there's genuinely new content with no existing home
5. All doc changes go in the same branch/worktree as the code changes (or main if reviewing merged work)
6. Report what was updated and why
