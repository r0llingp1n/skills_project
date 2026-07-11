# aops-dev-workflow

A [Claude Code](https://code.claude.com) plugin for an end-to-end development workflow, built around **Agent Teams**: triage and work issues in parallel, run coordinated sprints with `editor`/`reviewer` teammates, loop PRs through review → fix → merge, audit CI/infra, and keep changelogs and docs current. Shell/Python work is funneled through single-approval script runners.

## Install

```bash
# Add this repo as a marketplace, then install the plugin
/plugin marketplace add ./
/plugin install aops-dev-workflow@aops-dev-workflow-marketplace
```

Or load it directly for development:

```bash
claude --plugin-dir .
```

The sprint/review flows expect Agent Teams to be enabled:

```bash
export CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1
```

## Skills

| Command | What it does |
| --- | --- |
| `/triage` | List and prioritize open issues for the current repo |
| `/work-issue <n...>` | Fetch issues, implement in parallel, then review → fix → merge |
| `/sprint <n...>` | Run issues as a coordinated team sprint (editor + reviewer teammates) |
| `/review [pr-or-branch]` | Review a PR or branch for correctness and style |
| `/changelog` | Generate or update CHANGELOG from merged PRs and commits |
| `/ci-status [branch-or-pr]` | Check CI/CD pipeline status |
| `/scaffold-ci` | Generate or update CI/CD pipeline config |
| `/test-branch [branch]` | Run the test suite against a branch in its worktree |
| `/cleanup-worktrees` | Remove worktrees for merged branches |
| `/infra-check [category]` | Audit infra config for drift, security, best practices |
| `/doc-review` | Check docs for staleness, broken references, and gaps |
| `/update-docs` | Update project documentation to reflect recent changes |
| `/batch-scripts` | Compose bash into a single script for one-approval execution |
| `/python-scripts` | Compose automation into small Python scripts for one-approval execution |
| `/example` | Demonstrates the skill file format |

Non-invocable helper skills (`editor`, `infra-edit`, `ui-review`) are inlined into other skills' subagent prompts.

## Agents (Agent Teams teammates)

- **`aops-dev-workflow:editor`** — implements one issue in an isolated worktree, coordinates via the shared task list and messaging
- **`aops-dev-workflow:reviewer`** — reviews PRs as they're created during a sprint and reports verdicts to the lead

## Layout

```
.claude-plugin/
  plugin.json          # manifest
  marketplace.json     # local marketplace entry
skills/
  <name>/SKILL.md      # one directory per skill
agents/
  editor.md
  reviewer.md
```
