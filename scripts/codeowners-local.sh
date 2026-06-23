#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CODEOWNERS_FILE="${CODEOWNERS_FILE:-${ROOT_DIR}/.github/CODEOWNERS}"

usage() {
  cat <<'EOF'
Usage:
  scripts/codeowners-local.sh [path ...]

Without arguments, reports CODEOWNERS for local Git changes, including untracked files.
With path arguments, reports CODEOWNERS for those paths.

Environment:
  CODEOWNERS_FILE=/path/to/CODEOWNERS  Override the CODEOWNERS file.
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

if [[ ! -f "${CODEOWNERS_FILE}" ]]; then
  echo "CODEOWNERS file not found: ${CODEOWNERS_FILE}" >&2
  exit 1
fi

declare -a OWNER_PATTERNS=()
declare -a OWNER_VALUES=()

while IFS= read -r line || [[ -n "${line}" ]]; do
  line="${line%%#*}"
  line="${line#"${line%%[![:space:]]*}"}"
  line="${line%"${line##*[![:space:]]}"}"

  [[ -z "${line}" ]] && continue

  read -r pattern owners <<<"${line}"
  [[ -z "${pattern:-}" || -z "${owners:-}" ]] && continue

  OWNER_PATTERNS+=("${pattern}")
  OWNER_VALUES+=("${owners}")
done <"${CODEOWNERS_FILE}"

normalize_path() {
  local path="$1"
  path="${path#./}"
  path="${path#${ROOT_DIR}/}"
  printf '%s\n' "${path}"
}

matches_owner_pattern() {
  local pattern="$1"
  local path="$2"
  local normalized="${pattern#/}"

  if [[ "${pattern}" == "*" ]]; then
    return 0
  fi

  if [[ "${normalized}" == */ ]]; then
    [[ "${path}" == "${normalized}"* ]]
    return
  fi

  if [[ "${pattern}" == /* ]]; then
    [[ "${path}" == "${normalized}" ]]
    return
  fi

  if [[ "${pattern}" == *"/"* ]]; then
    [[ "${path}" == ${normalized} ]]
    return
  fi

  [[ "${path}" == "${pattern}" || "${path}" == */"${pattern}" ]]
}

owners_for_path() {
  local path="$1"
  local owners=""

  for i in "${!OWNER_PATTERNS[@]}"; do
    if matches_owner_pattern "${OWNER_PATTERNS[$i]}" "${path}"; then
      owners="${OWNER_VALUES[$i]}"
    fi
  done

  printf '%s\n' "${owners:-<unowned>}"
}

declare -a paths=()

if [[ "$#" -gt 0 ]]; then
  for arg in "$@"; do
    paths+=("$(normalize_path "${arg}")")
  done
else
  while IFS= read -r path; do
    [[ -z "${path}" ]] && continue
    paths+=("$(normalize_path "${path}")")
  done < <(
    {
      git -C "${ROOT_DIR}" diff --name-only
      git -C "${ROOT_DIR}" diff --name-only --cached
      git -C "${ROOT_DIR}" ls-files --others --exclude-standard
    } | sort -u
  )
fi

if [[ "${#paths[@]}" -eq 0 ]]; then
  echo "No paths to check."
  exit 0
fi

declare -a seen_owners=()

for path in "${paths[@]}"; do
  owners="$(owners_for_path "${path}")"

  already_seen=false
  if [[ "${#seen_owners[@]}" -gt 0 ]]; then
    for seen in "${seen_owners[@]}"; do
      if [[ "${seen}" == "${owners}" ]]; then
        already_seen=true
        break
      fi
    done
  fi
  [[ "${already_seen}" == true ]] || seen_owners+=("${owners}")
done

for owners in "${seen_owners[@]}"; do
  echo "${owners}"

  for path in "${paths[@]}"; do
    if [[ "$(owners_for_path "${path}")" == "${owners}" ]]; then
      echo "  ${path}"
    fi
  done
done
