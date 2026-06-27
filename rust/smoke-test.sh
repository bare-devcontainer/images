#!/usr/bin/env bash
set -euo pipefail

rustup --version
rustup toolchain install stable
rustup component add rust-analyzer clippy rustfmt
rustc --version
cargo --version
rust-analyzer --version
cargo clippy --version
cargo fmt --version
