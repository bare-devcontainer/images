#!/usr/bin/env bash
set -euo pipefail

echo "=== Verifying tool installations ==="
echo "zig: $(zig version)"
echo "zls: $(zls --version)"

echo "=== Verifying shell completions ==="
test -s /usr/share/bash-completion/completions/zig

echo "=== Verifying program execution ==="
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

cd "$TMPDIR"
zig init
zig build run
