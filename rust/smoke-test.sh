#!/usr/bin/env bash
set -euo pipefail

rustup --version
rustup toolchain install stable
rustc --version
cargo --version
