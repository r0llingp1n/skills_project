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

**Filesystem investigation** must use Claude's built-in functions — `Read()` to read files, `Glob()` to find files by pattern, and `Grep()` to search file contents. Never shell out just to explore the filesystem.

**All shell and automation work** must go through `/python-scripts`. Never run one-off shell commands; compose everything into small, idiomatic Python scripts in `/tmp/scripts/`. When searching, over-search in one script with response handling rather than asking permission for each command.

**Sprint requires Agent Teams** (`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`). You run as the *lead*: you create tasks on the shared task list and spawn the plugin's real teammate agents (`aops-dev-workflow:editor`, `aops-dev-workflow:reviewer`), which claim and coordinate work through `TaskList`/`TaskUpdate`/`SendMessage`. No manual team setup is needed, and teammate cleanup is automatic on session exit.

1. Parse all issue numbers from the arguments
2. Compose a script to fetch all issues via `gh issue view <number> --json number,title,body,labels` (one per issue)
3. **Distribute work by file, not by type of change.** When an issue touches multiple files, create one edit task per file (each handling all changes for that file) rather than one task per type of change across files. This avoids merge conflicts and keeps each editor's scope self-contained. Otherwise create one edit task per issue.
4. As the lead, create the edit tasks and spawn teammates to work them:
   - For each unit of work from step 3, call `TaskCreate` on the shared task list with the issue number, title, body, and the specific file(s) that task owns.
   - Spawn `aops-dev-workflow:editor` teammates (`subagent_type: "aops-dev-workflow:editor"`) **in a single message** for parallel execution. Each editor claims an open task via `TaskUpdate`, works in its own git worktree and branch, implements the changes, runs the test suite (fixing and re-running on failure, up to 2 retries), pushes its branch, opens a PR via `gh pr create`, and reports the result back to the lead via `SendMessage`.
   - Spawn an `aops-dev-workflow:reviewer` teammate (`subagent_type: "aops-dev-workflow:reviewer"`) to review the resulting PRs as they land and report its verdicts back to the lead via `SendMessage`.
   - **Never squash.** Any merge must use `gh pr merge <number> --merge` so every commit is preserved with a merge commit; integrate upstream with `git merge` (never `git rebase`, never `--squash`).
5. Collect all teammate results and present a sprint summary:
   - For each issue: number, title, branch, PR URL, reviewer verdict (or failure reason)
   - Overall: how many succeeded, how many need attention
