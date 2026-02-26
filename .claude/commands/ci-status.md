---
name: ci-status
user-invocable: true
description: Check CI/CD pipeline status for a branch or PR
---

# CI Status

Check the status of CI checks for a PR or branch.

## Usage

```
/ci-status 12
/ci-status issue-42-add-login-page
```

## Instructions

All shell commands in this skill must be composed into scripts following `.claude/commands/batch-scripts.md` — write them to `tmp/scripts/`, validate safety, and run as a single script per block.

1. Determine if the argument is a PR number or branch name
2. Compose a script to fetch check status:
   - If a PR number: `gh pr checks <number>`
   - If a branch name: `gh run list --branch <branch> --limit 5 --json name,status,conclusion`
3. Present results as a table: check name, status, conclusion, duration
4. If any checks failed, compose a script to run `gh run view <run-id> --log-failed` to fetch failure logs
   - Provide a brief diagnosis of each failure
   - Suggest fixes if the cause is apparent
