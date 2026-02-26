---
name: test-branch
user-invocable: true
description: Run the test suite against a branch in its worktree
---

# Test Branch

Run tests against a branch (typically one created by an editor agent) and report results.

## Usage

```
/test-branch issue-42-add-login-page
```

## Instructions

All shell commands in this skill must be composed into scripts following `.claude/commands/batch-scripts.md` — write them to `tmp/scripts/`, validate safety, and run as a single script per block.

1. Compose a script to locate the worktree via `git worktree list`, and if none exists, create one with `git worktree add ../<branch> <branch>`
2. Spawn a Task subagent with `subagent_type: "general-purpose"` to run tests in the worktree directory. The prompt should instruct it to:
   - Detect the project's test runner (look for `package.json`, `pytest.ini`, `Makefile`, `Cargo.toml`, etc.)
   - Run the full test suite
   - If tests fail, read the failing test files and changed source files to diagnose the issue
   - Report: pass/fail counts, failing test names, and a brief root-cause analysis for each failure
4. Present the results to the user with a clear pass/fail verdict
