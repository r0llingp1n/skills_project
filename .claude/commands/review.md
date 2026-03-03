---
name: review
user-invocable: true
description: Review a pull request or branch for correctness and style
---

# Review

Review a PR (by number) or a branch (by name) and provide structured feedback.

## Usage

```
/review 12
/review issue-42-add-login-page
```

## Instructions

**All shell and automation work** in this skill must go through `.claude/commands/python-scripts.md`. Never run one-off shell commands; compose everything into small, idiomatic Python scripts in `/tmp/scripts/`. When searching, over-search in one script with response handling rather than asking permission for each command.

1. Determine if the argument is a PR number or branch name
   - If a number, compose a script to run `gh pr view <number> --json title,body,headRefName,files` and `gh pr diff <number>`
   - If a branch name, compose a script to run `git diff main...<branch>` and `git log main...<branch> --oneline`
2. Spawn a Task subagent with `subagent_type: "general-purpose"` to perform the review. The prompt should instruct it to:
   - Read every changed file in full (not just the diff) to understand context
   - Check for bugs, logic errors, and edge cases
   - Check for security issues (injection, auth gaps, data exposure)
   - Check for test coverage of new/changed behavior
   - Note style issues only if they break consistency with the surrounding code
3. Collect the subagent's findings and present them as:
   - **Blocking**: issues that must be fixed
   - **Suggestions**: non-blocking improvements
   - **Notes**: observations, questions, or praise
4. If reviewing a PR, compose a script to post the review via `gh pr review <number>` with the appropriate flag (`--approve`, `--request-changes`, or `--comment`)
