#!/usr/bin/env bash
# update-material.sh — refresh the trust material declared under `materials`
# in <image>/build.yaml, writing changed files in place in the working tree.
# Prints "true" or "false" to stdout depending on whether anything changed;
# per-file download and comparison progress goes to stderr. Performs no git
# or GitHub operations.
#
# A material declares either a `url` to download, or a `command` to run whose
# stdout becomes the file — for an upstream that publishes nothing fetchable,
# so this repository derives the material itself. The command is a list whose
# first element names a script in the image's own directory, keeping the logic
# next to the Dockerfile it protects; it runs with the version named by
# version_key exported under that name.
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
  '[(.materials // [])[] | {"path": (strenv(IMAGE) + "/" + .path), "url": .url, "command": .command, "version_key": .version_key, "commit_to_pr": (.commit_to_pr // false)}]' \
  "$FILE" | \
  jq -c --argjson args "$BUILD_ARGS" \
    'map(
       (if .version_key then
          ($args[.version_key] // error("missing build arg: " + .version_key)) as $v
          | .version = $v
          | (if .url then .url = (.url | gsub("VERSION"; $v)) else . end)
        else . end))')

if [ "$FILTER" = "--commit-to-pr-only" ]; then
  FILES=$(jq -c '[.[] | select(.commit_to_pr)]' <<< "$FILES")
fi

if [ "$FILES" = "[]" ]; then
  echo false
  exit 0
fi

changed=false
# One compact object per line, with each field read back out individually: a
# material declares either a url or a command, so a flat record would carry an
# empty field, and read drops those when the separator is whitespace.
while IFS= read -r entry; do
  path=$(jq -r '.path' <<< "$entry")
  url=$(jq -r '.url // ""' <<< "$entry")
  tmp=$(mktemp)
  if [ -n "$url" ]; then
    echo "Downloading ${url} -> ${path}" >&2
    wget -q -T 30 -t 3 -O "$tmp" "$url"
  else
    mapfile -t argv < <(jq -r '.command[]' <<< "$entry")
    mapfile -t env_args < <(jq -r 'select(.version_key) | .version_key + "=" + .version' <<< "$entry")
    echo "Running ${argv[*]} -> ${path}" >&2
    # The loop's stdin is the list of materials, and the body inherits it. A
    # command that reads stdin would swallow the entries after its own, leaving
    # them silently unprocessed.
    env "${env_args[@]}" bash "${IMAGE}/${argv[0]}" "${argv[@]:1}" < /dev/null > "$tmp"
  fi
  if cmp -s "$tmp" "$path" 2>/dev/null; then
    echo "  unchanged" >&2
  else
    echo "  changed" >&2
    changed=true
  fi
  chmod 644 "$tmp"
  mkdir -p "$(dirname "$path")"
  mv "$tmp" "$path"
done < <(jq -c '.[]' <<< "$FILES")

echo "$changed"
