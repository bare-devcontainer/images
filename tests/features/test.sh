#!/usr/bin/env bash
# Verifies the Dev Container Features this configuration layers on. The image's
# own smoke test runs beforehand and covers the tooling the image ships.
set -euo pipefail

echo "=== Verifying common-utils ==="
zsh --version
# The feature provisions a user, and has to adopt the image's existing dev user
# rather than adding one of its own. 65534 is nobody.
[ "$(id -un)" = "dev" ] \
  || { echo "ERROR: expected user dev, got $(id -un)" >&2; exit 1; }
[ "$HOME" = "/home/dev" ] \
  || { echo "ERROR: expected home /home/dev, got ${HOME}" >&2; exit 1; }
mapfile -t users < <(awk -F: '$3 >= 1000 && $3 < 65534 { print $1 }' /etc/passwd | sort)
if [ "${#users[@]}" -ne 1 ] || [ "${users[0]}" != "dev" ]; then
  echo "ERROR: expected only dev, found: ${users[*]}" >&2
  exit 1
fi
[ -d "${HOME}/.oh-my-zsh" ] \
  || { echo "ERROR: oh-my-zsh is missing from ${HOME}" >&2; exit 1; }
# The feature rewrites the shell rc files.
bash -lc 'git --version'

echo "=== Verifying github-cli ==="
# The release .deb is selected by Debian architecture.
gh --version

echo "=== Verifying git-lfs ==="
git lfs version
# Registration happens in a postCreateCommand, after the image is built.
git config --get-regexp '^filter\.lfs\.' >/dev/null \
  || { echo "ERROR: git-lfs filters are not configured" >&2; exit 1; }

echo "=== Verifying node ==="
command -v node
node --version
npm --version
node -e 'console.log("Hello, world!")'
