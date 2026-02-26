---
name: scaffold-ci
user-invocable: true
description: Generate or update CI/CD pipeline config for the project
---

# Scaffold CI

Generate or update CI/CD configuration based on the project's stack.

## Usage

```
/scaffold-ci
/scaffold-ci github-actions
```

## Instructions

All shell commands in this skill must be composed into scripts following `.claude/commands/batch-scripts.md` — write them to `tmp/scripts/`, validate safety, and run as a single script per block.

1. Detect the project stack:
   - Language/runtime: look at source files, `package.json`, `requirements.txt`, `go.mod`, `Cargo.toml`, etc.
   - Existing CI: check `.github/workflows/`, `.gitlab-ci.yml`, etc.
   - Test runner: detect from config or scripts
   - Linter/formatter: detect from config or devDependencies
2. If CI config already exists, read it and suggest improvements
3. If no CI config exists, generate one for the detected platform (default: GitHub Actions) that includes:
   - Install dependencies
   - Lint / format check
   - Run tests
   - Build (if applicable)
   - Cache dependencies for speed
   - Pin action versions to SHAs
4. Use the infra-edit skill (spawn as subagent) to make changes in an isolated worktree
5. Report what was generated and the branch name
