---
name: sprint
user-invocable: true
description: Work multiple issues in parallel as a coordinated sprint
---

# Sprint

Run a batch of issues through the full workflow: edit, test, review, and PR — all in parallel.

## Usage

```
/sprint 42 43 55
```

## Instructions

All shell commands in this skill must be composed into scripts following `.claude/commands/batch-scripts.md` — write them to `tmp/scripts/`, validate safety, and run as a single script per block.

1. Parse all issue numbers from the arguments
2. Compose a script to fetch all issues via `gh issue view <number> --json number,title,body,labels` (one per issue)
3. For each issue, spawn a Task subagent with `subagent_type: "general-purpose"` **in a single message** for parallel execution. Each agent should:
   - Follow the editor skill (`.claude/commands/editor.md`) to create a worktree and implement changes
   - Compose scripts for running the test suite, pushing the branch, and creating a PR via `gh pr create`
   - If tests fail, fix the issues and re-run (up to 2 retries)
4. Collect all results and present a sprint summary:
   - For each issue: number, title, branch, PR URL (or failure reason)
   - Overall: how many succeeded, how many need attention
