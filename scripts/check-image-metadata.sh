#!/usr/bin/env bash
# check-image-metadata.sh — assert that every image re-declaring the
# devcontainer.metadata label still carries what the debian base image declares.
#
# Usage:
#   check-image-metadata.sh
#
# Must be run from the repository root. A client merges the entries of a single
# label, but a child image's LABEL replaces the value inherited from its base
# rather than merging with it, so an image that declares its own has to repeat
# what the base declares.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# LABEL devcontainer.metadata='<JSON>', which the Dockerfile continues across
# lines and, between single quotes, takes as-is.
metadata() {
  sed -e ':join' -e '/\\$/{N;s/\\\n//;bjoin}' "$1/Dockerfile" \
    | sed -n "s/^LABEL devcontainer\.metadata='\(.*\)'\$/\1/p"
}

BASE=$(metadata debian)
[ -n "$BASE" ] || {
  echo "⚠️ debian/Dockerfile declares no devcontainer.metadata label" >&2
  exit 1
}

mapfile -t IMAGES < <(bash "${SCRIPT_DIR}/build-config.sh" images | jq -r '.[]')

STATUS=0
for IMAGE in "${IMAGES[@]}"; do
  [ "$IMAGE" != "debian" ] || continue

  # An image that declares no label of its own inherits the base's unchanged.
  IMAGE_METADATA=$(metadata "$IMAGE")
  [ -n "$IMAGE_METADATA" ] || continue

  DROPPED=$(jq -rn --argjson base "$BASE" --argjson image "$IMAGE_METADATA" '
    def merged: {
      remoteUser: ([.[].remoteUser // empty] | last),
      containerUser: ([.[].containerUser // empty] | last),
      remoteEnv: ([.[].remoteEnv // {}] | add // {}),
    };
    ($base | merged) as $b | ($image | merged) as $i
    | [ (["remoteUser", "containerUser"][] as $key
          | select($i[$key] != $b[$key]) | "\($key): \($b[$key])"),
        ($b.remoteEnv | to_entries[] | select($i.remoteEnv[.key] != .value)
          | "remoteEnv.\(.key): \(.value)") ]
    | .[]')

  if [ -n "$DROPPED" ]; then
    mapfile -t ENTRIES <<< "$DROPPED"
    echo "⚠️ ${IMAGE}/Dockerfile drops what debian/Dockerfile declares:" >&2
    printf '  %s\n' "${ENTRIES[@]}" >&2
    STATUS=1
  fi
done

if [ "$STATUS" -ne 0 ]; then
  cat >&2 <<'REASON'

A re-declared devcontainer.metadata label replaces the base image's rather than
merging with it, so repeat every entry above in the label that declares the
image's own.
REASON
  exit 1
fi

echo "✅ every image repeats what debian/Dockerfile declares"
