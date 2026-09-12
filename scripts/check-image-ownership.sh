#!/usr/bin/env bash
# check-image-ownership.sh — assert that nothing an image ships outside the dev
# user's home directory is owned by that user.
#
# Usage:
#   check-image-ownership.sh <image_ref>
#
#   image_ref  Tagged reference of an image the local Docker daemon holds
#
# A Dev Container client remaps dev to the host user's UID/GID when
# updateRemoteUserUID is on, which it is by default on Linux. The remap
# rewrites /etc/passwd and /etc/group and then chowns the home directory alone
# (https://github.com/devcontainers/cli/blob/main/scripts/updateUID.Dockerfile),
# so anything dev owns elsewhere is left behind under the old UID. tar running
# as root restores the ownership its archive records, which is how an upstream
# release archive built under uid 1000 ends up owned by dev; extract those with
# --no-same-owner.
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
  echo "⚠️ ${IMAGE_REF} ships ${#PATHS[@]} path(s) owned by dev outside its home directory" >&2
  printf '%s\n' "${PATHS[@]:0:20}" >&2
  [ "${#PATHS[@]}" -le 20 ] || echo "... and $(( ${#PATHS[@]} - 20 )) more" >&2
  exit 1
fi

echo "✅ ${IMAGE_REF} owns nothing outside dev's home directory"
