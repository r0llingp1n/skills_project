---
name: plan-sprint
user-invocable: true
argument-hint: "<objective>"
description: Decompose an objective into a sprint plan and publish it as GitHub tickets
---

# Plan Sprint

Turn a stated objective into a set of work items, show the plan and its provisional
lanes for approval, then publish the approved items as GitHub issues that `/sprint`
can consume directly.

## Usage

```
/plan "add SSO and fix token refresh"
/plan "reduce cold-start latency on the API"
```

## Instructions

Read `${CLAUDE_PLUGIN_ROOT}/skills/_shared/conventions.md` and follow it.
Read `${CLAUDE_PLUGIN_ROOT}/skills/_shared/limits.md` — decomposition is capped at
**12 items**.
Read `${CLAUDE_PLUGIN_ROOT}/skills/_shared/ticket-format.md` — the ticket body you
produce must conform to it exactly, because `/sprint` parses it.

**Create no tickets until the user approves the plan.**

1. **Ground the plan in the repo.** Before decomposing anything, explore with
   `Read`/`Glob`/`Grep`: locate the modules the objective touches, the existing
   patterns and conventions, the test layout, and any code that already does part of
   what is being asked. A plan written without reading the code produces predicted
   files that do not exist, which breaks laning downstream.

2. **Decompose into work items.** Each item should be independently implementable
   and independently reviewable. Prefer items that touch a coherent set of files
   over items that are conceptually tidy but smear across the tree — file locality
   is what makes parallel lanes possible.

   If the objective needs more than **12** items, stop. Present the decomposition
   you have, explain what is not yet covered, and ask the user whether to narrow the
   objective or run it as consecutive sprints.

3. **For each item, produce:**
   - **Title** — imperative, specific.
   - **Rationale** — one or more bullets saying *why*, in terms a reviewer would
     want to read. These become the PR's `WHY` section verbatim, so write them for
     that audience rather than restating the title.
   - **Acceptance criteria** — observable conditions that mean the item is done.
   - **Predicted files** — repo-relative paths, grounded in what you actually found
     in step 1. Name new files explicitly when the item creates them.

4. **Compute provisional lanes.** Group items by file overlap using the union-find
   rule in `ticket-format.md`: any two items sharing a file are in the same lane,
   and overlap is transitive. Report the lanes as part of the proposal so the user
   can see the achievable parallelism before anything is created.

   If one lane swallows most of the items, say so plainly and suggest a re-cut —
   that usually means an item is doing too much, or a shared file (a router, a
   config, a barrel export) is acting as a chokepoint.

5. **Present the full plan for approval.** Show, per item: title, rationale,
   acceptance criteria, predicted files, and assigned lane. Then a summary: item
   count, lane count, expected parallelism, and any items you could not lane cleanly.

   Ask which items to create. The user may accept all, accept a subset, or ask for
   a re-cut. **Do not proceed without an explicit answer.**

6. **Publish approved items as tickets.** Compose one script that creates them via
   `gh issue create`, each body conforming to `ticket-format.md`. Apply labels where
   the item obviously warrants one (`bug`, `feature`, `refactor`, `infra`, `docs`,
   and `ui` when it involves frontend work — `/sprint` uses that label to decide
   whether the lane's editor needs the UI review guidance).

7. **Report** the created issue numbers grouped by lane, followed by the exact
   command to run next:

   ```
   /sprint <all created issue numbers>
   ```

## Notes

- This skill creates issues. It does **not** create branches, worktrees, commits, or
  pull requests, and it never pushes. Remote write operations belong to `/submit-pr`.
- Tickets written by hand are welcome in `/sprint`, but they need a
  `## Predicted files` block to be laned automatically. Point people at
  `ticket-format.md`.
