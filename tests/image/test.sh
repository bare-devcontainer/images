#!/usr/bin/env bash
# Verifies what referencing the image as a dev container adds to it: the
# devcontainer.metadata label it carries.
set -euo pipefail

echo "=== Verifying devcontainer.metadata ==="
[ "$(id -un)" = "dev" ] \
  || { echo "ERROR: expected user dev, got $(id -un)" >&2; exit 1; }
[ "$HOME" = "/home/dev" ] \
  || { echo "ERROR: expected home /home/dev, got ${HOME}" >&2; exit 1; }

# The base image declares HISTFILE through remoteEnv, so every image carries it.
[ "${HISTFILE-}" = "/home/dev/.local/state/bash/history" ] \
  || { echo "ERROR: expected HISTFILE /home/dev/.local/state/bash/history, got ${HISTFILE-<unset>}" >&2; exit 1; }
# Where an image extends PATH through remoteEnv, the client resolves
# ${containerEnv:PATH} against the image's own; nothing else does.
case ":${PATH}:" in
  *:/usr/bin:*) ;;
  *) echo "ERROR: PATH does not carry the image's own: ${PATH}" >&2; exit 1 ;;
esac
