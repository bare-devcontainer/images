#!/usr/bin/env bash
# checksum.sh — print the sha256 line for a uv release tarball, after
# confirming the tarball's build provenance.
#
# The tarball is accepted only once `gh attestation verify` has bound its
# digest to uv's release workflow at the commit the version's tag points to.
# The digest is then committed as trust material and is what the image build
# verifies against, the way every other image here verifies a committed
# checksum. The checksum uv publishes beside the tarball is written by the
# same workflow run, so it is not the material.
#
# Run by scripts/update-material.sh from the materials declared in
# build.yaml, with UV_VERSION taken from the pinned build args. Needs `gh`
# authenticated for the read of a public attestation, and `git` for the tag
# lookup; GitHub-hosted runners provide all three.
#
# Usage:
#   UV_VERSION=<version> checksum.sh <amd64|arm64>
set -euo pipefail

ARCH="${1:?Usage: UV_VERSION=<version> checksum.sh <amd64|arm64>}"
: "${UV_VERSION:?UV_VERSION must be set}"

case "$ARCH" in
  amd64) UV_ARCH="x86_64" ;;
  arm64) UV_ARCH="aarch64" ;;
  *) echo "Unsupported architecture: ${ARCH}" >&2; exit 1 ;;
esac

TARBALL="uv-${UV_ARCH}-unknown-linux-gnu.tar.gz"
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

wget -q -T 30 -t 3 -P "$TMPDIR" \
  "https://github.com/astral-sh/uv/releases/download/${UV_VERSION}/${TARBALL}"

# uv's release workflow is dispatched on main and creates the version's tag at
# the commit it ran on, so the signing certificate names refs/heads/main as
# the source ref and only its source digest ties the tarball to the version.
# For an annotated tag ls-remote lists the peeled commit after the tag object,
# so the last line holds the commit either way.
TAG_COMMIT=$(git ls-remote https://github.com/astral-sh/uv \
  "refs/tags/${UV_VERSION}" "refs/tags/${UV_VERSION}^{}" | tail -n 1 | cut -f 1)
: "${TAG_COMMIT:?no tag ${UV_VERSION} in astral-sh/uv}"

gh attestation verify "${TMPDIR}/${TARBALL}" \
  --repo astral-sh/uv \
  --signer-workflow "astral-sh/uv/.github/workflows/release.yml" \
  --source-digest "$TAG_COMMIT" \
  --deny-self-hosted-runners >&2

env --chdir="$TMPDIR" sha256sum "$TARBALL"
