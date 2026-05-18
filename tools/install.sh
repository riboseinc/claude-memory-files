#!/usr/bin/env bash
# tools/install.sh — install a memory file from riboseinc/claude-memory-files
# into your local ~/.claude/.
#
# Usage: install.sh [options] <path/to/file.md>
#
# Designed to be runnable directly via curl | bash:
#   curl -fsSL https://raw.githubusercontent.com/riboseinc/claude-memory-files/main/tools/install.sh \
#     | bash -s -- instructions/github-pr-title-issue-link.md
#
# Tools required: curl, awk, jq, mktemp, mkdir, shasum or sha256sum.
# Optional: gh CLI (used to resolve symbolic refs like `main` to a SHA for the
# manifest, so updates can detect drift precisely).

set -euo pipefail

REPO="riboseinc/claude-memory-files"
BASE_RAW="https://raw.githubusercontent.com/${REPO}"

CLAUDE_DIR="${CLAUDE_DIR:-${HOME}/.claude}"
MANIFEST="${CLAUDE_DIR}/.memory-files-manifest.json"

REF="main"
PROJECT_DIR=""
FORCE=0
SOURCE_PATH=""
REPO_ROOT=""  # if set, read from local checkout instead of fetching

usage() {
  cat <<'EOF'
Usage: install.sh [options] <path/to/file.md>

Install a memory file from riboseinc/claude-memory-files into your local
~/.claude/.

Arguments:
  <path/to/file.md>     Relative path in the repo (e.g.
                        instructions/github-pr-title-issue-link.md).

Options:
  --ref <sha>           Pin to a specific git ref or branch (default: main).
  --repo-root <dir>     Read from a local checkout instead of fetching.
                        Useful for CI testing and offline use.
  --project <dir>       Required for type: project-claude-md;
                        optional override for type: path-rule.
  --force               Overwrite existing target file.
  -h, --help            Show this help.

Environment:
  CLAUDE_DIR            Override the default ~/.claude/ location.

Examples:
  install.sh instructions/github-pr-title-issue-link.md
  install.sh --ref v1.2.0 instructions/github-pr-title-issue-link.md
  install.sh --project ~/my-gem project-claude-md/ruby-gem.md
EOF
}

err() { echo "ERROR: $*" >&2; exit 1; }
info() { echo "$*" >&2; }

# Cross-platform sha256 (macOS uses shasum -a 256; Linux has sha256sum).
sha256() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum | awk '{print $1}'
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 | awk '{print $1}'
  else
    err "Neither sha256sum nor shasum found"
  fi
}

# Parse arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    --ref) REF="$2"; shift 2 ;;
    --repo-root) REPO_ROOT="$2"; shift 2 ;;
    --project) PROJECT_DIR="$2"; shift 2 ;;
    --force) FORCE=1; shift ;;
    -h|--help) usage; exit 0 ;;
    -*) err "Unknown option: $1" ;;
    *)
      [[ -n "$SOURCE_PATH" ]] && err "Multiple source paths given; expected one"
      SOURCE_PATH="$1"; shift ;;
  esac
done

[[ -z "$SOURCE_PATH" ]] && { usage; err "Missing required <path/to/file.md>"; }

# Tool check
for cmd in curl awk jq mktemp mkdir; do
  command -v "$cmd" >/dev/null 2>&1 || err "Required tool not found: $cmd"
done

