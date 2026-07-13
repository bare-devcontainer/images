#!/usr/bin/env bash
# update-readme.sh — regenerate the Tags table in image READMEs from build.yaml
#
# Usage:
#   update-readme.sh [image...]
#
# With no arguments, every directory containing a build.yaml is updated.
# The table is rendered between the <!-- tags:begin --> and <!-- tags:end -->
# markers in <image>/README.md; content outside the markers is preserved.
# Fails if a README is missing the markers.
set -euo pipefail

BEGIN_MARK='<!-- tags:begin -->'
END_MARK='<!-- tags:end -->'

generate_block() {
  local file="$1/build.yaml"
  echo '| Tags | Debian variant |'
  echo '|------|----------------|'
  # shellcheck disable=SC2016  # backticks are literal Markdown code spans
  yq -r '.variants[] | "| " + (.tags | map("`" + . + "`") | join(", ")) + " | " + (.debian_variant // .variant) + " |"' \
    "$file"
  echo ''
  local primary
  primary=$(yq -r '.variants[0].tags[0]' "$file")
  echo "Tags are also published with a date suffix on each build (e.g., \`${primary}-<YYYYMMDD>\`)."
}

update_readme() {
  local dir="$1"
  local readme="${dir}/README.md"
  if ! grep -qxF "$BEGIN_MARK" "$readme" || ! grep -qxF "$END_MARK" "$readme"; then
    echo "error: ${readme} is missing ${BEGIN_MARK} / ${END_MARK} markers" >&2
    exit 1
  fi
  local tmp
  tmp=$(mktemp)
  # The block is passed through the environment because awk -v mangles
  # backslash escapes in values.
  BLOCK="$(generate_block "$dir")" awk -v begin="$BEGIN_MARK" -v end="$END_MARK" '
    $0 == begin { print; print ENVIRON["BLOCK"]; inside=1; next }
    $0 == end   { inside=0 }
    !inside     { print }
  ' "$readme" > "$tmp"
  mv "$tmp" "$readme"
}

if [ "$#" -gt 0 ]; then
  IMAGES=("$@")
else
  mapfile -t IMAGES < <(find . -maxdepth 2 -name build.yaml \
    ! -path './.devcontainer/*' \
    -printf '%h\n' | sed 's|^\./||' | sort)
fi

for IMG in "${IMAGES[@]}"; do
  update_readme "$IMG"
done
