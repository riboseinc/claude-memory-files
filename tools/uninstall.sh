#!/usr/bin/env bash
# tools/uninstall.sh — uninstall a memory file by slug.
#
# Reads ~/.claude/.memory-files-manifest.json to find what was installed,
# then reverses the install per type:
#
#   - instruction: remove the file and strip the @-include from CLAUDE.md.
#   - memory-*: remove the file.
#   - settings-fragment: subtract the recorded merged-fragment entries from
#                        ~/.claude/settings.json (hand-added entries kept).
#   - project-claude-md: removal is manual — the project's CLAUDE.md may
#                        have been hand-edited since install; we only print
#                        a removal hint.
#   - path-rule: remove the file.

set -euo pipefail

CLAUDE_DIR="${CLAUDE_DIR:-${HOME}/.claude}"
MANIFEST="${CLAUDE_DIR}/.memory-files-manifest.json"

usage() {
  cat <<'EOF'
Usage: uninstall.sh <slug>

Uninstall a memory file by its slug (the `name:` from its frontmatter).

Environment:
  CLAUDE_DIR            Override the default ~/.claude/ location.
EOF
}

err() { echo "ERROR: $*" >&2; exit 1; }
info() { echo "$*" >&2; }

[[ $# -eq 0 ]] && { usage; err "Missing slug argument"; }
[[ "$1" == "-h" || "$1" == "--help" ]] && { usage; exit 0; }

SLUG="$1"

for cmd in jq awk; do
  command -v "$cmd" >/dev/null 2>&1 || err "Required tool not found: $cmd"
done

[[ -f "${MANIFEST}" ]] || err "Manifest not found at ${MANIFEST}; nothing to uninstall."

ENTRY="$(jq --arg name "${SLUG}" '.files[$name] // empty' "${MANIFEST}")"
[[ -z "${ENTRY}" || "${ENTRY}" == "null" ]] && err "No installed entry for slug '${SLUG}' in ${MANIFEST}"

TYPE="$(printf '%s' "${ENTRY}" | jq -r .type)"
LOCAL_PATH="$(printf '%s' "${ENTRY}" | jq -r '."local-path"')"

case "${TYPE}" in
  instruction)
    [[ -f "${LOCAL_PATH}" ]] && rm "${LOCAL_PATH}" && info "Removed ${LOCAL_PATH}"
    CLAUDE_MD="${CLAUDE_DIR}/CLAUDE.md"
    if [[ -f "${CLAUDE_MD}" ]]; then
      INCLUDE_LINE="@instructions/${SLUG}.md"
      if grep -qF "${INCLUDE_LINE}" "${CLAUDE_MD}"; then
        grep -vF "${INCLUDE_LINE}" "${CLAUDE_MD}" > "${CLAUDE_MD}.tmp" \
          && mv "${CLAUDE_MD}.tmp" "${CLAUDE_MD}"
        info "Stripped @-include for ${SLUG} from ${CLAUDE_MD}"
      fi
    fi ;;

  memory-feedback|memory-reference|memory-project|memory-user|path-rule)
    [[ -f "${LOCAL_PATH}" ]] && rm "${LOCAL_PATH}" && info "Removed ${LOCAL_PATH}" ;;

  settings-fragment)
    MERGED_FRAGMENT="$(printf '%s' "${ENTRY}" | jq '.["merged-fragment"]')"
    if [[ "${MERGED_FRAGMENT}" == "null" || -z "${MERGED_FRAGMENT}" ]]; then
      info "settings-fragment: no merged-fragment recorded in manifest; cannot un-merge precisely."
      info "Restore from a backup at ${LOCAL_PATH}.bak.* if needed."
    elif [[ -f "${LOCAL_PATH}" ]]; then
      BACKUP="${LOCAL_PATH}.bak.$(date -u +%Y%m%dT%H%M%SZ)"
      cp "${LOCAL_PATH}" "${BACKUP}"
      info "Backed up settings.json → ${BACKUP}"
      UNMERGED="$(jq -s '
        .[0] as $current | .[1] as $frag |
        $current |
        if $frag.permissions.allow then
          .permissions.allow = ((.permissions.allow // []) - $frag.permissions.allow)
        else . end |
        if $frag.permissions.deny then
          .permissions.deny = ((.permissions.deny // []) - $frag.permissions.deny)
        else . end |
        if $frag.permissions.ask then
          .permissions.ask = ((.permissions.ask // []) - $frag.permissions.ask)
        else . end
      ' "${LOCAL_PATH}" <(printf '%s' "${MERGED_FRAGMENT}"))"
      printf '%s\n' "${UNMERGED}" > "${LOCAL_PATH}"
      info "Un-merged ${SLUG} entries from ${LOCAL_PATH}"
    fi ;;

  project-claude-md)
    info "project-claude-md removal is manual."
    info "  Manifest local-path: ${LOCAL_PATH}"
    info "  The project's CLAUDE.md may have been hand-edited since install;"
    info "  review and remove manually if appropriate." ;;

  *)
    err "Unknown type in manifest: ${TYPE}" ;;
esac

# Remove from manifest
UPDATED="$(jq --arg name "${SLUG}" 'del(.files[$name])' "${MANIFEST}")"
printf '%s\n' "${UPDATED}" > "${MANIFEST}"
info "Removed ${SLUG} from manifest"
