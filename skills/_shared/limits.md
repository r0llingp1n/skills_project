# Iteration Limits

Every loop in this plugin has three parts: a **counter**, a **cap**, and a named
**terminal state**. A loop without all three is a bug. On reaching a cap, the loop
always terminates with a report — it never retries, and it never silently continues.

## Caps

| Loop | Counter lives with | Cap | Terminal state |
| --- | --- | --- | --- |
| Review → fix, per lane | the lane's editor | **5** | `UNFINISHED` |
| Test/build retries, per edit | the lane's editor | **2** | `TESTS FAILING` |
| Integration conflict resolution | the lead | **2** | `BLOCKED` |
| Reviewer re-review, per lane | the reviewer | **5** | `REVIEW BUDGET EXHAUSTED` |
| Teammate idle polling | the teammate | **3** consecutive empty polls | `IDLE` |
| Concurrent lanes | the lead | **2** | surplus lanes queue |
| `TeammateIdle` nudges per agent | the hook | **2** | agent allowed to stop |
| `/plan` decomposition | the lead | **12** items | stop and ask the user |
| Follow-up ticket recursion | the lead | **depth 1** | create only; never auto-work |

## Terminal states

Each state is a literal string. Report it verbatim so the lead can group results
without interpretation.

- **`UNFINISHED`** — five review cycles elapsed with Blocking findings still open.
  Report the outstanding findings, grouped by lens. The lane is **not** integrated
  into the sprint branch. Its worktree and branch are left in place for follow-up.

- **`TESTS FAILING`** — the test or build command failed twice after fixes.
  Report the command, the failing output, and what was attempted. Commit nothing
  further. Do not request review.

- **`BLOCKED`** — a lane went green but could not be merged into the sprint branch
  after two conflict-resolution attempts. Report the conflicting files. The lane
  branch is left intact.

- **`REVIEW BUDGET EXHAUSTED`** — a reviewer was asked for a sixth pass on the same
  lane. Report and stop; the editor's `UNFINISHED` state is the authoritative one.

- **`IDLE`** — three consecutive `TaskList` polls returned no claimable task.
  Message the lead `IDLE — no claimable tasks` and exit. Do not keep polling.

## Why concurrent lanes is 2

2 lane editors plus the 3-lens review panel is **5 concurrent teammates**, which is
the top of the range the Claude Code docs recommend: "Start with 3-5 teammates for
most workflows… Three focused teammates often outperform five scattered ones."
Token cost scales linearly per teammate, and coordination overhead grows faster than
throughput. Surplus lanes queue and start as earlier lanes finish, so raising this
buys parallelism at a steepening price.

## Enforcement

Three of these caps are enforced by hooks rather than prose, since an agent can
drift from an instruction but not from a denied tool call:

- `hooks/gate-remote.sh` (`PreToolUse`) — denies push/PR operations outside `/submit-pr`
- `hooks/enforce-terminal-state.sh` (`TeammateIdle`) — refuses idle while a lane has
  no terminal state, at most twice per agent
- `hooks/enforce-task-complete.sh` (`TaskCompleted`) — refuses to complete a task
  whose lane still carries open Blocking findings

The nudge hooks are themselves bounded, and every hook fails **open**. A hook that
could block forever would break the very invariant it exists to enforce.

## Rules

- Never invent a new cap. If a loop needs one that is not listed here, add it to
  this file first, then reference it.
- Never raise a cap at runtime because progress "seems close". The cap is the budget.
- When relaying feedback into a capped loop, always include the **cumulative**
  history of prior iterations, not just the latest round. Without it the loop cannot
  detect that it is re-attempting a fix that already failed.
