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

1. Run `gh issue list --state open --json number,title,labels,assignees,createdAt --limit 50` to fetch open issues
2. If a label filter argument was provided (e.g., "bug"), filter results to matching labels
3. Group issues by label category:
   - **Bugs**: issues with "bug" label — highest priority
   - **Features**: issues with "feature" or "enhancement" labels
   - **Chores**: issues with "chore", "refactor", "docs", or "maintenance" labels
   - **Uncategorized**: issues with no matching labels
4. Within each group, sort by creation date (oldest first)
5. Present the summary as a table with: issue number, title, labels, assignee, and age
6. Suggest which issues to tackle next based on priority and dependencies
