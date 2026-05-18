---
schema-version: 1
name: feedback_pr_always_assigned
description: "PR-ownership discipline: never open a PR unassigned. Owned gems → self; non-owned gems → maintainer per user-maintained-gems.md."
type: memory-feedback
scope: team
target: memory/feedback_pr_always_assigned.md
autoload: false
tags: [github, pr, review]
author:
  name: Nick Nicholas
  github: opoudjis
owners: [opoudjis]
license: MIT
requires-companion: [user-maintained-gems]
version: 1.0.0
---

# Never open a PR unassigned

**Universal rule: do not open any PR unassigned.** Always pass `--assignee <handle>` to `gh pr create` (or `gh pr edit <PR#> --add-assignee <handle>` immediately after).

## Branching logic

The single source of truth for "who maintains this gem" is the companion file `user-maintained-gems.md`. Consult it before opening any PR in a repo whose ownership is uncertain.

1. **PR on a gem you maintain** (per the "Gems you maintain" section of `user-maintained-gems.md`): assign to yourself.
2. **PR on a gem you do *not* maintain whose class is in the default-maintainer table** in `user-maintained-gems.md`: set the listed person as **both assignee and reviewer** without prompting the user. Pass `--assignee <maintainer> --reviewer <maintainer>` to `gh pr create`.
3. **PR on a repo not covered by either of the above**: ask the user who the maintainer is *before* opening the PR. Once they name the maintainer, assign and request review.

## Why

Unassigned PRs are invisible on the maintainer's GitHub dashboard and get missed in the merge queue. For external-maintainer PRs, the reviewer flag also tells them action is expected.

## How to apply

- `gh pr create --assignee <your-handle> --title "..." --body-file ...` for owned-gem PRs.
- `gh pr create --assignee <maintainer> --reviewer <maintainer> --title "..." --body-file ...` for non-owned-gem PRs whose class is in the default-maintainer table.
- Your own GitHub handle should be set as `<your-github-handle>` in your installed `user-maintained-gems.md` — never `@me`.
- This rule is in addition to source-issue tagging in the PR body (see `feedback_pr_always_tagged_to_issue`), which is a separate convention.

**Exception:** none. There is no scenario where an unassigned PR is acceptable.

Companion file `user-maintained-gems.md` must be installed and customised for this rule to be operational.
