#!/usr/bin/env bash
# github-cli.sh — verify the github-cli feature complements the image.
#
# None of the images ship the GitHub CLI, so the feature is the supported way to
# add it. By default the feature installs a release .deb selected by the Debian
# architecture, which makes this check meaningful on both amd64 and arm64.
set -euo pipefail

echo "=== Verifying the GitHub CLI added by the github-cli feature ==="
gh --version

echo "=== Verifying program execution ==="
gh help >/dev/null
