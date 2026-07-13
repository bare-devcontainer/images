#!/usr/bin/env bash
# build-config.sh — utility for querying build configuration for a given image
#
# Usage:
#   build-config.sh <command> <image> [args...]
#
# Commands:
#   all-matrix
#       Output all image entries as a single JSON array of
#       {"image": <image>, "variant": "...", "primary_tag": "..."}.
#       Used to generate the GitHub Actions job matrix.
#
#   get-field <image> <variant> <field>
#       Print the value of an arbitrary field for the entry matching <variant>.
#
#   build-args <image> <variant>
#       Print the build_args for <variant> as KEY=VALUE pairs, one per line.
#       Suitable for passing to Docker --build-arg flags.
#
#   primary-tag <image> <variant>
#       Print the first (primary) tag for <variant>.
#
#   variants <image>
#       Output all variant names for <image> as a JSON array.
#
#   description <image>
#       Print the human-readable image description.
#
#   tags <image> <variant> <image_ref>
#       Print all tags for <variant> as <image_ref>:<tag>, one per line.
set -euo pipefail

COMMAND="${1:?Usage: build-config.sh <command> [image] [args...]}"
IMAGE_NAME="${2:-}"
FILE="${IMAGE_NAME:+${IMAGE_NAME}/build.yaml}"

case "$COMMAND" in
  variants)
    yq -o json '[.variants[].variant]' "$FILE"
    ;;
  description)
    yq '.description // ""' "$FILE"
    ;;
  get-field)
    VARIANT="${3:?Missing variant}" FIELD="${4:?Missing field}" yq \
      '.variants[] | select(.variant == strenv(VARIANT)) | .[strenv(FIELD)]' "$FILE"
    ;;
  build-args)
    VARIANT="${3:?Missing variant}" yq \
      '.variants[] | select(.variant == strenv(VARIANT)) | .build_args | to_entries[] | .key + "=" + .value' \
      "$FILE"
    ;;
  primary-tag)
    VARIANT="${3:?Missing variant}" yq \
      '.variants[] | select(.variant == strenv(VARIANT)) | .tags[0]' "$FILE"
    ;;
  tags)
    VARIANT="${3:?Missing variant}" REF="${4:?Missing image_ref}" yq \
      '.variants[] | select(.variant == strenv(VARIANT)) | .tags[] | strenv(REF) + ":" + .' \
      "$FILE"
    ;;
  all-matrix)
    find . -maxdepth 2 -name build.yaml \
      ! -path './debian/*' \
      ! -path './.devcontainer/*' \
      -printf '%h\n' | sed 's|^\./||' | sort | \
    while IFS= read -r IMG; do
      IMAGE="$IMG" yq -o json \
        '[.variants[] | {"image": strenv(IMAGE), "variant": .variant, "primary_tag": .tags[0]}]' \
        "${IMG}/build.yaml"
    done | jq -c -s 'add // []'
    ;;
  *)
    echo "Unknown command: $COMMAND" >&2
    echo "Available commands: all-matrix, variants, get-field, description, primary-tag, build-args, tags" >&2
    exit 1
    ;;
esac
