#!/usr/bin/env bash
set -euo pipefail

echo "=== Verifying tool installations ==="
echo "bun: $(bun --version)"
echo "bunx: $(bunx --version)"

echo "=== Verifying program execution ==="
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

cat > "$TMPDIR/index.ts" <<'EOF'
const message: string = "Hello, world!";
console.log(message);
EOF

cd "$TMPDIR"
bun run index.ts

echo "=== Verifying bunx ==="
# Exercise bunx against a package authored on the fly (no npm registry
# packages, to avoid supply chain risk in this smoke test).
mkdir -p "$TMPDIR/local-cli" "$TMPDIR/project"

cat > "$TMPDIR/local-cli/package.json" <<'EOF'
{
  "name": "local-cli",
  "version": "1.0.0",
  "bin": { "local-cli": "./cli.js" }
}
EOF
cat > "$TMPDIR/local-cli/cli.js" <<'EOF'
#!/usr/bin/env bun
console.log("Hello from bunx");
EOF

cd "$TMPDIR/project"
bun init -y >/dev/null
bun add "file:../local-cli"
bunx local-cli
