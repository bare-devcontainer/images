#!/usr/bin/env bash
set -euo pipefail

echo "=== Verifying tool installations ==="
echo "go: $(go version)"
echo "gopls version $(gopls version)"

echo "=== Verifying pure-Go build ==="
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

echo "=== Verifying cgo build ==="
[ "$(go env CGO_ENABLED)" = "1" ]

CGO_TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR" "$CGO_TMPDIR"' EXIT

cat > "$CGO_TMPDIR/main.go" <<'EOF'
package main

/*
#include <string.h>
#include <stdlib.h>
*/
import "C"
import (
	"fmt"
	"unsafe"
)

func main() {
	s := C.CString("hello, cgo")
	defer C.free(unsafe.Pointer(s))
	fmt.Println("length:", C.strlen(s))
}
EOF

cd "$CGO_TMPDIR"
go mod init cgosmoketest
go build ./...
go run .

