#!/usr/bin/env bash
set -euo pipefail

echo "=== Verifying tool installations ==="
echo "pnpm: $(pnpm --version)"

echo "=== Verifying no runtime or package manager is baked in ==="
# The image ships pnpm alone; the Node.js version comes from the project.
for cmd in node npm npx corepack; do
    if command -v "$cmd" >/dev/null 2>&1; then
        echo "$cmd should not be installed" >&2
        exit 1
    fi
done

echo "=== Verifying shell completions ==="
test -s /usr/share/bash-completion/completions/pnpm

echo "=== Verifying pnpm home ==="
echo "PNPM_HOME: ${PNPM_HOME:-unset}"
test -w "${PNPM_HOME:?PNPM_HOME must be set}"
# Global installs go to $PNPM_HOME/bin, which pnpm requires to be on PATH.
case ":${PATH}:" in
    *":${PNPM_HOME}/bin:"*) ;;
    *) echo "${PNPM_HOME}/bin is not on PATH" >&2; exit 1 ;;
esac
[[ "$(pnpm store path)" == "${PNPM_HOME}/"* ]]

echo "=== Verifying global runtime installation ==="
# Any supported major works here; what matters is that it differs from the one
# the project below pins, so the two can be told apart.
pnpm runtime set node 22 -g
node --version
[[ "$(node --version)" == v22.* ]]

echo "=== Verifying project-pinned runtime ==="
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

# Exercise the project workflow against a package authored on the fly (no npm
# registry packages, to avoid supply chain risk in this smoke test).
mkdir -p "$TMPDIR/local-cli" "$TMPDIR/project"

cat > "$TMPDIR/local-cli/package.json" <<'EOF'
{
  "name": "local-cli",
  "version": "1.0.0",
  "bin": { "local-cli": "./cli.js" }
}
EOF
cat > "$TMPDIR/local-cli/cli.js" <<'EOF'
#!/usr/bin/env node
console.log("Hello from pnpm exec");
EOF
chmod +x "$TMPDIR/local-cli/cli.js"

# A project asking for a different major than the global one; pnpm downloads it
# on first use and its shims dispatch to it inside the project.
cat > "$TMPDIR/project/package.json" <<'EOF'
{
  "name": "smoketest",
  "version": "1.0.0",
  "private": true,
  "devEngines": {
    "runtime": { "name": "node", "version": "^24.0.0", "onFail": "download" }
  }
}
EOF

cd "$TMPDIR/project"
pnpm add ../local-cli
[ "$(pnpm exec local-cli)" = "Hello from pnpm exec" ]
[[ "$(pnpm exec node --version)" == v24.* ]]
[[ "$(node --version)" == v24.* ]]

echo "=== Verifying the global runtime outside the project ==="
cd "$TMPDIR"
[[ "$(node --version)" == v22.* ]]
