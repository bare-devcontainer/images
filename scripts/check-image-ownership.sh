#!/usr/bin/env bash
# check-image-ownership.sh — assert that nothing an image ships outside the dev
# user's home directory is owned by that user.
#
# Usage:
#   check-image-ownership.sh <image_ref>
#
#   image_ref  Tagged reference of an image the local Docker daemon holds
#
# Such ownership does not survive the UID remap a Dev Container client applies
# by default on Linux.
set -euo pipefail

IMAGE_REF="${1:?Usage: check-image-ownership.sh <image_ref>}"

# /workspaces is created by WORKDIR after USER, and a dev container covers it
# with the workspace bind mount, so dev owning it reaches no consumer.
OWNED=$(docker run --rm --user root "$IMAGE_REF" sh -c '
  set -eu
  DEV_UID=$(id -u dev)
  DEV_GID=$(id -g dev)
  find / -xdev \( -uid "$DEV_UID" -o -gid "$DEV_GID" \) \
    -not -path /home/dev -not -path "/home/dev/*" \
    -not -path /workspaces')

if [ -n "$OWNED" ]; then
  mapfile -t PATHS <<< "$OWNED"
  echo "⚠️ ${IMAGE_REF} ships ${#PATHS[@]} path(s) owned by dev outside its home directory:" >&2
  printf '  %s\n' "${PATHS[@]:0:20}" >&2
  [ "${#PATHS[@]}" -le 20 ] || echo "  ... and $(( ${#PATHS[@]} - 20 )) more" >&2
  cat >&2 <<'REASON'

A Dev Container client's updateRemoteUserUID chowns dev's home alone, so these
keep the old UID and end up owned by nobody. Consider making them root-owned:
https://github.com/devcontainers/cli/blob/main/scripts/updateUID.Dockerfile
REASON
  exit 1
fi

echo "✅ ${IMAGE_REF} owns nothing outside dev's home directory"
