# AutonomousOps Dev Workflow Plugin

This repository is a **Claude Code plugin** (`aops-dev-workflow`) that bundles skills and Agent-Teams teammates for an end-to-end dev workflow: parallel issue work, coordinated sprints, PR review/fix/merge loops, CI/infra audits, changelogs, and docs.

## Structure

- `.claude-plugin/plugin.json` — plugin manifest (name, version, metadata)
- `.claude-plugin/marketplace.json` — single-plugin marketplace for local install/testing
- `skills/<name>/SKILL.md` — skills (each in its own directory); `user-invocable: true` ones show up as `/<name>`
- `agents/<name>.md` — Agent-Teams teammates (`editor`, `reviewer`) that coordinate via `TaskList`/`TaskUpdate`/`SendMessage`

Not part of the distributed plugin (author-local config): `.claude/settings*.json`, `.claude/scripts/`, `.claude/worktrees/`, and the vendored `.agents/skills/` (tracked by `skills-lock.json`).

## Agent Teams

The `sprint`/`work-issue` flows are designed to run with Agent Teams enabled
(`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`, still required and still experimental). The lead spawns `aops-dev-workflow:editor`
and `aops-dev-workflow:reviewer` teammates, which self-coordinate through the shared
task list and direct messaging. There is no manual team setup: teammates are spawned directly with no `TeamCreate`, naming, or teardown step, and the session-derived team is cleaned up automatically when the session exits.

## Git conventions

**Never rebase. Never squash.** Git history is preserved exactly as authored — every commit stands on its own.

- Integrate upstream changes with merge commits: `git merge origin/main` (never `git rebase`, never `git merge --squash`)
- Merge PRs with `gh pr merge <number> --merge` (never `--squash`, never `--rebase`)
- Do not rewrite history: no interactive-rebase squash/fixup, no `git commit --amend` on pushed commits, no force-pushing shared branches

Skills and agents that commit or merge (`editor`, `infra-edit`, `work-issue`) restate this rule
inline, since their text is pasted into subagent prompts that don't inherit this file.

## Installing

Install from GitHub — the canonical source:

```
/plugin marketplace add r0llingp1n/skills_project
/plugin install aops-dev-workflow@aops-dev-workflow-marketplace
```

When developing this plugin against un-pushed edits, load the working copy directly instead:

```
claude --plugin-dir .
```

Run `/reload-plugins` to pick up edits without restarting.

## Adding a skill

Create `skills/<name>/SKILL.md` with front matter:

1. `name` — the skill/command name (matches the directory)
2. `description` — what it does; Claude uses this to auto-invoke and to label the `/<name>` command
3. Optional: `user-invocable: false` to hide from the `/` menu, plus `argument-hint`, `allowed-tools`
4. The body: instructions Claude follows when the skill runs

Reference another skill's file from within a skill as `${CLAUDE_PLUGIN_ROOT}/skills/<name>/SKILL.md`, and spawn a teammate agent as `subagent_type: "aops-dev-workflow:<name>"`.
