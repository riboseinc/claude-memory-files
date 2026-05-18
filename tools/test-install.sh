#!/usr/bin/env bash
# tools/test-install.sh — end-to-end smoke test for install.sh and uninstall.sh.
#
# Sandboxes CLAUDE_DIR under a temp dir, exercises one install per type using
# --repo-root (so we read the PR's committed files, not whatever is on
# main), verifies the manifest and on-disk state, then uninstalls all and
# verifies clean state. Includes the hand-curated-entry preservation test
# for settings-fragments.
#
# Usage: tools/test-install.sh
#
# Exits 0 on success, non-zero on any failure.

set -euo pipefail

cd "$(dirname "$0")/.."
REPO_ROOT="$(pwd)"

SANDBOX="$(mktemp -d)"
PROJECT="$(mktemp -d)"
trap 'rm -rf "${SANDBOX}" "${PROJECT}"' EXIT

export CLAUDE_DIR="${SANDBOX}"

INSTALL="${REPO_ROOT}/tools/install.sh"
UNINSTALL="${REPO_ROOT}/tools/uninstall.sh"

fail() { echo "FAIL: $*" >&2; exit 1; }
pass() { echo "  ✓ $*"; }
header() { echo; echo "=== $* ==="; }

# Test 1: install one of each type
header "Install one of each type"

"${INSTALL}" --repo-root "${REPO_ROOT}" instructions/github-pr-title-issue-link.md >/dev/null
[[ -f "${SANDBOX}/instructions/github-pr-title-issue-link.md" ]] \
  || fail "instruction file not installed"
grep -qF "@instructions/github-pr-title-issue-link.md" "${SANDBOX}/CLAUDE.md" \
  || fail "@-include not appended to CLAUDE.md"
pass "instruction installed + @-include appended"

"${INSTALL}" --repo-root "${REPO_ROOT}" memory/feedback_pr_always_tagged_to_issue.md >/dev/null
[[ -f "${SANDBOX}/memory/feedback_pr_always_tagged_to_issue.md" ]] \
  || fail "memory file not installed"
pass "memory-feedback installed"

"${INSTALL}" --repo-root "${REPO_ROOT}" settings-fragments/common-unix-reads-allowlist.md >/dev/null
[[ -f "${SANDBOX}/settings.json" ]] || fail "settings.json not created"
jq -e '.permissions.allow | index("Bash(grep:*)")' "${SANDBOX}/settings.json" >/dev/null \
  || fail "settings-fragment entry not merged"
pass "settings-fragment deep-merged"

"${INSTALL}" --repo-root "${REPO_ROOT}" rules/feedback_pr_chain_no_local_deps.md >/dev/null
[[ -f "${SANDBOX}/rules/feedback_pr_chain_no_local_deps.md" ]] \
  || fail "path-rule file not installed"
pass "path-rule installed"

"${INSTALL}" --repo-root "${REPO_ROOT}" --project "${PROJECT}" project-claude-md/ruby-gem.md >/dev/null
[[ -f "${PROJECT}/CLAUDE.md" ]] || fail "project CLAUDE.md not installed"
grep -qF "Common commands" "${PROJECT}/CLAUDE.md" \
  || fail "project CLAUDE.md body content missing"
! grep -qF "schema-version:" "${PROJECT}/CLAUDE.md" \
  || fail "frontmatter not stripped from project CLAUDE.md"
pass "project-claude-md installed (frontmatter stripped)"

# Test 2: manifest schema
header "Manifest schema check"

MANIFEST="${SANDBOX}/.memory-files-manifest.json"
[[ -f "${MANIFEST}" ]] || fail "manifest not created"

ENTRY_COUNT="$(jq '.files | length' "${MANIFEST}")"
[[ "${ENTRY_COUNT}" -eq 5 ]] || fail "expected 5 manifest entries, got ${ENTRY_COUNT}"
pass "manifest has 5 entries"

for slug in github-pr-title-issue-link feedback_pr_always_tagged_to_issue \
            common-unix-reads-allowlist feedback_pr_chain_no_local_deps ruby-gem; do
  for field in type installed-at installed-hash upstream-ref source-path local-path forked history; do
    jq -e --arg s "${slug}" --arg f "${field}" '.files[$s] | has($f)' "${MANIFEST}" >/dev/null \
      || fail "manifest ${slug} missing field: ${field}"
  done
done
pass "every manifest entry has all PR-9 fields populated"

# Settings-fragment entry must have merged-fragment recorded
jq -e '.files["common-unix-reads-allowlist"]["merged-fragment"].permissions.allow' "${MANIFEST}" >/dev/null \
  || fail "settings-fragment merged-fragment not recorded"
