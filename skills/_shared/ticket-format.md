# Ticket Format

`/plan` writes tickets in this format. `/sprint` parses them. The `Predicted files`
block is a **contract**, not a courtesy: lane assignment is computed from it, and a
ticket without one cannot be laned automatically.

## Body template

```markdown
## Rationale
- <why this change is needed, in the user's terms>
- <second reason, if there is one>

## Acceptance criteria
- [ ] <observable condition that means this is done>
- [ ] <another>

## Predicted files
- path/to/file.go
- path/to/other.go

<!-- lane-hint: <short-slug> -->
```

## Field contracts

**`## Rationale`** — one or more bullets. These are lifted **verbatim** into the
`WHY` section of the pull request by `/submit-pr`. Write them as reasons a reviewer
would want to read, not as restatements of the title.

**`## Acceptance criteria`** — observable conditions. The editor treats these as the
definition of done; the reviewers treat them as what the change is *supposed* to do.

**`## Predicted files`** — repo-relative paths, one per bullet. Must be grounded in
files that actually exist (or in a clearly-named new file). Globs are permitted
(`auth/*.go`) and are expanded against the current tree at sprint time.

**`<!-- lane-hint: slug -->`** — optional. A human-readable name for the lane this
ticket is expected to land in. Advisory only: actual laning is computed from file
overlap, and the hint is used solely to name the lane in reports.

## Parsing rules for `/sprint`

1. Read each ticket with `gh issue view <n> --json number,title,body,labels`.
2. Extract the `## Predicted files` block. If absent or empty, **do not guess** —
   collect the ticket into a `needs-files` list, report it, and ask the user whether
   to (a) analyse the repo to infer files, (b) run it as its own isolated lane, or
   (c) drop it from the sprint.
3. Expand globs against the current tree.
4. Two tickets sharing **any** file belong to the same lane. Overlap is transitive:
   compute lanes with union-find, so A↔B and B↔C put A, B, and C in one lane even
   when A and C share nothing.
5. Name each lane from the shared `lane-hint` when the tickets agree on one,
   otherwise from the longest common path prefix of its files.
