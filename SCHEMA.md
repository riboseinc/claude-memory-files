# Frontmatter schema

Every content file in this repo (under `instructions/`, `memory/`, `settings-fragments/`, `project-claude-md/`, `rules/`) starts with a YAML frontmatter block matching the schema below. The validator at `_meta/validate.mjs` (shipping with PR 2) enforces this against `_meta/schema.json`.

## Full contract

```yaml
---
schema-version: 1                      # integer; defaults to 1 if omitted. Bumped only on
                                       # breaking schema changes; additive changes are lazy.
name: kebab-case-slug                  # must match filename minus .md; unique across repo.
description: One-line summary          # ≤140 chars; used in README and slash-command picker.
type: instruction
    | memory-feedback | memory-reference | memory-project | memory-user
    | settings-fragment | project-claude-md | path-rule | hook
scope: universal | team | personal-share
team: metanorma                        # optional; only meaningful with scope: team. Names the
                                       # specific team this norm belongs to. Omit (or "any")
                                       # for generic team practice that any team could adopt.
target:                                # where the file lands; semantics depend on type:
                                       #   instruction       → ~/.claude/instructions/<name>.md (+ @-include)
                                       #   memory-*          → ~/.claude/memory/<name>.md
                                       #   settings-fragment → deep-merge into ~/.claude/settings.json
                                       #   project-claude-md → <project>/CLAUDE.md
                                       #   path-rule         → ~/.claude/rules/<name>.md
                                       #   hook              → ~/.claude/hooks/<name>/ (v2 only)
autoload: true | false                 # forced true for type: instruction; forced false otherwise.
tags: [github, pr]                     # 1–5 tags from _meta/tags.txt.
author:
  name: Nick Nicholas
  github: opoudjis
owners: [opoudjis]                     # GitHub handles allowed to merge changes.
                                       # Defaults to [author.github]. For scope: personal-share,
                                       # validator enforces owners == [author.github] (length 1).
license: MIT                           # SPDX; defaults to MIT if omitted.
requires:
  claude-code: ">=2.0"                 # optional; minimum Claude Code version.
requires-companion: []                 # slugs of companion files this entry depends on
                                       # (e.g. instruction → data file).
conflicts-with: []                     # slugs of files that contradict this rule.
supersedes: []                         # slugs this file replaces (migration).
deprecated: false                      # tombstone flag.
deprecated-reason: ""                  # required if deprecated: true.
superseded-by: ""                      # optional slug; the file that replaces this one.
deprecated-since: ""                   # ISO date; required if deprecated: true.
changelog: []                          # optional list of {version, date, summary} entries
                                       # for minor/major bumps.
version: 1.0.0                         # semver; bumped on substantive content change.
---

# Body (markdown, freeform)
```

## Caps (enforced)

- Body ≤ 200 lines (matches Anthropic's `MEMORY.md` cap and CLAUDE.md guidance).
- `description` ≤ 140 chars.
- `tags`: 1–5 entries from `_meta/tags.txt`.

## Type-specific requirements

### `settings-fragment`

Body must contain exactly one JSON code block under a `## fragment` heading:

````markdown
## fragment

```json
{
  "permissions": {
    "allow": ["Bash(bundle exec:*)", "Bash(rake:*)"]
  }
}
```
````

The validator parses this block and refuses keys outside `permissions.{allow,deny,ask}` and `env` in v1. Each `allow[]` entry is regex-validated against the Claude Code permission-pattern grammar.

### `project-claude-md`

- Frontmatter must declare `project-type:` (e.g. `ruby-gem`, `jekyll-docs`, `rails-app`, `generic`).
- Body is the literal `CLAUDE.md` template content (Markdown). On install, frontmatter is stripped and body is written to `<project>/CLAUDE.md`.
- Body length capped at 200 lines.

### `path-rule`

- Frontmatter must declare a `paths:` list with at least one glob pattern (Anthropic's native `.claude/rules/` syntax).
- Each glob is syntax-checked.
- Example: `paths: [Gemfile, "*.gemspec", "_layouts/**"]`.

### `hook` (v2 only)

Reserved. See [SAFETY.md](SAFETY.md) for the v2 policy and the mandatory `safety:` frontmatter field.

## Validator rules

The validator at `_meta/validate.mjs` (ships in PR 2) reports the following as **errors** (block PR):

1. Missing required field (`name`, `description`, `type`, `scope`, `author`, `version`).
2. Unknown value for `type` or `scope`.
3. Body > 200 lines.
4. `description` > 140 chars.
5. Tag not in `_meta/tags.txt` controlled vocabulary.
6. `name` ≠ filename (minus `.md`).
7. Type-specific schema violations (see above).
8. PR changes body without bumping `version:`.
9. `version:` regression or flat-on-body-change.
10. `scope: personal-share` with `len(owners) != 1` or `owners[0] != author.github`.
11. `deprecated: true` without populated `deprecated-reason:` or `deprecated-since:`.
12. CODEOWNERS drift (committed `.github/CODEOWNERS` differs from `_meta/build-codeowners.mjs` output).
13. PR touches a file under `hooks/` other than `.gitkeep` (v1 guard).

The validator reports the following as **warnings** (do not block):

- File A declares `conflicts-with: [B]` but B doesn't declare A or carry an explanatory note.
- `supersedes:` references a slug not in the repo.
- `[[wiki-link]]`-style body reference doesn't resolve to a file in the repo.

GitHub Actions enforces these rules on every PR via `.github/workflows/validate.yml`. The workflow runs `node _meta/validate.mjs` plus drift checks against `_meta/build-codeowners.mjs` and `_meta/build-index.mjs` output. Originally deferred to v2 per [issue #1 comment 2](https://github.com/riboseinc/claude-memory-files/issues/1), but wired up earlier because the validator script is proven and the marginal CI cost is approximately zero.

## Worked examples (once seeds land)

After the seed PRs land, see:
- `instructions/github-pr-title-issue-link.md` — simple universal instruction.
- `instructions/github-narrative-location.md` — instruction with `requires-companion:`.
- `memory/user-maintained-gems.md` — personal-share data template.
- `memory/feedback_handhold_when_frustrated.md` — personal-share behavioural preference.
- `settings-fragments/ruby-bundler-allowlist.md` — settings-fragment with `## fragment` JSON block.
- `rules/feedback_pr_chain_no_local_deps.md` — path-rule with `paths:` frontmatter.
- `project-claude-md/ruby-gem.md` — project-claude-md with `project-type:`.
