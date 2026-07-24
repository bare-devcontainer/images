#!/usr/bin/env bash
# check-hardening.sh — assert the runtime security constraints a hardened dev
# container is expected to run under. Executed inside the container by the
# devcontainer checks workflow, before the image smoke tests.
#
# Constraints verified:
#   - the process runs as a non-root user
#   - no-new-privileges is in effect (privilege escalation is blocked)
#   - all Linux capabilities have been dropped
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

echo "All hardening constraints satisfied."
