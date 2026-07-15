#!/usr/bin/env bash
# update-material.sh — refresh the trust material declared under `materials`
# in <image>/build.yaml, writing changed files in place in the working tree.
# Prints "true" or "false" to stdout depending on whether anything changed.
# Performs no git or GitHub operations.
#
# Usage:
#   update-material.sh <image> [--commit-to-pr-only]
#
# --commit-to-pr-only restricts the refresh to materials with
# commit_to_pr: true (used when a version bump is applied directly onto
# its own pull request).
set -euo pipefail

IMAGE="${1:?Usage: update-material.sh <image> [--commit-to-pr-only]}"
FILTER="${2:-}"
FILE="${IMAGE}/build.yaml"

BUILD_ARGS=$(yq -o json '.variants[0].build_args // {}' "$FILE")
FILES=$(IMAGE="$IMAGE" yq -o json \
  '[(.materials // [])[] | {"path": (strenv(IMAGE) + "/" + .path), "url": .url, "version_key": .version_key, "commit_to_pr": (.commit_to_pr // false)}]' \
  "$FILE" | \
  jq -c --argjson args "$BUILD_ARGS" \
    'map(
       (if .version_key then
          ($args[.version_key] // error("missing build arg: " + .version_key)) as $v
          | .url = (.url | gsub("VERSION"; $v))
        else . end)
       | del(.version_key))')

if [ "$FILTER" = "--commit-to-pr-only" ]; then
  FILES=$(jq -c '[.[] | select(.commit_to_pr)]' <<< "$FILES")
fi

changed=false
while IFS=$'\t' read -r path url; do
  tmp=$(mktemp)
  wget -q -T 30 -t 3 -O "$tmp" "$url"
  cmp -s "$tmp" "$path" 2>/dev/null || changed=true
  chmod 644 "$tmp"
  mkdir -p "$(dirname "$path")"
  mv "$tmp" "$path"
done < <(jq -r '.[] | [.path, .url] | @tsv' <<< "$FILES")

echo "$changed"
