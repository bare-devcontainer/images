#!/usr/bin/env bash
set -euo pipefail

echo "=== Verifying tool installation ==="
tofu version
tofu-ls version

echo "=== Verifying init/plan/apply against a provider-less configuration ==="
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

cat > "$TMPDIR/main.tf" <<'EOF'
terraform {
}

output "hello" {
  value = "Hello, world!"
}
EOF

cd "$TMPDIR"
tofu init -input=false
tofu validate
tofu apply -auto-approve
tofu output hello
