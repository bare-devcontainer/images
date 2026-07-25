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
# "files" lists the changes under <image>/ plus the cross-image files listed
# below; changes that select every image through the repository-wide rule are
# named by "reason" instead, so the report does not repeat them for every image.
#
# Selection rules, from the most specific to the most general:
#   - Paths matching IGNORED_PATTERN are dropped before any other rule applies.
#   - Files under <image>/ affect that image.
#   - Files under .devcontainer/feature-<image>/ affect that image, since that
#     configuration layers the Dev Container Features onto it.
#   - Files under .devcontainer/sandbox-<image>/ affect that image, since that
#     configuration builds it as a dev container.
#   - The files listed in CROSS_IMAGE_PATHS affect every image even though they
#     live in one image's directory. Note that debian/Dockerfile is NOT one of
#     them: build-checks.yml builds each derived image FROM the *published*
#     ghcr.io debian tag, so a base image change in the working tree never
#     reaches a derived image build there.
#   - Every path outside an image directory (the workflow definition itself,
#     the shared scripts, the ignore lists, ...) is a repository-wide change and
#     affects every image. This is the catch-all: a path this script does not
#     know about is never silently skipped, and only the exceptions above have
#     to be maintained by hand.
set -euo pipefail

# Paths that live in one image's directory but are consumed by every image, so
# the rule above them does not apply. build-checks.yml bind-mounts the debian
# smoke test into each image and runs it before the image's own smoke test.
CROSS_IMAGE_PATHS='["debian/smoke-test.sh"]'

# Paths that cannot reach any build the caller performs, matched as a regular
# expression against each changed path. Without this they would fall through to
# the repository-wide catch-all below and rebuild every image on both
# architectures. Markdown is documentation only; no Dockerfile copies one in.
IGNORED_PATTERN='\.md$'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

INPUT="${1:--}"
if [ "$INPUT" = "-" ]; then
  CHANGED=$(cat)
else
  CHANGED=$(cat "$INPUT")
fi

IMAGES=$(bash "${SCRIPT_DIR}/build-config.sh" images)

jq -n -c --argjson images "$IMAGES" --argjson cross_image "$CROSS_IMAGE_PATHS" \
  --arg ignored "$IGNORED_PATTERN" --arg changed "$CHANGED" '
  # Directory of the image a path belongs to, or null when it belongs to none.
  def owner($path):
    ($images | map(select(. as $dir | $path | startswith($dir + "/"))) | first)
    // ($images | map(select(. as $dir | $path | startswith(".devcontainer/feature-" + $dir + "/"))) | first)
    // ($images | map(select(. as $dir | $path | startswith(".devcontainer/sandbox-" + $dir + "/"))) | first);

  ($changed | split("\n") | map(select(length > 0 and (test($ignored) | not)))) as $files
  | ($files | map(select(IN($cross_image[])))) as $cross_image_changed
  | ($files | map(select(owner(.) == null))) as $repo_wide
  | $images | map(
      . as $image
      | ($files | map(select(owner(.) == $image))) as $own
      # A cross-image path in this image own directory is covered by $own.
      | ($cross_image_changed | map(select(owner(.) != $image))) as $inherited
      | {
          image: $image,
          selected: (($own + $inherited + $repo_wide) | length > 0),
          reason: (
            if ($own | length) > 0 then "own files changed"
            elif ($inherited | length) > 0 then "cross-image files changed"
            elif ($repo_wide | length) > 0 then "repository-wide files changed"
            else "no relevant changes"
            end
          ),
          files: ($own + $inherited)
        }
    )
'
