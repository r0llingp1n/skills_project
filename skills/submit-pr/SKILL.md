---
name: submit-pr
user-invocable: true
argument-hint: "[sprint number]"
description: Push the sprint branch and open a pull request with WHAT / WHY / TESTING sections
---

# Submit PR

Push a completed sprint branch and open its pull request. **This is the only skill
in the plugin permitted to touch the remote**, and only the user invokes it — no
skill, agent, or teammate may call it or reproduce what it does.

A `PreToolUse` hook (`hooks/gate-remote.sh`) denies `git push`, `gh pr create`, and
`gh pr merge` everywhere else. This skill lifts that gate for one session, only
after the user has confirmed the pull request body.

## Usage

```
/submit-pr
/submit-pr 7
```

With no argument, use the most recent sprint under `.claude/sprints/`.

## Instructions

Read and follow:
- `${CLAUDE_PLUGIN_ROOT}/skills/_shared/conventions.md`
- `${CLAUDE_PLUGIN_ROOT}/skills/_shared/ledger.md`

### 1. Load the ledger

Read `.claude/sprints/sprint-<n>/ledger.json`. If it is missing, stop — there is
nothing to submit, and a PR body cannot be reconstructed after the fact.

### 2. Check lane status

Every lane must be `green`. If any lane is `UNFINISHED`, `TESTS FAILING`, or
`BLOCKED`, **stop and report it**:

```
Sprint 7 has 1 lane that is not green:
  lane-2 (#43)  UNFINISHED — 2 Blocking findings outstanding after 5 cycles
    - security  api/handler.go:88 — user input reaches the query unvalidated
    - simplicity api/handler.go:120 — duplicates parseFilter() in api/query.go

Submitting now opens a PR without that lane's work.
Proceed anyway, or leave it for follow-up?
```

Only continue on an explicit override. Non-green lanes were never merged into the
sprint branch, so their work is simply absent from the PR — say so plainly.

### 3. Verify the branch

Confirm the sprint branch exists, is checked out or reachable, and that its merge
commits match the green lanes in the ledger:

```bash
git log main..sprint-<n> --oneline --merges
git diff main...sprint-<n> --stat
```

If a green lane has no corresponding merge commit, stop and report the discrepancy
rather than opening a PR that misrepresents its contents.

### 4. Assemble the pull request body

Three sections, in this order and with these exact headings:

```markdown
## WHAT
- <lane 1 what[0]>
- <lane 1 what[1]>
- <lane 2 what[0]>

## WHY
- <lane 1 what[0]>
  - <why bullet from the ticket that motivated it>
  - <second why bullet, if the ticket had one>
- <lane 1 what[1]>
  - <why bullet>
- <lane 2 what[0]>
  - <why bullet>

## TESTING
- <every test/build command actually run, with its result>
- <any manual verification performed>
```

Rules for assembly:

- **`WHAT`** — concatenate each green lane's `what` array, in lane order. One bullet
  per user-visible change.
- **`WHY`** — mirrors `WHAT`'s order exactly. Each `WHAT` bullet is repeated as a
  parent, with its motivating rationale nested beneath it. A single change may carry
  **several** `why` bullets; a change with none means its ticket had no
  `## Rationale`, so say so rather than inventing one.
- **`TESTING`** — concatenate every green lane's `testing` array. These are commands
  that were actually run. **Never add an aspirational entry**, and never write
  "tests pass" without the command and result that show it.

Add a trailing line linking the tickets: `Closes #42, #43, #44`.

### 5. Confirm with the user

Present the complete body, the branch name, the target branch, the commit count, and
the diffstat. **Ask for explicit confirmation.** Offer to edit any section before
proceeding. Do not push on implied approval.

### 6. Record approval and submit

Only after explicit confirmation:

1. Write the approval marker so the hook will permit the push — its contents must be
   this session's `session_id`:
   ```bash
   printf '%s' "$CLAUDE_SESSION_ID" > .claude/sprints/sprint-<n>/SUBMIT_APPROVED
   ```
   If the session id is not available in the environment, read it from the hook's
   own denial message, or ask the user to run `/hooks` — do **not** work around the
   gate by other means.
2. Push and open the PR:
   ```bash
   git push -u origin sprint-<n>
   gh pr create --title "<title>" --body-file /tmp/scripts/pr-body-<n>.md
   ```
3. **Remove the marker immediately** so the gate closes behind you:
   ```bash
   rm -f .claude/sprints/sprint-<n>/SUBMIT_APPROVED
   ```
4. Record the PR URL in the ledger.

### 7. Report

Give the user the PR URL, the sections as submitted, and — if any lane was left
behind — a reminder of what is still outstanding and the suggested follow-up tickets.

## Rules

- **Never merge the pull request.** Opening it is where this skill stops.
- Never push a branch other than the sprint branch named in the ledger.
- Never write the approval marker before the user has confirmed. The marker is a
  record of consent, not a convenience.
- If the push or PR creation fails, do not retry automatically. Remove the marker,
  diagnose, and report.