pass "settings-fragment merged-fragment recorded for uninstall"

# Test 3: hand-curated-entry preservation
header "Hand-curated-entry preservation on settings-fragment uninstall"

# Append a hand-added entry the user didn't get from the seed
TMP_SETTINGS="$(mktemp)"
jq '.permissions.allow += ["Bash(rg:*)"]' "${SANDBOX}/settings.json" > "${TMP_SETTINGS}"
mv "${TMP_SETTINGS}" "${SANDBOX}/settings.json"

"${UNINSTALL}" common-unix-reads-allowlist >/dev/null

jq -e '.permissions.allow | index("Bash(rg:*)")' "${SANDBOX}/settings.json" >/dev/null \
  || fail "hand-added Bash(rg:*) was incorrectly removed on uninstall"
jq -e '.permissions.allow | index("Bash(grep:*)") == null' "${SANDBOX}/settings.json" >/dev/null \
  || fail "manifest-recorded Bash(grep:*) survived uninstall"
pass "hand-added entry survived; manifest-recorded entries removed"

# Test 4: uninstall the rest, verify clean state
header "Uninstall remaining types"

"${UNINSTALL}" github-pr-title-issue-link >/dev/null
[[ ! -f "${SANDBOX}/instructions/github-pr-title-issue-link.md" ]] || fail "instruction not removed"
! grep -qF "@instructions/github-pr-title-issue-link.md" "${SANDBOX}/CLAUDE.md" \
  || fail "@-include not stripped from CLAUDE.md"
pass "instruction removed + @-include stripped"

"${UNINSTALL}" feedback_pr_always_tagged_to_issue >/dev/null
[[ ! -f "${SANDBOX}/memory/feedback_pr_always_tagged_to_issue.md" ]] || fail "memory not removed"
pass "memory removed"

"${UNINSTALL}" feedback_pr_chain_no_local_deps >/dev/null
[[ ! -f "${SANDBOX}/rules/feedback_pr_chain_no_local_deps.md" ]] || fail "path-rule not removed"
pass "path-rule removed"

"${UNINSTALL}" ruby-gem >/dev/null  # manual; just removes manifest entry
pass "project-claude-md manifest entry removed (file kept per manual policy)"

FINAL_COUNT="$(jq '.files | length' "${MANIFEST}")"
[[ "${FINAL_COUNT}" -eq 0 ]] || fail "manifest not empty after all uninstalls (${FINAL_COUNT} left)"
pass "manifest empty after all uninstalls"

# Test 5: --update flow (drift detection + decision matrix)
header "Update: clean local + version bump → overwrite"

# Install fresh
"${INSTALL}" --repo-root "${REPO_ROOT}" instructions/github-pr-title-issue-link.md >/dev/null
ORIG_HASH="$(jq -r '.files["github-pr-title-issue-link"]["installed-hash"]' "${MANIFEST}")"

# Build a fake "upstream" with the file mutated to v1.1.0
UPSTREAM_DIR="$(mktemp -d)"
mkdir -p "${UPSTREAM_DIR}/instructions"
cp "${REPO_ROOT}/instructions/github-pr-title-issue-link.md" "${UPSTREAM_DIR}/instructions/"
sed -i.bak 's/^version: 1\.0\.0$/version: 1.1.0/' "${UPSTREAM_DIR}/instructions/github-pr-title-issue-link.md"
rm -f "${UPSTREAM_DIR}/instructions/github-pr-title-issue-link.md.bak"
echo "" >> "${UPSTREAM_DIR}/instructions/github-pr-title-issue-link.md"
echo "*[Update smoke test: extra body line]*" >> "${UPSTREAM_DIR}/instructions/github-pr-title-issue-link.md"

"${INSTALL}" --update --repo-root "${UPSTREAM_DIR}" github-pr-title-issue-link >/dev/null
NEW_HASH="$(jq -r '.files["github-pr-title-issue-link"]["installed-hash"]' "${MANIFEST}")"
[[ "${NEW_HASH}" != "${ORIG_HASH}" ]] || fail "manifest hash should change after update"
HIST_COUNT="$(jq '.files["github-pr-title-issue-link"].history | length' "${MANIFEST}")"
[[ "${HIST_COUNT}" -eq 2 ]] || fail "expected 2 history events after update, got ${HIST_COUNT}"
LAST_EVENT="$(jq -r '.files["github-pr-title-issue-link"].history[-1].event' "${MANIFEST}")"
[[ "${LAST_EVENT}" == "update" ]] || fail "last history event should be 'update', got '${LAST_EVENT}'"
pass "clean local + version bump → overwrite + manifest history appended"

