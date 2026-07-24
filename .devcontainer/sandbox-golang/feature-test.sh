#!/usr/bin/env bash
# feature-test.sh — verify the Dev Container Features layered onto this sandbox
# are installed and runnable. Run by the devcontainer checks workflow after the
# image smoke test.
set -euo pipefail

echo "=== Verifying common-utils feature ==="
zsh --version
