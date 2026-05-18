#!/usr/bin/env node
/**
 * Build _meta/index.json from frontmatter of all content files.
 *
 * The index powers the slash-command picker and the (future) generated
 * README catalogue. Active and deprecated entries are kept in separate
 * arrays so the picker can hide deprecated by default.
 *
 * Usage: node _meta/build-index.mjs
 */

import { readFile, readdir, writeFile } from 'node:fs/promises';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import * as YAML from 'yaml';

const ROOT = join(dirname(fileURLToPath(import.meta.url)), '..');
const CATEGORIES = ['instructions', 'memory', 'settings-fragments', 'project-claude-md', 'rules'];

// Output is deterministic — no timestamp field — so CI can drift-check via
// `git diff --exit-code _meta/index.json` after regenerating.
const index = {
  files: [],
  deprecated: [],
};

for (const category of CATEGORIES) {
  const dirPath = join(ROOT, category);
  let entries;
  try {
    entries = await readdir(dirPath);
  } catch {
    continue;
  }
  for (const entry of entries.sort()) {
    if (entry === '.gitkeep' || !entry.endsWith('.md')) continue;
    const relPath = `${category}/${entry}`;
    const content = await readFile(join(ROOT, relPath), 'utf-8');
    const match = content.match(/^---\n([\s\S]*?)\n---/);
    if (!match) continue;
    const fm = YAML.parse(match[1]);

    const indexEntry = {
      name: fm.name,
      path: relPath,
      description: fm.description,
      type: fm.type,
      scope: fm.scope,
      ...(fm.team ? { team: fm.team } : {}),
      ...(fm['project-type'] ? { 'project-type': fm['project-type'] } : {}),
      ...(fm.paths ? { paths: fm.paths } : {}),
      tags: fm.tags || [],
      version: fm.version,
      author: fm.author?.github,
      owners: fm.owners || [fm.author?.github].filter(Boolean),
      ...(fm['requires-companion']?.length ? { 'requires-companion': fm['requires-companion'] } : {}),
      ...(fm['conflicts-with']?.length ? { 'conflicts-with': fm['conflicts-with'] } : {}),
    };

    if (fm.deprecated) {
      index.deprecated.push({
        ...indexEntry,
        'deprecated-reason': fm['deprecated-reason'],
        'deprecated-since': fm['deprecated-since'],
        'superseded-by': fm['superseded-by'],
      });
    } else {
      index.files.push(indexEntry);
    }
  }
}

await writeFile(join(ROOT, '_meta', 'index.json'), JSON.stringify(index, null, 2) + '\n', 'utf-8');
console.log(`Wrote _meta/index.json: ${index.files.length} active, ${index.deprecated.length} deprecated`);
