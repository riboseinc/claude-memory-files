---
schema-version: 1
name: github-cli-reads-allowlist
description: Read-only gh CLI allowlist (issue view, pr view/list, api, repo view) for ~/.claude/settings.json. No write operations.
type: settings-fragment
scope: team
target: ~/.claude/settings.json (permissions.allow merge)
autoload: false
tags: [settings, allowlist, github, cli]
author:
  name: Nick Nicholas
  github: opoudjis
owners: [opoudjis]
license: MIT
version: 1.0.0
---

# GitHub CLI read-only allowlist

Add to `~/.claude/settings.json.permissions.allow[]` the patterns that cover read-only `gh` CLI invocations: viewing issues, listing PRs, reading API responses, inspecting repo metadata. These are the calls that come up constantly when investigating GitHub state — and without an allowlist, each one triggers a permission prompt.

## Scope

**Read-only.** Deliberately excludes write operations:

- No `gh pr create`, `gh pr merge`, `gh pr close`, `gh pr edit`.
- No `gh issue create`, `gh issue close`, `gh issue edit`, `gh issue comment`.
- No `gh api -X PATCH` or `gh api -X POST` against state-changing endpoints.
- No `gh project item-add` or other org-level mutations.

Write operations should remain prompt-gated; they're the ones the user wants to consciously approve.

## What's allowed

| Pattern | Purpose |
|---|---|
| `Bash(gh issue *)` | covers `gh issue view`, `gh issue list`; `gh issue create/close/edit` need separate explicit prompts |
| `Bash(gh pr view:*)` | read a PR's metadata, body, files, status |
| `Bash(gh pr list:*)` | list PRs with filters |
| `Bash(gh api:*)` | direct API queries (GET only via this pattern — `-X PATCH/POST` still needs `Bash(gh api -X *)` which isn't in this allowlist) |
| `Bash(gh repo view:*)` | inspect repo metadata |

NOTE: `Bash(gh issue *)` is broader than the others by design — it covers both `view` and `list`. If you want stricter scoping, replace it with `Bash(gh issue view:*)` + `Bash(gh issue list:*)`.

## fragment

```json
{
  "permissions": {
    "allow": [
      "Bash(gh issue *)",
      "Bash(gh pr view:*)",
      "Bash(gh pr list:*)",
      "Bash(gh api:*)",
      "Bash(gh repo view:*)"
    ]
  }
}
```
