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

echo
echo "✓ All install/uninstall smoke tests passed"
