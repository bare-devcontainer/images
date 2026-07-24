#!/usr/bin/env bash
# feature-test.sh — verify the Dev Container Features layered onto this sandbox
# are installed and runnable. Run by the devcontainer checks workflow after the
# image smoke test.
set -euo pipefail

echo "=== Verifying node feature ==="
# The node feature installs its own Node.js, distinct from mise's runtimes. Its
# binaries must resolve on PATH ahead of mise's shims (which carry no node).
command -v node
node --version
npm --version
