---
schema-version: 1
name: github-pr-title-issue-link
description: Embed the full issue URL in the PR title so GitHub renders the cross-reference card with the PR title visible on the issue timeline.
type: instruction
scope: universal
target: instructions/github-pr-title-issue-link.md
autoload: true
tags: [github, pr, issue]
author:
  name: Nick Nicholas
  github: opoudjis
owners: [opoudjis]
license: MIT
version: 1.0.0
---

# PR titles must embed the full issue URL for backlink rendering

When opening a pull request that resolves or addresses a GitHub issue, **embed the full issue URL inside the PR title itself**, in the form:

```
<short description>: <full https URL to the issue>
```

Examples from established practice that confirm the convention:

- `move isodoc loader to metanorma-core: https://github.com/metanorma/metanorma-standoc/issues/<id>`
- `move to Relaton 2.0: https://github.com/metanorma/metanorma-standoc/issues/<id>`
- `lookup cross-references to other documents on anchor as well as id: https://github.com/metanorma/<repo>/issues/<id>`

**Why.** Putting the issue URL in the **title** (not just the body) is what makes GitHub render the rich "cross-referenced this issue in pull request" backlink on the issue's timeline with the PR title visible. Body-only references, `Fixes #123` shorthand in the body, or full URLs in the body trigger a closing event or a plain reference event, but **do not** produce the title-rendered backlink expected on the issue page.

**How to apply.**

- Every PR opened that addresses an issue: title is `<description>: <full URL>`.
- Always use the **full https URL** (`https://github.com/<org>/<repo>/issues/<n>`), not the `#123` shorthand. The shorthand resolves but does not render the same way in the cross-reference card.
- Cross-repo references: same rule, full URL. The title-embedded URL is in fact the only form that renders cleanly when the PR and the issue are in different repos.
- The PR body can additionally use `Fixes <URL>` for auto-close behaviour; that is independent of the title rule and is unaffected by it.
- Applies to **every repo and every project** — this is a global GitHub convention.

**Direct commits to main / `Fixes` URL closure.** When work lands as a direct commit on the default branch rather than via PR, GitHub generates only the `closed` event and sometimes omits the visible "referenced this issue in commit X" line — that is the documented failure mode. There is no PR title to carry the URL in this case. Mitigation: post a follow-up comment on the issue linking the commit, so an explicit visible backlink exists on the timeline. This is a workaround for the no-PR path, not a substitute for the PR-title rule above.
