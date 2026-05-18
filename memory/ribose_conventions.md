---
schema-version: 1
name: ribose_conventions
description: "Ribose-org conventions for shared content: MS Teams (not Slack), redact non-Ribose names, AsciiDoc docs default, periodic memory review."
type: memory-feedback
scope: team
target: memory/ribose_conventions.md
autoload: false
tags: [ribose, conventions]
author:
  name: Nick Nicholas
  github: opoudjis
owners: [opoudjis]
license: MIT
version: 1.0.0
---

# Ribose org working conventions

When producing content for Ribose orgs (`riboseinc/*`, `metanorma/*`, `lutaml/*`, `plurimath/*`, `relaton/*`) or content shared with Ribose colleagues, apply the following conventions. They surfaced during the design of this repo (May 2026) after repeated corrections.

## 1. Messaging platform: Microsoft Teams, not Slack

In any example or narration referencing a messaging platform inside Ribose-facing content, use **Microsoft Teams**. Ribose runs on Microsoft Teams; Slack is an AI-default that misrepresents the stack.

**How to apply:** When drafting GitHub issue/PR bodies, comments, or documentation for Ribose repos, the messaging-platform example should be Microsoft Teams. If neither MS Teams nor a specific platform actually matters, prefer the generic "team chat" framing.

## 2. External project names redacted in Ribose-facing content

Do not expose specific project names from work outside the Ribose orgs (any external-org project, day-job projects external to Ribose, etc.) in Ribose-org-facing content. Replace with **"non-Ribose activity"** or context-generic phrasing.

**How to apply:** When writing GitHub content, plan files, or shared documentation for a Ribose project, scan drafts for external project names before posting and redact. The rule applies to **shared** content; personal memory files in `~/.claude/` retain specific names because they're for personal reference.

## 3. Documentation: AsciiDoc, not Markdown

For Ribose project documentation sites and longer-form rendered docs, default to **AsciiDoc** (`*.adoc`, `jekyll-asciidoc` plugin, AsciiDoc-flavoured callouts and cross-references). Ribose is an AsciiDoc house. The concrete precedent is `lutaml/canon` (published at `lutaml.org/canon`), which uses Jekyll + Just the Docs + `jekyll-asciidoc`.

**How to apply:** When proposing a new doc site, generator, or longer-form document for a Ribose project, default to AsciiDoc. Content files whose format is fixed by external constraint (`CLAUDE.md` and `~/.claude/*/*.md` are mandated Markdown by Claude Code) stay Markdown — that's not a choice. But any new doc surface where the format is open defaults to AsciiDoc.

## 4. Periodic memory review for shared-repo promotion

Once this repo is live (v1 implementation in progress as of May 2026), each developer's local `~/.claude/memory/` and `~/.claude/instructions/` continue to grow. Periodically review them and identify files worth promoting here as team standards.

**How to apply:** Cadence suggested quarterly or at natural milestones. At each pass, walk `~/.claude/memory/` and `~/.claude/instructions/` and identify files that (a) are durable over multiple sessions/projects, (b) generalise beyond personal idiom, (c) have a clear scope (`universal`/`team`/`personal-share`), and (d) don't already exist in the shared repo. A `/review-memory-for-promotion` slash command is on the v1.1 roadmap.

---

Originating event: design and implementation of this repo, May 2026. See [issue #1](https://github.com/riboseinc/claude-memory-files/issues/1) and [issue #2](https://github.com/riboseinc/claude-memory-files/issues/2) for the design history.
