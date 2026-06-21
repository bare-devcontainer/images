#!/usr/bin/env bash
# build-config.sh — utility for querying build configuration for a given image
#
# Usage:
#   build-config.sh <command> <image> [args...]
#
# Commands:
#   image-matrix <image>
#       Output all entries as a JSON array of {"image": <image>, "variant": "...", "primary_tag": "..."}.
#       Used to generate the GitHub Actions job matrix.
#
#   get-field <image> <variant> <field>
#       Print the value of an arbitrary field for the entry matching <variant>.
#
#   build-args <image> <variant>
#       Print the build_args for <variant> as KEY=VALUE pairs, one per line.
#       Suitable for passing to Docker --build-arg flags.
#
#   tags <image> <variant> <image_ref>
#       Print all tags for <variant> as <image_ref>:<tag>, one per line.
set -euo pipefail

COMMAND="${1:?Usage: build-config.sh <command> <image> [args...]}"
IMAGE_NAME="${2:?Missing image name}"
FILE="${IMAGE_NAME}/build.yaml"

case "$COMMAND" in
  image-matrix)
    IMAGE="$IMAGE_NAME" yq -o json \
      '[.[] | {"image": strenv(IMAGE), "variant": .variant, "primary_tag": .tags[0]}]' "$FILE"
    ;;
  get-field)
    VARIANT="${3:?Missing variant}" FIELD="${4:?Missing field}" yq \
      '.[] | select(.variant == strenv(VARIANT)) | .[strenv(FIELD)]' "$FILE"
    ;;
  build-args)
    VARIANT="${3:?Missing variant}" yq \
      '.[] | select(.variant == strenv(VARIANT)) | .build_args | to_entries[] | .key + "=" + .value' \
      "$FILE"
    ;;
  tags)
    VARIANT="${3:?Missing variant}" REF="${4:?Missing image_ref}" yq \
      '.[] | select(.variant == strenv(VARIANT)) | .tags[] | strenv(REF) + ":" + .' \
      "$FILE"
    ;;
  *)
    echo "Unknown command: $COMMAND" >&2
    echo "Available commands: image-matrix, get-field, build-args, tags" >&2
    exit 1
    ;;
esac
