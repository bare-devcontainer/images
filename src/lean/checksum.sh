#!/usr/bin/env bash
# checksum.sh — print the sha256 line for an elan release tarball, after
# confirming it matches the digest GitHub recorded for the release asset.
#
# elan publishes neither a checksum, a signature, nor build provenance for its
# release tarballs, so the digest is derived here and committed as trust
# material, reviewed like any other change, and is what the image build
# verifies against, the way every other image here verifies a committed
# checksum. GitHub records each release asset's digest when it is uploaded;
# a tarball that differs from it was not served as uploaded.
#
# Run by scripts/update-material.sh from the materials declared in
# build.yaml, with ELAN_VERSION taken from the pinned build args. Needs `gh`
# authenticated for the read of a public release; GitHub-hosted runners
# provide it.
#
# Usage:
#   ELAN_VERSION=<version> checksum.sh <amd64|arm64>
set -euo pipefail

ARCH="${1:?Usage: ELAN_VERSION=<version> checksum.sh <amd64|arm64>}"
: "${ELAN_VERSION:?ELAN_VERSION must be set}"

case "$ARCH" in
  amd64) ELAN_ARCH="x86_64" ;;
  arm64) ELAN_ARCH="aarch64" ;;
  *) echo "Unsupported architecture: ${ARCH}" >&2; exit 1 ;;
esac

TARBALL="elan-${ELAN_ARCH}-unknown-linux-gnu.tar.gz"
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

wget -q -T 30 -t 3 -P "$TMPDIR" \
  "https://github.com/leanprover/elan/releases/download/v${ELAN_VERSION}/${TARBALL}"

RECORDED=$(gh api "repos/leanprover/elan/releases/tags/v${ELAN_VERSION}" \
  --jq ".assets[] | select(.name == \"${TARBALL}\") | .digest")
: "${RECORDED:?no digest recorded for ${TARBALL} in elan v${ELAN_VERSION}}"

LINE=$(env --chdir="$TMPDIR" sha256sum "$TARBALL")
if [ "sha256:${LINE%% *}" != "$RECORDED" ]; then
  echo "${TARBALL}: sha256:${LINE%% *} does not match the recorded ${RECORDED}" >&2
  exit 1
fi

echo "$LINE"
