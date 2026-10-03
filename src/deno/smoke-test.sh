#!/usr/bin/env bash
set -euo pipefail

echo "=== Verifying tool installations ==="
echo "deno: $(deno --version)"

echo "=== Verifying shell completions ==="
test -s /usr/share/bash-completion/completions/deno

echo "=== Verifying program execution ==="
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

cat > "$TMPDIR/index.ts" <<'EOF'
const message: string = "Hello, world!";
console.log(message);
EOF

cd "$TMPDIR"
deno run index.ts

echo "=== Verifying deno eval ==="
# shellcheck disable=SC2016  # the template literal is evaluated by deno, not bash
deno eval 'console.log(`1 + 2 = ${1 + 2}`)'

echo "=== Verifying deno type checking ==="
# Exercise the built-in TypeScript type checker offline (no network or
# registry access).
deno check index.ts
