---
name: changelog
user-invocable: true
description: Generate or update CHANGELOG from merged PRs and commits
---

# Changelog

Generate or update the CHANGELOG based on recent activity.

## Usage

```
/changelog
/changelog v1.2.0..v1.3.0
/changelog --unreleased
```

## Instructions

All shell commands in this skill must be composed into scripts following `.claude/commands/batch-scripts.md` — write them to `tmp/scripts/`, validate safety, and run as a single script per block.

1. Determine the range:
   - If a range is given (e.g., `v1.2.0..v1.3.0`), use it
   - If `--unreleased`, use the latest tag to HEAD: find latest tag with `git describe --tags --abbrev=0`, then diff from there
   - If no argument, default to `--unreleased`
2. Compose a script to gather changes:
   - `git log <range> --oneline` for commit summaries
   - `gh pr list --state merged --json number,title,labels,mergedAt` filtered to the range
3. Categorize entries using conventional commit prefixes or PR labels:
   - **Added**: new features (`feat`, `feature`, `enhancement`)
   - **Fixed**: bug fixes (`fix`, `bug`)
   - **Changed**: modifications to existing behavior (`refactor`, `change`)
   - **Infrastructure**: CI/CD, Docker, deploy changes (`infra`, `ci`, `devops`)
   - **Documentation**: doc updates (`docs`)
   - **Removed**: deleted features or deprecated code
4. If `CHANGELOG.md` exists, prepend the new section. If not, create one following Keep a Changelog format
5. Report the new entries added
