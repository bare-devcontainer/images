#!/usr/bin/env bash
# housekeeper-pr.sh — commit working tree changes as the housekeeper app and
# open a pull request for them
#
# Usage:
#   housekeeper-pr.sh --branch <name> --title <title> [options] [<path>...]
#
# Options:
#   --branch <name>     Branch to commit to.
#   --title <title>     Commit message, and title of the pull request.
#   --body <text>       Pull request body.
#   --body-file <path>  Pull request body, read from a file.
#   --base <branch>     Base branch of the pull request (default: main).
#   --no-pr             Commit onto an existing branch and open no pull
#                       request. For committing onto the head branch of a pull
#                       request that already exists, so the branch is neither
#                       created nor reset.
#
# Paths default to every file the working tree adds, changes or deletes,
# ignored files excluded; nothing to commit is not an error. The commits are
# created through the API rather than with git, so GitHub signs them as the app
# and they come out verified. Requires GH_TOKEN to hold the app's token, plus
# GITHUB_REPOSITORY and GITHUB_SHA from the run.
set -euo pipefail

BRANCH=""
TITLE=""
BODY=""
BASE="main"
OPEN_PR=true
PATHS=()

while [ "$#" -gt 0 ]; do
  case "$1" in
    --branch) BRANCH="${2:?Missing value for --branch}"; shift 2 ;;
    --title) TITLE="${2:?Missing value for --title}"; shift 2 ;;
    --body) BODY="${2:?Missing value for --body}"; shift 2 ;;
    --body-file) BODY=$(cat "${2:?Missing value for --body-file}"); shift 2 ;;
    --base) BASE="${2:?Missing value for --base}"; shift 2 ;;
    --no-pr) OPEN_PR=false; shift ;;
    -*) echo "error: unknown option $1" >&2; exit 1 ;;
    *) PATHS+=("$1"); shift ;;
  esac
done

: "${BRANCH:?Missing --branch}"
: "${TITLE:?Missing --title}"
: "${GH_TOKEN:?Missing GH_TOKEN}"
REPO="${GITHUB_REPOSITORY:?Missing GITHUB_REPOSITORY}"
SHA="${GITHUB_SHA:?Missing GITHUB_SHA}"

if [ "${#PATHS[@]}" -eq 0 ]; then
  # --others covers a file the caller created, such as the first material of
  # an image that had none; git diff would report only tracked ones.
  mapfile -d '' -t PATHS < <(
    git ls-files -z --modified --others --exclude-standard | sort -zu
  )
fi
if [ "${#PATHS[@]}" -eq 0 ]; then
  echo "Nothing to commit." >&2
  exit 0
fi

# Callers assign the result rather than test it inline: a failed query has to
# stop the run, not read as "no pull request is open" and reset a branch.
open_pr_number() {
  gh pr list --repo "$REPO" --state open --head "$BRANCH" --json number --jq '.[0].number'
}

if [ "$OPEN_PR" = true ]; then
  if gh api "repos/${REPO}/git/ref/heads/${BRANCH}" > /dev/null 2>&1; then
    OPEN_PR_NUMBER=$(open_pr_number)
    if [ -z "$OPEN_PR_NUMBER" ]; then
      # Left over from an earlier run whose pull request is gone, so restart
      # it from the commit this run is working from.
      gh api "repos/${REPO}/git/refs/heads/${BRANCH}" \
        --method PATCH \
        -f sha="${SHA}" \
        -F force=true
    fi
  else
    gh api "repos/${REPO}/git/refs" \
      --method POST \
      -f ref="refs/heads/${BRANCH}" \
      -f sha="${SHA}"
  fi
fi

HEAD_SHA=$(gh api "repos/${REPO}/git/ref/heads/${BRANCH}" --jq '.object.sha')
BASE_TREE=$(gh api "repos/${REPO}/git/commits/${HEAD_SHA}" --jq '.tree.sha')

# base64 keeps binary files such as keyrings intact; --input avoids the
# kernel's per-argument size limit.
TREE_ENTRIES='[]'
for PATH_ENTRY in "${PATHS[@]}"; do
  if [ -e "$PATH_ENTRY" ]; then
    echo "Committing ${PATH_ENTRY}" >&2
    BLOB_SHA=$(base64 -w0 "$PATH_ENTRY" \
      | jq -R '{content: ., encoding: "base64"}' \
      | gh api "repos/${REPO}/git/blobs" --method POST --input - --jq '.sha')
    MODE=$([ -x "$PATH_ENTRY" ] && echo "100755" || echo "100644")
    TREE_ENTRIES=$(jq --arg path "$PATH_ENTRY" --arg sha "$BLOB_SHA" --arg mode "$MODE" \
      '. + [{path: $path, mode: $mode, type: "blob", sha: $sha}]' <<< "$TREE_ENTRIES")
  else
    echo "Deleting ${PATH_ENTRY}" >&2
    TREE_ENTRIES=$(jq --arg path "$PATH_ENTRY" \
      '. + [{path: $path, mode: "100644", type: "blob", sha: null}]' <<< "$TREE_ENTRIES")
  fi
done

TREE_SHA=$(jq -n --arg base_tree "$BASE_TREE" --argjson tree "$TREE_ENTRIES" \
  '{base_tree: $base_tree, tree: $tree}' \
  | gh api "repos/${REPO}/git/trees" --method POST --input - --jq '.sha')

if [ "$TREE_SHA" = "$BASE_TREE" ]; then
  echo "Branch ${BRANCH} already carries these changes; nothing to commit." >&2
  exit 0
fi

# No author/committer, so GitHub signs the commit (Verified).
COMMIT_SHA=$(gh api "repos/${REPO}/git/commits" \
  --method POST \
  -f message="${TITLE}" \
  -f tree="${TREE_SHA}" \
  -f "parents[]=${HEAD_SHA}" \
  --jq '.sha')

# Fast-forward only; if a concurrent push moved the branch, the run that push
# triggers commits the files again.
gh api "repos/${REPO}/git/refs/heads/${BRANCH}" \
  --method PATCH \
  -f sha="${COMMIT_SHA}"
echo "Committed ${COMMIT_SHA} to ${BRANCH}." >&2

if [ "$OPEN_PR" = false ]; then
  exit 0
fi

OPEN_PR_NUMBER=$(open_pr_number)
if [ -z "$OPEN_PR_NUMBER" ]; then
  gh pr create \
    --repo "$REPO" \
    --title "${TITLE}" \
    --body "${BODY}" \
    --head "${BRANCH}" \
    --base "${BASE}"
fi
