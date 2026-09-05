#!/usr/bin/env bash
# update-zig-master.sh — refresh the Zig master build pinned in zig/build.yaml
#
# Usage:
#   update-zig-master.sh
#
# Resolves the master build ziglang.org currently publishes and the ZLS build
# that matches it, then writes both into the master variant's build args in the
# working tree. Prints "true" or "false" to stdout depending on whether
# anything changed; progress goes to stderr. Performs no git or GitHub
# operations, like update-material.sh.
#
# Renovate cannot keep these two versions current the way it keeps every other
# pinned version here: master builds carry no tag, and the ZLS build that works
# with a given master is served by an API rather than published as a release.
set -euo pipefail

FILE="zig/build.yaml"
VARIANT="master-trixie"
# The image is published for these two targets, so a build missing either one
# has to fail here rather than in the release build that consumes the pin.
TARGETS=(x86_64-linux aarch64-linux)

fetch() {
  wget -q -T 30 -t 3 -O - "$1"
}

VARIANT="$VARIANT" yq -e '.variants[] | select(.variant == strenv(VARIANT))' "$FILE" > /dev/null \
  || { echo "error: ${FILE} has no ${VARIANT} variant" >&2; exit 1; }

echo "Resolving the published Zig master build" >&2
ZIG_INDEX=$(fetch https://ziglang.org/download/index.json)
ZIG_VERSION=$(jq -r '.master.version // ""' <<< "$ZIG_INDEX")
[ -n "$ZIG_VERSION" ] || { echo "error: ziglang.org index.json names no master version" >&2; exit 1; }

# The ZLS release worker answers 200 with an error body when it has no build
# for the requested Zig version, so the payload decides, not the status code.
ZLS_META=$(fetch "https://releases.zigtools.org/v1/zls/select-version?zig_version=${ZIG_VERSION//+/%2B}&compatibility=only-runtime")
if jq -e 'has("code") or has("error")' > /dev/null <<< "$ZLS_META"; then
  echo "error: no ZLS build for Zig ${ZIG_VERSION}: $(jq -r '.message // .error' <<< "$ZLS_META")" >&2
  exit 1
fi
ZLS_VERSION=$(jq -r '.version // ""' <<< "$ZLS_META")
[ -n "$ZLS_VERSION" ] || { echo "error: the ZLS release worker named no version" >&2; exit 1; }

# Compared by name, not just presence: zig/Dockerfile builds the file name from
# the version, and upstream has renamed these artifacts before, so a rename has
# to fail here rather than as a 404 in the build.
for TARGET in "${TARGETS[@]}"; do
  ZIG_TARBALL=$(jq -r --arg t "$TARGET" '.master[$t].tarball // ""' <<< "$ZIG_INDEX")
  [ "${ZIG_TARBALL##*/}" = "zig-${TARGET}-${ZIG_VERSION}.tar.xz" ] \
    || { echo "error: Zig ${ZIG_VERSION} publishes '${ZIG_TARBALL##*/}' for ${TARGET}, not zig-${TARGET}-${ZIG_VERSION}.tar.xz" >&2; exit 1; }
  ZLS_TARBALL=$(jq -r --arg t "$TARGET" '.[$t].tarball // ""' <<< "$ZLS_META")
  [ "${ZLS_TARBALL##*/}" = "zls-${TARGET}-${ZLS_VERSION}.tar.xz" ] \
    || { echo "error: ZLS ${ZLS_VERSION} publishes '${ZLS_TARBALL##*/}' for ${TARGET}, not zls-${TARGET}-${ZLS_VERSION}.tar.xz" >&2; exit 1; }
done

echo "  zig ${ZIG_VERSION}, zls ${ZLS_VERSION}" >&2

BEFORE=$(cat "$FILE")
# Rewritten line by line rather than with `yq -i`, which reformats the whole
# document and drops the blank lines between variants.
TMP=$(mktemp)
awk -v variant="$VARIANT" -v zig="$ZIG_VERSION" -v zls="$ZLS_VERSION" '
  /^  - variant:/ { inside = ($0 ~ "\"" variant "\"") }
  inside && /^      ZIG_VERSION:/ { print "      ZIG_VERSION: \"" zig "\""; next }
  inside && /^      ZLS_VERSION:/ { print "      ZLS_VERSION: \"" zls "\""; next }
  { print }
' "$FILE" > "$TMP"
chmod --reference="$FILE" "$TMP"
mv "$TMP" "$FILE"

# The substitution above matches on layout, so confirm the values it wrote are
# the ones the build actually reads back.
for KEY_VALUE in "ZIG_VERSION=${ZIG_VERSION}" "ZLS_VERSION=${ZLS_VERSION}"; do
  KEY="${KEY_VALUE%%=*}"
  WRITTEN=$(VARIANT="$VARIANT" KEY="$KEY" yq \
    '.variants[] | select(.variant == strenv(VARIANT)) | .build_args[strenv(KEY)]' "$FILE")
  [ "$WRITTEN" = "${KEY_VALUE#*=}" ] \
    || { echo "error: ${KEY} in ${FILE} reads back as '${WRITTEN}'" >&2; exit 1; }
done

if [ "$BEFORE" = "$(cat "$FILE")" ]; then
  echo "  unchanged" >&2
  echo false
else
  echo "  changed" >&2
  echo true
fi
