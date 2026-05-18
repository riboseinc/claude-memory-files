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
UPDATE=0      # if 1, treat SOURCE_PATH as slug and run the update flow
UPSTREAM=0    # for --update on personal-share: force overwrite of local fork

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
  --update              Update an already-installed file by slug. The positional
                        argument is treated as a slug (not a path) and the
                        source path is read from the manifest. Drift is detected
                        by hash; the decision matrix (per the plan) decides
                        overwrite vs abort. Abort cases require --force to
                        proceed.
  --upstream            For --update on a scope: personal-share entry, force
                        overwrite from upstream (otherwise --update is a no-op
                        for forked entries).
  -h, --help            Show this help.

Environment:
  CLAUDE_DIR            Override the default ~/.claude/ location.

Examples:
  install.sh instructions/github-pr-title-issue-link.md
  install.sh --ref v1.2.0 instructions/github-pr-title-issue-link.md
  install.sh --project ~/my-gem project-claude-md/ruby-gem.md
  install.sh --update github-pr-title-issue-link
  install.sh --update --force github-pr-title-issue-link
  install.sh --update --upstream user-maintained-gems
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

# semver bump category: outputs none|patch|minor|major|unknown
semver_category() {
  local from="$1" to="$2"
  [[ -z "$from" || -z "$to" ]] && { echo "unknown"; return; }
  [[ "$from" == "$to" ]] && { echo "none"; return; }
  local fM fm fp tM tm tp
  IFS='.' read -r fM fm fp <<< "$from"
  IFS='.' read -r tM tm tp <<< "$to"
  if [[ "$fM" != "$tM" ]]; then echo "major"
  elif [[ "$fm" != "$tm" ]]; then echo "minor"
  else echo "patch"
  fi
}

