#!/usr/bin/env bash
#
# Assert that .claude-plugin/plugin.json's version matches the release tag.
#
# Why this exists: the plugin cache is keyed on the MANIFEST version, not the
# tag — it installs to ~/.claude/plugins/cache/<marketplace>/<plugin>/<version>/.
# A tag cut while the manifest still reads the previous version ships nothing:
# `/plugin` reports "already at the latest version", the update reinstalls over
# the old cache directory, and sessions keep loading pre-fix code. That has
# happened twice (0.5.0 and 0.5.2), the second time after the convention was
# written into CLAUDE.md — prose alone did not hold.
#
# Usage:
#   scripts/check-release-version.sh 0.5.3   # check against an explicit tag
#   scripts/check-release-version.sh         # check against the current HEAD's tag
#
# Run it before `git push --tags`, and CI runs it on every tag push.

set -euo pipefail

MANIFEST=".claude-plugin/plugin.json"

tag="${1:-}"
if [ -z "$tag" ]; then
  tag="$(git describe --exact-match --tags HEAD 2>/dev/null || true)"
  if [ -z "$tag" ]; then
    echo "error: no tag given and HEAD is not tagged." >&2
    echo "usage: $0 [tag]" >&2
    exit 2
  fi
fi

[ -f "$MANIFEST" ] || { echo "error: $MANIFEST not found (run from the repo root)." >&2; exit 2; }

# Parsed with python rather than grep so a reformatted manifest cannot slip past.
manifest_version="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["version"])' "$MANIFEST")"

# Tags are X.Y.Z with no v prefix (CLAUDE.md, Releasing). Reject the prefixed
# form outright rather than silently tolerating it — mixing the two is how the
# historical vX.Y.Z tags had to be renamed.
case "$tag" in
  v*) echo "error: tag '$tag' has a 'v' prefix; tags are X.Y.Z (see CLAUDE.md, Releasing)." >&2; exit 1 ;;
esac

if [ "$manifest_version" != "$tag" ]; then
  cat >&2 <<MSG
error: the release tag and the manifest disagree, so this release would ship nothing.

  tag:                  $tag
  $MANIFEST version:  $manifest_version

The plugin cache is keyed on the manifest version, so a tag without a matching
bump reinstalls over the old directory and \`/plugin\` reports no update.

Fix: bump "version" in $MANIFEST to $tag on a branch, merge that PR, and cut
the tag at its merge commit — the bump rides the PR (see CLAUDE.md, Releasing).
MSG
  exit 1
fi

echo "ok: $MANIFEST version ($manifest_version) matches tag ($tag)"
