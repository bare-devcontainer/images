#!/usr/bin/env bash
# check-image-path.sh — assert that no directory on an image's PATH can be
# written by the dev user.
#
# Usage:
#   check-image-path.sh <image_ref>
#
#   image_ref  Tagged reference of an image the local Docker daemon holds
set -euo pipefail

IMAGE_REF="${1:?Usage: check-image-path.sh <image_ref>}"

# ENV PATH is the same for every user, so reading it as dev, who then answers
# whether each entry is writable, covers what any other user would resolve.
WRITABLE=$(docker run --rm --user dev "$IMAGE_REF" sh -c '
  echo "$PATH" | tr ":" "\n" | while IFS= read -r DIR; do
    [ -n "$DIR" ] || continue
    # An entry the image does not ship is one dev may be free to create, so the
    # closest existing ancestor decides.
    while [ ! -e "$DIR" ] && [ "$DIR" != "/" ]; do
      DIR=$(dirname "$DIR")
    done
    if [ -w "$DIR" ]; then
      echo "$DIR"
    fi
  done')

if [ -n "$WRITABLE" ]; then
  mapfile -t DIRS <<< "$WRITABLE"
  echo "⚠️ ${IMAGE_REF} has ${#DIRS[@]} PATH entr(y|ies) dev can write:" >&2
  printf '  %s\n' "${DIRS[@]}" >&2
  cat >&2 <<'REASON'

ENV PATH applies to every user in the container, so a directory dev can write
lets anything dev runs shadow a command another user resolves, root included.
Declare such a directory through remoteEnv in the devcontainer.metadata label
instead, which only a Dev Container client's own processes pick up:
https://containers.dev/implementors/json_reference/
REASON
  exit 1
fi

echo "✅ ${IMAGE_REF} has no PATH entry dev can write"
