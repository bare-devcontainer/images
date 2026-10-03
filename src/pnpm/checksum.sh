#!/usr/bin/env bash
# checksum.sh — print the sha256 line for a pnpm release archive, after
# confirming the archive's build provenance.
#
# pnpm publishes no checksum and no detached signature, so this repository
# derives its own trust anchor: the archive is accepted only once
# `gh attestation verify` has bound its digest to pnpm's release workflow at
# the tag being pinned. The digest is then committed as trust material and is
# what the image build verifies against, the way every other image here
# verifies a committed checksum.
#
# Run by scripts/update-material.sh from the materials declared in
# build.yaml, with PNPM_VERSION taken from the pinned build args. Needs `gh`
# authenticated for the read of a public attestation; GitHub-hosted runners
# provide both.
#
# Usage:
#   PNPM_VERSION=<version> checksum.sh <amd64|arm64>
set -euo pipefail

ARCH="${1:?Usage: PNPM_VERSION=<version> checksum.sh <amd64|arm64>}"
: "${PNPM_VERSION:?PNPM_VERSION must be set}"

case "$ARCH" in
  amd64) PNPM_ARCH="x64" ;;
  arm64) PNPM_ARCH="arm64" ;;
  *) echo "Unsupported architecture: ${ARCH}" >&2; exit 1 ;;
esac

TARBALL="pnpm-linux-${PNPM_ARCH}.tar.gz"
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

wget -q -T 30 -t 3 -P "$TMPDIR" \
  "https://github.com/pnpm/pnpm/releases/download/v${PNPM_VERSION}/${TARBALL}"

# --deny-self-hosted-runners is deliberately absent: pnpm builds its Linux
# release binaries on Blacksmith runners, so the signing certificate reports a
# self-hosted runner environment and the flag would reject every release.
gh attestation verify "${TMPDIR}/${TARBALL}" \
  --repo pnpm/pnpm \
  --signer-workflow "pnpm/pnpm/.github/workflows/release.yml" \
  --source-ref "refs/tags/v${PNPM_VERSION}" >&2

env --chdir="$TMPDIR" sha256sum "$TARBALL"
