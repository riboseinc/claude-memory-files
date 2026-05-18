# Contributing to claude-memory-files

Welcome. This repo curates memory and instruction files for [Claude Code](https://claude.com/claude-code) so developers across the Ribose orgs can cherry-pick them into their own `~/.claude/` setups. See [README.md](README.md) for what the repo is; this file is how to add to it.

## Quick summary

1. Pick a file in your own `~/.claude/` setup that you think would help others. Generalise it to remove personal specifics.
2. Choose the right **category directory** (see "Categories" below).
3. Choose the right **scope** (`universal` / `team` / `personal-share`; see "Scopes").
4. Add the mandatory **frontmatter** (see [SCHEMA.md](SCHEMA.md) for the contract).
5. Run the **local validator**: `node _meta/validate.mjs` (lands with PR 2).
6. Open a **PR** with the title `feat: add <slug>` and a one-line body pointing at the design rationale.

A `/submit-memory-file` slash command (shipping with the companion plugin) automates steps 1–6 by reading the local file, scaffolding the frontmatter interactively, running the validator, and opening the PR.

## Categories

| Directory | What goes here | Install target |
|---|---|---|
| `instructions/` | Operational rules that always load | `~/.claude/instructions/<name>.md` + `@`-include in `CLAUDE.md` |
| `memory/` | Reference notes, feedback, project facts | `~/.claude/memory/<name>.md` |
| `settings-fragments/` | JSON snippets for permission allowlists, env vars | Deep-merged into `~/.claude/settings.json` |
| `project-claude-md/` | Starter `CLAUDE.md` templates for project types | `<project>/CLAUDE.md` |
| `rules/` | Path-scoped rules with Anthropic's `paths:` frontmatter | `~/.claude/rules/<name>.md` |
| `hooks/` | **Reserved for v2** (see [SAFETY.md](SAFETY.md)) | — |

## Scopes

- **`universal`** — applies regardless of team or org context. E.g. "PR titles should embed the issue URL".
- **`team`** — a team's operating norm. Two flavours:
  - **generic team practice** (any team could adopt) — no `team:` qualifier.
  - **specific-team norm** (e.g. metanorma's fortnightly-release cycle) — use `team: metanorma` qualifier so the picker can filter.
- **`personal-share`** — a single author's idiosyncratic data or preference, shared for opt-in cherry-pick. **NOT** endorsed as team norm. Strict validator rule: `owners == [author.github]` (length 1, exact author). Third parties who want to amend fork as a new slug (e.g. `andrew-maintained-gems` parallel to `user-maintained-gems`).

`personal-share` covers both:
- **data templates** (e.g. `user-maintained-gems.md` — "your data goes here, here's a worked example")
- **behavioural preferences** (e.g. `feedback_handhold_when_frustrated.md` — "your preference for how you want to be handled goes here")

## What we don't accept

- Files containing **personal credentials** or identifying data (GitHub handles in body content, work emails, API keys).
- **Personal-language idiom** files specific to one author (e.g. preferences for narrating in a specific human language).
- Files **duplicating mature existing aggregators**' content — slash commands, subagents, skills, MCP server configurations, output styles, keybindings. Those go to `hesreallyhim/awesome-claude-code` and similar (see [README.md](README.md) "Further reading").
- Files **exceeding 200 lines of body content** (matches Anthropic's MEMORY.md cap).
- **Non-Ribose project names** in shared content. Redact to "non-Ribose activity" or context-generic phrasing before submitting. Personal memory files in your own `~/.claude/` can retain specific names; this repo is for shared content.

## PR conventions

- **Title**: `<conventional-commit-type>: <short description>` (e.g. `feat: add foo-rule`, `chore: bump validator`, `docs: add guide for X`).
- **Body**: short and pointing at the design rationale or issue. Avoid duplicating rationale across PR and ticket; the canonical narrative lives in the relevant issue thread.
- **Sign-off**: `Co-Authored-By` trailer if pair-authored. Claude attribution per `github-claude-attribution.md` convention.

## Owners model

Each file's frontmatter declares `owners: [...]`. For `scope: personal-share`, the validator enforces single-owner (`owners == [author.github]`). For `scope: team` or `universal`, multiple owners can be listed.

Branch protection (configured outside this repo) treats scopes differently:
- `scope: personal-share` → 1 review from the named owner.
- `scope: team` → 1 review from any listed owner.
- `scope: universal` → 1 review from a listed owner **plus** 1 review from a maintainer.

See [issue #2](https://github.com/riboseinc/claude-memory-files/issues/2) for the full update-regulation policy.

## Updating an existing file

The `--update` mode in `tools/install.sh` handles drift detection and decision-matrix-driven overwrite. Semver rules for PRs that change existing files:

- **patch** (`x.y.Z`) — typo/clarification, no behaviour change.
- **minor** (`x.Y.0`) — additive (new example, scope broadened).
- **major** (`X.0.0`) — semantics change, scope change, deprecation.

The validator rejects PRs that change body without bumping `version:` (rule TBD; currently the version-monotonicity check is documented in `SCHEMA.md` and applied by reviewers; full enforcement lands with the broader ticket #2 work).

Client `--update` behavior (drift + abort matrix):

| Local edited? | Bump | Action |
|---|---|---|
| no | any | silent overwrite; manifest history appended |
| yes | any | abort; `--force` overrides |
| `forked: true` (personal-share) | any | no-op; `--upstream` forces overwrite |

Run via `bash tools/install.sh --update <slug>` (locally) or via the `/update-memory-file` slash command (inside Claude Code). See `--help` on the script for full flag reference.

## Local validator

`node _meta/validate.mjs` is the local pre-submission gate. It runs all the checks listed in [SCHEMA.md](SCHEMA.md) under "Validator rules". Run it before opening a PR.

GitHub Actions also runs the validator on every PR via `.github/workflows/validate.yml`. The CI workflow additionally checks that `.github/CODEOWNERS` and `_meta/index.json` have been regenerated (drift check) — if you modify any frontmatter `owners:` field or add/remove a content file, run `node _meta/build-codeowners.mjs` and `node _meta/build-index.mjs` locally and commit the regenerated outputs alongside your content change.

## License

By contributing, you agree your content is licensed under [MIT](LICENSE) (unless your file's frontmatter specifies otherwise).
