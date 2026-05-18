# claude-memory-files

Curated, modular memory and instruction files for [Claude Code](https://claude.com/claude-code), maintained by Ribose for developers across our orgs (`riboseinc/*`, `metanorma/*`, `lutaml/*`, `plurimath/*`, `relaton/*`).

**📖 Documentation site: [riboseinc.github.io/claude-memory-files](https://riboseinc.github.io/claude-memory-files/)** — getting started, concepts (scope rubric, mechanism/data, hooks-deferred rationale), task guides (cherry-pick via curl, slash commands, submitting your own file, customising personal-share, updating installed files), reference (frontmatter schema, file types, validator rules, manifest format, slash commands), and roadmap.

## What this repo is

A flat, cherry-pickable collection of small files that you can drop into your local `~/.claude/` setup individually — **not** a monolithic configuration to adopt wholesale. Each file declares mandatory YAML frontmatter (`name`, `description`, `type`, `scope`, …) and lives under one of five category directories that mirror Claude Code's content surface:

- **`instructions/`** — files that land at `~/.claude/instructions/<name>.md` and get `@`-included from your `~/.claude/CLAUDE.md`. Load every session.
- **`memory/`** — files that land at `~/.claude/memory/<name>.md`. Reference, not auto-loaded.
- **`settings-fragments/`** — JSON snippets that deep-merge into `~/.claude/settings.json` (especially permission allowlists).
- **`project-claude-md/`** — per-project-type `CLAUDE.md` starter templates installed into a chosen project directory.
- **`rules/`** — Anthropic's native `.claude/rules/` files with `paths:` frontmatter; load only when matching files are in scope.

A sixth category, `hooks/`, is reserved for v2 — see [SAFETY.md](SAFETY.md) for the policy.

Two install paths are planned: a `curl | bash` one-liner per file (zero install ceremony), and a small companion plugin shipping slash commands (`/install-memory-file`, `/list-memory-files`, etc.). Both write to a user-side manifest at `~/.claude/.memory-files-manifest.json`. See [CONTRIBUTING.md](CONTRIBUTING.md) for the contribution flow and [SCHEMA.md](SCHEMA.md) for the frontmatter contract.

## What this repo deliberately does NOT host

Slash commands, subagents, skills, MCP server configurations, output styles, and keybindings are **out of scope here.** Those categories are abundantly catalogued already by mature aggregators (see "Further reading" below). Hosting them here would duplicate without adding value. We focus on the white-space categories the existing ecosystem doesn't cover: memory, instructions, settings fragments, project CLAUDE.md templates, and path-scoped rules.

## Further reading and exemplar listings

Curated outbound links to **aggregator listings** that stay maintained — not individual exemplar files that bit-rot the day after they're written:

- [`hesreallyhim/awesome-claude-code`](https://github.com/hesreallyhim/awesome-claude-code) — the canonical community-maintained `awesome-` aggregator
- [Anthropic's memory documentation](https://code.claude.com/docs/en/memory) — authoritative on `CLAUDE.md` semantics, `@`-imports, `.claude/rules/`, and the `MEMORY.md` cap
- [Anthropic's plugin docs](https://code.claude.com/docs/en/plugins) and [marketplace docs](https://code.claude.com/docs/en/plugin-marketplaces) — relevant context for the install-tools plugin we ship
- [`anthropics/claude-plugins-official`](https://github.com/anthropics/claude-plugins-official) — Anthropic's curated marketplace (the "blessed" reference for plugin shape)
- [`davila7/claude-code-templates`](https://github.com/davila7/claude-code-templates) and the live aggregator at [aitmpl.com](https://www.aitmpl.com/) — third-party template/component catalogue with active maintenance
- [`VoltAgent/awesome-claude-code-subagents`](https://github.com/VoltAgent/awesome-claude-code-subagents) — well-organised subagent catalogue (per-file YAML frontmatter, named categories)
- [`PatrickJS/awesome-cursorrules`](https://github.com/PatrickJS/awesome-cursorrules) — cross-ecosystem analogue; cited deliberately because the cursor-rules failure mode is what our schema and validator exist to prevent

## Design history

The foundational design is captured in [issue #1](https://github.com/riboseinc/claude-memory-files/issues/1) (seven comments covering distribution model, scope, schema, hooks-deferred, install paths, seed set, roadmap). The update-regulation policy is in [issue #2](https://github.com/riboseinc/claude-memory-files/issues/2). Implementation lands as a series of small PRs; see issue #1's roadmap comment for the sequence.

## License

[MIT](LICENSE).
