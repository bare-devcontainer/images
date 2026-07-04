#!/usr/bin/env bash
set -euo pipefail

echo "=== Verifying tool installations ==="
echo "uv: $(uv --version)"
echo "uvx: $(uvx --version)"

echo "=== Verifying on-demand Python installation ==="
uv python install 3.13
uv run --python 3.13 python3 --version
uv run --python 3.13 python3 -c "print('hello from managed python')"

echo "=== Verifying project workflow ==="
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

cd "$TMPDIR"
uv init --python 3.13 smoketest
cd smoketest
uv add six
uv run python -c "import six; print('six version:', six.__version__)"
