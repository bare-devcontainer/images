#!/usr/bin/env bash
set -euo pipefail

echo "=== Verifying tool installations ==="
echo "elan: $(elan --version)"
ELAN_VERSION_BEFORE="$(elan --version)"

echo "=== Verifying toolchain installation ==="
elan toolchain install stable
elan default stable
test "$(elan --version)" = "${ELAN_VERSION_BEFORE}"
lean --version
lake --version

echo "=== Verifying program execution ==="
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

cd "$TMPDIR"
lake new smoketest
cd smoketest
test -f lean-toolchain
lake build
lake exe smoketest
