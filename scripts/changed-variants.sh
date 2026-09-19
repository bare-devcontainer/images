#!/usr/bin/env bash
# changed-variants.sh — map a set of changed files to the image variants they affect
#
# Usage:
#   changed-variants.sh <base-ref> [<file>]
#
# Must be run from the repository root. Reads changed paths (one per line,
# repository-relative) from <file>, or from stdin when <file> is omitted or
# "-", and prints a JSON array with one entry per variant of every image:
#
#   [{"image": "node", "variant": "26-trixie", "primary_tag": "26.9.0-trixie",
#     "selected": true, "reason": "variant changed"}, ...]
#
# Each entry carries the fields build-config.sh all-matrix produces, so
# release.yml builds its job matrix out of the selected ones directly.
#
# This refines the release mode of changed-images.sh, which names the images a
# change reaches, down to the variants of those images; the paths that mode
# ignores are ignored here too. Only the release publishes at this granularity.
# The pull request checks stay at the image level, so every variant of a
# changed image is still built before the change can merge, and the Monday
# rebuild remains the catch-all for what no rule below reaches.
#
# Which files a variant is built from cannot be read from the changed paths
# alone: the variants of an image share one Dockerfile and one build.yaml, and
# what separates them is the entry build.yaml holds for each. So the entries of
# <base-ref> are compared with those of the working tree as the JSON yq parses
# them, which leaves a comment, a key order or an indentation change equal.
#
# Rules, applied per image:
#   - A file other than build.yaml changed under <image>/ (the Dockerfile, a
#     trust material, an asset): every variant, since they share it.
#   - <base-ref> holds no <image>/build.yaml: every variant.
#   - build.yaml changed outside .variants (description, materials): every
#     variant. The description reaches the published image as an OCI label.
#   - A variant entry was added or differs: that variant.
#   - The debian variant a variant names in debian_variant was selected by the
#     rules above: that variant. publish-image.yml resolves the base through
#     that tag, so a rebuilt base reaches the variants built FROM it alone.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

BASE_REF="${1:?Usage: changed-variants.sh <base-ref> [<file>]}"
INPUT="${2:--}"

fail() {
  echo "error: $*" >&2
  exit 1
}

# One line of JSON out of a build.yaml, read from the file named or from stdin,
# so the rules below are one jq program over both revisions of it.
config_json() {
  yq -o json -I 0 '.' "$@"
}

if [ "$INPUT" = "-" ]; then
  CHANGED=$(cat)
else
  CHANGED=$(cat "$INPUT")
fi

IMAGE_REPORT=$(bash "${SCRIPT_DIR}/changed-images.sh" release - <<< "$CHANGED")

# Captured by assignment before it is read. mapfile reading a process
# substitution succeeds even when the command inside it failed, which would
# drop images from the report instead of stopping the script.
REPORT_ENTRIES=$(echo "$IMAGE_REPORT" | jq -c '.[]')
[ -n "$REPORT_ENTRIES" ] || fail "no image directory contains a build.yaml"
mapfile -t ENTRIES <<< "$REPORT_ENTRIES"

RECORDS=()
for ENTRY in "${ENTRIES[@]}"; do
  IMAGE=$(echo "$ENTRY" | jq -r '.image')
  NEW=$(config_json "${IMAGE}/build.yaml")
  OLD=null
  # The build.yaml of an earlier revision is not on disk, so git supplies it.
  if OLD_YAML=$(git show "${BASE_REF}:${IMAGE}/build.yaml" 2> /dev/null); then
    OLD=$(config_json <<< "$OLD_YAML")
  fi
  RECORDS+=("$(jq -c -n --argjson entry "$ENTRY" --argjson new "$NEW" --argjson old "$OLD" \
    '{image: $entry.image, files: $entry.files, new: $new, old: $old}')")
done

printf '%s\n' "${RECORDS[@]}" | jq -s -c '
  # The variants of one image the change selects, as {<variant>: <reason>},
  # before the base image is taken into account.
  def reasons($record):
    [$record.new.variants[].variant] as $all
    | ($record.files | map(select(. != ($record.image + "/build.yaml")))) as $other
    | if ($record.files | length) == 0 then {}
      elif $record.old == null then
        ($all | map({key: ., value: "image added"}) | from_entries)
      elif ($other | length) > 0 then
        ($all | map({key: ., value: "image files changed"}) | from_entries)
      elif ($record.new | del(.variants)) != ($record.old | del(.variants)) then
        ($all | map({key: ., value: "build.yaml metadata changed"}) | from_entries)
      else
        (($record.old.variants // []) | INDEX(.variant)) as $old
        | [$record.new.variants[] | select($old[.variant] != .)
            | {key: .variant, value: "variant changed"}]
          | from_entries
      end;

  . as $records
  | ($records | map(select(.image == "debian")) | first) as $base
  | (if $base == null then {} else reasons($base) end) as $base_reasons
  | [ $records[]
      | . as $record
      | reasons($record) as $own
      | $record.new.variants[]
      | . as $variant
      | (
          if $own[$variant.variant] then $own[$variant.variant]
          # The empty key stands in for an image built FROM no debian variant,
          # since indexing an object with null is an error.
          elif $record.image != "debian"
            and $base_reasons[$variant.debian_variant // ""] then "base variant changed"
          else null
          end
        ) as $reason
      | {
          image: $record.image,
          variant: $variant.variant,
          primary_tag: $variant.tags[0],
          selected: ($reason != null),
          reason: ($reason // "no relevant changes")
        }
    ]
'
