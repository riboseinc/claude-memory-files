---
schema-version: 1
name: sibling-clones
description: Clone external repos into the parent of cwd (sibling directories), never /tmp; persistence across sessions is the goal.
type: instruction
scope: universal
target: instructions/sibling-clones.md
autoload: true
tags: [sibling-clones, conventions]
author:
  name: Nick Nicholas
  github: opoudjis
owners: [opoudjis]
license: MIT
version: 1.0.0
---

# Sibling clones for external repo contributions

When you need a checkout of a gem/repo to make a contribution (open a PR, file a docs PR, inspect upstream history, prepare a fork-based change), do **not** clone into `/tmp`. Clones must live next to the current working directory so they persist across sessions and can be re-entered, branch-switched, and inspected later.

**Procedure:**

1. Take the parent of the current working directory (`..` from `pwd`).
2. If a sibling directory matching the target repo name already exists there, `cd` into it, fetch and pull `main`, and work in that checkout.
3. If it doesn't exist, `git clone` into that sibling path and work there.

**Naming.** Default to the repo's own name (e.g. clone `lutaml/lutaml-model` to `../lutaml-model`). When the user explicitly names a different sibling directory — most commonly a `-docs`, `-fork`, or task-scoped suffix like `lutaml-model-docs` — use that exact name verbatim. They are deliberately keeping the new checkout separate from an existing sibling that may carry their own in-progress changes; do not collapse the two.

**Scope.** Applies any time the task involves cloning an external gem/repo for a non-trivial contribution. A throwaway `git clone … && grep …` for a quick read can still go to `/tmp`; the rule is about checkouts where work will be done, branches will be pushed, or state will need to be reinspected.

**Why.** The goal is persistence across iterations: future sessions need to see what was changed, what branch is active, what the working tree looks like. `/tmp` is wiped and breaks that.
