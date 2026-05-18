---
schema-version: 1
name: feedback_pr_always_tagged_to_issue
description: Every PR must reference a source issue (Closes #N, Part of org/repo#N, etc.). Derive from session context first; ask only as last resort.
type: memory-feedback
scope: universal
target: memory/feedback_pr_always_tagged_to_issue.md
autoload: false
tags: [github, pr, issue]
author:
  name: Nick Nicholas
  github: opoudjis
owners: [opoudjis]
license: MIT
version: 1.0.0
---

# Every PR must be tagged to a source issue

**Universal rule: every PR must be tagged to a source issue.** The PR body must contain a reference to the issue that motivated the work (or that the PR partially closes), using one of GitHub's keyword forms: `Closes #N`, `Fixes #N`, `Resolves #N`, or non-closing references like `Part of org/repo#N`, `See #N`, `For #N`. The reference can be in the same repo (`#N`) or cross-repo (`org/repo#N`).

## Why

Linking the PR to its issue gives GitHub the bidirectional cross-reference (a "linked PR" entry appears in the issue's timeline) and lets reviewers find the strategic context in one click. Untagged PRs leave reviewers guessing why the change exists.

## How to apply

1. **Derive the issue from session context first.** In a multi-PR refactor, the strategic-ticket reference is usually obvious from prior conversation — reuse it. In a one-PR change, the user has usually mentioned an issue number or URL earlier in the session.
2. **If the issue isn't obvious, look briefly** (`gh issue list --search "<topic keywords>"` on the relevant repo) before asking. A 5-second search usually surfaces it.
3. **Ask the user** only if neither session context nor a quick `gh issue list` produces a clear match.
4. **Only skip the tag if the user has explicitly told you there's no issue** ("just push it, no ticket"). Even then, the PR body should briefly say *why* there's no issue (e.g. "Trivial typo, no ticket needed.") so reviewers know the omission is intentional.
5. **Use closing keywords (`Closes`/`Fixes`/`Resolves`) only when the PR fully closes the issue.** For multi-PR sequences where each PR addresses a slice, use `Part of org/repo#N` so the issue stays open until the last PR lands.

## Choice of phrasing

- One-PR-resolves-issue: `Closes #N` (or `Closes org/repo#N`).
- Multi-PR sequence: `Part of org/repo#N (Phase 3a — ...)` for the first/middle PRs; the final PR uses `Closes`.
- PR addresses an issue but doesn't fully resolve it (e.g. mitigation): `Mitigates #N` or `Addresses #N`.
