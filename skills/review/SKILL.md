---
name: review
user-invocable: true
description: Review a pull request or branch through a security/performance/simplicity panel, plus an infrastructure reviewer when the diff touches IaC, containers, or CI config
---

# Review

Review a PR (by number) or a branch (by name) and provide structured feedback.

## Usage

```
/review 12
/review issue-42-add-login-page
```

## Instructions

Read and follow `${CLAUDE_PLUGIN_ROOT}/skills/_shared/conventions.md`.

1. Determine if the argument is a PR number or branch name
   - If a number, compose a script to run `gh pr view <number> --json title,body,headRefName,files` and `gh pr diff <number>`
   - If a branch name, compose a script to run `git diff main...<branch>` and `git log main...<branch> --oneline`
2. **In a single message**, spawn three `aops-dev-workflow:reviewer` subagents, one
   per lens: `security`, `performance`, `simplicity`. The lens is the only thing that
   differs between them, and it is the same panel `/sprint` uses — see
   [`agents/reviewer.md`](../../agents/reviewer.md) for what each lens blocks on.

   Each spawn prompt must carry:
   - **that this is a standalone review** — there is no lead and no task queue, so
     the reviewer returns findings as its final response instead of posting them
   - the target: the PR number or branch, and the command that yields its diff
   - the instruction to read every changed file **in full**, not only the diff hunks
   - the instruction to **verify** each finding by running builds, tests, or renders
     before reporting it, and to say plainly if its lens turns up nothing

   One general-purpose reviewer produces a shallower pass than three focused ones,
   and its findings drift toward whichever concern it noticed first.

   **In the same message**, if any changed file is infrastructure config, spawn a
   fourth `aops-dev-workflow:reviewer` with lens `infra`. Infrastructure config
   means any of:
   - Terraform/OpenTofu: `*.tf`, `*.tfvars`
   - Containers: `Dockerfile*`, `docker-compose*.yml`, `*.containerfile`
   - CI/CD: `.github/workflows/`, `.gitlab-ci.yml`, `Jenkinsfile`, `.circleci/`
   - Kubernetes/Helm: `k8s/`, `charts/`, `Chart.yaml`, any `*.yaml` containing `apiVersion:`
   - Cloud config: `serverless.yml`, `cdk.json`, `pulumi.*`, `template.yaml`, `samconfig.toml`
   - Ansible: `playbook*.yml`, `roles/`, `inventory*`

   The `infra` spawn prompt carries everything the other three do, plus the list of
   changed infra files. The lens itself — reading
   `${CLAUDE_PLUGIN_ROOT}/skills/infra-check/SKILL.md`, its checklists, and the
   severity mapping — is defined in `agents/reviewer.md`, not here.

   Skip the infra reviewer when no changed file matches. An infra review of a diff
   with no infra in it produces only "worth confirming" noise.

3. Merge the result sets and **dedupe overlapping findings** — simplicity and
   performance routinely flag the same redundant loop, and reporting it twice reads
   as two problems, and a `security` finding and an `infra` finding on the same
   hardcoded secret are one finding, filed once under Blocking. Present the
   consolidated set as:
   - **Blocking**: issues that must be fixed
   - **Suggestions**: non-blocking improvements
   - **Notes**: observations, questions, or praise
4. If reviewing a PR, compose a script to post the review via `gh pr review <number>`:
   - `--approve` when there are no Blocking findings
   - `--comment -b "<feedback>"` when there are

   **Never `--request-changes`.** GitHub rejects it on your own pull requests, and
   PRs opened by this plugin are authored by the same account — so it fails in the
   common case. `--comment` carries the same information.
