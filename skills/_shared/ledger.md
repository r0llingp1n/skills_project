# Sprint Ledger

`.claude/sprints/sprint-<n>/ledger.json` is written during the sprint and read by
`/submit-pr` to build the pull request body.

It exists because **`WHY` cannot be reconstructed after the fact**. `WHAT` is
derivable from a diff and `TESTING` is partly inferable from CI output, but the
reason a change was made lives only in the ticket that prompted it. Capture it while
the work is happening or lose it.

## Schema

```json
{
  "sprint": 7,
  "branch": "sprint-7",
  "created": "2026-08-15",
  "objective": "Add SSO and fix token refresh",
  "lanes": [
    {
      "lane": 1,
      "name": "auth",
      "tickets": [42, 44],
      "branch": "sprint-7/lane-1",
      "worktree": "/tmp/sprint-7-lane-1",
      "status": "green",
      "cycles": 2,
      "what": [
        "Added SSO session handler",
        "Extracted token refresh into TokenStore"
      ],
      "why": {
        "42": [
          "Users re-authenticate on every deploy",
          "Sessions were not shared across pods"
        ],
        "44": [
          "Refresh logic was duplicated in three call sites"
        ]
      },
      "testing": [
        "go test ./auth/... — 34 passed",
        "manual: login → restart → session survives"
      ],
      "reviews": {
        "security":    { "verdict": "clear", "cycles": 2 },
        "performance": { "verdict": "clear", "cycles": 1 },
        "simplicity":  { "verdict": "clear", "cycles": 2 }
      },
      "outstanding": []
    }
  ]
}
```

## Field contracts

- **`status`** — `green` | `UNFINISHED` | `TESTS FAILING` | `BLOCKED`. Only `green`
  lanes are merged into the sprint branch, and only a ledger with no non-`green`
  lanes may be submitted without an explicit user override.
- **`what`** — one bullet per user-visible change, written by the lane's editor as
  it commits. Ordered. Becomes the `WHAT` list in the PR.
- **`why`** — keyed by ticket number, values lifted verbatim from that ticket's
  `## Rationale`. One `what` entry may map to several `why` bullets.
- **`testing`** — every test/build command the editor actually ran, with its result,
  plus any manual verification performed. Never aspirational: if it was not run, it
  does not go in.
- **`outstanding`** — Blocking findings still open at `UNFINISHED`, each `{lens,
  file, line, finding}`. Empty for green lanes. Feeds the follow-up ticket proposal.

## Write discipline

- The **lead** creates the file at sprint start and owns `sprint`, `branch`,
  `created`, `objective`, and each lane's identity fields.
- The **lane's editor** owns `what`, `testing`, and `cycles` for its own lane, and
  appends after every cycle — not once at the end, so a crashed lane still leaves
  evidence.
- The **lead** writes `reviews`, `status`, and `outstanding` from reviewer verdicts.
- Never rewrite history in the ledger. Append and update status in place.
