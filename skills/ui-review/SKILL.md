---
name: ui-review
user-invocable: false
description: Apply web design guidelines to UI work within a sprint lane
---

# UI Review

Inlined into a lane editor's context when any ticket in that lane carries a `ui`
label or otherwise involves frontend work. It supplies the design standards the
edits must meet; the editor still does the editing.

## Instructions

Read and follow `${CLAUDE_PLUGIN_ROOT}/skills/_shared/conventions.md`.

1. **Confirm UI relevance.** This applies when the lane's tickets show any of:
   - labels `ui`, `frontend`, `design`, `ux`, `accessibility`, `css`, `styling`
   - text describing visual changes, layout, components, responsiveness, or a11y
   - predicted files under templates, stylesheets, components, or frontend source

   If none apply, ignore this guidance and edit normally.

2. **Load the guidelines.** Read
   `${CLAUDE_PLUGIN_ROOT}/skills/ui-review/reference/web-design-guidelines.md`,
   which ships with the plugin.

   Optionally refresh against the upstream source if the network is available:
   ```
   https://raw.githubusercontent.com/vercel-labs/web-interface-guidelines/main/command.md
   ```
   Treat a fetch failure as a non-event — the bundled copy is authoritative and
   sufficient. Do **not** block the lane on a network read.

3. **Locate the affected files.** Use `Glob`/`Grep` over the lane's predicted files
   and their neighbours: `**/*.tsx`, `**/*.jsx`, `**/*.vue`, `**/*.svelte`,
   `**/*.html`, `**/*.css`, `**/*.scss`.

4. **Make the edits**, ensuring each one:
   - satisfies the ticket's acceptance criteria
   - passes the guidelines checklist
   - commits to a deliberate, context-appropriate aesthetic — typography, colour,
     and spacing chosen on purpose rather than defaulted into
   - matches the conventions already present in the codebase over any external
     house style

5. **Record design decisions** in the lane's ledger `what` entries, so they reach the
   pull request rather than being lost: what was changed visually, and why that
   direction was chosen.

## Notes

- The `simplicity` reviewer will flag gratuitous abstraction in components, and the
  `performance` reviewer will flag render-path costs. Expect UI lanes to draw
  findings from all three lenses.
- This skill installs nothing and fetches no plugins. If a richer design skill is
  available in the session, use it; if not, the bundled guidelines stand alone.
