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

**All shell and automation work** in this skill must go through `.claude/commands/python-scripts.md`. Never run one-off shell commands; compose everything into small, idiomatic Python scripts in `tmp/scripts/`. When searching, over-search in one script with response handling rather than asking permission for each command.

1. Compose a script that:
   - Runs `git worktree list` to get all worktrees
   - For each worktree (excluding the main one), checks if the branch has been merged via `git branch --merged main | grep <branch>`
   - For merged branches, runs `git worktree remove <path>` and `git branch -d <branch>`
2. Report which worktrees were cleaned up and which remain active
