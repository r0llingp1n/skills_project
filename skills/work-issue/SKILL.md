---
name: work-issue
user-invocable: true
description: Fetch one or more GitHub issues and start working on them in parallel
---

# Work Issue

Given one or more issue numbers, fetch each issue and spawn parallel editor agents to implement them.

## Usage

```
/work-issue 42
/work-issue 42 43 55
```

## Instructions

**Filesystem investigation** must use Claude's built-in functions — `Read()` to read files, `Glob()` to find files by pattern, and `Grep()` to search file contents. Never shell out just to explore the filesystem.

**All shell and automation work** must go through `/python-scripts`. Never run one-off shell commands; compose everything into small, idiomatic Python scripts in `/tmp/scripts/`. When searching, over-search in one script with response handling rather than asking permission for each command.

**This flow intentionally uses plain Task subagents** (`subagent_type: "general-purpose"`), not Agent Teams teammates, for its single-issue review→fix→merge loop. Team-based parallel orchestration with the `aops-dev-workflow:editor`/`aops-dev-workflow:reviewer` teammates lives in `/sprint`.

1. Parse all issue numbers from the arguments
2. Compose a script to fetch issue details: `gh issue view <number> --json number,title,body,labels,assignees` for each issue
3. **Classify each issue**: Check whether the issue involves UI/frontend work by examining labels (e.g., `ui`, `frontend`, `design`, `ux`, `css`) and issue body (mentions of visual changes, components, styling, layout, accessibility).
4. **Distribute work by file, not by type of change.** When an issue touches multiple files, spawn one editor per file (each handling all changes for that file) rather than one editor per type of change across files. This avoids merge conflicts and keeps each editor's scope self-contained.
5. Spawn one Task subagent per issue **in a single message** so they run in parallel. Each Task call should use:
   - `subagent_type: "general-purpose"`
   - A prompt containing:
     - The full instructions from `${CLAUDE_PLUGIN_ROOT}/skills/editor/SKILL.md`
     - The issue number, title, and body
     - Any relevant labels (e.g., "bug", "feature", "refactor")
     - **If the issue involves UI work**: also include the full instructions from `${CLAUDE_PLUGIN_ROOT}/skills/ui-review/SKILL.md`, which will apply the web design guidelines from `.agents/skills/web-design-guidelines/SKILL.md` and use the `frontend-design` skill (via `find-skills` / `anthropics/skills` registry) for the actual edits
   - The editor agent will create its own git worktree and branch to work in isolation
6. Collect the results from all editor agents as they return
7. **Create pull requests**: For each successfully completed issue, compose a script per branch to push and open a PR:
   - `git push -u origin <branch>` to push the branch
   - `gh pr create` with:
     - A concise title derived from the branch name or issue title
     - A body containing:
       - Summary of changes (use `git diff main...<branch> --stat` and `git log main...<branch> --oneline`)
       - `Closes #<number>` to link the issue
   - These can be done in parallel across branches
8. **Review each PR**: For each created PR, spawn a Task subagent per PR **in parallel** with `subagent_type: "general-purpose"`. Each subagent's prompt should include:
   - The full instructions from `${CLAUDE_PLUGIN_ROOT}/skills/review/SKILL.md`
   - The PR number
   - An instruction to return structured findings (Blocking / Suggestions / Notes) but **not** to post a GH review or approve/request-changes — just return the findings
9. **Fix review issues**: For each PR that has **Blocking** findings, spawn a Task subagent per PR **in parallel** with `subagent_type: "general-purpose"`. Each subagent's prompt should include:
   - The full instructions from `${CLAUDE_PLUGIN_ROOT}/skills/editor/SKILL.md` (but skip the branch/worktree creation — the worktree at `/tmp/<branch-name>/` already exists)
   - The list of Blocking findings to fix
   - An instruction to work in the existing worktree (`/tmp/<branch-name>/`), commit the fixes, and push the updated branch
   - After all fix subagents complete, loop back to step 8 to re-review. Repeat until no Blocking findings remain (max 3 iterations to avoid infinite loops).
10. **Post review approval**: Once a PR has no Blocking findings, compose a script to post an approving review via `gh pr review <number> --approve --body "Automated review: all clear"`
11. **Recommend follow-up work**: Collect all **Suggestions** and **Notes** from the final review pass across all PRs. Present them to the user as recommended additional work, grouped by theme (e.g., test coverage, refactoring, documentation, performance). For each recommendation, include:
   - A clear description of the work
   - Which files/areas are affected
   - Why it's worth doing
   - Ask the user which (if any) recommendations they'd like to pursue.
12. **Create follow-up issues**: For each recommendation the user approves, compose a script to create a new GitHub issue via `gh issue create` with:
   - A descriptive title
   - A body containing the recommendation details, affected files, and a reference to the original issue/PR (e.g., "Follow-up from #42")
   - Appropriate labels if applicable
   - Then immediately apply `/work-issue` to the newly created issue numbers to begin working on them.
13. **Merge**: Present the user with the list of approved PRs (from the original work and any follow-up work) and ask for confirmation before merging. Only merge PRs the user explicitly approves. Compose a script to merge approved PRs via `gh pr merge <number> --merge --delete-branch`. **Never squash** — always use `--merge` so every commit is preserved with a merge commit.
14. Present a unified summary to the user:
   - For each issue: issue number, title, branch name, list of changes made, **PR URL**, review iterations needed
   - For UI issues: design decisions made and guidelines compliance notes
   - Follow-up issues created and their status
   - Any issues that failed or need follow-up
