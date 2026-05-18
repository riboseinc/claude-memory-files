---
schema-version: 1
name: web-research-allowlist
description: Web research allowlist (WebSearch + WebFetch against Anthropic and GitHub docs) for ~/.claude/settings.json. Read-only sources.
type: settings-fragment
scope: universal
target: ~/.claude/settings.json (permissions.allow merge)
autoload: false
tags: [settings, allowlist, web]
author:
  name: Nick Nicholas
  github: opoudjis
owners: [opoudjis]
license: MIT
version: 1.0.0
---

# Web research allowlist

Add to `~/.claude/settings.json.permissions.allow[]` the baseline web-research permissions: `WebSearch` plus `WebFetch` against canonical documentation domains (Anthropic docs, GitHub). Without this, every documentation lookup or web search triggers a permission prompt during normal investigation.

## Scope

**Read-only documentation sources.** Each `WebFetch(domain:...)` entry is scoped to a single hostname — the model can fetch any URL on that host but cannot fetch elsewhere without a separate prompt.

The baseline covers:

- `WebSearch` — the model's web search capability (no domain restriction; results are surfaced to the user, not auto-fetched in detail).
- `WebFetch(domain:docs.anthropic.com)` — Anthropic API documentation.
- `WebFetch(domain:code.claude.com)` — Claude Code documentation, plugin docs, memory docs.
- `WebFetch(domain:github.com)` — GitHub repos, PRs, issues, raw file contents.

## Extending

For project-specific documentation domains (your gem's docs site, an internal docs portal), add `WebFetch(domain:your-domain.example)` entries to your own `~/.claude/settings.json` directly. Don't fork this seed for that — your team's domains aren't generally shareable.

For broader web access, consider whether the prompt-per-domain workflow is actually a problem for you before allowlisting; broad `WebFetch` allowlists make it easier for the model to fetch from unexpected sources.

## fragment

```json
{
  "permissions": {
    "allow": [
      "WebSearch",
      "WebFetch(domain:docs.anthropic.com)",
      "WebFetch(domain:code.claude.com)",
      "WebFetch(domain:github.com)"
    ]
  }
}
```
