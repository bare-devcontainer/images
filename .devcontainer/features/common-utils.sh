#!/usr/bin/env bash
# common-utils.sh — verify the common-utils feature complements the image.
#
# The feature adds general-purpose CLI tooling and shell configuration that the
# minimal images deliberately omit. Its riskiest behaviour for these images is
# user provisioning: it must adopt the image's existing uid 1000 user rather
# than creating one of its own. That is asserted by
# scripts/check-container-invariants.sh, which runs for every container.
set -euo pipefail

echo "=== Verifying the shell added by common-utils ==="
zsh --version

echo "=== Verifying the feature provisioned the existing dev user's home ==="
# oh-my-zsh is installed by default into the detected user's home, so its
# presence under $HOME shows the feature targeted the image's user.
[ -d "${HOME}/.oh-my-zsh" ] \
  || { echo "ERROR: oh-my-zsh is missing from ${HOME}" >&2; exit 1; }

echo "=== Verifying login shells still resolve the base tooling ==="
# The feature rewrites /etc/bash.bashrc and the user rc files; a login shell
# must still find the tools the image provides.
bash -lc 'git --version'
