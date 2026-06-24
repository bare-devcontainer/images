#!/usr/bin/env bash
set -euo pipefail

[ "$(id -u)" -ne 0 ] || { echo "ERROR: running as root" >&2; exit 1; }

git --version
