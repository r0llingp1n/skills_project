---
name: editor
user-invocable: false
description: An independent editor agent that works in its own git worktree and branch
---

# Editor

This skill is invoked as a subagent by work-issue. It receives an issue description and works on the implementation in an isolated git worktree and branch.

## Instructions

All shell commands in this skill must be composed into scripts following `.claude/commands/batch-scripts.md` — write them to `tmp/scripts/`, validate safety, and run as a single script per block.

1. Derive a branch name from the issue title (e.g., `issue-42-add-login-page`), keeping it short and kebab-cased
2. Compose a script to create the branch and worktree: `git worktree add ../<branch-name> -b <branch-name>`
3. Do all work inside the new worktree directory (`../<branch-name>/`)
4. Implement the changes described in the issue prompt
5. Compose a script to stage and commit your changes with a message referencing the issue number (e.g., `fix: resolve login bug (#42)`)
6. When finished, report back with:
   - The branch name
   - A summary of changes made
   - A list of files modified
7. Do NOT push or create a PR — leave that to the caller
8. When editing, always favor the most idiomatic and human readable solution.

## Code Style: Interface-First Design

- **Always define interfaces for important types** (services, repositories, clients, handlers, etc.) before or alongside their concrete implementations.
- **Pass interfaces, not concrete types**, in function signatures, struct fields, and constructor parameters.
- **Implement interfaces as needed** — create concrete structs that satisfy the interface, but consumers should only depend on the interface.
- This enables testability (mocks/stubs), loose coupling, and clean dependency injection.
- Keep interfaces small and focused (prefer many small interfaces over one large one).
