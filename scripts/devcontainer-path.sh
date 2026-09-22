#!/usr/bin/env bash
# devcontainer-path.sh — resolve the PATH a Dev Container client applies to the
# processes it starts, from the remoteEnv of an image's devcontainer.metadata
# label.
#
# Usage:
#   devcontainer-path.sh <mode> <image_ref>
#
#   mode       resolved  the whole PATH, the image's own where the label sets none
#              declared  the entries the label prepends, empty where it sets none
#   image_ref  Tagged reference of an image the local Docker daemon holds
set -euo pipefail

MODE="${1:?Usage: devcontainer-path.sh <resolved|declared> <image_ref>}"
IMAGE_REF="${2:?Usage: devcontainer-path.sh <resolved|declared> <image_ref>}"

IMAGE_PATH=$(docker image inspect --format '{{range .Config.Env}}{{println .}}{{end}}' \
  "$IMAGE_REF" | sed -n 's/^PATH=//p')
METADATA=$(docker image inspect --format '{{index .Config.Labels "devcontainer.metadata"}}' \
  "$IMAGE_REF")

# The client merges the label's entries in order, so the last remoteEnv.PATH is
# the one it applies, with ${containerEnv:PATH} resolved against the image's own.
RESOLVED=$(jq -rn --argjson metadata "$METADATA" --arg image_path "$IMAGE_PATH" '
  [$metadata[].remoteEnv.PATH // empty] | last // $image_path
    | gsub("\\$\\{containerEnv:PATH\\}"; $image_path)')

case "$MODE" in
  resolved) echo "$RESOLVED" ;;
  declared) [ "$RESOLVED" = "$IMAGE_PATH" ] || echo "${RESOLVED%":${IMAGE_PATH}"}" ;;
  *) echo "Unknown mode: ${MODE}" >&2; exit 1 ;;
esac
