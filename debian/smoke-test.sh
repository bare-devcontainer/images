#!/usr/bin/env bash
set -euo pipefail

[ "$(id -u)" -ne 0 ] || { echo "ERROR: running as root" >&2; exit 1; }

git --version
cc --version
make --version

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
