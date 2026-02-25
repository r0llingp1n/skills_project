---
name: ui-review
user-invocable: false
description: Detect UI changes needed in an issue and apply edits using web design guidelines and the frontend-design skill
---

# UI Review

This skill is invoked as a subagent by work-issue when an issue involves UI changes. It reviews the issue for frontend work, applies web design guidelines, and delegates the actual edits to the `frontend-design` skill from `anthropics/skills`.

## Instructions

1. **Detect UI relevance**: Examine the issue title, body, and labels. If any of the following are present, this skill applies:
   - Labels like `ui`, `frontend`, `design`, `ux`, `accessibility`, `css`, `styling`
   - Issue text mentioning visual changes, layout, components, styling, responsiveness, or accessibility
   - File paths referencing templates, stylesheets, components, or frontend code

2. **Load web design guidelines**: Read the guidelines from `.agents/skills/web-design-guidelines/SKILL.md` and fetch the latest rules from:
   ```
   https://raw.githubusercontent.com/vercel-labs/web-interface-guidelines/main/command.md
   ```
   All UI edits must comply with these guidelines.

3. **Find affected UI files**: Use Glob and Grep to locate the frontend files relevant to the issue (e.g., `**/*.tsx`, `**/*.jsx`, `**/*.vue`, `**/*.svelte`, `**/*.html`, `**/*.css`, `**/*.scss`).

4. **Delegate edits via frontend-design**: Use `find-skills` to install and invoke the `frontend-design` skill from the official `anthropics/skills` registry:
   ```
   /plugin marketplace add anthropics/skills
   /plugin install frontend-design@anthropic-agent-skills
   ```
   Then apply the skill's design principles when making edits — commit to a bold, context-appropriate aesthetic direction rather than generic defaults.

5. **Apply edits**: Make the UI changes in the worktree, ensuring each edit:
   - Solves the issue requirements
   - Passes the web design guidelines checklist
   - Follows the frontend-design skill's standards (no generic "AI slop", deliberate typography/color/spacing choices)

6. **Report findings**: Return a summary including:
   - UI files modified
   - Guidelines violations found and fixed
   - Design decisions made and rationale
