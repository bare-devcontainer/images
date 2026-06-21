#!/usr/bin/env bash
# build-json.sh — utility for querying and updating build.json
#
# Usage:
#   build-json.sh <build.json> <command> [args...]
#
# Commands:
#   image-matrix <image_name>
#       Output all entries as a JSON array of {"image": <image_name>, "variant": "...", "primary_tag": "..."}.
#       Used to generate the GitHub Actions job matrix.
#
#   get-field <variant> <field>
#       Print the value of an arbitrary field for the entry matching <variant>.
#
#   build-args <variant>
#       Print the build_args for <variant> as KEY=VALUE pairs, one per line.
#       Suitable for passing to Docker --build-arg flags.
#
#   tags <variant> <image_ref>
#       Print all tags for <variant> as <image_ref>:<tag>, one per line.
set -euo pipefail

FILE="${1:?Usage: build-json.sh <build.json> <command> [args...]}"
COMMAND="${2:?Missing command}"

case "$COMMAND" in
  image-matrix)
    # image-matrix <image_name>
    # → [{"image":"golang","variant":"1.26","primary_tag":"1.26.4-trixie"}, ...]
    jq -c --arg img "${3:?Missing image name}" \
      '[.[] | {image: $img, variant, primary_tag: .tags[0]}]' "$FILE"
    ;;
  get-field)
    # get-field <variant> <field>
    jq -r --arg tag "${3:?Missing variant}" --arg field "${4:?Missing field}" \
      '.[] | select(.variant == $tag) | .[$field]' "$FILE"
    ;;
  build-args)
    # build-args <variant>  → "KEY=VALUE\n..." を出力
    jq -r --arg tag "${3:?Missing variant}" \
      '.[] | select(.variant == $tag) | .build_args | to_entries[] | "\(.key)=\(.value)"' \
      "$FILE"
    ;;
  tags)
    # tags <variant> <image_ref>  → "image_ref:tag\n..." を出力
    jq -r --arg tag "${3:?Missing variant}" --arg ref "${4:?Missing image_ref}" \
      '.[] | select(.variant == $tag) | .tags[] | $ref + ":" + .' \
      "$FILE"
    ;;
  *)
    echo "Unknown command: $COMMAND" >&2
    echo "Available commands: image-matrix, get-field, build-args, tags" >&2
    exit 1
    ;;
esac
