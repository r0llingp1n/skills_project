---
name: infra-check
user-invocable: true
description: Review merge/pull requests that touch infrastructure code (Terraform, Kubernetes manifests/Helm, Ansible, CloudFormation/CDK, Dockerfiles, CI pipeline configs, networking/IaC configs, etc.), grading changes on stability, performance, idiomatic use of the tool, and simplicity. Use this whenever the user asks to review, critique, or give feedback on an infra MR/PR/diff, asks "does this infra change look safe/good", pastes a Terraform/K8s/Ansible/CDK diff for review, or asks for an infra code review checklist. Prioritize this skill over a generic code review approach for anything involving infrastructure-as-code, deployment configs, or cloud resources.
---

# Infrastructure MR Reviewer

Reviews merge requests that touch infrastructure code. The goal is a **tight, high-signal review** — flag what matters, ignore what doesn't, and default toward the simplest solution that works.

## Review priorities (in order)

1. **Stability** — Will this break something in production or during rollout?
2. **Architecture** — Does this scale horizontally, and does it avoid unnecessary network hops?
3. **Performance** — Does this introduce latency, resource waste, cost blowup, or scaling limits?
4. **Build & deploy velocity** — Are build steps deduplicated and cached, and can this be deployed/reconfigured fast?
5. **Idiomatic** — Does it follow the conventions of the tool/ecosystem being used, or does it fight the tool?
6. **Simplicity** — Is this the lightest-weight solution, or is there unnecessary abstraction, indirection, or config sprawl? New dependencies should only be added when no simple, idiomatic, localized approach exists.

When priorities conflict (e.g. an idiomatic pattern is heavier than a simpler non-idiomatic one), default to whichever better protects stability, then favor simplicity as the tiebreaker. Note the tradeoff explicitly rather than silently picking one.

## Process

1. **Identify the tool/ecosystem** first (Terraform, K8s/Helm, Ansible, CDK/CloudFormation, Docker, CI YAML, etc.) — the idiomatic checklist below depends on it.
2. **Read the whole diff before commenting.** Don't review line-by-line blind; understand what the MR is trying to accomplish.
3. **Walk the four priorities in order** against the diff (see checklists below).
4. **Classify every finding** by severity: `blocker` (will break something / must fix before merge), `should-fix` (real issue, not merge-blocking), `nit` (style/preference, optional).
5. **Output the review** in the format below. Don't pad with praise for things that are merely correct — only call out things worth the author's attention.

## Checklists by priority

### Stability
- Destructive changes: resource replacement/recreation instead of in-place update (check `terraform plan` semantics — anything forcing `-/+`), deletion of resources still referenced elsewhere, renamed resources without state migration (`moved` blocks / `terraform state mv`).
- Blast radius: does this change apply to prod directly, or is there a staged rollout (canary, percentage-based, separate env first)?
- Rollback: is there an easy revert path, or does this change make rollback hard (e.g. irreversible migrations, one-way schema/state changes)?
- Health checks / readiness / liveness probes present and sane for new services or containers.
- Secrets and credentials: no hardcoded secrets, proper use of secret managers/vaults, no secrets logged.
- Dependency ordering: implicit vs explicit dependencies (`depends_on`, `needs`, init containers) correct so things don't race on startup.
- Idempotency: reapplying the change produces the same result (no drift-inducing patterns like unpinned "latest" resolving differently each apply).
- Version pinning: provider/module/image/chart versions pinned to avoid surprise upgrades; unpinned `latest` tags are a flag.

### Architecture
- Horizontal scalability: can this component run as 2+ replicas without breaking? Flag anything that assumes a single instance — local disk state, in-memory session/cache not shared across replicas, singleton leader-election logic bolted on where it isn't needed, sticky-session requirements, hardcoded self-references (own IP/hostname), file locks on local volumes.
- Statefulness: state that should live in a shared store (DB, object storage, distributed cache) instead of on the instance/pod itself. `StatefulSet` used only where genuinely needed (stable identity/storage), not as a default for scalable services.
- Scaling knobs actually exist and work: HPA/ASG/autoscaler config present and wired to a meaningful metric for anything expected to scale out; no manual-only scaling for a component described as scalable.
- Network hop count: count the hops a request/data path takes through the new/changed topology (load balancer → proxy → gateway → sidecar → service → datastore, etc.) and flag hops that don't earn their cost — redundant proxies, unnecessary service-mesh sidecars, extra internal load balancers, chained internal calls that could be collapsed or done in parallel instead of serially.
- Cross-AZ/cross-region hops introduced unnecessarily (also a performance/cost concern — cross-reference with the Performance checklist rather than duplicating).
- Single points of failure introduced by the topology itself (one NAT gateway, one bastion, one non-replicated cache) even if each individual resource is otherwise "stable."

### Performance
- Resource requests/limits (CPU/memory) set and reasonable — not missing, not wildly over/under-provisioned.
- Autoscaling config (HPA/cluster autoscaler/ASG) makes sense for the workload's actual traffic pattern.
- No obvious N+1-style infra patterns (e.g. per-request resource creation, excessive API calls in loops in provisioning scripts).
- Data transfer cost/latency: cross-AZ/cross-region chatter, egress cost (topology/hop concerns themselves are covered under Architecture — this is about the cost/latency impact specifically).
- Storage/instance sizing matches workload; no oversized instances "just in case" without justification.
- Caching layers used where they'd meaningfully help, not added speculatively where they add complexity for no measured benefit.

