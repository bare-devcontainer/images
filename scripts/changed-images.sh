#!/usr/bin/env bash
# changed-images.sh — map a set of changed files to the images they affect
#
# Usage:
#   changed-images.sh [<file>]
#
# Must be run from the repository root. Reads changed paths (one per line,
# repository-relative) from <file>, or from stdin when <file> is omitted or
# "-", and prints a JSON array with one entry per image directory:
#
#   [{"image": "node", "selected": true, "reason": "own files changed",
#     "files": ["node/Dockerfile"]}, ...]
#
# "files" lists only the changes under <image>/; changes that select an image
# through one of the broader rules below are named by "reason" instead, so the
# report does not repeat the same shared paths for every image.
#
# Selection rules, from the most specific to the most general:
#   - Files under <image>/ affect that image.
#   - Files under debian/ affect every image: all other images are built on the
#     debian base and reuse debian/smoke-test.sh in their own smoke test.
#   - Any other path (workflow definition, shared scripts, ignore lists, ...)
#     counts as a repository-wide change and affects every image, so a path
#     this script does not know about never silently skips a test.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

INPUT="${1:--}"
if [ "$INPUT" = "-" ]; then
  CHANGED=$(cat)
else
  CHANGED=$(cat "$INPUT")
fi

IMAGES=$(bash "${SCRIPT_DIR}/build-config.sh" images)

jq -n -c --argjson images "$IMAGES" --arg changed "$CHANGED" '
  # Directory of the image a path belongs to, or null when it belongs to none.
  def owner($path): $images | map(select(. as $dir | $path | startswith($dir + "/"))) | first;

  ($changed | split("\n") | map(select(length > 0))) as $files
  | ($files | map(select(owner(.) == "debian"))) as $base
  | ($files | map(select(owner(.) == null))) as $repo_wide
  | $images | map(
      . as $image
      | ($files | map(select(owner(.) == $image))) as $own
      # debian is its own base, so $base is already covered by $own there.
      | (if $image == "debian" then [] else $base end) as $inherited
      | {
          image: $image,
          selected: (($own + $inherited + $repo_wide) | length > 0),
          reason: (
            if ($own | length) > 0 then "own files changed"
            elif ($inherited | length) > 0 then "debian base image changed"
            elif ($repo_wide | length) > 0 then "repository-wide files changed"
            else "no relevant changes"
            end
          ),
          files: $own
        }
    )
'
