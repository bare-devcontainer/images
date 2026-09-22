#!/usr/bin/env bash
# check-image-env.sh — assert that no path in an image's environment can be
# written by the dev user.
#
# Usage:
#   check-image-env.sh <image_ref>
#
#   image_ref  Tagged reference of an image the local Docker daemon holds
set -euo pipefail

IMAGE_REF="${1:?Usage: check-image-env.sh <image_ref>}"

# The environment is the same for every user, so reading it as dev, who then
# answers whether each path is writable, covers what any other user resolves.
WRITABLE=$(docker run --rm --user dev "$IMAGE_REF" sh -c '
  # HOME is the one path dev is meant to own.
  env | grep -v "^HOME=" | while IFS= read -r VARIABLE; do
    NAME="${VARIABLE%%=*}"
    # A value holds several paths where it extends PATH, and none at all where
    # it is not a path in the first place.
    echo "${VARIABLE#*=}" | tr ":" "\n" | while IFS= read -r DIR; do
      case "$DIR" in /*) ;; *) continue ;; esac
      # A path the image does not ship is one dev may be free to create, so the
      # closest existing ancestor decides.
      while [ ! -e "$DIR" ] && [ "$DIR" != "/" ]; do
        DIR=$(dirname "$DIR")
      done
      if [ -w "$DIR" ]; then
        echo "${NAME}: ${DIR}"
      fi
    done
  done')

if [ -n "$WRITABLE" ]; then
  mapfile -t ENTRIES <<< "$WRITABLE"
  echo "⚠️ ${IMAGE_REF} points ${#ENTRIES[@]} environment entr(y|ies) at a path dev can write:" >&2
  printf '  %s\n' "${ENTRIES[@]}" >&2
  cat >&2 <<'REASON'

ENV applies to every user in the container, so a path dev can write lets
anything dev runs shadow a command another user resolves, or decide what
another user's tool reads and writes. Declare such a variable through remoteEnv
in the devcontainer.metadata label instead, which only a Dev Container client's
own processes pick up:
https://containers.dev/implementors/json_reference/
REASON
  exit 1
fi

echo "✅ ${IMAGE_REF} points no environment entry at a path dev can write"
