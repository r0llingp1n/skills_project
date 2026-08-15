---
name: cleanup-worktrees
user-invocable: true
description: Remove worktrees for branches that have been merged
---

# Cleanup Worktrees

Remove git worktrees whose branches have been merged into main.

## Usage

```
/cleanup-worktrees
```

## Instructions

Read and follow `${CLAUDE_PLUGIN_ROOT}/skills/_shared/conventions.md`.

1. Compose a script that:
   - Runs `git worktree list` to get all worktrees
   - Builds the merged set **by exact name**, never by substring:
     `git branch --merged main --format='%(refname:short)'` into a Python `set`.
     A `grep <branch>` match would treat `issue-4` as merged whenever `issue-42`
     is, and delete live work.
   - For each worktree except the main one, checks membership in that set
   - For merged branches, deletes the **branch first** (`git branch -d <branch>`),
     and removes the worktree only if that succeeded. `git branch -d` refuses an
     unmerged branch, so this ordering means a misjudged branch can never lose its
     worktree — and any uncommitted work in it survives.
2. Never use `git branch -D`, and never `git worktree remove --force`. A worktree
   that refuses to go is reported, not forced.
3. Report which worktrees were cleaned up, which remain active, and any whose
   branch delete was refused (those are unmerged — say so explicitly)
