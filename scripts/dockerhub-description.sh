#!/usr/bin/env bash
# dockerhub-description.sh — set the Docker Hub description and overview of every image
#
# Usage:
#   dockerhub-description.sh check <source_prefix> <target_prefix> <repository_url>
#   dockerhub-description.sh publish <source_prefix> <target_prefix> <repository_url>
#
# Must be run from the repository root. <target_prefix> names the Docker Hub
# namespace to write to; it and the other two arguments are passed on to
# dockerhub-overview.sh.
#
# Each repository is given the description its build.yaml carries — the same
# string the image carries as its org.opencontainers.image.description label —
# and, as its overview, dockerhub-overview.sh's rendering of the image README.
#
# Modes:
#   check
#       Render every overview and hold it against the limits of the API,
#       without contacting Docker Hub. A table of what would be published is
#       written to stdout. Needs no credentials.
#
#   publish
#       Do the same, then write both fields to Docker Hub.
#
# Credentials are read from the environment in publish mode: DOCKERHUB_USERNAME
# and DOCKERHUB_PAT, a personal access token with write access to the
# namespace. They are exchanged for a short-lived token, which reaches curl in
# a configuration file rather than on the command line so that it stays out of
# the process list.
set -euo pipefail

MODE="${1:?Usage: dockerhub-description.sh <check|publish> <source_prefix> <target_prefix> <repository_url>}"
SOURCE_PREFIX="${2:?Missing source_prefix}"
TARGET_PREFIX="${3:?Missing target_prefix}"
REPOSITORY_URL="${4:?Missing repository_url}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NAMESPACE="${TARGET_PREFIX#*/}"
API="https://hub.docker.com/v2"

# https://docs.docker.com/reference/api/hub/latest/ gives description this
# maximum; dockerhub-overview.sh holds the overview to the one on
# full_description.
MAX_DESCRIPTION=100

fail() {
  echo "error: $*" >&2
  exit 1
}

case "$MODE" in
  check | publish) ;;
  *)
    echo "Unknown mode: $MODE" >&2
    echo "Available modes: check, publish" >&2
    exit 1
    ;;
esac

IMAGE_LIST=$(bash "${SCRIPT_DIR}/build-config.sh" images | jq -r '.[]')
[ -n "$IMAGE_LIST" ] || fail "no image directory contains a build.yaml"
mapfile -t IMAGES <<< "$IMAGE_LIST"

# Every image is rendered and held against the limits before the first
# repository is written, so an image the rendering stops at leaves Docker Hub
# as it was rather than carrying the update for the images ahead of it.
declare -A DESCRIPTIONS OVERVIEWS

for IMAGE in "${IMAGES[@]}"; do
  DESCRIPTION=$(bash "${SCRIPT_DIR}/build-config.sh" description "$IMAGE")
  [ -n "$DESCRIPTION" ] || fail "${IMAGE}/build.yaml defines no description"
  [ "${#DESCRIPTION}" -le "$MAX_DESCRIPTION" ] ||
    fail "${IMAGE}/build.yaml: the description is ${#DESCRIPTION} characters, past the ${MAX_DESCRIPTION} character limit"

  DESCRIPTIONS["$IMAGE"]="$DESCRIPTION"
  OVERVIEWS["$IMAGE"]=$(bash "${SCRIPT_DIR}/dockerhub-overview.sh" \
    "$IMAGE" "$SOURCE_PREFIX" "$TARGET_PREFIX" "$REPOSITORY_URL")
done

if [ "$MODE" = "publish" ]; then
  : "${DOCKERHUB_USERNAME:?Missing DOCKERHUB_USERNAME}"
  : "${DOCKERHUB_PAT:?Missing DOCKERHUB_PAT}"

  CURL_CONFIG=$(umask 077 && mktemp)
  trap 'rm -f "$CURL_CONFIG"' EXIT

  TOKEN=$(
    jq -n --arg u "$DOCKERHUB_USERNAME" --arg s "$DOCKERHUB_PAT" \
      '{identifier: $u, secret: $s}' |
      curl -fsS -X POST -H 'Content-Type: application/json' --data @- \
        "${API}/auth/token" |
      jq -r '.access_token // ""'
  )
  [ -n "$TOKEN" ] || fail "Docker Hub returned no access token"
  printf 'header = "Authorization: Bearer %s"\n' "$TOKEN" > "$CURL_CONFIG"
fi

printf '| Repository | Description | Overview |\n'
printf '|------------|-------------|----------|\n'

# A row is written as each repository is done, so a run the API stops partway
# through still names the repositories it reached.
for IMAGE in "${IMAGES[@]}"; do
  if [ "$MODE" = "publish" ]; then
    jq -n --arg d "${DESCRIPTIONS["$IMAGE"]}" --arg o "${OVERVIEWS["$IMAGE"]}" \
      '{description: $d, full_description: $o}' |
      curl -fsS -K "$CURL_CONFIG" -X PATCH -H 'Content-Type: application/json' \
        --data @- "${API}/repositories/${NAMESPACE}/${IMAGE}/" > /dev/null
  fi

  # shellcheck disable=SC2016  # backticks are literal Markdown code spans
  printf '| `%s/%s` | %s characters | %s bytes |\n' \
    "$NAMESPACE" "$IMAGE" "${#DESCRIPTIONS["$IMAGE"]}" \
    "$(printf '%s\n' "${OVERVIEWS["$IMAGE"]}" | wc -c)"
done
