---
name: alphabetize-declarations
user-invocable: true
description: Keep Makefile targets, variable groups, and other declaration lists sorted alphabetically
---

# Alphabetize Declarations

Declaration lists in build and config files are kept in alphabetical order.
Reading them is a lookup, not a narrative: sorted order means a name can be found
without reading everything, and a new entry has exactly one correct position, so
no one has to decide where it goes.

## What this covers

- **Makefile targets** — every target block, alphabetically, each carrying its
  own leading comment.
- **Makefile variable groups** — assignments sorted within each labelled group.
  Keep the groups themselves (`# Build configuration`, `# Go flags`); they are
  semantic and are not sorted against each other.
- **`.PHONY`** — sorted, and matching the real target list exactly.
- Package/dependency lists, environment-variable blocks, and keys in
  hand-maintained YAML or TOML config.

## What this does NOT cover

Order carries meaning in these; leave them alone.

- Prerequisites on a target line (`build: deps-update lint`) — a dependency order.
- Sequential steps inside a recipe.
- Hook lists where execution order matters (`.pre-commit-config.yaml`).
- Anything whose order the tool itself interprets — `PATH`-like values, layered
  config where later entries override earlier ones, `Dockerfile` instructions.

## Applying it to an existing file

Sorting a Makefile is a mechanical edit that is easy to get subtly wrong.

1. **Move mid-file variables into the config section first.** A variable defined
   between two targets is anchored by position to the target below it. Sorting
   will strand it, or strand the comment it sits inside. Lift it before
   reordering anything.
2. **Keep each comment with its target.** A comment block directly above a target
   documents that target and must travel with it.
3. **Rebuild `.PHONY` from the actual target list**, rather than sorting what is
   there. Stale entries and omissions are common, and this is the moment they
   become visible.
4. **Check for order-dependent expansion.** Reordering `:=` assignments is only
   safe when none references another variable defined below it. `?=` and `=` are
   lazily expanded and are always safe.

## Verifying the result

A reorder must be provably content-preserving. Check all four before committing:

```bash
# 1. the target set is unchanged
diff <(grep -o '^[a-zA-Z][a-zA-Z0-9_-]*:' Makefile.before | sort) \
     <(grep -o '^[a-zA-Z][a-zA-Z0-9_-]*:' Makefile | sort)

# 2. every recipe line survives (compare sorted, since order changed)
diff <(grep '^\t' Makefile.before | sort) <(grep '^\t' Makefile | sort)

# 3. targets really are in order
grep -o '^[a-zA-Z][a-zA-Z0-9_-]*:' Makefile | sed 's/:$//' > /tmp/o
diff /tmp/o <(sort /tmp/o)

# 4. make still parses, and the targets still resolve
make -n help >/dev/null && for t in build test lint; do make -n "$t" >/dev/null; done
```

Exclude the `.PHONY` continuation lines from check 2 if you rebuilt it — those
are tab-indented and will otherwise register as recipe changes.
