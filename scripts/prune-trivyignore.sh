#!/usr/bin/env bash
# prune-trivyignore.sh — drop the entries of the Trivy ignore file that no
# longer suppress anything, rewriting the file in place.
#
# Reads every Trivy JSON report under <reports-dir>, collects the
# (vulnerability id, finding path) pairs they contain, and removes from
# <ignore-file>:
#   - every path of an entry that no report pairs with the entry's id, so
#     an entry stays for the binaries that are still affected while the
#     ones that upstream has fixed drop out of it, and
#   - every entry whose paths were all removed, plus every entry that lists
#     no path — those suppress their id everywhere — whose id no report
#     contains at all.
# Expired entries are reported but kept: Trivy already stopped applying
# them, and extending the date instead of dropping the entry is a
# judgement call for the reviewer.
#
# Entries are removed line by line so the comments, grouping and blank
# lines around the surviving ones stay untouched. The rewritten file is
# parsed again and compared with what the pruning decided, so a file whose
# layout this cannot edit safely fails the run instead of being mangled.
#
# Prints "true" or "false" to stdout depending on whether anything was
# removed; the report of what was removed goes to stderr. Performs no git
# or GitHub operations.
#
# Usage:
#   prune-trivyignore.sh <reports-dir> [ignore-file]
set -euo pipefail

REPORTS_DIR="${1:?Usage: prune-trivyignore.sh <reports-dir> [ignore-file]}"
FILE="${2:-.trivyignore.yaml}"

mapfile -t REPORTS < <(find "$REPORTS_DIR" -type f -name '*.json' | sort)
if [ "${#REPORTS[@]}" -eq 0 ]; then
  echo "error: no Trivy JSON report found under ${REPORTS_DIR}" >&2
  exit 1
fi

