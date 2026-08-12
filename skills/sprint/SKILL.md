---
name: sprint
user-invocable: true
description: Work multiple issues in parallel as a coordinated sprint
---

# Sprint

Run a batch of issues through the **full per-issue work-cycle** — edit → test → PR → review → fix → approve → merge — in parallel, coordinated as an Agent Team. This is the team-based equivalent of `/work-issue`: every issue gets the same complete cycle, executed by teammates instead of nested subagents.

## Usage

```
/sprint 42 43 55
```

## Instructions

**Filesystem investigation** must use Claude's built-in functions — `Read()` to read files, `Glob()` to find files by pattern, and `Grep()` to search file contents. Never shell out just to explore the filesystem.

**All shell and automation work** must go through `/python-scripts`. Never run one-off shell commands; compose everything into small, idiomatic Python scripts in `/tmp/scripts/`. When searching, over-search in one script with response handling rather than asking permission for each command.

**Sprint requires Agent Teams** (`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`). You run as the *lead*: you create tasks on the shared task list and spawn the plugin's teammate agents (`aops-dev-workflow:editor`, `aops-dev-workflow:reviewer`), which claim and coordinate work through `TaskList`/`TaskUpdate`/`SendMessage`. No manual team setup is needed, and teammate cleanup is automatic on session exit. Because teammates cannot spawn their own subagents, the **review→fix loop runs through team messaging** (reviewer ↔ lead ↔ editor), not nested subagents.

1. Parse all issue numbers from the arguments.
2. Compose a script to fetch each issue via `gh issue view <number> --json number,title,body,labels`.
3. **Distribute work by file, not by type of change.** When an issue touches multiple files, create one edit task per file (each handling all changes for that file) rather than one task per type of change across files. This avoids merge conflicts and keeps each editor's scope self-contained. Otherwise create one edit task per issue.
4. **Create tasks and spawn the team.**
   - For each unit of work from step 3, call `TaskCreate` on the shared task list with the issue number, title, body, and the specific file(s) that task owns.
   - Spawn `aops-dev-workflow:editor` teammates (`subagent_type: "aops-dev-workflow:editor"`) **in a single message** for parallel execution, plus one `aops-dev-workflow:reviewer` teammate (`subagent_type: "aops-dev-workflow:reviewer"`).
5. **Edit** (editor teammates). Each editor claims an open edit task via `TaskUpdate`, works in its own git worktree and branch, implements the change, runs the test suite and build (fixing and re-running on failure, up to 2 retries), commits with a message referencing the issue number, marks the task done, and messages the lead that the branch is ready. Editors do **not** push or open PRs — the lead does that.
6. **Open PRs** (lead). For each ready branch, compose a script to push it (`git push -u origin <branch>`) and open a PR via `gh pr create` — title derived from the issue, body containing a change summary (`git diff main...<branch> --stat`, `git log main...<branch> --oneline`) and `Closes #<number>`. Then `TaskCreate` a **review task** for that PR so the reviewer can claim it.
7. **Review** (reviewer teammate). The reviewer claims each review task via `TaskUpdate`, reads the changed files in full, and messages the lead a verdict grouped as **Blocking / Suggestions / Notes**.
8. **Fix loop.** For any PR with **Blocking** findings, the lead relays them to the owning editor as a fix request; the editor fixes in its existing worktree, commits (`fix: address review feedback (#<number>)`), and messages back; the lead re-pushes and the reviewer re-reviews. Repeat until no Blocking findings remain (**max 3 iterations** to avoid loops).
9. **Approve.** Once a PR has no Blocking findings, the reviewer approves it (`gh pr review <number> --approve`).
10. **Recommend follow-up work.** Collect all **Suggestions** and **Notes** across PRs, group them by theme (test coverage, refactoring, docs, performance), and present them to the user with affected files and rationale. Ask which (if any) to pursue; for approved ones, compose a script to open follow-up issues via `gh issue create` (referencing the original issue/PR, e.g. "Follow-up from #42").
11. **Merge.** Present the approved PRs and ask the user for confirmation. Only merge PRs the user explicitly approves. Compose a script to merge them via `gh pr merge <number> --merge --delete-branch`. **Never squash** — always use `--merge` so every commit is preserved with a merge commit; integrate upstream with `git merge` (never `git rebase`, never `--squash`).
12. **Sprint summary.** Present, for each issue: number, title, branch, PR URL, review iterations needed, reviewer verdict, and merge status (or failure reason). Overall: how many succeeded, how many need attention, and any follow-up issues created.
