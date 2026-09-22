#!/usr/bin/env bash
# devcontainer-env.sh — resolve the environment a Dev Container client applies
# to the processes it starts, from the remoteEnv of an image's
# devcontainer.metadata label.
#
# Usage:
#   devcontainer-env.sh <image_ref>
#
#   image_ref  Tagged reference of an image the local Docker daemon holds
#
# One NAME=value per line, which is also the format docker run --env-file reads.
set -euo pipefail

IMAGE_REF="${1:?Usage: devcontainer-env.sh <image_ref>}"

IMAGE_ENV=$(docker image inspect --format '{{json .Config.Env}}' "$IMAGE_REF")
METADATA=$(docker image inspect --format '{{index .Config.Labels "devcontainer.metadata"}}' \
  "$IMAGE_REF")

# A client merges the label's entries in order, the last value of a name
# winning, and resolves ${containerEnv:NAME} against the image's own environment.
jq -rn --argjson metadata "$METADATA" --argjson image_env "$IMAGE_ENV" '
  (($image_env // []) | map(index("=") as $i | {key: .[:$i], value: .[$i + 1:]}) | from_entries) as $env
  | ([$metadata[].remoteEnv // {}] | add // {})
  | to_entries[]
  | "\(.key)=\(.value | gsub("\\$\\{containerEnv:(?<name>[A-Za-z_][A-Za-z0-9_]*)\\}"; $env[.name] // ""))"'
