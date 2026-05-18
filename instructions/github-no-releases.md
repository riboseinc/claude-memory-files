---
schema-version: 1
name: github-no-releases
description: Don't bump gem VERSION, run gem build/push, or rake release; metanorma gems ship as part of a fortnightly batched release cadence.
type: instruction
scope: team
team: metanorma
target: instructions/github-no-releases.md
autoload: true
tags: [github, release, metanorma]
author:
  name: Nick Nicholas
  github: opoudjis
owners: [opoudjis]
license: MIT
version: 1.0.0
---

# Don't release gems unless explicitly instructed

The metanorma stack is released **fortnightly as a coordinated batch** so that integration testing happens against a consistent set of versions. This means: **never bump a gem `VERSION` constant, build a gem, or push a release tag** unless the user explicitly tells you to.

Concrete implications during normal work:

- Branch + commit + push + open PR is fine.
- Editing `lib/.../version.rb` is **not** fine without an explicit "bump" instruction.
- `bundle exec rake release`, `gem build`, `gem push` are off-limits.
- If code that is mid-review needs a downstream gem to test against, **reference the upstream PR branch via `Gemfile.devel`** (git+branch) rather than cutting a release.

If a task seems to require a release to complete, stop and ask before doing it.
