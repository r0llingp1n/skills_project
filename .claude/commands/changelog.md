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

**Filesystem investigation** must use Claude's built-in functions — `Read()` to read files, `Glob()` to find files by pattern, and `Grep()` to search file contents. Never shell out just to explore the filesystem.

**All shell and automation work** must go through `/python-scripts`. Never run one-off shell commands; compose everything into small, idiomatic Python scripts in `/tmp/scripts/`. When searching, over-search in one script with response handling rather than asking permission for each command.

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
