#!/usr/bin/env bash
# dockerhub-overview.sh — render an image README as its Docker Hub overview
#
# Usage:
#   dockerhub-overview.sh <image> <source_prefix> <target_prefix> <repository_url>
#
# Must be run from the repository root. <source_prefix> and <target_prefix> are
# tag-less registry paths (e.g. ghcr.io/bare-devcontainer) that the image name
# is appended to, and <repository_url> is the GitHub repository holding the
# README, without a trailing slash. The overview is written to stdout.
#
# The READMEs are written for GitHub, which resolves paths relative to the file
# and renders the alert syntax; a Docker Hub overview is a page on its own and
# does neither. The rendering therefore:
#
#   - opens with a note that the Docker Hub repository is a mirror, and that
#     the README lives in the GitHub repository the supply chain sections mean
#     by "this repository",
#   - rewrites each ../<image> and ../README.md link to its address on GitHub,
#   - turns the > [!NOTE] alert syntax into a bold lead-in, and
#   - drops the <!-- tags:begin/end --> markers update-readme.sh writes between.
#
# Anything else Docker Hub would not render — a relative link of another shape,
# an alert or an HTML comment left behind, or an overview past the 25,000 byte
# limit of the description API — fails the script instead of reaching the page.
set -euo pipefail

IMAGE="${1:?Usage: dockerhub-overview.sh <image> <source_prefix> <target_prefix> <repository_url>}"
SOURCE_PREFIX="${2:?Missing source_prefix}"
TARGET_PREFIX="${3:?Missing target_prefix}"
REPOSITORY_URL="${4:?Missing repository_url}"

README="${IMAGE}/README.md"

# https://docs.docker.com/reference/api/hub/latest/ gives full_description this
# maximum; the API rejects the whole request past it.
MAX_BYTES=25000

fail() {
  echo "error: $*" >&2
  exit 1
}

emit_banner() {
  local slug="${REPOSITORY_URL##*/github.com/}"
  cat <<EOF
> **Mirror.** This Docker Hub repository mirrors \`${SOURCE_PREFIX}/${IMAGE}\`, under
> the same tags and with the same digests. GitHub Container Registry receives every
> build first and applies no pull rate limit, so prefer \`${SOURCE_PREFIX}/${IMAGE}\`
> unless your environment requires Docker Hub, where the image is
> \`${TARGET_PREFIX}/${IMAGE}\`.
>
> This page is rendered from the image's README in
> [${slug}](${REPOSITORY_URL}/tree/main/${IMAGE}).
> That is the repository "this repository" refers to below.
EOF
}

# Docker Hub resolves no path outside the page, so a link it is handed has to
# be absolute already. A fragment is left to it: it addresses the overview.
check_targets() {
  local target
  while IFS= read -r target; do
    case "$target" in
      '' | http://* | https://* | '#'*) ;;
      *) fail "${README}: Docker Hub cannot resolve the link target '${target}'" ;;
    esac
  done
}

[ -f "$README" ] || fail "${README} does not exist"
head -n 1 "$README" | grep -q '^# ' || fail "${README} does not open with a heading"

# \L\u lowercases the alert name and uppercases its first character, in that
# order: a \L cancels a \u that precedes it. This is GNU sed, as is the -printf
# build-config.sh lists images with.
RENDERED=$(
  BANNER="$(emit_banner)" awk '
    NR == 1 { print; print ""; print ENVIRON["BANNER"]; print ""; next }
    { print }
  ' "$README" |
    sed -E \
      -e "s|\]\(\.\./([a-z0-9][a-z0-9-]*)\)|](${REPOSITORY_URL}/tree/main/\1)|g" \
      -e "s|\]\(\.\./README\.md(#[a-z0-9-]+)?\)|](${REPOSITORY_URL}/blob/main/README.md\1)|g" \
      -e 's|^> \[!([A-Z]+)\][[:space:]]*$|> **\L\u\1**|' \
      -e '/^<!-- tags:(begin|end) -->$/d'
)

INLINE_TARGETS=$(printf '%s\n' "$RENDERED" | grep -oE '\]\([^)]*\)' | sed -E 's|^\]\((.*)\)$|\1|' || true)
printf '%s\n' "$INLINE_TARGETS" | check_targets

# A reference-style definition carries its target on a line of its own, out of
# reach of the inline link pattern above.
REFERENCE_TARGETS=$(printf '%s\n' "$RENDERED" | sed -nE 's|^\[[^]]+\]:[[:space:]]+(.*)$|\1|p' || true)
printf '%s\n' "$REFERENCE_TARGETS" | check_targets

if printf '%s\n' "$RENDERED" | grep -qE '^>[[:space:]]*\[!'; then
  fail "${README}: an alert is left unconverted"
fi

if printf '%s\n' "$RENDERED" | grep -q '<!--'; then
  fail "${README}: an HTML comment would reach the overview"
fi

BYTES=$(printf '%s\n' "$RENDERED" | wc -c)
[ "$BYTES" -le "$MAX_BYTES" ] ||
  fail "${README}: the overview is ${BYTES} bytes, past the ${MAX_BYTES} byte limit"

printf '%s\n' "$RENDERED"
