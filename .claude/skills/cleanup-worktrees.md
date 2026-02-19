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

1. Run `git worktree list` to get all worktrees
2. For each worktree (excluding the main one):
   - Check if the branch has been merged: `git branch --merged main | grep <branch>`
   - If merged, run `git worktree remove <path>` and `git branch -d <branch>`
3. Report which worktrees were cleaned up and which remain active
