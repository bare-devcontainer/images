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
# "files" lists the changes under <image>/; changes that select every image
# are named by "reason" instead, so the report does not repeat them for every
# image.
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
#       - Files under debian/ affect every image: build-checks.yml builds the
#         debian base from the checkout and builds each other image FROM it,
#         so a base image change reaches every image build. It also
#         bind-mounts debian/smoke-test.sh into each image and runs it before
#         the image's own one.
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
#         published, so a base image change reaches every derived image. The
#         smoke tests are the exception; the pattern above drops them.
#       - Every other path affects no image. The weekly rebuild of every image
#         is the catch-all for what a change outside the image directories
#         (a workflow, a shared script) alters in a published image.
set -euo pipefail

# Paths that cannot reach any build the caller performs, matched as a regular
# expression against each changed path. Markdown is documentation only; no
# Dockerfile copies one in. Each mode adds what it alone cannot reach.
IGNORED_PATTERN='\.md$'

# The image every other image is built FROM, so a change under it reaches
# every image.
BASE_IMAGE_DIR='debian/'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

MODE="${1:?Usage: changed-images.sh <build|release> [<file>]}"
INPUT="${2:--}"

case "$MODE" in
  build)
    DEVCONTAINER_OWNED=true
    UNOWNED_REPO_WIDE=true
    ;;
  release)
    DEVCONTAINER_OWNED=false
    UNOWNED_REPO_WIDE=false
    # No image copies its smoke test in; build-checks.yml bind-mounts them at
    # test time, so a change to one alters nothing that gets published.
    IGNORED_PATTERN="${IGNORED_PATTERN}|^[^/]+/smoke-test\.sh$"
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

jq -n -c --argjson images "$IMAGES" \
  --argjson devcontainer_owned "$DEVCONTAINER_OWNED" \
  --argjson unowned_repo_wide "$UNOWNED_REPO_WIDE" \
  --arg base_image_dir "$BASE_IMAGE_DIR" \
  --arg ignored "$IGNORED_PATTERN" --arg changed "$CHANGED" '
  # Directory of the image a path belongs to, or null when it belongs to none.
  def owner($path):
    ($images | map(select(. as $dir | $path | startswith($dir + "/"))) | first)
    // (if $devcontainer_owned then
         ($images | map(select(. as $dir | $path | startswith(".devcontainer/feature-" + $dir + "/"))) | first)
         // ($images | map(select(. as $dir | $path | startswith(".devcontainer/sandbox-" + $dir + "/"))) | first)
       else null end);

  ($changed | split("\n") | map(select(length > 0 and (test($ignored) | not)))) as $files
  | ($files | map(select(startswith($base_image_dir)))) as $base_image
  | ($files | map(select($unowned_repo_wide and owner(.) == null))) as $repo_wide
  | $images | map(
      . as $image
      | ($files | map(select(owner(.) == $image))) as $own
      | {
          image: $image,
          selected: (($own + $base_image + $repo_wide) | length > 0),
          reason: (
            if ($own | length) > 0 then "own files changed"
            elif ($base_image | length) > 0 then "base image changed"
            elif ($repo_wide | length) > 0 then "repository-wide files changed"
            else "no relevant changes"
            end
          ),
          files: $own
        }
    )
'
