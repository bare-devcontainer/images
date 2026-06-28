#!/usr/bin/env bash
set -euo pipefail

echo "=== Verifying tool installations ==="
echo "rustup: $(rustup --version)"

echo "=== Verifying toolchain and component installation ==="
rustup toolchain install stable
rustup component add rust-analyzer clippy rustfmt
rustc --version
cargo --version
rust-analyzer --version
cargo clippy --version
cargo fmt --version

echo "=== Verifying program execution ==="
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

cd "$TMPDIR"
cargo new smoketest
cd smoketest
cargo build
cargo run
