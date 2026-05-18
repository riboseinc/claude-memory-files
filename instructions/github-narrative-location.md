---
schema-version: 1
name: github-narrative-location
description: Narrative goes in ticket comments for gems you maintain, in PR descriptions otherwise. Mechanism universal; data in companion file.
type: instruction
scope: universal
target: instructions/github-narrative-location.md
autoload: true
tags: [github, pr, conventions]
author:
  name: Nick Nicholas
  github: opoudjis
owners: [opoudjis]
license: MIT
requires-companion: [user-maintained-gems]
version: 1.0.0
---

# Narrative goes in tickets for owned gems, in PR descriptions for everything else

The canonical list of gems you maintain — and the default maintainers for the rest — lives in your installed `~/.claude/memory/user-maintained-gems.md` (a companion file you install alongside this rule). Always consult that file when deciding which bucket a repo falls into.

## For gems you maintain

The detailed change narrative — diagnosis, refactor rationale, per-file changes, verification — belongs in **issue/ticket comments** on the relevant repo. PR descriptions stay concise (one or two lines pointing at the ticket). Reason: the full history of a change should be accessible in one place per ticket, not split between PR and ticket.

When writing the ticket-comment narrative for an owned gem, prefer multiple focused comments over one long wall of text — e.g. one comment for diagnosis, one for refactor, one for per-gem changes — when the change touches enough surface to warrant it.

**Tone for owned-gem tickets: internal-team voice.** No defensive context-setting, no backwards-compat reassurance, no "rationale" prose for things the maintainer already knows. Wordy is fine; six-paragraph walls of text aren't.

## For gems maintained by other people

Write the **detailed narrative in the PR description** (existing default behaviour). The PR is the visible artefact for outside maintainers; tickets in their tracker may not exist or may not be the primary discussion surface.

## If a target repo isn't covered

Ask the user before authoring the PR. Don't guess.

## Companion file requirement

This rule is inert without its companion `user-maintained-gems.md` installed and customised. The installer warns when a required companion is missing; see [SCHEMA.md `requires-companion:`](../SCHEMA.md).
