#!/usr/bin/env bash
# verify-image.sh — confirm the image verification steps succeed for a published image.
#
# Usage:
#   verify-image.sh <image_ref> <owner>
#
#   image_ref  Tagged image reference, e.g. ghcr.io/bare-devcontainer/debian:trixie
#   owner      Expected GitHub org that the artifact attestation must be signed by
set -euo pipefail

IMAGE_REF="${1:?Usage: verify-image.sh <image_ref> <owner>}"
OWNER="${2:?Missing owner}"

DIGEST=$(docker buildx imagetools inspect "$IMAGE_REF" --format '{{json .Manifest}}' | jq -r '.digest')
if [ -z "$DIGEST" ] || [ "$DIGEST" = "null" ]; then
  echo "⚠️ Failed to resolve digest for ${IMAGE_REF}" >&2
  exit 1
fi
DIGEST_REF="${IMAGE_REF}@${DIGEST}"
echo "Resolved ${IMAGE_REF} -> ${DIGEST_REF}"

# Verifying GitHub artifact attestation
gh attestation verify "oci://${DIGEST_REF}" --owner "$OWNER"
echo "✅ Verified GitHub artifact attestation for ${DIGEST_REF}"

# Verifying build provenance
PROVENANCE=$(docker buildx imagetools inspect "$DIGEST_REF" --format '{{json .Provenance}}')
if [ -z "$PROVENANCE" ] || [ "$PROVENANCE" = "null" ]; then
  echo "⚠️ No build provenance found for ${DIGEST_REF}" >&2
  exit 1
fi
echo "$PROVENANCE" | jq -e 'if type == "object" then (to_entries | length > 0) else false end' > /dev/null
echo "✅ Build provenance present for ${DIGEST_REF}"

# Smoke-testing build provenance contents
BUILDER_ID=$(echo "$PROVENANCE" | jq -r '[.. | objects | select(has("builder")) | .builder.id] | first // empty')
if [ -z "$BUILDER_ID" ]; then
  echo "⚠️ Provenance has no builder id for ${DIGEST_REF}" >&2
  exit 1
fi
if [[ "$BUILDER_ID" != "https://github.com/${OWNER}/"* ]]; then
  echo "⚠️ Provenance builder id '${BUILDER_ID}' does not belong to ${OWNER}" >&2
  exit 1
fi
echo "✅ Provenance builder id verified: ${BUILDER_ID}"

# Verifying SBOM
SBOM=$(docker buildx imagetools inspect "$DIGEST_REF" --format '{{json .SBOM}}')
if [ -z "$SBOM" ] || [ "$SBOM" = "null" ]; then
  echo "⚠️ No SBOM found for ${DIGEST_REF}" >&2
  exit 1
fi
echo "$SBOM" | jq -e 'if type == "object" then (to_entries | length > 0) else false end' > /dev/null
echo "✅ SBOM present for ${DIGEST_REF}"

# Smoke-testing SBOM contents
PACKAGE_COUNT=$(echo "$SBOM" | jq '[.. | objects | select(has("packages")) | .packages | length] | first // 0')
if [ "$PACKAGE_COUNT" -lt 1 ]; then
  echo "⚠️ SBOM lists no packages for ${DIGEST_REF}" >&2
  exit 1
fi
echo "✅ SBOM lists ${PACKAGE_COUNT} packages for ${DIGEST_REF}"
