---
name: infra-check
user-invocable: true
description: Audit infrastructure config files for drift, security issues, and best practices
---

# Infra Check

Scan infrastructure-as-code files and CI/CD config for issues.

## Usage

```
/infra-check
/infra-check terraform
/infra-check ci
```

## Instructions

All shell commands in this skill must be composed into scripts following `.claude/commands/batch-scripts.md` — write them to `tmp/scripts/`, validate safety, and run as a single script per block.

1. Detect what infra tooling the project uses by looking for:
   - Terraform/OpenTofu: `*.tf` files
   - Docker: `Dockerfile`, `docker-compose.yml`
   - CI/CD: `.github/workflows/`, `.gitlab-ci.yml`, `Jenkinsfile`
   - K8s: `k8s/`, `*.yaml` with `apiVersion`
   - Cloud config: `serverless.yml`, `cdk.json`, `pulumi.*`
2. If an argument was provided, scope the check to that category
3. Spawn a Task subagent with `subagent_type: "general-purpose"` to audit the detected files. The prompt should instruct it to:
   - Read each config file in full
   - Flag security issues (exposed secrets, overly permissive IAM, no resource limits, missing encryption)
   - Flag reliability issues (no health checks, missing restart policies, no resource constraints)
   - Flag drift risks (hardcoded values that should be variables, environment-specific config in shared files)
   - Check CI/CD for missing steps (no linting, no tests, no caching, no pinned action versions)
4. Present findings grouped by severity: **Critical**, **Warning**, **Info**
