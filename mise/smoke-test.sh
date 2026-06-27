#!/usr/bin/env bash
set -euo pipefail

mise --version
mise exec python@3 -- python -c 'print("Hello, world!")'
