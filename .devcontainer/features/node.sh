#!/usr/bin/env bash
# node.sh — verify the node feature complements the image.
#
# The feature installs Node.js through nvm and prepends its bin directory to
# PATH via containerEnv, supplying a Node.js runtime to images that ship none.
set -euo pipefail

echo "=== Verifying Node.js added by the node feature ==="
command -v node
node --version
npm --version

echo "=== Verifying program execution ==="
node -e 'console.log("Hello, world!")'
