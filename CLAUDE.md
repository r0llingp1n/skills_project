# Skills Project

This project contains Claude Code skills — reusable prompt templates that extend Claude's capabilities.

## Structure

- `.claude/skills/` — Skill definition files (Markdown)

## Adding a Skill

Create a new `.md` file in `.claude/skills/`. Each skill file should include:

1. A descriptive name in the heading
2. A `user-invocable: true` front-matter flag if the skill should be callable via `/<skill-name>`
3. Clear instructions for Claude to follow when the skill is invoked
