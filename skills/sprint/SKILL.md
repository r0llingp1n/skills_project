---
name: sprint
user-invocable: true
argument-hint: "<ticket numbers>"
description: Run tickets as parallel lanes of work, each reviewed by a security/performance/simplicity panel and integrated locally into a sprint branch
---

# Sprint

Take a set of tickets, group them into **lanes** that cannot conflict with each
other, work each lane in its own worktree, review each lane with a three-lens panel,
and integrate green lanes locally into a sprint branch.

The sprint stops at local integration. Pushing and opening a pull request is
`/submit-pr`, which only the user invokes.

## Usage

```
/sprint 42 43 44 45
```

## Instructions

Read and follow:
- `${CLAUDE_PLUGIN_ROOT}/skills/_shared/conventions.md`
- `${CLAUDE_PLUGIN_ROOT}/skills/_shared/limits.md`
- `${CLAUDE_PLUGIN_ROOT}/skills/_shared/ticket-format.md`
- `${CLAUDE_PLUGIN_ROOT}/skills/_shared/ledger.md`

**Sprint requires Agent Teams** (`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`). You run
as the *lead*. Teammates are spawned directly — no `TeamCreate`, no naming step, no
teardown — and are cleaned up when the session exits. If the flag is not set, stop
and tell the user rather than silently degrading.

### 1. Fetch and validate tickets

Compose a script to run `gh issue view <n> --json number,title,body,labels` for each
argument. Parse each body per `ticket-format.md`.

Any ticket missing a `## Predicted files` block goes into a `needs-files` list.
**Do not guess.** Report them and ask whether to (a) analyse the repo to infer their
files, (b) give each its own isolated lane, or (c) drop them from this sprint.

### 2. Assign lanes

Build a file → tickets map from the predicted files, expanding globs against the
current tree. Then compute lanes with **union-find**: any two tickets sharing a file
join the same lane, and overlap is transitive — if #42 and #43 share `auth.go` and
#43 and #44 share `token.go`, all three are one lane even though #42 and #44 share
nothing.

Name each lane from a shared `lane-hint`, else from the longest common path prefix.

Cap concurrent lanes at **4** (see `limits.md`). Surplus lanes queue and start as
earlier lanes finish. Report the lane plan before spawning anything.

### 3. Create the sprint branch and per-lane worktrees

Compose one script that:

```bash
git checkout -b sprint-<n> main          # <n> = next unused sprint number
git worktree add /tmp/sprint-<n>-lane-<k> -b sprint-<n>/lane-<k> sprint-<n>
```

**The lead allocates every branch name and worktree path.** Editors never derive
their own — that is what previously caused two workers on the same ticket to collide
on an identical branch name.

Create `.claude/sprints/sprint-<n>/ledger.json` per `ledger.md`, with the lane
identity fields filled in and `status: "pending"` for each lane.

### 4. Create tasks and spawn the team

For each lane, `TaskCreate` a task carrying:
- lane number and name
- ticket numbers, titles, full bodies, and acceptance criteria
- the assigned branch name and worktree path
- the predicted files this lane owns
- whether any ticket carries a `ui` label — if so, the editor must also apply
  `${CLAUDE_PLUGIN_ROOT}/skills/ui-review/SKILL.md`

Then, **in a single message**, spawn:
- one `aops-dev-workflow:editor` per active lane (≤4)
- three `aops-dev-workflow:reviewer` teammates, one per lens: `security`,
  `performance`, `simplicity`. Pass the lens in the spawn prompt; it is the only
  thing that differs between them.

### 5. Lane execution (editor teammates)

Each editor claims its lane task, works in its assigned worktree, implements the
tickets, runs tests and build (≤2 retries, then `TESTS FAILING`), commits
referencing the ticket numbers, and appends `what` and `testing` entries to the
ledger. Editors do **not** push and do **not** open PRs.

### 6. Review panel

When a lane reports ready, `TaskCreate` a review task per lens against that lane's
branch. All three reviewers work the same lane in parallel and post findings to the
lane's task as `BLOCKING` / `SUGGESTION` / `NOTE`.

Merge the three result sets and **dedupe overlapping findings** — simplicity and
performance will both flag the same redundant loop, and relaying it twice wastes a
cycle. Relay one consolidated Blocking list to that lane's editor.

### 7. Fix loop — capped at 5

The lane's editor owns the cycle counter. Each relay must carry the **cumulative**
findings history from cycles `1..k-1`, not just the newest round, so the editor can
tell it is re-attempting a fix that already failed.

- All three lenses clear → lane is **green**, go to step 8.
- Blocking findings remain and `cycle < 5` → editor fixes, re-tests, commits, and
  the panel re-reviews.
- `cycle == 5` → lane is **`UNFINISHED`**. Record the outstanding findings in the
  ledger. **Do not integrate it.** Leave its branch and worktree in place.

### 8. Integrate on green — immediately

The moment a lane goes green, merge it while that lane's editor is still alive to
resolve conflicts:

```bash
git -C <sprint worktree> merge --no-ff sprint-<n>/lane-<k>
```

On conflict, hand it back to that lane's editor with the conflicting paths. Allow
**2** resolution attempts, then mark the lane `BLOCKED` and leave it un-merged.

**Never rebase, never squash** — merge commits only, so every commit survives.

Update the lane's ledger entry with final `status`, `cycles`, `reviews`, and any
`outstanding` findings.

### 9. Stop and report

The sprint ends here. **Nothing is pushed. No pull request is opened.**

Present:
- **Green lanes** — tickets, branch, cycles used, panel verdicts, merged ✓
- **`UNFINISHED` lanes** — outstanding Blocking findings grouped by lens
- **`TESTS FAILING` / `BLOCKED` lanes** — the failure and what was attempted
- **Suggestions and Notes** across all lanes, grouped by theme
- **Proposed follow-up tickets** for unfinished work — proposed only. Create them
  only if the user asks, and never work them automatically (`limits.md`, depth 1).

Close with the exact next step:

```
Sprint branch sprint-<n> is ready locally.
Run /submit-pr when you want it pushed and opened as a PR.
```
