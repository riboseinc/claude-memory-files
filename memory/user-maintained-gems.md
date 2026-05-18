---
schema-version: 1
name: user-maintained-gems
description: Maintainer table for github-narrative-location + github-pr-assignment. Replace placeholders; Nick's metanorma row is the worked example.
type: memory-user
scope: personal-share
target: memory/user-maintained-gems.md
autoload: false
tags: [github, conventions, template]
author:
  name: Nick Nicholas
  github: opoudjis
owners: [opoudjis]
license: MIT
version: 1.0.0
---

# Gems you maintain, and default maintainers for the rest

This is a **`personal-share` template**. The skeleton is universal; the data is yours. Replace the placeholders and the worked-example rows with your own setup. Nick's metanorma list and default-maintainer table are kept below as a worked example — overwrite or extend.

**Consumed by:** `github-narrative-location.md`, `github-pr-assignment.md`. Both rules check this file to decide narrative routing and PR-assignment for any given repo.

## Your GitHub handle

```
<your-github-handle>
```

Replace `<your-github-handle>` with your handle (e.g. `opoudjis`, no `@`). Used by `github-pr-assignment.md` as the default assignee for PRs on gems you maintain.

## Gems / repos YOU maintain

List the gems and repos you maintain. PRs on these go to you for assignment and review; release-cadence rules apply per your team's conventions.

### EXAMPLE — Nick's metanorma list (replace with your own)

- `metanorma-*` — every `metanorma-<flavour>` and `metanorma-*-<tool>` repo under the `metanorma/` GitHub org (e.g. `metanorma-iso`, `metanorma-itu`, `metanorma-jis`, `metanorma-standoc`, `metanorma-cli`, `metanorma-core`, …)
  - **Exceptions:** `metanorma/pubid-*` and `metanorma/metanorma-plugin-*` are *not* maintained by this author — see default-maintainer table below.
- `isodoc`
- `isodoc-i18n`
- `relaton-render`

## Default maintainers for gems you do NOT maintain

For PRs against the following classes of repository, the default maintainer is the listed person. Use them as **both assignee and reviewer** when opening a PR there. If a specific repo within these classes has a different maintainer the user names explicitly, that override wins per-PR.

### EXAMPLE — Nick's default-maintainer table (replace/extend with your own)

| Repository / class | Default maintainer |
|---|---|
| `relaton/*` (except `relaton-render`, which Nick maintains) | `@andrew2net` |
| `plurimath/*` | `@suleman-uzair` |
| `lutaml/*` (lutaml-model, lutaml-path, lutaml-xsd, …) | `@HassanAkbar` |
| `lutaml/canon` (specific override inside `lutaml/`) | `@ronaldtse` |
| `metanorma.org` | `@ronaldtse` |
| `riboseinc/*` | `@ronaldtse` |
| `metanorma/pubid-*` | `@andrew2net` |
| `metanorma/metanorma-plugin-*` | `@kwkwan` |
| `metanorma/ci` (CI infrastructure) | `@ronaldtse` |

If the target repo doesn't fall into any row above and you have not maintained it directly, **ask the user** who the maintainer is before opening the PR.

## Heuristics are NOT permitted

**Do not infer maintenance from commit history, gemspec authors, or any other signal.** This file is the source of truth. When the question is "who maintains this repo?", consult this file. If the answer isn't here, ask the user — do not guess.

If a new repository appears or maintenance changes hands, this file is the right place to record it — append a row and bump the file's `version:` in frontmatter.
