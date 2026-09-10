#!/usr/bin/env bash
# changed-images.sh — map a set of changed files to the images they affect
#
# Usage:
#   changed-images.sh <build|release> [<file>]
#
# Must be run from the repository root. Reads changed paths (one per line,
# repository-relative) from <file>, or from stdin when <file> is omitted or
# "-", and prints a JSON array with one entry per image directory:
#
#   [{"image": "node", "selected": true, "reason": "own files changed",
#     "files": ["node/Dockerfile"]}, ...]
#
# "files" lists the changes under <image>/ plus the cross-image files that
# select this image; changes that select every image are named by "reason"
# instead, so the report does not repeat them for every image.
#
# The mode names the build the caller performs, since what a change can reach
# differs between the two:
#
#   build
#       The pull request checks of build-checks.yml. Rules, from the most
#       specific to the most general:
#       - Paths matching IGNORED_PATTERN are dropped before any other rule.
#       - Files under <image>/ affect that image.
#       - Files under .devcontainer/feature-<image>/ affect that image, since
#         that configuration layers the Dev Container Features onto it.
#       - Files under .devcontainer/sandbox-<image>/ affect that image, since
#         that configuration builds it as a dev container.
#       - The files listed in BUILD_CROSS_IMAGE_PATHS affect every image even
#         though they live in one image's directory. Note that debian/Dockerfile
#         is NOT one of them: build-checks.yml builds each derived image FROM
#         the *published* ghcr.io debian tag, so a base image change in the
#         working tree never reaches a derived image build there.
#       - Every path outside an image directory (the workflow definition
#         itself, the shared scripts, the ignore lists, ...) is a
#         repository-wide change and affects every image. This is the
#         catch-all: a path this script does not know about is never silently
#         skipped, and only the exceptions above have to be maintained by hand.
#
#   release
#       The images release.yml publishes from the changes since the last
#       release. Rules:
#       - Paths matching IGNORED_PATTERN are dropped before any other rule.
#       - Files under <image>/ affect that image.
#       - Files under debian/ affect every image: release.yml publishes debian
#         first and builds each derived image FROM the digest it just
#         published, so a base image change reaches every derived image.
#       - Every other path affects no image. The weekly rebuild of every image
#         is the catch-all for what a change outside the image directories
#         (a workflow, a shared script) alters in a published image.
set -euo pipefail

# Paths that live in one image's directory but are consumed by every build, so
# the per-image rule does not apply to them. build-checks.yml bind-mounts the
# debian smoke test into each image and runs it before the image's own one.
BUILD_CROSS_IMAGE_PATHS='["debian/smoke-test.sh"]'

# Paths that cannot reach any build the caller performs, matched as a regular
# expression against each changed path. Markdown is documentation only; no
# Dockerfile copies one in.
IGNORED_PATTERN='\.md$'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

MODE="${1:?Usage: changed-images.sh <build|release> [<file>]}"
INPUT="${2:--}"

case "$MODE" in
  build)
    DEVCONTAINER_OWNED=true
    CROSS_IMAGE_PATHS="$BUILD_CROSS_IMAGE_PATHS"
    CROSS_IMAGE_REASON="cross-image files changed"
    REPO_WIDE_PREFIX=""
    REPO_WIDE_REASON="repository-wide files changed"
    ;;
  release)
    DEVCONTAINER_OWNED=false
    CROSS_IMAGE_PATHS='[]'
    CROSS_IMAGE_REASON=""
    REPO_WIDE_PREFIX="debian/"
    REPO_WIDE_REASON="base image changed"
    ;;
  *)
    echo "Unknown mode: $MODE" >&2
    echo "Available modes: build, release" >&2
    exit 1
    ;;
esac

if [ "$INPUT" = "-" ]; then
  CHANGED=$(cat)
else
  CHANGED=$(cat "$INPUT")
fi

IMAGES=$(bash "${SCRIPT_DIR}/build-config.sh" images)

# $repo_wide_prefix selects the paths that affect every image: with no prefix,
# every path no image owns; with one, the paths under it, which their own
# image still counts as its own files.
jq -n -c --argjson images "$IMAGES" --argjson cross_image "$CROSS_IMAGE_PATHS" \
  --argjson devcontainer_owned "$DEVCONTAINER_OWNED" \
  --arg cross_image_reason "$CROSS_IMAGE_REASON" \
  --arg repo_wide_prefix "$REPO_WIDE_PREFIX" --arg repo_wide_reason "$REPO_WIDE_REASON" \
  --arg ignored "$IGNORED_PATTERN" --arg changed "$CHANGED" '
  # Directory of the image a path belongs to, or null when it belongs to none.
  def owner($path):
    ($images | map(select(. as $dir | $path | startswith($dir + "/"))) | first)
    // (if $devcontainer_owned then
         ($images | map(select(. as $dir | $path | startswith(".devcontainer/feature-" + $dir + "/"))) | first)
         // ($images | map(select(. as $dir | $path | startswith(".devcontainer/sandbox-" + $dir + "/"))) | first)
       else null end);

  ($changed | split("\n") | map(select(length > 0 and (test($ignored) | not)))) as $files
  | ($files | map(select(IN($cross_image[])))) as $cross_image_changed
  | ($files | map(select(
      if $repo_wide_prefix == "" then owner(.) == null
      else startswith($repo_wide_prefix) end))) as $repo_wide
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
            elif ($inherited | length) > 0 then $cross_image_reason
            elif ($repo_wide | length) > 0 then $repo_wide_reason
            else "no relevant changes"
            end
          ),
          files: ($own + $inherited)
        }
    )
'
