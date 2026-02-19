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
3. Spawn one Task subagent per issue **in a single message** so they run in parallel. Each Task call should use:
   - `subagent_type: "general-purpose"`
   - A prompt containing:
     - The full instructions from `.claude/skills/editor.md`
     - The issue number, title, and body
     - Any relevant labels (e.g., "bug", "feature", "refactor")
   - The editor agent will create its own git worktree and branch to work in isolation
4. Collect the results from all editor agents as they return
5. Present a unified summary to the user:
   - For each issue: issue number, title, branch name, and list of changes made
   - Any issues that failed or need follow-up
