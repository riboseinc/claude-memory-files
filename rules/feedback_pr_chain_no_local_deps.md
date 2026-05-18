---
schema-version: 1
name: feedback_pr_chain_no_local_deps
description: "Cross-repo Ruby PR sequences: downstream Gemfile.devel uses git+branch upstream PR ref, not bundle config local.* or path: Gemfile entries."
type: path-rule
scope: team
target: rules/feedback_pr_chain_no_local_deps.md
autoload: false
tags: [bundler, ruby, gemfile, pr]
author:
  name: Nick Nicholas
  github: opoudjis
owners: [opoudjis]
license: MIT
paths:
  - Gemfile
  - Gemfile.devel
  - "*.gemspec"
version: 1.0.0
---

# Sequential PR chains: Gemfile.devel branch refs, never local bundler overrides

When sequencing PRs across repos in a Ruby stack (e.g. an upstream gem PR consumed by a downstream gem PR), the cross-repo handshake is a `gem "<upstream-gem>", git: "https://github.com/<org>/<repo>", branch: "<pr-branch>"` line in the downstream `Gemfile.devel`. Never use `bundle config set --local local.<gem> <path>` or `gem "...", path: "../..."` Gemfile entries as a substitute, even as a "just for this dev loop" shortcut.

## Why

The dependency chain must be captured upstream early — visible on GitHub, reviewable in the PR diff, surviving a fresh checkout. Local-path overrides are invisible on GitHub, silently route around the published chain, and risk leaking via committed `Gemfile.lock` or `.bundle/config`. This rule was created after such a local dependency leaked to GitHub on 2026-05-11.

## How to apply

1. Commit the upstream PR's feature branch first; push to GitHub; open the upstream PR.
2. Edit the downstream repo's `Gemfile.devel` to add/update the `gem ..., git: ..., branch: "<pr-branch>"` line.
3. `bundle install` (or `bundle update <upstream-gem>`) in the downstream repo to refresh the lock to the PR branch's HEAD.
4. Run downstream tests against the PR branch.
5. Commit + push + open the downstream PR; the `Gemfile.devel` pointer travels with it.

If a quick local sanity check before the upstream is push-ready is genuinely unavoidable, `bundle config set --local local.<gem> <path>` is the least-bad escape hatch — but flag it to the user up front, unset (`bundle config unset local.<gem>`) before any commit/push, and never commit `.bundle/config`.

This rule auto-loads only when bundler-related files are in scope (`Gemfile`, `Gemfile.devel`, `*.gemspec`) — Anthropic's native `.claude/rules/` path-scoping.
