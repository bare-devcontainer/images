#!/usr/bin/env bash
set -euo pipefail

echo "=== Verifying tool installations ==="
echo "go: $(go version)"
echo "gopls: $(gopls version)"

echo "=== Verifying program execution ==="
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

cat > "$TMPDIR/main.go" <<'EOF'
package main

import (
	"fmt"
	"golang.org/x/text/cases"
	"golang.org/x/text/language"
)

func main() {
	c := cases.Title(language.English)
	fmt.Println(c.String("hello, world"))
}
EOF

cd "$TMPDIR"
go mod init smoketest
go mod tidy
go mod download
go build ./...
go run .

