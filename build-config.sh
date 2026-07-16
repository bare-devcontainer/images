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
#   images
#       Output the names of every image directory (one containing a
#       build.yaml) as a JSON array. Used by update-material.yml to loop
#       over every image and refresh its trust material, if any.
#
#   description <image>
#       Print the human-readable image description.
#
#   variants <image>
#       Output all variant names for <image> as a JSON array.
#
#   tags <image> <variant> <image_ref>
#       Print all tags for <variant> as <image_ref>:<tag>, one per line.
#
#   primary-tag <image> <variant>
#       Print the first (primary) tag for <variant>.
#
#   get-field <image> <variant> <field>
#       Print the value of an arbitrary field for the entry matching <variant>.
#
#   build-args <image> <variant>
#       Print the build_args for <variant> as KEY=VALUE pairs, one per line.
#       Suitable for passing to Docker --build-arg flags.
set -euo pipefail

COMMAND="${1:?Usage: build-config.sh <command> [image] [args...]}"
IMAGE_NAME="${2:-}"
FILE="${IMAGE_NAME:+${IMAGE_NAME}/build.yaml}"

case "$COMMAND" in
  images)
    find . -maxdepth 2 -name build.yaml \
      ! -path './.devcontainer/*' \
      -printf '%h\n' | sed 's|^\./||' | sort | \
    jq -c -R -s 'split("\n") | map(select(. != ""))'
    ;;
  variants)
    yq -o json '[.variants[].variant]' "$FILE"
    ;;
  description)
    yq '.description // ""' "$FILE"
    ;;
  tags)
    VARIANT="${3:?Missing variant}" REF="${4:?Missing image_ref}" yq \
      '.variants[] | select(.variant == strenv(VARIANT)) | .tags[] | strenv(REF) + ":" + .' \
      "$FILE"
    ;;
  primary-tag)
    VARIANT="${3:?Missing variant}" yq \
      '.variants[] | select(.variant == strenv(VARIANT)) | .tags[0]' "$FILE"
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
    echo "Available commands: images, variants, description, tags, primary-tag, get-field, build-args, all-matrix" >&2
    exit 1
    ;;
esac
