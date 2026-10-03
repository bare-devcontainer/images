#!/usr/bin/env bash
set -euo pipefail

echo "=== Verifying devcontainer.metadata ==="
[ "$(id -un)" = "dev" ] \
  || { echo "ERROR: expected user dev, got $(id -un)" >&2; exit 1; }
[ "$HOME" = "/home/dev" ] \
  || { echo "ERROR: expected home /home/dev, got ${HOME}" >&2; exit 1; }
[ "${HISTFILE-}" = "/home/dev/.local/state/bash/history" ] \
  || { echo "ERROR: expected HISTFILE /home/dev/.local/state/bash/history, got ${HISTFILE-<unset>}" >&2; exit 1; }

git --version
cc --version
make --version

echo "=== Verifying the shell history directory is writable ==="
[ -w "${HISTFILE%/*}" ]

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
