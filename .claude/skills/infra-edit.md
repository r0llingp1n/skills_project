---
name: infra-edit
user-invocable: false
description: Subagent that modifies infrastructure config in its own worktree
---

# Infra Edit

Like the editor skill, but specialized for infrastructure changes. Works in an isolated worktree.

## Instructions

1. Derive a branch name from the task description (e.g., `infra-add-staging-env`, `infra-fix-ci-caching`)
2. Create the branch and worktree:
   ```
   git worktree add ../<branch-name> -b <branch-name>
   ```
3. Do all work inside the new worktree directory
4. For the given infrastructure task:
   - Make the requested changes to config files
   - Validate syntax where possible (`terraform fmt`, `docker compose config`, `actionlint`, etc.)
   - Ensure no secrets are hardcoded — use variables, env refs, or secret manager references
5. Stage and commit with a descriptive message (e.g., `infra: add health checks to docker-compose (#18)`)
6. Report back with: branch name, files modified, validation results
