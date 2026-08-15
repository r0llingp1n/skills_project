# Shared Conventions

These rules apply to every skill and agent in this plugin. Skills reference this
file by path. Agents **inline** it, because an agent's `tools:` list may not include
`Skill`, and prose that assumes an unavailable tool is dead text.

## Filesystem investigation

Use the built-in functions — `Read()` for file contents, `Glob()` to find files by
pattern, `Grep()` to search contents. Never shell out just to explore the filesystem.

## Shell and automation work

Compose commands into scripts rather than running them one at a time, so the user
approves once per block of operations instead of once per command.

- Write scripts to `/tmp/scripts/<step>-<description>.py` (Python, preferred) or
  `.sh` (bash, fallback).
- Python: standard library only; `subprocess.run(..., check=True)` so failures
  surface immediately; small, procedural, commented.
- Bash: `#!/usr/bin/env bash` and `set -euo pipefail`.
- When searching, **over-search in one script** with response handling built in, so
  the script definitively answers the question in one run. One broad script beats
  five narrow ones that each need approval.
- Present the script before running it.
- If a script fails, do **not** retry automatically. Diagnose, then compose a fix.

### Refuse to write scripts containing

- `git push --force` / `git push -f` or any force-push variant
- `rm -rf`, `rm -r`, or `shutil.rmtree` on paths outside the repo working tree,
  `/tmp/scripts/`, or a sprint worktree
- Deletion of non-git-tracked files without explicit user confirmation
  (check `git ls-files` first)
- Deploy commands — `deploy`, `publish`, `release`, `kubectl apply`,
  `terraform apply`, `docker push`
- Destructive git — `git reset --hard`, `git clean -f`, `git checkout -- .`,
  `git restore .`
- State-mutating network calls to production APIs (POST/PUT/DELETE)

### Writable locations

Scripts may create, modify, or delete files that are:

1. tracked by git or inside the repo working tree,
2. inside `/tmp/scripts/`, or
3. inside a sprint worktree (`/tmp/sprint-<n>-lane-<k>/`).

Anything else needs explicit user confirmation.

## Remote operations are gated

`git push`, `gh pr create`, and `gh pr merge` are **reserved for `/submit-pr`**,
which only the user invokes. No skill and no agent may run them. A `PreToolUse`
hook enforces this, but treat the rule as binding regardless of the hook.

## Git history

**Never rebase. Never squash.** Every commit is preserved exactly as authored.

- Integrate upstream with merge commits: `git merge origin/main`
- Never `git rebase` (including interactive squash/fixup), never `git merge --squash`
- Never `git commit --amend` on pushed commits, never force-push a shared branch
- Merge PRs with `gh pr merge <n> --merge` — never `--squash`, never `--rebase`
