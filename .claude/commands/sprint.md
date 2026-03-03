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

**All shell and automation work** in this skill must go through `.claude/commands/python-scripts.md`. Never run one-off shell commands; compose everything into small, idiomatic Python scripts in `tmp/scripts/`. When searching, over-search in one script with response handling rather than asking permission for each command.

1. Parse all issue numbers from the arguments
2. Compose a script to fetch all issues via `gh issue view <number> --json number,title,body,labels` (one per issue)
3. **Distribute work by file, not by type of change.** When an issue touches multiple files, spawn one editor per file (each handling all changes for that file) rather than one editor per type of change across files. This avoids merge conflicts and keeps each editor's scope self-contained.
4. For each issue, spawn a Task subagent with `subagent_type: "general-purpose"` **in a single message** for parallel execution. Each agent should:
   - Follow the editor skill (`.claude/commands/editor.md`) to create a worktree and implement changes
   - Compose scripts for running the test suite, pushing the branch, and creating a PR via `gh pr create`
   - If tests fail, fix the issues and re-run (up to 2 retries)
5. Collect all results and present a sprint summary:
   - For each issue: number, title, branch, PR URL (or failure reason)
   - Overall: how many succeeded, how many need attention
