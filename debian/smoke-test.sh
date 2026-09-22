#!/usr/bin/env bash
set -euo pipefail

[ "$(id -u)" -ne 0 ] || { echo "ERROR: running as root" >&2; exit 1; }

git --version
cc --version
make --version

echo "=== Verifying the shell history directory is writable ==="
[ -w /home/dev/.local/state/bash ]
# HISTFILE is declared through remoteEnv, so a Dev Container client sets it and
# a container started any other way leaves it unset.
[ "${HISTFILE:-/home/dev/.local/state/bash/history}" = /home/dev/.local/state/bash/history ]

echo "=== Verifying the C toolchain compiles and links ==="
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

cat > "$TMPDIR/hello.c" <<'EOF'
#include <stdio.h>

int main(void) {
    puts("Hello, world!");
    return 0;
}
EOF

cc -o "$TMPDIR/hello" "$TMPDIR/hello.c"
"$TMPDIR/hello"