rm -rf "${UPSTREAM_DIR}"

header "Update: edited local → abort (without --force)"

# Hand-edit the installed file to simulate user edits
echo "" >> "${SANDBOX}/instructions/github-pr-title-issue-link.md"
echo "*[Local hand-edit]*" >> "${SANDBOX}/instructions/github-pr-title-issue-link.md"

UPSTREAM_DIR2="$(mktemp -d)"
mkdir -p "${UPSTREAM_DIR2}/instructions"
cp "${REPO_ROOT}/instructions/github-pr-title-issue-link.md" "${UPSTREAM_DIR2}/instructions/"
sed -i.bak 's/^version: 1\.0\.0$/version: 1.2.0/' "${UPSTREAM_DIR2}/instructions/github-pr-title-issue-link.md"
rm -f "${UPSTREAM_DIR2}/instructions/github-pr-title-issue-link.md.bak"
echo "*[Another upstream bump]*" >> "${UPSTREAM_DIR2}/instructions/github-pr-title-issue-link.md"

OUTPUT=$("${INSTALL}" --update --repo-root "${UPSTREAM_DIR2}" github-pr-title-issue-link 2>&1)
echo "${OUTPUT}" | grep -qi "aborted" || fail "expected abort message; got: ${OUTPUT}"
pass "edited local → abort without --force"

header "Update: --force overrides abort on edited local"

"${INSTALL}" --update --force --repo-root "${UPSTREAM_DIR2}" github-pr-title-issue-link >/dev/null
HIST_COUNT_AFTER="$(jq '.files["github-pr-title-issue-link"].history | length' "${MANIFEST}")"
[[ "${HIST_COUNT_AFTER}" -eq 3 ]] || fail "expected 3 history events after --force update, got ${HIST_COUNT_AFTER}"
pass "--force overrides abort; manifest history appended"

rm -rf "${UPSTREAM_DIR2}"

header "Update: personal-share is no-op without --upstream"

"${INSTALL}" --repo-root "${REPO_ROOT}" memory/user-maintained-gems.md >/dev/null
[[ "$(jq -r '.files["user-maintained-gems"].forked' "${MANIFEST}")" == "true" ]] \
  || fail "personal-share should be marked forked: true"

PS_HASH_BEFORE="$(jq -r '.files["user-maintained-gems"]["installed-hash"]' "${MANIFEST}")"

UPSTREAM_DIR3="$(mktemp -d)"
mkdir -p "${UPSTREAM_DIR3}/memory"
cp "${REPO_ROOT}/memory/user-maintained-gems.md" "${UPSTREAM_DIR3}/memory/"
sed -i.bak 's/^version: 1\.0\.0$/version: 1.1.0/' "${UPSTREAM_DIR3}/memory/user-maintained-gems.md"
rm -f "${UPSTREAM_DIR3}/memory/user-maintained-gems.md.bak"
echo "" >> "${UPSTREAM_DIR3}/memory/user-maintained-gems.md"
echo "[Upstream addition for forked test]" >> "${UPSTREAM_DIR3}/memory/user-maintained-gems.md"

OUTPUT=$("${INSTALL}" --update --repo-root "${UPSTREAM_DIR3}" user-maintained-gems 2>&1)
echo "${OUTPUT}" | grep -q "no-op for forked" || fail "expected no-op message; got: ${OUTPUT}"
PS_HASH_AFTER="$(jq -r '.files["user-maintained-gems"]["installed-hash"]' "${MANIFEST}")"
[[ "${PS_HASH_BEFORE}" == "${PS_HASH_AFTER}" ]] || fail "personal-share hash should not change on no-op update"
pass "personal-share --update is no-op without --upstream"

header "Update: --upstream forces overwrite of personal-share"

"${INSTALL}" --update --upstream --repo-root "${UPSTREAM_DIR3}" user-maintained-gems >/dev/null
PS_HASH_FINAL="$(jq -r '.files["user-maintained-gems"]["installed-hash"]' "${MANIFEST}")"
[[ "${PS_HASH_FINAL}" != "${PS_HASH_BEFORE}" ]] || fail "personal-share hash should change with --upstream"
pass "personal-share --update --upstream overwrites the local fork"

rm -rf "${UPSTREAM_DIR3}"

# Clean up update-test installs
"${UNINSTALL}" github-pr-title-issue-link >/dev/null
"${UNINSTALL}" user-maintained-gems >/dev/null

echo
echo "✓ All install/uninstall/update smoke tests passed"
