#!/usr/bin/env bash
# test.sh — verify the Dev Container Features this configuration layers on.
#
# Each block covers one Feature: that it installed and runs, and where a Feature
# overlaps with what the image already provides, that the two compose. The
# image's own smoke test runs before this script and covers the tooling the
# image ships, so nothing here repeats it.
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
# oh-my-zsh is installed into the detected user's home by default.
[ -d "${HOME}/.oh-my-zsh" ] \
  || { echo "ERROR: oh-my-zsh is missing from ${HOME}" >&2; exit 1; }
# The feature rewrites the shell rc files, so a login shell has to still resolve
# the tooling the image provides.
bash -lc 'git --version'

echo "=== Verifying github-cli ==="
# Installed from a release .deb selected by Debian architecture, so this also
# shows the correct amd64/arm64 build was picked.
gh --version

echo "=== Verifying git-lfs ==="
git lfs version
# The feature registers Git LFS from a postCreateCommand, so this covers the
# runtime hook alongside the install.
git config --get-regexp '^filter\.lfs\.' >/dev/null \
  || { echo "ERROR: git-lfs filters are not configured" >&2; exit 1; }

echo "=== Verifying node ==="
# The feature installs Node.js through nvm and prepends its bin directory to
# PATH, supplying a runtime the image does not ship.
command -v node
node --version
npm --version
node -e 'console.log("Hello, world!")'
