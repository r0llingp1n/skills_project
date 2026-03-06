---
name: triage
user-invocable: true
description: List and prioritize open issues for the current repo
---

# Triage

Scan open issues and present a prioritized summary.

## Usage

```
/triage
/triage bug
/triage --limit 20
```

## Instructions

**Filesystem investigation** must use Claude's built-in functions — `Read()` to read files, `Glob()` to find files by pattern, and `Grep()` to search file contents. Never shell out just to explore the filesystem.

**All shell and automation work** must go through `/python-scripts`. Never run one-off shell commands; compose everything into small, idiomatic Python scripts in `/tmp/scripts/`. When searching, over-search in one script with response handling rather than asking permission for each command.

1. Compose a script to run `gh issue list --state open --json number,title,labels,assignees,createdAt --limit 50` to fetch open issues
2. If a label filter argument was provided (e.g., "bug"), filter results to matching labels
3. Group issues by label category:
   - **Bugs**: issues with "bug" label — highest priority
   - **Features**: issues with "feature" or "enhancement" labels
   - **Chores**: issues with "chore", "refactor", "docs", or "maintenance" labels
   - **Uncategorized**: issues with no matching labels
4. Within each group, sort by creation date (oldest first)
5. Present the summary as a table with: issue number, title, labels, assignee, and age
6. Suggest which issues to tackle next based on priority and dependencies