### Build & deploy velocity
- Layer caching: Dockerfile instruction order puts rarely-changing steps (base image, system deps) before frequently-changing ones (app code) so cache hits are maximized; dependency install steps separated from source copy so a code change doesn't invalidate the dependency layer.
- Duplication across build steps/pipeline jobs: repeated install/build/lint steps across CI jobs that could share a cached artifact, base image, or reusable job/template instead of re-running from scratch each time.
- Build cache actually wired up in CI (registry cache, BuildKit cache mounts, CI-native cache action) — not just theoretically cacheable but unused because the pipeline doesn't persist/restore it.
- Multi-stage builds used to keep final images lean and to avoid rebuilding unchanged stages.
- Monorepo/multi-service builds: only the changed service's build triggered, not a full rebuild of everything on every change (path filters, affected-only builds).
- Deploy speed: rolling update / rollout strategy allows fast, incremental deploys (readiness gates that aren't overly conservative, reasonable `maxSurge`/`maxUnavailable`, no unnecessary full-restart-on-every-deploy patterns).
- Config changes decoupled from image rebuilds: config/env changes (feature flags, env vars, ConfigMaps/Secrets, `.tfvars`) can be applied without triggering a full rebuild+redeploy of the artifact, wherever that's a reasonable ask for the change in question.
- Fast rollback/rollout for config-only changes: config updates apply quickly (e.g. ConfigMap reload vs. requiring a pod restart chain; Terraform changes scoped so a config tweak doesn't force a full `apply` touching unrelated resources).
- Pipeline steps that block deploys without adding safety (e.g. redundant serial steps that could run in parallel, unnecessary manual approval gates for low-risk changes).

### Idiomatic
- Follows the tool's recommended module/file/resource organization (e.g. Terraform module structure, Helm chart conventions, Ansible role layout).
- Uses the tool's native constructs instead of reinventing them (e.g. Terraform `for_each`/`count` instead of copy-pasted resource blocks; Helm `values.yaml` overrides instead of templated hacks; K8s-native objects instead of custom scripts doing what a Job/CronJob/Operator would do).
- Naming conventions consistent with the rest of the codebase.
- Linting/formatting tool for that ecosystem would pass (`terraform fmt`/`validate`, `helm lint`, `ansible-lint`, `cfn-lint`, `hadolint` for Dockerfiles).
- No fighting the tool: e.g. excessive `local-exec`/`null_resource` in Terraform, shell scripts wrapping what a provider resource already does natively.

### Simplicity / lightweight
- **Dependency philosophy: new dependencies are a last resort, not a default.** Before approving a new provider, module, chart, operator, CRD, sidecar, or third-party tool, check whether a simple, idiomatic, *localized* approach already available in the existing stack could do the job — a native resource/construct, a small amount of glue config, or an existing shared module. Only accept a new dependency when that local option is genuinely absent, meaningfully harder to maintain, or clearly the wrong tool for the job — not just because the dependency is popular, "best practice," or slightly more convenient. When flagging this, name the specific local alternative you'd expect to be ruled out first.
- **Prefer native language/tool packages over OS-level packages.** When a dependency is needed, prefer the language ecosystem's own package (e.g. a Rust crate providing TLS, a Python/Node package) over installing it via the OS package manager (e.g. `apt install openssl-dev`, `apk add`). Native packages are more likely to be version-pinned per-project, reproducible across environments, and free of image-bloat/CVE-surface from unrelated OS packages. Flag `apt`/`apk`/`yum` installs of libraries that have a well-supported native equivalent in the project's language, and only accept the OS package when the native option is missing, unmaintained, or requires a system-level component (e.g. certificates, kernel modules) that genuinely can't live in the language ecosystem.
- Is there a smaller diff that accomplishes the same goal? Call out unnecessary abstraction layers, unused variables/outputs, speculative generality ("we might need this later").
- Config duplication that could be a shared module/variable — but also flag the opposite: over-abstracted shared modules for something used once.
- Number of new moving parts (new services, sidecars, operators, CRDs) justified by the actual requirement, not just by "best practice."
- Dependency count: new providers, modules, or third-party charts pulled in — each one should be justified against the localized alternative above, not just "are they earning their keep" in the abstract.

## Output format

```
## Summary
1-3 sentences: what this MR does and the overall verdict (safe to merge / needs changes / needs discussion).

## Blockers
- [file:line] Issue — why it matters — suggested fix

## Should-fix
- [file:line] Issue — why it matters — suggested fix

## Nits
- [file:line] Issue

## What's good (optional, brief)
Only if there's a genuinely notable good decision worth reinforcing — skip if nothing stands out.
```

If no file/line info is available (e.g. a pasted diff without full paths), reference the hunk or resource name instead.

## Notes
- If the diff's tool/ecosystem isn't identifiable, ask which stack it's for before applying the idiomatic checklist — the other three checklists (stability/performance/simplicity) are mostly stack-agnostic and can proceed regardless.
- Don't invent context about the environment (traffic levels, SLAs, team conventions) that isn't in the diff or given by the user — flag it as "worth confirming" rather than asserting a verdict.
- Keep the review short. A clean, low-risk MR should get a short review, not a padded one.
