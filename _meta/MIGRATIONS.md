# Schema migrations

No breaking schema migrations recorded yet.

When the frontmatter schema requires a **breaking change** (a field renamed, type changed, or new required field added that existing files don't carry), this file records:

- The bump from `schema-version: N` to `schema-version: N+1`.
- A link to `_meta/migrate-N-to-N+1.mjs` — the maintainer-side script that opens one PR rewriting all affected files.
- A one-paragraph rationale describing what changed and why.

**Additive schema changes** (new optional fields like the v1.1 `paths:`) are **lazy** — files keep their existing `schema-version:`; the validator accepts missing optional fields. No bulk migration needed for additive changes.

**Authors are never asked to migrate by hand.** Schema migrations are maintainer activity. Contributors submitting new files only need to know the current schema.

See [SCHEMA.md](../SCHEMA.md) for the current contract and [issue #2](https://github.com/riboseinc/claude-memory-files/issues/2) for the full update-regulation policy.