# Replay settings-fragment merge on update: subtract the old manifest-recorded
# fragment, then merge the new upstream fragment.
update_settings_fragment_action() {
  local slug="$1" tmp_file="$2" target="$3"

  local body new_frag
  body="$(awk '/^---$/{c++; next} c>=2' "$tmp_file")"
  new_frag="$(printf '%s\n' "$body" | awk '
    /^## fragment[[:space:]]*$/ { in_section = 1; next }
    in_section && /^```json[[:space:]]*$/ { in_block = 1; next }
    in_block && /^```[[:space:]]*$/ { exit }
    in_block { print }
  ')"
  [[ -z "$new_frag" ]] && err "Upstream settings-fragment missing '## fragment' json block"
  printf '%s' "$new_frag" | jq -e . >/dev/null 2>&1 \
    || err "Upstream settings-fragment JSON is invalid"

  local old_frag
  old_frag="$(jq -r --arg s "$slug" '.files[$s]."merged-fragment"' "$MANIFEST")"

  local backup="${target}.bak.$(date -u +%Y%m%dT%H%M%SZ)"
  cp "$target" "$backup"
  info "  Backed up settings.json → $backup"

  # Subtract old fragment first (so removed entries actually go away)
  if [[ "$old_frag" != "null" && -n "$old_frag" ]]; then
    local unmerged
    unmerged="$(jq -s '
      .[0] as $current | .[1] as $old |
      $current |
      if $old.permissions.allow then .permissions.allow = ((.permissions.allow // []) - $old.permissions.allow) else . end |
      if $old.permissions.deny then .permissions.deny = ((.permissions.deny // []) - $old.permissions.deny) else . end |
      if $old.permissions.ask then .permissions.ask = ((.permissions.ask // []) - $old.permissions.ask) else . end
    ' "$target" <(printf '%s' "$old_frag"))"
    printf '%s\n' "$unmerged" > "$target"
  fi

  # Then merge new fragment
  local merged
  merged="$(jq -s '
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
  ' "$target" <(printf '%s' "$new_frag"))"
  printf '%s\n' "$merged" > "$target"

  # Bump manifest's merged-fragment to the new one
  jq --arg s "$slug" --argjson frag "$new_frag" '.files[$s]."merged-fragment" = $frag' "$MANIFEST" > "${MANIFEST}.tmp" \
    && mv "${MANIFEST}.tmp" "$MANIFEST"
}

# --update flow: drift detection + decision matrix + per-type overwrite
do_update() {
  local slug="$1"
  [[ -f "$MANIFEST" ]] || err "Manifest not found at $MANIFEST"

  local entry
  entry="$(jq --arg s "$slug" '.files[$s] // empty' "$MANIFEST")"
  [[ -z "$entry" || "$entry" == "null" ]] && err "$slug not installed (not found in manifest)"

  local source_path local_path installed_hash type forked
  source_path="$(printf '%s' "$entry" | jq -r '."source-path"')"
  local_path="$(printf '%s' "$entry" | jq -r '."local-path"')"
  installed_hash="$(printf '%s' "$entry" | jq -r '."installed-hash"')"
  type="$(printf '%s' "$entry" | jq -r '.type')"
  forked="$(printf '%s' "$entry" | jq -r '.forked')"

  # Personal-share short-circuit: forked entries don't auto-update
  if [[ "$forked" == "true" && $UPSTREAM -eq 0 ]]; then
    info "$slug is scope: personal-share (forked at install)."
    info "  --update is a no-op for forked entries. Pass --upstream to overwrite from upstream."
    info "  Local: $local_path"
    return 0
  fi

  # Fetch upstream
  local up_tmp resolved_sha
  up_tmp="$(mktemp)"
  if [[ -n "$REPO_ROOT" ]]; then
    local src="$REPO_ROOT/$source_path"
    [[ -f "$src" ]] || { rm -f "$up_tmp"; err "Local source not found: $src"; }
    cp "$src" "$up_tmp"
    if command -v git >/dev/null 2>&1 && [[ -d "$REPO_ROOT/.git" ]]; then
      resolved_sha="$(git -C "$REPO_ROOT" rev-parse HEAD 2>/dev/null || echo "$REF")"
    else
      resolved_sha="$REF"
    fi
  else
    local url="$BASE_RAW/$REF/$source_path"
    info "Fetching $url"
    curl -fsSL "$url" -o "$up_tmp" || { rm -f "$up_tmp"; err "Failed to fetch $url"; }
    resolved_sha="$REF"
    if [[ "$REF" == "main" || "$REF" == "HEAD" ]] && command -v gh >/dev/null 2>&1; then
      resolved_sha="$(gh api "/repos/$REPO/commits/$REF" --jq '.sha' 2>/dev/null || echo "$REF")"
    fi
  fi

  # Parse upstream
  local up_body up_version up_hash
  up_body="$(awk '/^---$/{c++; next} c>=2' "$up_tmp")"
  up_version="$(awk '/^---$/{c++; next} c==1 && /^version:/{sub("^[^:]*:[ \t]*", ""); print; exit}' "$up_tmp")"
  up_hash="sha256:$(printf '%s' "$up_body" | sha256)"

  # No drift?
  if [[ "$up_hash" == "$installed_hash" ]]; then
    info "$slug: already up to date (upstream hash matches installed hash)."
    rm -f "$up_tmp"
    return 0
  fi

  # Local-edit check
  local local_edited="no" inst_version=""
  if [[ -f "$local_path" && "$type" != "settings-fragment" ]]; then
    local inst_body local_hash
    inst_body="$(awk '/^---$/{c++; next} c>=2' "$local_path")"
    inst_version="$(awk '/^---$/{c++; next} c==1 && /^version:/{sub("^[^:]*:[ \t]*", ""); print; exit}' "$local_path")"
    local_hash="sha256:$(printf '%s' "$inst_body" | sha256)"
    [[ "$local_hash" != "$installed_hash" ]] && local_edited="yes"
  elif [[ "$type" == "settings-fragment" ]]; then
    # For settings-fragment, "local edited" means a user-added entry beyond the
    # manifest-recorded fragment exists. Skip the body-hash check; the update
    # path subtracts the old fragment and merges the new one, preserving
    # user-added entries by construction.
    inst_version=""
  fi

  local bump
  bump="$(semver_category "$inst_version" "$up_version")"

  info "  Installed: ${inst_version:-?} (${installed_hash:0:18}...)"
  info "  Upstream:  ${up_version:-?} (${up_hash:0:18}...) [${bump} bump]"
  info "  Local edited: ${local_edited}"

  # Decision matrix: overwrite for clean local; abort otherwise unless --force
  if [[ "$local_edited" == "yes" && $FORCE -eq 0 ]]; then
    info ""
    info "✗ $slug: update aborted — local copy has been hand-edited since install."
    info "  Pass --force to overwrite local edits, or merge by hand."
    rm -f "$up_tmp"
    return 0
  fi

  # Apply overwrite per type
  case "$type" in
    instruction|memory-feedback|memory-reference|memory-project|memory-user|path-rule)
      cp "$up_tmp" "$local_path"
      info "  Overwrote $local_path" ;;
    project-claude-md)
      printf '%s\n' "$up_body" > "$local_path"
      info "  Overwrote $local_path (frontmatter stripped)" ;;
    settings-fragment)
      update_settings_fragment_action "$slug" "$up_tmp" "$local_path" ;;
    *)
      rm -f "$up_tmp"; err "Unknown type in manifest: $type" ;;
  esac

  # Update manifest: bump installed-hash + upstream-ref + installed-at; append history event
  local now
  now="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

  jq --arg s "$slug" \
     --arg hash "$up_hash" \
     --arg ref "$resolved_sha" \
     --arg now "$now" '
       .files[$s]."installed-hash" = $hash |
       .files[$s]."upstream-ref" = $ref |
       .files[$s]."installed-at" = $now |
       .files[$s].history += [{event: "update", ref: $ref, at: $now}]
     ' "$MANIFEST" > "${MANIFEST}.tmp" && mv "${MANIFEST}.tmp" "$MANIFEST"

  rm -f "$up_tmp"

  info ""
  info "✓ Updated $slug → ${up_version:-?} (was ${inst_version:-?}, ${bump} bump)"
  info "  Target:   $local_path"
  info "  Manifest: $MANIFEST"
}

# Parse arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    --ref) REF="$2"; shift 2 ;;
    --repo-root) REPO_ROOT="$2"; shift 2 ;;
    --project) PROJECT_DIR="$2"; shift 2 ;;
    --force) FORCE=1; shift ;;
    --update) UPDATE=1; shift ;;
    --upstream) UPSTREAM=1; shift ;;
    -h|--help) usage; exit 0 ;;
    -*) err "Unknown option: $1" ;;
    *)
      [[ -n "$SOURCE_PATH" ]] && err "Multiple source paths given; expected one"
      SOURCE_PATH="$1"; shift ;;
  esac
done

[[ -z "$SOURCE_PATH" ]] && { usage; err "Missing required <path/to/file.md> (or slug, with --update)"; }

# Tool check
for cmd in curl awk jq mktemp mkdir; do
  command -v "$cmd" >/dev/null 2>&1 || err "Required tool not found: $cmd"
done

# --update mode: SOURCE_PATH is a slug; dispatch to update flow and exit
if [[ $UPDATE -eq 1 ]]; then
  do_update "$SOURCE_PATH"
  exit 0
fi

# Path category check (install mode only)
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
