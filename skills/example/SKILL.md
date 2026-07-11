---
name: example
user-invocable: true
description: An example skill that demonstrates the skill file format
---

# Example Skill

When this skill is invoked, greet the user and explain how skills work.

## Instructions

**Filesystem investigation** must use Claude's built-in functions — `Read()` to read files, `Glob()` to find files by pattern, and `Grep()` to search file contents. Never shell out just to explore the filesystem.

**All shell and automation work** must go through `/python-scripts`. Never run one-off shell commands; compose everything into small, idiomatic Python scripts in `/tmp/scripts/`.

1. Say hello and mention this is the example skill
2. Explain that skills are Markdown files in `.claude/skills/` that teach Claude new behaviors
3. Suggest the user create their own skill by copying this template
