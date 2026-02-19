---
name: doc-review
user-invocable: true
description: Check docs for staleness, broken references, and gaps
---

# Doc Review

Audit project documentation for accuracy and completeness.

## Usage

```
/doc-review
```

## Instructions

1. Find all documentation files: `README.md`, `CHANGELOG.md`, `docs/**/*.md`, `API.md`, `CONTRIBUTING.md`
2. Spawn a Task subagent with `subagent_type: "general-purpose"` to audit. The prompt should instruct it to:
   - Cross-reference documented features/APIs against actual source code
   - Flag documented items that no longer exist in code (**stale**)
   - Flag code features with public APIs that have no documentation (**gaps**)
   - Check for broken internal links and references
   - Verify setup/install instructions still work (check against current dependency files)
   - Check code examples in docs against current function signatures
3. Present findings as:
   - **Stale**: docs referencing removed/renamed code
   - **Gaps**: undocumented public APIs or features
   - **Broken**: dead links or invalid references
   - **Outdated**: instructions that don't match current setup
