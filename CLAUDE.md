# AutonomousOps Dev Workflow Plugin

This repository is a **Claude Code plugin** (`aops-dev-workflow`) implementing a
plan → sprint → submit pipeline built on Agent Teams.

## Structure

- `.claude-plugin/plugin.json` — plugin manifest
- `.claude-plugin/marketplace.json` — single-plugin marketplace for local install
- `skills/<name>/SKILL.md` — skills; `user-invocable: true` ones appear as `/<name>`
- `skills/_shared/` — the contracts every other file references:
  - `limits.md` — every loop's counter, cap, and terminal state
  - `conventions.md` — filesystem and script rules
  - `ticket-format.md` — the ticket body `/sprint` parses to compute lanes
  - `ledger.md` — the sprint ledger schema that feeds the PR body
- `agents/<name>.md` — Agent-Teams teammates (`editor`, `reviewer`)
- `hooks/` — the `PreToolUse` gate on remote operations

Not distributed (author-local, gitignored): `.claude/settings*.json`,
`.claude/scripts/`, `.claude/worktrees/`, `.claude/sprints/`.

## The pipeline

`/plan` decomposes an objective into tickets carrying rationale and predicted files.
`/sprint` groups those tickets into **lanes** by file overlap (union-find, transitive),
gives each lane a worktree, reviews each lane with three lenses in parallel, lets the
lane's editor fix findings for up to 5 cycles, and merges green lanes into a local
sprint branch. `/submit-pr` — user-invoked only — pushes and opens the PR.

## Invariants

These hold across every skill and agent. Breaking one is a bug, not a style choice.

1. **The lead allocates branch names and worktree paths.** Workers never derive their
   own — that is how parallel workers collide.
2. **Every loop has a counter, a cap, and a named terminal state.** Add new caps to
   `limits.md` first, then reference them. Never raise one at runtime.
3. **Relay cumulative history into capped loops**, not just the latest round.
   Otherwise the loop cannot tell it is repeating a failed fix.
4. **No skill or agent touches the remote.** `git push`, `gh pr create`, and
   `gh pr merge` belong to `/submit-pr`. `hooks/gate-remote.sh` enforces it.
5. **Never rebase. Never squash.** Merge commits only; history is preserved as
   authored. No `--squash`, no `git rebase`, no `--amend` on pushed commits, no
   force-push.
6. **A skill's `description` is its contract.** It is the only text a user sees
   before invoking, and it drives auto-invocation. A read-only-sounding skill must
   not write files.
7. **Agents inline what they need.** An agent's `tools:` list is the real contract —
   prose referencing a `/command` an agent cannot invoke is dead text. Neither
   `editor` nor `reviewer` has `Skill`, so their rules are inlined.

## Installing

```
/plugin marketplace add r0llingp1n/skills_project
/plugin install aops-dev-workflow@aops-dev-workflow-marketplace
```

Developing against un-pushed edits: `claude --plugin-dir .`, then `/reload-plugins`
to pick up changes. **Hook changes need a full restart** — hooks load at session start.

## Adding a skill

Create `skills/<name>/SKILL.md` with front matter: `name` (matching the directory),
`description`, and optionally `user-invocable: false`, `argument-hint`,
`allowed-tools`. Then the body.

Reference shared contracts as `${CLAUDE_PLUGIN_ROOT}/skills/_shared/<file>.md`,
another skill as `${CLAUDE_PLUGIN_ROOT}/skills/<name>/SKILL.md`, and spawn a teammate
with `subagent_type: "aops-dev-workflow:<name>"`.
