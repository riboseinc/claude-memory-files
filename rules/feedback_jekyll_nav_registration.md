---
schema-version: 1
name: feedback_jekyll_nav_registration
description: New Jekyll doc pages must be registered in the layout's navigation YAML; the sidebar is hand-maintained, not directory-walked.
type: path-rule
scope: team
target: rules/feedback_jekyll_nav_registration.md
autoload: false
tags: [jekyll, docs, nav]
author:
  name: Nick Nicholas
  github: opoudjis
owners: [opoudjis]
license: MIT
paths:
  - _config.yml
  - "_layouts/**"
  - "_includes/**"
  - "*.adoc"
version: 1.0.0
---

# Jekyll nav registration on new doc pages

When adding a new page to a Jekyll-based docs site, the sidebar / TOC is not auto-discovered from the filesystem — it's driven by a `navigation:` YAML frontmatter block at the top of the relevant layout file (e.g. `_layouts/develop-docs.html`, `_layouts/author-docs.html`). A new content page renders at its URL but is unreachable from the sidebar unless the layout's navigation list is also updated.

**Always update both files in the same commit.**

## Why

Many metanorma-ecosystem docs sites use a hand-maintained navigation tree rather than directory-walking. Without the layout edit, the new page is effectively invisible to users who navigate the site through its menus — they would only land on it via a direct link. Flagged 2026-05-11.

## How to apply

1. When adding a new `.adoc` page under `author/topics/`, `develop/topics/`, or any other layout-bound section, identify the relevant layout file in `_layouts/` (`author-docs.html`, `develop-docs.html`, etc.).
2. Open that layout file and locate the `navigation:` YAML block at the top.
3. Add an entry under the appropriate `items:` list with the page's `title:` and `path:` (path is the URL slug, e.g. `/topics/date-formatting/`, NOT the filesystem path).
4. Place the new entry alphabetically or thematically near related pages — match the surrounding ordering convention rather than appending at the end.
5. Include this layout edit in the same commit as the new `.adoc` file.

## Scope

Applies to Jekyll-based docs sites in the metanorma ecosystem that use a hand-maintained nav frontmatter (e.g. `jekyll-theme-open-project`). Sites using auto-discovered nav (e.g. Just the Docs frontmatter-driven sidebar) don't need this rule — the `paths:` glob will still match, but the rule is informational rather than required.

This rule auto-loads only when Jekyll site files are in scope (`_config.yml`, `_layouts/**`, `_includes/**`, `*.adoc`) — Anthropic's native `.claude/rules/` path-scoping.
