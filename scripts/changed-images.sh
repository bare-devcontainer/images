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
# "files" lists the changes under <image>/ plus the shared files listed below;
# changes that select every image through the repository-wide rule are named by
# "reason" instead, so the report does not repeat them for every image.
#
# Selection rules, from the most specific to the most general:
#   - Files under <image>/ affect that image.
#   - The shared files listed in SHARED_PATHS affect every image. Note that
#     debian/Dockerfile is NOT one of them: build-checks.yml builds each derived
#     image FROM the *published* ghcr.io debian tag, so a base image change in
#     the working tree never reaches a derived image build there.
#   - Any other path (workflow definition, shared scripts, ignore lists, ...)
#     counts as a repository-wide change and affects every image, so a path
#     this script does not know about never silently skips a test.
set -euo pipefail

# Files that live in one image directory but are consumed by every image.
# build-checks.yml bind-mounts the debian smoke test into each image and runs
# it before the image's own smoke test.
SHARED_PATHS='["debian/smoke-test.sh"]'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

INPUT="${1:--}"
if [ "$INPUT" = "-" ]; then
  CHANGED=$(cat)
else
  CHANGED=$(cat "$INPUT")
fi

IMAGES=$(bash "${SCRIPT_DIR}/build-config.sh" images)

jq -n -c --argjson images "$IMAGES" --argjson shared "$SHARED_PATHS" --arg changed "$CHANGED" '
  # Directory of the image a path belongs to, or null when it belongs to none.
  def owner($path): $images | map(select(. as $dir | $path | startswith($dir + "/"))) | first;

  ($changed | split("\n") | map(select(length > 0))) as $files
  | ($files | map(select(IN($shared[])))) as $shared_changed
  | ($files | map(select(owner(.) == null))) as $repo_wide
  | $images | map(
      . as $image
      | ($files | map(select(owner(.) == $image))) as $own
      # A shared file in this image own directory is already covered by $own.
      | ($shared_changed | map(select(owner(.) != $image))) as $inherited
      | {
          image: $image,
          selected: (($own + $inherited + $repo_wide) | length > 0),
          reason: (
            if ($own | length) > 0 then "own files changed"
            elif ($inherited | length) > 0 then "shared files changed"
            elif ($repo_wide | length) > 0 then "repository-wide files changed"
            else "no relevant changes"
            end
          ),
          files: ($own + $inherited)
        }
    )
'
