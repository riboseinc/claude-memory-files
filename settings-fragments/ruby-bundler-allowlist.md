---
schema-version: 1
name: ruby-bundler-allowlist
description: Permission allowlist for common Ruby/Bundler commands (bundle exec, rake, rubocop, rspec) — deep-merged into ~/.claude/settings.json.
type: settings-fragment
scope: team
target: ~/.claude/settings.json (permissions.allow merge)
autoload: false
tags: [settings, allowlist, ruby, bundler]
author:
  name: Nick Nicholas
  github: opoudjis
owners: [opoudjis]
license: MIT
version: 1.0.0
---

# Ruby + Bundler allowlist

Add to `~/.claude/settings.json.permissions.allow[]` the patterns that cover the routine Ruby / Bundler / RSpec / RuboCop commands run during gem development. Without this, every `bundle exec rspec` and `bundle exec rubocop` triggers a permission prompt.

## When to install

You're working on Ruby gems (especially Ribose-style ones — see `instructions/github-no-releases.md`) and want to stop being prompted on every common dev-loop command.

## What it does NOT cover

This allowlist is **read-and-test-only**. It does not authorise `gem build`, `gem push`, `rake release`, or any version-bumping operation — those should always be explicit per the `github-no-releases.md` convention.

## fragment

```json
{
  "permissions": {
    "allow": [
      "Bash(bundle exec:*)",
      "Bash(ruby -e:*)",
      "Bash(rake:*)",
      "Bash(rubocop:*)",
      "Bash(rspec:*)"
    ]
  }
}
```
