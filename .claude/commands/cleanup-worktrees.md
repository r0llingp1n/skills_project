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

All shell commands in this skill must be composed into scripts following `.claude/commands/batch-scripts.md` — write them to `tmp/scripts/`, validate safety, and run as a single script per block.

1. Compose a script that:
   - Runs `git worktree list` to get all worktrees
   - For each worktree (excluding the main one), checks if the branch has been merged via `git branch --merged main | grep <branch>`
   - For merged branches, runs `git worktree remove <path>` and `git branch -d <branch>`
2. Report which worktrees were cleaned up and which remain active
