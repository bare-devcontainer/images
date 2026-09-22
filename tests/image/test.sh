#!/usr/bin/env bash
# Verifies what referencing the image as a dev container adds to it: the
# devcontainer.metadata label it carries. What the image ships is covered by its
# own smoke-test.sh, so never repeat that here.
set -euo pipefail

echo "=== Verifying devcontainer.metadata ==="
# The configuration names no user, so the label is the only thing that can put
# this session in the dev account.
[ "$(id -un)" = "dev" ] \
  || { echo "ERROR: expected user dev, got $(id -un)" >&2; exit 1; }
[ "$HOME" = "/home/dev" ] \
  || { echo "ERROR: expected home /home/dev, got ${HOME}" >&2; exit 1; }
