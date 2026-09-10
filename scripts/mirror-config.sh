#!/usr/bin/env bash
# mirror-config.sh — generate a regsync configuration that mirrors published images
#
# Usage:
#   mirror-config.sh release <source_prefix> <target_prefix> <build_date> <images>
#   mirror-config.sh full <source_prefix> <target_prefix>
#
# Must be run from the repository root. <source_prefix> and <target_prefix> are
# tag-less registry paths (e.g. ghcr.io/bare-devcontainer) that each image name
# is appended to. <images> is a JSON array naming the images the release dated
# <build_date> published, each of which must have a build.yaml; a release
# publishes only the images that changed since the one before it, so this list
# is what bounds the tags the registry holds for that date. The configuration
# is written to stdout.
#
# Both modes read the working tree, so run this against a released commit: an
# image directory or a tag that no release has published yet resolves to a
# source reference the registry does not hold, which fails the sync.
#
# Modes:
#   release
#       One entry per tag the release dated <build_date> published: for each
#       image in <images>, every tag <image>/build.yaml defines, plus each
#       variant's primary tag carrying the date suffix.
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

MODE="${1:?Usage: mirror-config.sh <release|full> <source_prefix> <target_prefix> [build_date images]}"
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

emit_image() {
  local source_ref="$1" target_ref="$2"
  printf -- '  - source: %s\n    target: %s\n    type: image\n' "$source_ref" "$target_ref"
}

emit_repository() {
  local image="$1"
  printf -- '  - source: %s/%s\n    target: %s/%s\n    type: repository\n' \
    "$SOURCE_PREFIX" "$image" "$TARGET_PREFIX" "$image"
  printf -- '    tags:\n      deny:\n        - sha256-.*\n'
}

# Every list below is captured by assignment before it is read. mapfile reading
# a process substitution succeeds even when the command inside it failed, which
# would drop entries from the configuration instead of stopping the script.
emit_release() {
  local image="$1" build_date="$2"
  local variants variant primary source_tags target_tags source_refs target_refs i

  variants=$(build_config variants "$image" | jq -r '.[]')
  [ -n "$variants" ] || fail "${image}/build.yaml defines no variant"

  while IFS= read -r variant; do
    primary=$(build_config primary-tag "$image" "$variant")
    [ -n "$primary" ] || fail "variant ${variant} of ${image} defines no tag"
    emit_image "${SOURCE_PREFIX}/${image}:${primary}-${build_date}" \
      "${TARGET_PREFIX}/${image}:${primary}-${build_date}"

    source_tags=$(build_config tags "$image" "$variant" "${SOURCE_PREFIX}/${image}")
    target_tags=$(build_config tags "$image" "$variant" "${TARGET_PREFIX}/${image}")
    mapfile -t source_refs <<< "$source_tags"
    mapfile -t target_refs <<< "$target_tags"
    for i in "${!source_refs[@]}"; do
      emit_image "${source_refs[$i]}" "${target_refs[$i]}"
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
    RELEASED="${5:?Missing images}"
    RELEASED_LIST=$(jq -r '.[]' <<< "$RELEASED")
    [ -n "$RELEASED_LIST" ] || fail "the release names no image"
    while IFS= read -r IMAGE; do
      printf '%s\n' "${IMAGES[@]}" | grep -qxF -- "$IMAGE" \
        || fail "no image directory ${IMAGE} contains a build.yaml"
      emit_release "$IMAGE" "$BUILD_DATE"
    done <<< "$RELEASED_LIST"
    ;;
  full)
    for IMAGE in "${IMAGES[@]}"; do
      emit_repository "$IMAGE"
    done
    ;;
  *)
    echo "Unknown mode: $MODE" >&2
    echo "Available modes: release, full" >&2
    exit 1
    ;;
esac
