#!/usr/bin/env bash
# check-container-invariants.sh — assert the properties every dev container in
# this repository must hold, with or without Dev Container Features layered on
# top. Run inside the container by the devcontainer and feature checks, ahead of
# the image smoke tests.
#
# Identity invariants:
#   - the container runs as the image's unprivileged dev user
#   - no feature has provisioned a second unprivileged user
# Hardening invariants:
#   - no-new-privileges is in effect
#   - all Linux capabilities have been dropped
set -euo pipefail

EXPECTED_USER="dev"

echo "=== Verifying the container runs as ${EXPECTED_USER} ==="
# The uid itself is not asserted: the Dev Container CLI remaps the container
# user to the host user's id, so the value depends on where the container runs.
[ "$(id -u)" -ne 0 ] || { echo "ERROR: running as root" >&2; exit 1; }
[ "$(id -un)" = "$EXPECTED_USER" ] \
  || { echo "ERROR: expected user ${EXPECTED_USER}, got $(id -un)" >&2; exit 1; }
[ "$HOME" = "/home/${EXPECTED_USER}" ] \
  || { echo "ERROR: expected home /home/${EXPECTED_USER}, got ${HOME}" >&2; exit 1; }

echo "=== Verifying no additional unprivileged user was provisioned ==="
# Features that set up a user (common-utils) must adopt the image's existing
# user instead of adding one of their own. 65534 is nobody.
mapfile -t users < <(awk -F: '$3 >= 1000 && $3 < 65534 { print $1 }' /etc/passwd | sort)
if [ "${#users[@]}" -ne 1 ] || [ "${users[0]}" != "$EXPECTED_USER" ]; then
  echo "ERROR: expected only ${EXPECTED_USER}, found: ${users[*]}" >&2
  exit 1
fi

echo "=== Verifying no-new-privileges ==="
grep -q '^NoNewPrivs:[[:space:]]*1$' /proc/self/status \
  || { echo "ERROR: NoNewPrivs is not set" >&2; exit 1; }

echo "=== Verifying all capabilities are dropped ==="
# CapEff is the effective capability set as a hex bitmask; all zeros means no
# capabilities are held.
grep -Eq '^CapEff:[[:space:]]*0+$' /proc/self/status \
  || { echo "ERROR: effective capabilities are not empty" >&2; \
       grep '^CapEff:' /proc/self/status >&2; exit 1; }

echo "All container invariants satisfied."
