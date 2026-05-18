---
schema-version: 1
name: github-pr-assignment
description: Every PR must have an assignee at creation time. Pass --assignee to gh pr create; consult user-maintained-gems.md for who.
type: instruction
scope: universal
target: instructions/github-pr-assignment.md
autoload: true
tags: [github, pr, review]
author:
  name: Nick Nicholas
  github: opoudjis
owners: [opoudjis]
license: MIT
requires-companion: [user-maintained-gems]
version: 1.0.0
---

# PR assignment: never open a PR unassigned

Every PR created must have an assignee at creation time. Pass `--assignee <handle>` (and `--reviewer <handle>` for non-owned repos) to `gh pr create` directly — do not open the PR first and add the assignee after, since that's the documented failure mode this rule was created against.

## Branching logic

The single source of truth for "who maintains this gem" is your installed `~/.claude/memory/user-maintained-gems.md` companion file. Consult it before opening any PR in a repo whose ownership you're not certain about.

1. **PR on a gem you maintain** (per the "Gems you maintain" section of `user-maintained-gems.md`): assign to yourself. No reviewer required.
2. **PR on a non-owned gem whose class is in the default-maintainer table** in `user-maintained-gems.md`: set the listed person as **both assignee and reviewer**.
3. **PR on a repo not covered by either of the above**: ask the user who the maintainer is before opening the PR. Do not guess from commit history, gemspec authors, or recent activity — those heuristics are explicitly rejected.

## Why

Unassigned PRs are invisible on the maintainer's GitHub dashboard and get missed in the merge queue. For external-maintainer PRs, the reviewer flag also signals that action is expected. This rule has no exception — there is no scenario where an unassigned PR is acceptable.

## How to apply (concrete invocations)

- Owned-gem PR: `gh pr create --assignee <your-handle> --title "..." --body-file ...`.
- Non-owned-gem PR with maintainer in the table: `gh pr create --assignee <maintainer> --reviewer <maintainer> --title "..." --body-file ...`.
- Repo not in the table: stop, ask the user first, then `gh pr create` with the answer.
- Your own GitHub handle should be set in your installed `user-maintained-gems.md` — never `@me`, never inferred from `git config user.email`.

## Companion file requirement

This rule is inert without its companion `user-maintained-gems.md` installed and customised. The installer warns when a required companion is missing; see [SCHEMA.md `requires-companion:`](../SCHEMA.md).

This rule is in addition to source-issue tagging in the PR title (per `github-pr-title-issue-link.md`) and Claude attribution in the PR body (per `github-claude-attribution.md`) — those are separate conventions and all apply together.
