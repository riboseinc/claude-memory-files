---
schema-version: 1
name: github-metanorma-project
description: Issues created in any metanorma/* repo must be added to the org-level Metanorma project #15 via gh project item-add immediately after creation.
type: instruction
scope: team
team: metanorma
target: instructions/github-metanorma-project.md
autoload: true
tags: [github, metanorma, issue]
author:
  name: Nick Nicholas
  github: opoudjis
owners: [opoudjis]
license: MIT
version: 1.0.0
---

# metanorma-org issues: auto-add to the org-level "Metanorma" project

When creating a new **issue** in any repo under the `metanorma/` GitHub organisation, also add it to the org-level "Metanorma" project (project number **15**, node ID `PVT_kwDOAlieiM2dFg`, URL <https://github.com/orgs/metanorma/projects/15>) so the issue lands on the maintainer's dashboard.

## Scope

- **Issues only.** PRs are explicitly excluded — `gh pr create` does *not* trigger this rule. Comments on existing issues do not trigger it either (no new ticket created).
- **Every `metanorma/*` repo.** Owned-gem status is irrelevant; the org boundary defines the scope. Examples: `metanorma/metanorma-cli`, `metanorma/metanorma-standoc`, `metanorma/isodoc`, `metanorma/metanorma`, `metanorma/metanorma.org`, `metanorma/pubid-*`, `metanorma/metanorma-plugin-*`, etc.
- **Other orgs are out of scope** — Ribose-adjacent orgs (`lutaml/*`, `fontist/*`, `relaton/*`, `plurimath/*`, `riboseinc/*`) and any external org are not auto-added. If a corresponding rule is needed for another org, configure it separately.

## How to apply (mandatory, automatic)

Immediately after `gh issue create --repo metanorma/<repo> ...` returns the new issue URL, run:

```sh
gh project item-add 15 --owner metanorma --url <issue-url>
```

No prompt to the user — this is automatic on every metanorma-org issue creation. If the call fails (network, scope, project archived, already present), **surface the failure to the user in narration**; do not silently retry or skip, because a silent miss defeats the dashboard's authoritativeness.

## Token scope

`gh project item-add` requires the gh token to carry the `project` (write) scope. If the call errors with a scope message, ask the user to run `gh auth refresh -s project`.
