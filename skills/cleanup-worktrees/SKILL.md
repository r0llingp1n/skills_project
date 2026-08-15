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
   - For merged branches only, runs `git worktree remove <path>` and **then**
     `git branch -d <branch>`. This order is forced by git: a branch checked out in
     a worktree cannot be deleted at all (`cannot delete branch 'x' used by worktree
     at ...`), so the worktree must go first.

2. **Three independent safety nets protect real work.** Rely on all three; never
   defeat any of them:

   | Net | Protects against | Mechanism |
   | --- | --- | --- |
   | Exact-name merged check | mis-identifying the branch | `set` membership, never `grep` |
   | `git worktree remove` without `--force` | losing **uncommitted** work | refuses: `contains modified or untracked files` |
   | `git branch -d` (never `-D`) | losing **committed** work | refuses to delete an unmerged branch |

   Because removal happens before the branch delete, the middle net is the one
   standing between a misjudged branch and its uncommitted changes. **Never pass
   `--force` to `git worktree remove`, and never use `git branch -D`.** A worktree
   that refuses to go is reported, not forced.

3. Report which worktrees were cleaned up, which remain active, and — separately —
   any whose removal or branch delete was **refused**. A refusal means real work is
   there: name the path and say what git objected to, so the user can decide.
