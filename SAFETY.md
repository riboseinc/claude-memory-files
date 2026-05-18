# Hooks safety policy (v2)

Hooks are reserved for v2 of this repo. This file documents the v2 policy in advance; v1 ships zero hook files.

## Why hooks are not in v1

Shared repos that ship hooks are a real supply-chain attack surface. Concrete precedent:

**CVE-2025-59536** and **CVE-2026-21852** (Check Point Research, 2026). Hooks defined in repo-controlled `.claude/settings.json` ran *automatically on session start* before the trust dialog, allowing arbitrary shell execution and `ANTHROPIC_BASE_URL` override → API key exfiltration. Check Point's writeup:

> "When a victim clones the repository and runs claude, their API key would be sent directly to the attacker's server – before the victim decides to trust the directory."

Anthropic patched by deferring network calls until trust, hardening the trust dialog, and gating MCP. The class of risk doesn't disappear — it just becomes harder to trigger.

Memory and instruction files (the v1 categories) carry **no executable payload** — installing one drops a markdown file into `~/.claude/`. The blast radius of a malicious or sloppy PR is bounded to "Claude misbehaves until you remove the file." Hooks change that calculus.

## v2 policy (when `hooks/` opens for submissions)

Every entry must:

### 1. Declare a mandatory `safety:` frontmatter field

```yaml
safety:
  runs-shell: true
  network: false
  modifies-files: true
  reads-credentials: false
  paths-touched: ["${CLAUDE_PLUGIN_ROOT}/**"]
```

Reviewers audit the file against this declaration. The validator enforces the field is populated with all sub-keys.

### 2. Pass a CI lint that rejects

- **Absolute paths** (`/Users/...`, `/home/...`).
- **`$HOME` literals**.
- **`curl | bash`** patterns (any unauthenticated remote-code-execution pattern).
- **Unsigned `curl`** to non-allowlisted domains.
- **Writes outside** `${CLAUDE_PLUGIN_ROOT}`, `${CLAUDE_PLUGIN_DATA}`, or `~/.claude/`.

### 3. Get two-reviewer approval via CODEOWNERS

Any PR touching `hooks/` requires the original author/owner **plus** the maintainer (`@opoudjis`). Configured outside this repo via branch protection rules referencing the auto-generated `.github/CODEOWNERS`.

### 4. Ship as a plugin (recommended, not enforced)

So execution is sandboxed under `${CLAUDE_PLUGIN_ROOT}` rather than reaching arbitrary filesystem state. Anthropic's plugin spec uses `${CLAUDE_PLUGIN_ROOT}` and `${CLAUDE_PLUGIN_DATA}` precisely for hook portability — see [Anthropic's plugin docs](https://code.claude.com/docs/en/plugins).

## Gate condition for v2 opening

`hooks/` opens for contributions after **at least three v1 PRs have flowed through the schema and the local validator has had real exercise**. The point is to learn what falls out of the schema before adding the highest-risk category. If we discover the frontmatter contract is wrong, better to find out on memory/instruction files than on hooks.

## In the meantime

The v1 validator rejects any file added under `hooks/` other than `.gitkeep`. This is enforced locally (the validator script's belt-and-braces guard); CI enforcement with the full safety lint above lands in v2 alongside the GitHub Actions workflow.

See [issue #1 comment 3](https://github.com/riboseinc/claude-memory-files/issues/1) for the full v1/v2 split rationale.
