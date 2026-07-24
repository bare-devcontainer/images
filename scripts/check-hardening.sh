#!/usr/bin/env bash
# check-hardening.sh — assert the runtime security constraints a hardened dev
# container is expected to run under. Executed inside the container by the
# devcontainer checks workflow, before the image smoke tests.
#
# Constraints verified:
#   - the process runs as a non-root user
#   - no-new-privileges is in effect (privilege escalation is blocked)
#   - all Linux capabilities have been dropped
#   - the root filesystem is read-only (only the workspace and mounted tmpfs
#     paths are writable)
set -euo pipefail

echo "=== Verifying non-root user ==="
[ "$(id -u)" -ne 0 ] || { echo "ERROR: running as root" >&2; exit 1; }

echo "=== Verifying no-new-privileges ==="
grep -q '^NoNewPrivs:[[:space:]]*1$' /proc/self/status \
  || { echo "ERROR: NoNewPrivs is not set" >&2; exit 1; }

echo "=== Verifying all capabilities are dropped ==="
# CapEff is the effective capability set as a hex bitmask; all zeros means no
# capabilities are held.
grep -Eq '^CapEff:[[:space:]]*0+$' /proc/self/status \
  || { echo "ERROR: effective capabilities are not empty" >&2; \
       grep '^CapEff:' /proc/self/status >&2; exit 1; }

echo "=== Verifying read-only root filesystem ==="
# Probe a path the current user owns, so a write failure proves the filesystem
# is read-only (EROFS) rather than merely lacking permission (EACCES).
if touch "${HOME}/.rw-probe" 2>/dev/null; then
  rm -f "${HOME}/.rw-probe"
  echo "ERROR: root filesystem is writable at ${HOME}" >&2
  exit 1
fi

echo "=== Verifying the workspace and /tmp remain writable ==="
workspace_probe="${PWD}/.hardening-rw-probe"
touch "$workspace_probe" || { echo "ERROR: workspace is not writable" >&2; exit 1; }
rm -f "$workspace_probe"
touch /tmp/.hardening-rw-probe || { echo "ERROR: /tmp is not writable" >&2; exit 1; }
rm -f /tmp/.hardening-rw-probe

echo "All hardening constraints satisfied."
