---
schema-version: 1
name: common-unix-reads-allowlist
description: Read-only Unix tool allowlist (grep, find, ls, cat, head, tail, wc) for ~/.claude/settings.json. No writes.
type: settings-fragment
scope: universal
target: ~/.claude/settings.json (permissions.allow merge)
autoload: false
tags: [settings, allowlist, toolchain]
author:
  name: Nick Nicholas
  github: opoudjis
owners: [opoudjis]
license: MIT
version: 1.0.0
---

# Common Unix read-only allowlist

Add to `~/.claude/settings.json.permissions.allow[]` the patterns that cover routine read-only Unix tools — searching, listing, inspecting file content. Without this, every `grep`, `find`, `ls`, `cat` triggers a permission prompt during exploration.

## Scope

**Read-only.** Deliberately excludes any write-capable tool: no `rm`, no `mv`, no `cp`, no `sed -i`, no `awk` with redirect, no `tee`. Those should remain prompt-gated.

`Bash(grep:*)` and `Bash(find:*)` give broad search latitude over the working tree, which is the intended behaviour — but be aware that `find` *can* invoke arbitrary commands via `-exec` or `-delete`. If that's a concern for your setup, tighten this allowlist to `Bash(find * -name *)` patterns specifically.

## What's allowed

| Pattern | Purpose |
|---|---|
| `Bash(grep:*)` | search text in files |
| `Bash(find:*)` | locate files by name/pattern |
| `Bash(ls:*)` | directory listings |
| `Bash(cat:*)` | inspect file contents |
| `Bash(head:*)` | first-N-lines |
| `Bash(tail:*)` | last-N-lines |
| `Bash(wc:*)` | word/line count |

For more targeted tools (`rg`, `fd`, `bat`, `eza`), add their patterns yourself — they're not in this baseline because not every dev installs them.

## fragment

```json
{
  "permissions": {
    "allow": [
      "Bash(grep:*)",
      "Bash(find:*)",
      "Bash(ls:*)",
      "Bash(cat:*)",
      "Bash(head:*)",
      "Bash(tail:*)",
      "Bash(wc:*)"
    ]
  }
}
```
