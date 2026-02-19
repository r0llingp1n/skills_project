---
name: create-pr
user-invocable: true
description: Create a pull request from a branch produced by an editor agent
---

# Create PR

Given a branch name (and optionally an issue number), push the branch and open a pull request.

## Usage

```
/create-pr issue-42-add-login-page
/create-pr issue-42-add-login-page 42
```

## Instructions

1. Parse the branch name from the first argument and optional issue number from the second
2. Run `git push -u origin <branch>` to push the branch
3. If an issue number was provided, run `gh issue view <number> --json title,body` for context
4. Run `gh pr create` with:
   - A concise title derived from the branch name or issue title
   - A body containing:
     - Summary of changes (use `git diff main...<branch> --stat` and `git log main...<branch> --oneline`)
     - `Closes #<number>` if an issue number was provided
5. Report the PR URL back to the user
