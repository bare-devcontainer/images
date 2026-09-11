#!/usr/bin/env bash
# mirror-config.sh — generate a regsync configuration that mirrors published images
#
# Usage:
#   mirror-config.sh release <source_prefix> <target_prefix> <build_date>
#   mirror-config.sh full <source_prefix> <target_prefix>
#
# Must be run from the repository root. <source_prefix> and <target_prefix> are
# tag-less registry paths (e.g. ghcr.io/bare-devcontainer) that each image name
# is appended to. The configuration is written to stdout.
#
# Both modes read the working tree, so run this against a released commit: an
# image directory the source registry holds no repository for fails the sync.
# A tag no release has published is skipped instead, since both modes take
# their tags from what the registry lists rather than naming them.
#
# Modes:
#   release
#       One entry per image, allowing every tag <image>/build.yaml defines plus
#       each variant's primary tag carrying the date suffix. regsync lists the
#       tags the source repository holds and copies the ones the allow list
#       matches, so a release that built only some of the images needs no say
#       in which: an image it left alone holds no tag for <build_date>, and the
#       rest of its allow list still resolves to what it published before.
#
#   full
#       One entry per image, covering every tag the source repository holds.
#       This picks up the tags of releases predating the mirror and of variants
#       build.yaml no longer defines, which the release mode cannot name. The
#       sha256-<digest> tags are excluded: they carry the fallback copy of the
#       attestations, which gh attestation verify reads from the GitHub API.
#
# Credentials are read from the environment at regsync run time, so the
# generated file holds no secrets and an unset variable leaves the registry
# anonymous: SOURCE_REGISTRY_USER, SOURCE_REGISTRY_TOKEN, TARGET_REGISTRY_USER,
# and TARGET_REGISTRY_TOKEN.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

MODE="${1:?Usage: mirror-config.sh <release|full> <source_prefix> <target_prefix> [build_date]}"
SOURCE_PREFIX="${2:?Missing source_prefix}"
TARGET_PREFIX="${3:?Missing target_prefix}"

# Bounds the concurrent copies. regsync compares the source and target digests
# before it takes this throttle, so the comparisons stay unbounded either way.
PARALLEL=3

fail() {
  echo "error: $*" >&2
  exit 1
}

build_config() {
  bash "${SCRIPT_DIR}/build-config.sh" "$@"
}

emit_header() {
  printf -- 'version: 1\n'
  printf -- 'creds:\n'
  printf -- "  - registry: %s\n    user: '%s'\n    pass: '%s'\n" \
    "${SOURCE_PREFIX%%/*}" '{{env "SOURCE_REGISTRY_USER"}}' '{{env "SOURCE_REGISTRY_TOKEN"}}'
  printf -- "  - registry: %s\n    user: '%s'\n    pass: '%s'\n" \
    "${TARGET_PREFIX%%/*}" '{{env "TARGET_REGISTRY_USER"}}' '{{env "TARGET_REGISTRY_TOKEN"}}'
  printf -- 'defaults:\n  parallel: %s\nsync:\n' "$PARALLEL"
}

# The entry both modes emit: regsync lists the tags the source repository holds
# and each mode appends the filter that decides which of them are copied.
emit_entry() {
  local image="$1"
  printf -- '  - source: %s/%s\n    target: %s/%s\n    type: repository\n' \
    "$SOURCE_PREFIX" "$image" "$TARGET_PREFIX" "$image"
  printf -- '    tags:\n'
}

emit_full() {
  emit_entry "$1"
  printf -- '      deny:\n        - sha256-.*\n'
}

# regsync compiles every allow pattern as a regular expression anchored with ^
# and $, so a tag only matches itself once its metacharacters are escaped.
escape_tag() {
  sed 's/[^A-Za-z0-9_-]/\\&/g'
}

# Every list below is captured by assignment before it is read. mapfile reading
# a process substitution succeeds even when the command inside it failed, which
# would drop entries from the configuration instead of stopping the script.
emit_release() {
  local image="$1" build_date="$2"
  local variants variant primary tags allow patterns pattern

  variants=$(build_config variants "$image" | jq -r '.[]')
  [ -n "$variants" ] || fail "${image}/build.yaml defines no variant"

  emit_entry "$image"
  printf -- '      allow:\n'

  while IFS= read -r variant; do
    tags=$(build_config tag-names "$image" "$variant")
    [ -n "$tags" ] || fail "variant ${variant} of ${image} defines no tag"
    primary=$(build_config primary-tag "$image" "$variant")

    allow=$(printf '%s\n%s\n' "${primary}-${build_date}" "$tags" | escape_tag)
    mapfile -t patterns <<< "$allow"
    for pattern in "${patterns[@]}"; do
      printf -- "        - '%s'\n" "$pattern"
    done
  done <<< "$variants"
}

IMAGE_LIST=$(build_config images | jq -r '.[]')
[ -n "$IMAGE_LIST" ] || fail "no image directory contains a build.yaml"
mapfile -t IMAGES <<< "$IMAGE_LIST"

emit_header

case "$MODE" in
  release)
    BUILD_DATE="${4:?Missing build_date}"
    for IMAGE in "${IMAGES[@]}"; do
      emit_release "$IMAGE" "$BUILD_DATE"
    done
    ;;
  full)
    for IMAGE in "${IMAGES[@]}"; do
      emit_full "$IMAGE"
    done
    ;;
  *)
    echo "Unknown mode: $MODE" >&2
    echo "Available modes: release, full" >&2
    exit 1
    ;;
esac
