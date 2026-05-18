---
schema-version: 1
name: ruby-gem
description: "Starter CLAUDE.md for Ribose-style Ruby gem repos (Bundler + RSpec + RuboCop + batched release cadence)."
type: project-claude-md
scope: team
project-type: ruby-gem
target: <project>/CLAUDE.md
autoload: false
tags: [ruby, bundler, template, ribose]
author:
  name: Nick Nicholas
  github: opoudjis
owners: [opoudjis]
license: MIT
version: 1.0.0
---

# CLAUDE.md

This file provides guidance to Claude Code when working with code in this repository.

## Project overview

<One paragraph: what this gem does, what ecosystem it belongs to, key external
dependencies. Replace this placeholder.>

## Common commands

```bash
bundle install              # Install dependencies
bundle exec rake            # Default task (typically tests + lint)
bundle exec rake spec       # Run all tests
bundle exec rspec spec/path/to_spec.rb       # Run a single spec file
bundle exec rspec spec/path/to_spec.rb:42    # Run a single test by line number
bundle exec rubocop         # Lint
bundle exec rubocop -a      # Lint with auto-correct
```

## Architecture

<Replace with a description of the main moving parts. Style guide:
- One short subsection per concept area (core models, parsing, rendering, CLI…).
- Reference key classes with markdown links to file:line, e.g. [ClassName](lib/path/to/file.rb).
- Show representative usage in code blocks where it aids understanding.
- See worked examples at relaton-bib/CLAUDE.md, suma/CLAUDE.md.>

### <Concept area 1, e.g. Core models / Pipeline / Public API>

<placeholder>

### <Concept area 2, e.g. Parsing / Persistence / Wiring>

<placeholder>

## Code style

- Ruby version target: **<fill in, e.g. 3.0+, 3.1+>**.
- `frozen_string_literal: true` at the top of every Ruby file.
- RuboCop inheriting from the riboseinc OSS guide via `.rubocop.yml`.
- YARD documentation comments for public API.

## Release cadence

This gem ships as part of a **batched release** (Ribose convention). Do not bump
`lib/<gem-name>/version.rb`, and do not run `gem build`, `gem push`, or
`rake release` unless explicitly instructed.

---

*This template is a starter. Replace bracketed placeholders, prune sections that
don't apply, and add project-specific gotchas as the codebase teaches them.*