# Path category check
case "$SOURCE_PATH" in
  instructions/*.md|memory/*.md|settings-fragments/*.md|project-claude-md/*.md|rules/*.md)
    ;;
  hooks/*)
    err "hooks/ is reserved for v2; see SAFETY.md in the repo." ;;
  *)
    err "Path must be of form <category>/<name>.md where category is one of: instructions, memory, settings-fragments, project-claude-md, rules" ;;
esac

# Fetch the file
TMP_FILE="$(mktemp)"
trap 'rm -f "$TMP_FILE"' EXIT

if [[ -n "${REPO_ROOT}" ]]; then
  LOCAL_FILE="${REPO_ROOT}/${SOURCE_PATH}"
  [[ -f "${LOCAL_FILE}" ]] || err "Local file not found: ${LOCAL_FILE}"
  info "Reading from local checkout: ${LOCAL_FILE}"
  cp "${LOCAL_FILE}" "${TMP_FILE}"
  # Resolve ref to local checkout's HEAD SHA when possible
  if command -v git >/dev/null 2>&1 && [[ -d "${REPO_ROOT}/.git" ]]; then
    RESOLVED_SHA="$(git -C "${REPO_ROOT}" rev-parse HEAD 2>/dev/null || echo "${REF}")"
  else
    RESOLVED_SHA="${REF}"
  fi
else
  URL="${BASE_RAW}/${REF}/${SOURCE_PATH}"
  info "Fetching ${URL}"
  curl -fsSL "${URL}" -o "${TMP_FILE}" || err "Failed to fetch ${URL}"
  # Resolve symbolic refs to actual SHA when gh is available
  RESOLVED_SHA="${REF}"
  if [[ "${REF}" == "main" || "${REF}" == "HEAD" ]] && command -v gh >/dev/null 2>&1; then
    RESOLVED_SHA="$(gh api "/repos/${REPO}/commits/${REF}" --jq '.sha' 2>/dev/null || echo "${REF}")"
  fi
fi

# Split frontmatter and body
FRONTMATTER="$(awk '/^---$/{c++; next} c==1 {print} c>=2 {exit}' "${TMP_FILE}")"
BODY="$(awk '/^---$/{c++; next} c>=2' "${TMP_FILE}")"
[[ -z "${FRONTMATTER}" ]] && err "No YAML frontmatter found in ${SOURCE_PATH}"

# Extract a scalar field from frontmatter
fm_get() {
  printf '%s\n' "${FRONTMATTER}" | awk -v k="$1" '
    BEGIN { key = k ":" }
    $1 == key {
      sub("^[^:]*:[ \t]*", "")
      gsub(/^["\047]|["\047][ \t]*$/, "")
      print
      exit
    }
  '
}

NAME="$(fm_get name)"
TYPE="$(fm_get type)"
SCOPE="$(fm_get scope)"
[[ -z "${NAME}" ]] && err "frontmatter missing 'name'"
[[ -z "${TYPE}" ]] && err "frontmatter missing 'type'"

info "Installing ${NAME} (type: ${TYPE}, scope: ${SCOPE:-?})"

# Body hash, frontmatter-stripped (used by PR 9 --update for drift detection)
BODY_HASH="sha256:$(printf '%s' "${BODY}" | sha256)"
NOW="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

# Determine install target per type
INSTALL_TARGET=""
FORKED="false"
case "${TYPE}" in
  instruction)
    INSTALL_TARGET="${CLAUDE_DIR}/instructions/${NAME}.md" ;;
  memory-feedback|memory-reference|memory-project|memory-user)
    INSTALL_TARGET="${CLAUDE_DIR}/memory/${NAME}.md" ;;
  settings-fragment)
    INSTALL_TARGET="${CLAUDE_DIR}/settings.json" ;;
  project-claude-md)
    [[ -z "${PROJECT_DIR}" ]] && err "type project-claude-md requires --project <dir>"
    INSTALL_TARGET="${PROJECT_DIR}/CLAUDE.md" ;;
  path-rule)
    if [[ -n "${PROJECT_DIR}" ]]; then
      INSTALL_TARGET="${PROJECT_DIR}/.claude/rules/${NAME}.md"
    else
      INSTALL_TARGET="${CLAUDE_DIR}/rules/${NAME}.md"
    fi ;;
  hook)
    err "hook type is reserved for v2; see SAFETY.md in the repo." ;;
  *)
    err "Unknown type: ${TYPE}" ;;
esac

# personal-share installs as a "fork" — its installed copy diverges from upstream
# and PR 9's --update will be a no-op by default (--upstream forces overwrite).
[[ "${SCOPE}" == "personal-share" ]] && FORKED="true"

mkdir -p "${CLAUDE_DIR}"
MERGED_FRAGMENT="null"  # populated for settings-fragment installs

if [[ "${TYPE}" == "settings-fragment" ]]; then
  # Extract the ## fragment ```json block
  JSON_FRAG="$(printf '%s\n' "${BODY}" | awk '
    /^## fragment[[:space:]]*$/ { in_section = 1; next }
    in_section && /^```json[[:space:]]*$/ { in_block = 1; next }
    in_block && /^```[[:space:]]*$/ { exit }
    in_block { print }
  ')"
  [[ -z "${JSON_FRAG}" ]] && err "settings-fragment missing '## fragment' json block"
  printf '%s' "${JSON_FRAG}" | jq -e . >/dev/null 2>&1 \
    || err "settings-fragment JSON is not valid JSON"

  # Backup current settings.json, then deep-merge.
  if [[ -f "${INSTALL_TARGET}" ]]; then
    BACKUP="${INSTALL_TARGET}.bak.$(date -u +%Y%m%dT%H%M%SZ)"
    cp "${INSTALL_TARGET}" "${BACKUP}"
    info "Backed up existing settings.json → ${BACKUP}"
  else
    echo '{}' > "${INSTALL_TARGET}"
  fi

  # Validate allowlisted top-level keys before merging
  EXTRANEOUS="$(printf '%s' "${JSON_FRAG}" | jq -r 'keys[] | select(. != "permissions" and . != "env")')"
  [[ -n "${EXTRANEOUS}" ]] && err "settings-fragment JSON touches disallowed top-level keys: ${EXTRANEOUS}"

  MERGED="$(jq -s '
    .[0] as $current | .[1] as $frag |
    ($current * $frag) |
    if $frag.permissions.allow then
      .permissions.allow = ((($current.permissions.allow // []) + ($frag.permissions.allow // [])) | unique)
    else . end |
    if $frag.permissions.deny then
      .permissions.deny = ((($current.permissions.deny // []) + ($frag.permissions.deny // [])) | unique)
    else . end |
    if $frag.permissions.ask then
      .permissions.ask = ((($current.permissions.ask // []) + ($frag.permissions.ask // [])) | unique)
    else . end
  ' "${INSTALL_TARGET}" <(printf '%s' "${JSON_FRAG}"))"

  printf '%s\n' "${MERGED}" > "${INSTALL_TARGET}"
  info "Deep-merged ${SOURCE_PATH} → ${INSTALL_TARGET}"

  # Record merged fragment in the manifest so uninstall can subtract it precisely.
  MERGED_FRAGMENT="${JSON_FRAG}"

else
  # File-copy types
  if [[ -e "${INSTALL_TARGET}" ]] && [[ "${FORCE}" -eq 0 ]]; then
    err "Target ${INSTALL_TARGET} already exists. Use --force to overwrite."
  fi
  mkdir -p "$(dirname "${INSTALL_TARGET}")"

  if [[ "${TYPE}" == "project-claude-md" ]]; then
    # Strip frontmatter; the project CLAUDE.md is just the body.
    printf '%s\n' "${BODY}" > "${INSTALL_TARGET}"
  else
    cp "${TMP_FILE}" "${INSTALL_TARGET}"
  fi
  info "Installed ${SOURCE_PATH} → ${INSTALL_TARGET}"
fi

# Instructions: append @-include to CLAUDE.md under a managed block.
if [[ "${TYPE}" == "instruction" ]]; then
  CLAUDE_MD="${CLAUDE_DIR}/CLAUDE.md"
  touch "${CLAUDE_MD}"
  MARKER_START="<!-- claude-memory-files: managed block start -->"
  MARKER_END="<!-- claude-memory-files: managed block end -->"
  INCLUDE_LINE="@instructions/${NAME}.md"

  if ! grep -qF "${MARKER_START}" "${CLAUDE_MD}"; then
    {
      printf '\n%s\n%s\n%s\n' "${MARKER_START}" "${INCLUDE_LINE}" "${MARKER_END}"
    } >> "${CLAUDE_MD}"
    info "Appended managed @-include block to ${CLAUDE_MD}"
  elif ! grep -qF "${INCLUDE_LINE}" "${CLAUDE_MD}"; then
    awk -v marker="${MARKER_END}" -v line="${INCLUDE_LINE}" '
      $0 == marker { print line }
      { print }
    ' "${CLAUDE_MD}" > "${CLAUDE_MD}.tmp" && mv "${CLAUDE_MD}.tmp" "${CLAUDE_MD}"
    info "Added @-include for ${NAME} to managed block in ${CLAUDE_MD}"
  else
    info "@-include for ${NAME} already present"
  fi
fi

# Update manifest. Schema includes all fields PR 9's --update will read,
# written up front so PR 9 needs only read logic, not a manifest migration.
[[ -f "${MANIFEST}" ]] || echo '{"files": {}}' > "${MANIFEST}"

ENTRY="$(jq -n \
  --arg type "${TYPE}" \
  --arg installed_at "${NOW}" \
  --arg installed_hash "${BODY_HASH}" \
  --arg upstream_ref "${RESOLVED_SHA}" \
  --arg source_path "${SOURCE_PATH}" \
  --arg local_path "${INSTALL_TARGET}" \
  --argjson forked "${FORKED}" \
  --argjson merged_fragment "${MERGED_FRAGMENT}" \
  '{
    type: $type,
    "installed-at": $installed_at,
    "installed-hash": $installed_hash,
    "upstream-ref": $upstream_ref,
    "source-path": $source_path,
    "local-path": $local_path,
    forked: $forked,
    "merged-fragment": $merged_fragment,
    history: [
      { event: "install", ref: $upstream_ref, at: $installed_at }
    ]
  }')"

UPDATED_MANIFEST="$(jq --arg name "${NAME}" --argjson entry "${ENTRY}" '.files[$name] = $entry' "${MANIFEST}")"
printf '%s\n' "${UPDATED_MANIFEST}" > "${MANIFEST}"

info ""
info "✓ Installed ${NAME}"
info "  Target:   ${INSTALL_TARGET}"
info "  Manifest: ${MANIFEST}"
info "  Remove:   tools/uninstall.sh ${NAME}"
