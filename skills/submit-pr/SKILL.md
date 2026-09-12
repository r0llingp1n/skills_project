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

With no argument, submit **the branch that is currently checked out**. Find the
ledger under `.claude/sprints/` whose `branch` matches it; that ledger's `base` is
the pull request's target.

The shape is `base -> feature branch -> PR against base`. A sprint cut from `main`
targets `main`; one cut from a feature branch targets that feature branch. Do not
assume `main`.

With a sprint number, submit that sprint's branch instead — check it out first if
it is not current, and still target its recorded `base`.

**Do not fall back to "the most recent sprint."** The newest ledger is frequently
not the branch in hand: it may already be merged, or work may be sitting on a
branch that was never a sprint at all. Submitting the wrong branch is worse than
stopping.

## Instructions

Read and follow:
- `${CLAUDE_PLUGIN_ROOT}/skills/_shared/conventions.md`
- `${CLAUDE_PLUGIN_ROOT}/skills/_shared/ledger.md`

### 1. Resolve the branch and load the ledger

```bash
git branch --show-current
```

Find the ledger under `.claude/sprints/*/ledger.json` whose `branch` field equals
that branch, and read `base` from it. Three cases:

- **A ledger matches.** Normal path. Continue.
- **A ledger matches but has no `base`** (written before `base` was recorded).
  Ask which branch to target rather than guessing — `git merge-base` cannot
  recover the branch point once lane merges exist.
- **No ledger matches.** The branch was not produced by `/sprint`. Say so, and ask
  whether to proceed: a body can still be written by hand from the commits and the
  diff, but it will not carry the `WHY` a ledger preserves. Do not invent
  rationale. Ask which branch to target.

If the resolved branch is already merged into its base, or has no commits the base
lacks, stop and report it — there is nothing to submit.

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

Confirm the branch exists, is checked out or reachable, and that its merge commits
match the green lanes in the ledger. Compare against the ledger's `base`, never a
hardcoded `main`:

```bash
git fetch origin                              # base may have moved
git log <base>..<branch> --oneline --merges
git diff <base>...<branch> --stat
```

Update the local base first if it is behind its remote. A stale base inflates the
diff with commits already merged, and the pull request then appears to re-propose
another branch's work.

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

Add a trailing line linking the tickets, with the closing keyword repeated **before
every issue number**: `Closes #42, closes #43, closes #44`.

There is no shorthand for this. GitHub's documentation is explicit — *"Use full
syntax for each issue"* — and only the issue directly following a keyword is
linked. `Closes #42, #43, #44` closes #42 and silently ignores the rest: the PR
merges, the extra issues stay open, and nothing reports it. An issue in another
repository takes the same form with its full name, `closes owner/repo#123`.

The keywords are `close`, `closes`, `closed`, `fix`, `fixes`, `fixed`, `resolve`,
`resolves`, `resolved`.

**The pull request must target the repository's DEFAULT branch or nothing closes
at all.** GitHub interprets these keywords *only* when the PR targets the default
branch — it does not defer them, and it does not warn. A PR merged into any other
branch links the issues in the UI and leaves every one of them open.

That is not an edge case for this plugin, it is the normal case. A sprint branches
from whatever is checked out, so a sprint cut from another sprint targets that
sprint, not `main`. **Every stacked pull request therefore closes nothing on its
own merge.** Say so when you report, rather than leaving the user to discover it:
the issues close only when the branch that finally lands on the default branch
carries those keywords, and until then they must be closed by hand.

This was measured, not assumed. Two PRs merged minutes apart from the same
session: the one targeting `main` closed all seven of its issues; the one
targeting a sprint branch closed none of its eight, with identical syntax.

So after merge, verify. `gh issue view <n> --json state` per ticket is enough, and
it is the only thing that distinguishes "the keywords worked" from "the keywords
were never read".

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
2. Push and open the PR, targeting the ledger's `base` explicitly:
   ```bash
   git push -u origin <branch>
   gh pr create --base <base> --head <branch> \
     --title "<title>" --body-file /tmp/scripts/pr-body-<n>.md
   ```
   `--base` is not optional. Without it `gh` uses the repository's default branch,
   which silently retargets a stacked sprint at `main` and drags its parent's
   commits into the diff.
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
- Push only the branch resolved in step 1 — the one checked out, or the one named
  by an explicit sprint number. Never substitute a different branch because it
  looks newer or more complete.
- Open the pull request against the ledger's `base`. Never assume `main`.
- Never write the approval marker before the user has confirmed. The marker is a
  record of consent, not a convenience.
- If the push or PR creation fails, do not retry automatically. Remove the marker,
  diagnose, and report.
