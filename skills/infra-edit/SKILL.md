---
name: infra-edit
user-invocable: false
description: Subagent that modifies infrastructure config in its own worktree
---

# Infra Edit

Like the editor skill, but specialized for infrastructure changes. Works in an isolated worktree.

## Instructions

Read and follow `${CLAUDE_PLUGIN_ROOT}/skills/_shared/conventions.md`.

**Never rebase. Never squash.** Preserve every commit as authored. Do not use `git merge --squash`, `git rebase` (including interactive squash/fixup), `git commit --amend` on pushed commits, or `gh pr merge --squash`. Integrate upstream changes with merge commits (`git merge origin/main`).

1. Derive a branch name from the task description (e.g., `infra-add-staging-env`, `infra-fix-ci-caching`)
2. Compose a script to create the branch and worktree: `git worktree add /tmp/<branch-name> -b <branch-name>`
3. Do all work inside the new worktree directory
4. For the given infrastructure task:
   - Make the requested changes to config files
   - Compose a script to validate syntax where possible (`terraform fmt`, `docker compose config`, `actionlint`, etc.)
   - Ensure no secrets are hardcoded — use variables, env refs, or secret manager references
5. **Bump affected Helm charts.** If this change touched files under a chart
   directory, read that chart's `Chart.yaml` and increment its `version` by a patch
   semver step (`0.2.1` → `0.2.2`) so consumers receive a new release. Do **not**
   modify `appVersion`. Bump only charts this change actually touched — not every
   chart in the repo.
6. Compose a script to stage and commit with a descriptive message (e.g., `infra: add health checks to docker-compose (#18)`)
7. Report back with: branch name, files modified, charts bumped, validation results
