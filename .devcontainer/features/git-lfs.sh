#!/usr/bin/env bash
# git-lfs.sh — verify the git-lfs feature complements the image.
#
# None of the images ship Git LFS. The feature installs it from a third-party
# apt repository and registers it through a postCreateCommand, so this check
# covers both the build-time install and the runtime hook.
set -euo pipefail

echo "=== Verifying Git LFS added by the git-lfs feature ==="
git lfs version

echo "=== Verifying the feature's postCreateCommand registered Git LFS ==="
# The feature runs `git lfs install` after the container starts, which writes
# the lfs filter into the user's git configuration.
git config --get-regexp '^filter\.lfs\.' >/dev/null \
  || { echo "ERROR: git-lfs filters are not configured" >&2; exit 1; }
