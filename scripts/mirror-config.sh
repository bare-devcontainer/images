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
# Modes:
#   release
#       One entry per tag the release dated <build_date> published: every tag
#       <image>/build.yaml defines, plus each variant's primary tag carrying the
#       date suffix. Reads build.yaml, so it has to run against the released
#       commit rather than whatever main holds now.
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

# regsync compares the source and target digests before copying anything, so
# this bounds the concurrent comparisons as well as the concurrent copies.
PARALLEL=3

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

emit_release() {
  local image="$1" build_date="$2"
  local variant primary source_refs target_refs i

  while IFS= read -r variant; do
    primary=$(build_config primary-tag "$image" "$variant")
    emit_image "${SOURCE_PREFIX}/${image}:${primary}-${build_date}" \
      "${TARGET_PREFIX}/${image}:${primary}-${build_date}"

    mapfile -t source_refs < <(build_config tags "$image" "$variant" "${SOURCE_PREFIX}/${image}")
    mapfile -t target_refs < <(build_config tags "$image" "$variant" "${TARGET_PREFIX}/${image}")
    for i in "${!source_refs[@]}"; do
      emit_image "${source_refs[$i]}" "${target_refs[$i]}"
    done
  done < <(build_config variants "$image" | jq -r '.[]')
}

mapfile -t IMAGES < <(build_config images | jq -r '.[]')

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
      emit_repository "$IMAGE"
    done
    ;;
  *)
    echo "Unknown mode: $MODE" >&2
    echo "Available modes: release, full" >&2
    exit 1
    ;;
esac
