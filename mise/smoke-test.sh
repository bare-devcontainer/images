#!/usr/bin/env bash
set -euo pipefail

echo "=== Verifying tool installations ==="
echo "mise: $(mise --version)"

echo "=== Verifying program execution ==="
mise exec python@3 -- python -c 'print("Hello, world!")'
