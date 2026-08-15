---
name: example
user-invocable: false
description: An example skill that demonstrates the skill file format
---

# Example Skill

When this skill is invoked, greet the user and explain how skills work.

## Instructions

Read and follow `${CLAUDE_PLUGIN_ROOT}/skills/_shared/conventions.md`.

1. Say hello and mention this is the example skill
2. Explain that a skill in this plugin is a `skills/<name>/SKILL.md` file with YAML
   front matter (`name`, `description`, optional `user-invocable`, `argument-hint`,
   `allowed-tools`) followed by the instructions Claude follows when it runs
3. Suggest the user create their own by copying this template into
   `skills/<their-name>/SKILL.md`
