#!/usr/bin/env bash
set -euo pipefail

echo "=== Verifying tool installations ==="
echo "node: $(node --version)"
echo "corepack: $(corepack --version)"

echo "=== Verifying npm/npx are not installed ==="
if command -v npm >/dev/null 2>&1 || command -v npx >/dev/null 2>&1; then
    echo "npm/npx should not be installed" >&2
    exit 1
fi

echo "=== Verifying program execution ==="
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

cat > "$TMPDIR/index.js" <<'EOF'
console.log("Hello, world!");
EOF

node "$TMPDIR/index.js"
