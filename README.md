# aops-dev-workflow

A [Claude Code](https://code.claude.com) plugin for an end-to-end development
workflow built around **Agent Teams**.

Plan an objective into tickets, work those tickets as **parallel lanes that cannot
conflict**, review every lane through a **three-lens panel** (security, performance,
simplicity), let the lane's editor resolve findings over up to five cycles, and
integrate green lanes locally into a sprint branch. Nothing reaches the remote until
**you** run `/submit-pr`.

## The pipeline

```
/plan "objective"   →  tickets with rationale + predicted files
/sprint 42 43 44    →  lanes → worktrees → 3-lens review → fix ≤5 → local merge
/submit-pr          →  push + PR with WHAT / WHY / TESTING     ← only you run this
```

## Install

```bash
/plugin marketplace add r0llingp1n/skills_project
/plugin install aops-dev-workflow@aops-dev-workflow-marketplace
```

Pull the newest release later with:

```bash
/plugin marketplace update aops-dev-workflow-marketplace
```

Sprints need Agent Teams (still experimental, still required):

```bash
export CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1
```

There is no team setup step — teammates are spawned directly and cleaned up when the
session exits.

**Restart Claude Code after installing.** The plugin ships a `PreToolUse` hook, and
hooks load at session start.

## How a sprint runs

1. **Lanes.** `/sprint` reads each ticket's `## Predicted files` block and groups
   tickets by file overlap using union-find — any two tickets sharing a file land in
   the same lane, transitively. Lanes cannot conflict with each other by construction.
2. **Worktrees.** Each lane gets `sprint-<n>/lane-<k>` in `/tmp/sprint-<n>-lane-<k>`.
   The **lead** allocates every branch name; editors never derive their own.
3. **Panel review.** Three reviewers examine each lane in parallel, one per lens.
   Findings are consolidated and deduped before reaching the editor.
4. **Fix loop.** The lane's editor owns a counter and runs up to **5** cycles,
   receiving the cumulative findings history each round. It exits green, or
   `UNFINISHED` with everything still outstanding.
5. **Merge on green.** A lane merges into the sprint branch the moment it passes,
   while its editor is still alive to resolve conflicts.
6. **Stop.** The sprint reports and halts. No push, no PR.

## Nothing runs indefinitely

Every loop has a counter, a cap, and a named terminal state — see
[`skills/_shared/limits.md`](skills/_shared/limits.md).

| Loop | Cap | Terminal state |
| --- | --- | --- |
| Review → fix, per lane | 5 | `UNFINISHED` |
| Test/build retries | 2 | `TESTS FAILING` |
| Integration conflicts | 2 | `BLOCKED` |
| Teammate idle polls | 3 | `IDLE` |
| Concurrent lanes | 2 | surplus queues |
| `TeammateIdle` nudges | 2 per agent | agent may stop |
| `/plan` items | 12 | stop and ask |
| Follow-up recursion | depth 1 | create only, never auto-work |

## What the hooks enforce

Prose is something an agent can drift from; a denied tool call is not. Three gates
ship with the plugin:

| Hook | Event | Refuses |
| --- | --- | --- |
| [`gate-remote.sh`](hooks/gate-remote.sh) | `PreToolUse` | `git push` / `gh pr create` / `gh pr merge` outside `/submit-pr` |
| [`enforce-terminal-state.sh`](hooks/enforce-terminal-state.sh) | `TeammateIdle` | a teammate going idle while a lane has no terminal state |
| [`enforce-task-complete.sh`](hooks/enforce-task-complete.sh) | `TaskCompleted` | closing a task whose lane still has open Blocking findings |

Every one of them **fails open**, and the nudging gate is itself bounded at 2 per
agent — a hook that could block forever would break the same invariant it exists to
enforce.

The remote gate stops drift, not a determined adversary: an agent with `Bash` could
write the approval marker itself. Drift is the failure mode that actually occurs.

Because teammate spawning needs an **interactive** session, `/sprint` cannot run
headless under `-p` or the Agent SDK.

## Commands

| Command | What it does |
| --- | --- |
| `/plan <objective>` | Decompose into work items, show lanes, publish approved items as tickets |
| `/sprint <n...>` | Run tickets as parallel lanes with panel review and local integration |
| `/submit-pr [n]` | **You only.** Push the sprint branch, open a PR with WHAT/WHY/TESTING |
| `/triage` | List and prioritize open issues |
| `/review [pr-or-branch]` | Ad-hoc review of a single PR or branch |
| `/changelog` | Generate or update CHANGELOG from merged PRs and commits |
| `/ci-status [branch-or-pr]` | Check CI/CD pipeline status |
| `/scaffold-ci` | Generate or update CI/CD pipeline config |
| `/test-branch [branch]` | Run the test suite against a branch in its worktree |
| `/cleanup-worktrees` | Remove worktrees for merged branches |
| `/infra-check [category]` | Audit infra config — read-only |
| `/doc-review` | Check docs for staleness, broken references, and gaps |
| `/update-docs` | Update documentation to reflect recent changes |
| `/batch-scripts` | Compose bash into one script for single-approval execution |
| `/python-scripts` | Compose automation into Python scripts for single-approval execution |

Non-invocable helpers (`infra-edit`, `ui-review`, `example`) are inlined into other
skills' subagent prompts.

## Agents

- **`aops-dev-workflow:editor`** — owns one lane, implements it in its assigned
  worktree, and resolves review findings over up to 5 cycles
- **`aops-dev-workflow:reviewer`** — examines a lane through one assigned lens;
  three are spawned per sprint

## Layout

```
.claude-plugin/
  plugin.json            # manifest
  marketplace.json       # marketplace entry
skills/
  _shared/               # limits, conventions, ticket format, ledger schema
  <name>/SKILL.md        # one directory per skill
agents/
  editor.md
  reviewer.md
hooks/
  hooks.json             # PreToolUse gate registration
  gate-remote.sh         # the gate itself
```

## Upgrading from 0.1.x

`/work-issue` is **removed** — `/sprint` subsumes it. The two shared thirteen of
fourteen stages and had drifted apart.

Sprints no longer push or open PRs. Run `/submit-pr` when you want that.

Tickets now need a `## Predicted files` block to be laned automatically; see
[`skills/_shared/ticket-format.md`](skills/_shared/ticket-format.md). `/plan` writes
it for you. `/sprint` will ask what to do with tickets that lack one rather than
guessing.
