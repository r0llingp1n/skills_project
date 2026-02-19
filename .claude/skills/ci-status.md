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

1. Determine if the argument is a PR number or branch name
2. If a PR number, run `gh pr checks <number>` to get check status
3. If a branch name, run `gh run list --branch <branch> --limit 5 --json name,status,conclusion`
4. Present results as a table: check name, status, conclusion, duration
5. If any checks failed:
   - Run `gh run view <run-id> --log-failed` to fetch failure logs
   - Provide a brief diagnosis of each failure
   - Suggest fixes if the cause is apparent