# The path Trivy matches an entry against: the package path when the report
# carries one, and the result target otherwise.
FINDINGS=$(jq -r '
  (.Results // [])[]
  | .Target as $target
  | (.Vulnerabilities // [])[]
  | [.VulnerabilityID, (if (.PkgPath // "") == "" then $target else .PkgPath end)]
  | @tsv' "${REPORTS[@]}" | sort -u)

# Reports without a single vulnerability mean a broken scan far more often
# than an image fleet that has nothing left to ignore, and pruning on them
# would empty the file.
if [ -z "$FINDINGS" ]; then
  echo "error: ${#REPORTS[@]} report(s) contain no vulnerability at all; refusing to prune" >&2
  exit 1
fi

ENTRIES=$(yq -o=json -I=0 \
  '[(.vulnerabilities // [])[] | {"id": .id, "paths": (.paths // null), "expired_at": (.expired_at // null)}]' \
  "$FILE")

declare -A DROP_ENTRY=()  # entry index -> 1
declare -A DROP_PATH=()   # entry index -> newline-separated paths to remove
EXPECTED='[]'             # the entries the rewrite below has to leave behind
REPORT=''
CHANGED=false

TODAY=$(date -u +%F)
COUNT=$(jq 'length' <<< "$ENTRIES")
for ((i = 0; i < COUNT; i++)); do
  id=$(jq -r ".[$i].id" <<< "$ENTRIES")
  mapfile -t patterns < <(jq -r ".[$i].paths // [] | .[]" <<< "$ENTRIES")
  mapfile -t reported < <(awk -F'\t' -v id="$id" '$1 == id { print $2 }' <<< "$FINDINGS")

  kept=()
  dropped=()
  for pattern in ${patterns+"${patterns[@]}"}; do
    matched=false
    for path in ${reported+"${reported[@]}"}; do
      # Trivy globs the path; bash globbing is close enough here and, by
      # letting * span directories too, only ever errs towards keeping.
      # shellcheck disable=SC2053 # the pattern is meant to glob
      if [[ "$path" == $pattern ]]; then
        matched=true
        break
      fi
    done
    if [ "$matched" = true ]; then
      kept+=("$pattern")
    else
      dropped+=("$pattern")
    fi
  done

  if [ "${#patterns[@]}" -eq 0 ]; then
    # No paths: the entry suppresses its id wherever it is reported.
    if [ "${#reported[@]}" -eq 0 ]; then
      DROP_ENTRY[$i]=1
      REPORT+="${id}: removed, no scanned image reports it any more"$'\n'
      CHANGED=true
      continue
    fi
    EXPECTED=$(jq -c --arg id "$id" '. + [{"id": $id, "paths": null}]' <<< "$EXPECTED")
  elif [ "${#kept[@]}" -eq 0 ]; then
    DROP_ENTRY[$i]=1
    REPORT+="${id}: removed, none of its paths reports it any more"$'\n'
    CHANGED=true
    continue
  else
    if [ "${#dropped[@]}" -gt 0 ]; then
      DROP_PATH[$i]=$(printf '%s\n' "${dropped[@]}")
      for pattern in "${dropped[@]}"; do
        REPORT+="${id}: removed path ${pattern}, no longer reported for it"$'\n'
      done
      CHANGED=true
    fi
    EXPECTED=$(jq -c --arg id "$id" --argjson paths "$(printf '%s\n' "${kept[@]}" | jq -R -s 'split("\n") | map(select(. != ""))')" \
      '. + [{"id": $id, "paths": $paths}]' <<< "$EXPECTED")
  fi

  expired_at=$(jq -r ".[$i].expired_at // \"\"" <<< "$ENTRIES")
  if [ -n "$expired_at" ] && [[ "$expired_at" < "$TODAY" ]]; then
    REPORT+="${id}: expired at ${expired_at}, so Trivy no longer applies it"$'\n'
  fi
done

printf '%s' "$REPORT" >&2

if [ "$CHANGED" = false ]; then
  echo false
  exit 0
fi

# Rewrite the file, dropping the lines of the entries and paths decided
# above. Blank lines and comments trailing a dropped entry lead the next
# one — they are the section headers of the file — so they are held back
# and emitted once the entry ends.
mapfile -t LINES < "$FILE"
out=()
pending=()
section=''
entry=-1
in_paths=false
skipping=false

# Emits the held back lines, dropping the blank ones that would otherwise
# double up or open a section now that the entry above them is gone.
flush_pending() {
  local held
  for held in ${pending+"${pending[@]}"}; do
    if [ -z "${held//[[:space:]]/}" ] &&
      { [ "${#out[@]}" -eq 0 ] || [ -z "${out[-1]//[[:space:]]/}" ] || [[ "${out[-1]}" =~ ^[^[:space:]#] ]]; }; then
      continue
    fi
    out+=("$held")
  done
  pending=()
}

for line in ${LINES+"${LINES[@]}"}; do
  if [[ "$line" =~ ^[^[:space:]#] ]]; then
    # A top-level key ends whatever entry we were in.
    flush_pending
    section="${line%%:*}"
    entry=-1
    in_paths=false
    skipping=false
    out+=("$line")
    continue
  fi

  if [ "$section" = vulnerabilities ] && [[ "$line" =~ ^[[:space:]]{2}-([[:space:]]|$) ]]; then
    flush_pending
    entry=$((entry + 1))
    in_paths=false
    if [ -n "${DROP_ENTRY[$entry]:-}" ]; then
      skipping=true
      continue
    fi
    skipping=false
    out+=("$line")
    continue
  fi

  if [ "$skipping" = true ]; then
    if [ -z "${line//[[:space:]]/}" ] || [[ "$line" =~ ^[[:space:]]*# ]]; then
      pending+=("$line")
    else
      pending=()
    fi
    continue
  fi

  if [ "$section" = vulnerabilities ] && [ "$entry" -ge 0 ]; then
    if [[ "$line" =~ ^[[:space:]]{4}[^[:space:]] ]]; then
      # A key of the current entry; only its paths list is edited.
      if [[ "$line" =~ ^[[:space:]]{4}paths:[[:space:]]*$ ]]; then
        in_paths=true
      else
        in_paths=false
      fi
    elif [ "$in_paths" = true ] && [[ "$line" =~ ^[[:space:]]{6}-[[:space:]] ]]; then
      path="${line#*- }"
      path="${path%[\"\']}"
      path="${path#[\"\']}"
      if grep -qxF "$path" <<< "${DROP_PATH[$entry]:-}"; then
        continue
      fi
    fi
  fi

  out+=("$line")
done
flush_pending

TMP=$(mktemp)
trap 'rm -f "$TMP"' EXIT
printf '%s\n' ${out+"${out[@]}"} > "$TMP"

ACTUAL=$(yq -o=json -I=0 '[(.vulnerabilities // [])[] | {"id": .id, "paths": (.paths // null)}]' "$TMP")
if [ "$(jq -Sc . <<< "$ACTUAL")" != "$(jq -Sc . <<< "$EXPECTED")" ]; then
  echo "error: the rewritten ${FILE} does not hold the expected entries; not touching it" >&2
  diff <(jq -S . <<< "$EXPECTED") <(jq -S . <<< "$ACTUAL") >&2 || true
  exit 1
fi

chmod 644 "$TMP"
mv "$TMP" "$FILE"
echo true
