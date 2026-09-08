#!/usr/bin/env bash
set -euo pipefail

echo "=== Verifying tool installations ==="
java -version
javac -version
jshell --version
java -version 2>&1 | grep -q "Temurin"

echo "=== Verifying JAVA_HOME ==="
[ -n "${JAVA_HOME:-}" ]
[ "$(readlink -f "$(command -v java)")" = "${JAVA_HOME}/bin/java" ]
[ "$(readlink -f "$(command -v javac)")" = "${JAVA_HOME}/bin/javac" ]

echo "=== Verifying compile, package and run ==="
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

cat > "$TMPDIR/Hello.java" <<'EOF'
public class Hello {
    public static void main(String[] args) {
        System.out.println("Hello, " + String.join(" ", args) + "!");
    }
}
EOF

cd "$TMPDIR"
javac Hello.java
java Hello world
jar --create --file hello.jar --main-class Hello Hello.class
java -jar hello.jar jar
java Hello.java source

echo "=== Verifying the trust store ==="
keytool -list -cacerts -storepass changeit | grep -E "Your keystore contains [1-9][0-9]* entries"
