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

1. Parse all issue numbers from the arguments
2. Fetch all issues in parallel via `gh issue view <number> --json number,title,body,labels`
3. For each issue, spawn a Task subagent with `subagent_type: "general-purpose"` **in a single message** for parallel execution. Each agent should:
   - Follow the editor skill (`.claude/skills/editor.md`) to create a worktree and implement changes
   - Run the project's test suite in the worktree
   - If tests pass, push the branch and create a PR via `gh pr create` linking the issue
   - If tests fail, fix the issues and re-run (up to 2 retries)
4. Collect all results and present a sprint summary:
   - For each issue: number, title, branch, PR URL (or failure reason)
   - Overall: how many succeeded, how many need attention
