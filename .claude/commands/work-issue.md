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

1. Parse all issue numbers from the arguments
2. For each issue, run `gh issue view <number> --json number,title,body,labels,assignees` to fetch the details
3. **Classify each issue**: Check whether the issue involves UI/frontend work by examining labels (e.g., `ui`, `frontend`, `design`, `ux`, `css`) and issue body (mentions of visual changes, components, styling, layout, accessibility).
4. Spawn one Task subagent per issue **in a single message** so they run in parallel. Each Task call should use:
   - `subagent_type: "general-purpose"`
   - A prompt containing:
     - The full instructions from `.claude/commands/editor.md`
     - The issue number, title, and body
     - Any relevant labels (e.g., "bug", "feature", "refactor")
     - **If the issue involves UI work**: also include the full instructions from `.claude/commands/ui-review.md`, which will apply the web design guidelines from `.agents/skills/web-design-guidelines/SKILL.md` and use the `frontend-design` skill (via `find-skills` / `anthropics/skills` registry) for the actual edits
   - The editor agent will create its own git worktree and branch to work in isolation
5. Collect the results from all editor agents as they return
6. **Create pull requests**: For each successfully completed issue, push the branch and open a PR:
   - Run `git push -u origin <branch>` to push the branch
   - Run `gh pr create` with:
     - A concise title derived from the branch name or issue title
     - A body containing:
       - Summary of changes (use `git diff main...<branch> --stat` and `git log main...<branch> --oneline`)
       - `Closes #<number>` to link the issue
   - These can be done in parallel across branches
7. Present a unified summary to the user:
   - For each issue: issue number, title, branch name, list of changes made, and **PR URL**
   - For UI issues: design decisions made and guidelines compliance notes
   - Any issues that failed or need follow-up
