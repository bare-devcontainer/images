#!/usr/bin/env bash
set -euo pipefail

echo "=== Verifying tool installation ==="
terraform version
terraform-ls version

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
terraform init -input=false
terraform validate
terraform apply -auto-approve
terraform output hello
