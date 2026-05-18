---
schema-version: 1
name: feedback_external_docs_framing
description: "External Ruby-dev docs: scope statement, link out for inherited surface, cite POSIX/CLDR conventions, define deps + domain terms before use."
type: memory-feedback
scope: universal
target: memory/feedback_external_docs_framing.md
autoload: false
tags: [docs, external-docs, asciidoc, conventions, ruby]
author:
  name: Nick Nicholas
  github: opoudjis
owners: [opoudjis]
license: MIT
version: 1.0.0
---

# External-facing docs framing

For docs targeted at external Ruby developers (e.g. anyone who finds the gem on rubygems), not just maintainers and internal contributors:

- **Scope statement at the outset** — make explicit that the doc covers *only the additions* introduced by this gem, not the full prior surface (`strftime`, CLDR locale names, etc.). Readers should not be misled into thinking the page is the complete spec.
- **Link out, don't re-explain** — for the un-extended surface (vanilla `Date#strftime` directives, CLDR locale month/day names), cite the canonical online reference (Ruby's `Date#strftime` docs, twitter-cldr GitHub README) rather than embedding a partial duplicate.
- **Cite the borrowed conventions** — when the API piggy-backs on POSIX (`%E*`/`%O*`) or GNU strftime conventions, name the source. Readers should know the namespace wasn't invented in-house.
- **Don't assume reader vocabulary** — define dependencies the first time they appear (e.g. "twitter_cldr is the Ruby port of CLDR data…") and define domain terms ("an era is a regnal/calendar epoch like 令和…"). The audience is "any Ruby dev who finds the gem", not "someone who already works in this stack".

## How to apply

At the top of any external-facing reference doc, write a one-paragraph framing block that:

1. Names the new surface introduced by this gem/library.
2. Names the existing surface inherited and links to its canonical doc.
3. Introduces every dependency by short definition before first use.

For domain terms unfamiliar to a generalist Ruby dev, add a one-clause definition the first time they appear.
