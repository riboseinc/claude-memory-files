---
schema-version: 1
name: feedback_metanorma_org_project_assignment
description: Incident-history memory supporting github-metanorma-project. Issues in metanorma/* repos must be added to org project #15 immediately after creation.
type: memory-feedback
scope: team
team: metanorma
target: memory/feedback_metanorma_org_project_assignment.md
autoload: false
tags: [github, metanorma, issue]
author:
  name: Nick Nicholas
  github: opoudjis
owners: [opoudjis]
license: MIT
version: 1.0.0
---

# metanorma-org issues auto-add to "Metanorma" project #15

When opening a new GitHub **issue** in a repo under the `metanorma/` organisation, also add it to the org-level "Metanorma" project so it shows up on the maintainer's dashboard. The project's number is **15** and its node ID is `PVT_kwDOAlieiM2dFg`. URL: <https://github.com/orgs/metanorma/projects/15>.

This memory file is the supporting incident-history record for the operational rule in `instructions/github-metanorma-project.md`.

## Why

The maintainer's dashboard view is filtered by membership of the "Metanorma" project to track in-flight metanorma-org work across the many repos in the org. Issues that aren't added to the project fall out of that dashboard and become invisible to daily planning, which forces a "where did that ticket go" lookup later. The user gave this directive explicitly on 2026-05-18 after an upstream issue in a Ribose-adjacent org was filed (outside scope — different org — so not retroactively applicable), to make the rule durable from that point on.

## How to apply

1. **Trigger.** Any `gh issue create --repo metanorma/<anything> ...` invocation. Covers every repo in the metanorma org — owned or not. The org boundary, not the maintainer status, defines the scope.
2. **Action.** Immediately after the `gh issue create` returns the issue URL, run:
   ```sh
   gh project item-add 15 --owner metanorma --url <issue-url>
   ```
   No prompt — automatic on every metanorma-org issue creation.
3. **Out of scope — do not apply to:**
   - **Pull requests.** Explicitly excluded.
   - **Comments.** `gh issue comment` doesn't create a new ticket; nothing to add.
   - **Other orgs.** Ribose-adjacent orgs (`lutaml/*`, `fontist/*`, `relaton/*`, `plurimath/*`, `riboseinc/*`) and any external org are explicitly outside scope.
4. **Token scope.** Adding to an org-level project requires the gh token to carry `project` scope. If `item-add` errors with a scope message, run `gh auth refresh -s project`.
5. **Failure modes to flag.** If `gh project item-add` fails (network, scope, project archived, item already present), surface the failure in narration — do not silently retry or skip. A silent miss defeats the dashboard's authoritativeness.

## Linked rules

- The operational instruction is `instructions/github-metanorma-project.md`.
- The parallel rule for PR assignees (separate concern: issues = project membership; PRs = assignee/reviewer) is `feedback_pr_always_assigned.md`.
