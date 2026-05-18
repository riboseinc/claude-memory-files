#!/usr/bin/env node
/**
 * Local validator for claude-memory-files content.
 *
 * Reads every *.md under instructions/, memory/, settings-fragments/,
 * project-claude-md/, rules/, hooks/. Parses YAML frontmatter, validates
 * against _meta/schema.json + the additional rules documented in SCHEMA.md.
 *
 * Usage: node _meta/validate.mjs
 *
 * Exits 0 on success, 1 on validation errors. Prints errors with file:rule
 * context.
 */

import { readFile, readdir } from 'node:fs/promises';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import * as YAML from 'yaml';
import Ajv from 'ajv/dist/2020.js';
import addFormats from 'ajv-formats';

const ROOT = join(dirname(fileURLToPath(import.meta.url)), '..');

const CATEGORIES = [
  'instructions',
  'memory',
  'settings-fragments',
  'project-claude-md',
  'rules',
  'hooks',
];

const TYPE_TO_CATEGORY = {
  'instruction': 'instructions',
  'memory-feedback': 'memory',
  'memory-reference': 'memory',
  'memory-project': 'memory',
  'memory-user': 'memory',
  'settings-fragment': 'settings-fragments',
  'project-claude-md': 'project-claude-md',
  'path-rule': 'rules',
  'hook': 'hooks',
};

const errors = [];
const warnings = [];
const filesValidated = Object.fromEntries(CATEGORIES.map((c) => [c, 0]));
const allFrontmatters = new Map(); // name -> { fm, relPath }

const error = (file, msg) => errors.push(`ERROR ${file}: ${msg}`);
const warn = (file, msg) => warnings.push(`WARN  ${file}: ${msg}`);

async function loadSchema() {
  return JSON.parse(await readFile(join(ROOT, '_meta', 'schema.json'), 'utf-8'));
}

async function loadTagsVocab() {
  const text = await readFile(join(ROOT, '_meta', 'tags.txt'), 'utf-8');
  return new Set(text.split('\n').map((l) => l.trim()).filter(Boolean));
}

function parseFrontmatter(content, file) {
  const match = content.match(/^---\n([\s\S]*?)\n---\n([\s\S]*)$/);
  if (!match) {
    error(file, 'No YAML frontmatter block found (expected --- ... --- at top)');
    return null;
  }
  try {
    return { frontmatter: YAML.parse(match[1]), body: match[2] };
  } catch (e) {
    error(file, `YAML parse error: ${e.message}`);
    return null;
  }
}

function checkBodyLength(body, file) {
  const lines = body.split('\n').length;
  if (lines > 200) {
    error(file, `body length ${lines} exceeds 200-line cap`);
  }
}

const ALLOWED_SETTINGS_TOP_KEYS = new Set(['permissions', 'env']);
const ALLOWED_PERMISSIONS_KEYS = new Set(['allow', 'deny', 'ask']);

function checkSettingsFragmentBody(body, file) {
  const fragmentMatch = body.match(/##\s+fragment\s*\n+```json\n([\s\S]*?)\n```/);
  if (!fragmentMatch) {
    error(file, 'settings-fragment body must contain a "## fragment" heading followed by a ```json code block');
    return;
  }
  let parsed;
  try {
    parsed = JSON.parse(fragmentMatch[1]);
  } catch (e) {
    error(file, `settings-fragment JSON parse error: ${e.message}`);
    return;
  }
  for (const key of Object.keys(parsed)) {
    if (!ALLOWED_SETTINGS_TOP_KEYS.has(key)) {
      error(file, `settings-fragment JSON: top-level key "${key}" not in {permissions, env}`);
    }
  }
  if (parsed.permissions) {
    for (const key of Object.keys(parsed.permissions)) {
      if (!ALLOWED_PERMISSIONS_KEYS.has(key)) {
        error(file, `settings-fragment JSON: permissions.${key} not in {allow, deny, ask}`);
      }
    }
  }
}

function checkPathRule(frontmatter, file) {
  if (!frontmatter.paths || !Array.isArray(frontmatter.paths) || frontmatter.paths.length === 0) {
    error(file, 'path-rule requires non-empty paths: list in frontmatter');
    return;
  }
  for (const glob of frontmatter.paths) {
    if (typeof glob !== 'string' || glob.length === 0) {
      error(file, `path-rule: invalid glob entry ${JSON.stringify(glob)}`);
    }
  }
}

function checkPersonalShare(frontmatter, file) {
  const owners = frontmatter.owners || (frontmatter.author?.github ? [frontmatter.author.github] : []);
  if (owners.length !== 1) {
    error(file, `scope: personal-share requires exactly one owner (got ${owners.length})`);
    return;
  }
  if (owners[0] !== frontmatter.author?.github) {
    error(
      file,
      `scope: personal-share requires owners == [author.github] (got owners=[${owners[0]}], author.github=${frontmatter.author?.github})`,
    );
  }
}

function checkDeprecation(frontmatter, file) {
  if (frontmatter.deprecated !== true) return;
  if (!frontmatter['deprecated-reason']) {
    error(file, 'deprecated: true requires deprecated-reason');
  }
  if (!frontmatter['deprecated-since']) {
    error(file, 'deprecated: true requires deprecated-since (ISO date)');
  }
}

async function validateFile(category, entry, validate, tagsVocab) {
  const relPath = `${category}/${entry}`;
  const filePath = join(ROOT, category, entry);
  const content = await readFile(filePath, 'utf-8');
  const parsed = parseFrontmatter(content, relPath);
  if (!parsed) return;

  const { frontmatter, body } = parsed;
  const expectedName = entry.replace(/\.md$/, '');

  if (frontmatter.name !== expectedName) {
    error(relPath, `frontmatter name "${frontmatter.name}" does not match filename "${expectedName}"`);
  }

  const type = frontmatter.type;
  if (TYPE_TO_CATEGORY[type] !== category) {
    const expectedTypes = Object.entries(TYPE_TO_CATEGORY)
      .filter(([, c]) => c === category)
      .map(([t]) => t)
      .join('|');
    error(relPath, `frontmatter type "${type}" does not match category "${category}" (expected one of: ${expectedTypes})`);
  }

  if (typeof frontmatter.description === 'string' && frontmatter.description.length > 140) {
    error(relPath, `description length ${frontmatter.description.length} exceeds 140 chars`);
  }

  if (Array.isArray(frontmatter.tags)) {
    for (const tag of frontmatter.tags) {
      if (!tagsVocab.has(tag)) {
        error(relPath, `tag "${tag}" not in _meta/tags.txt controlled vocabulary`);
      }
    }
  }

  if (frontmatter.scope === 'personal-share') {
    checkPersonalShare(frontmatter, relPath);
  }

  checkDeprecation(frontmatter, relPath);
  checkBodyLength(body, relPath);

  if (type === 'settings-fragment') {
    checkSettingsFragmentBody(body, relPath);
  }
  if (type === 'path-rule') {
    checkPathRule(frontmatter, relPath);
  }
  if (type === 'project-claude-md' && !frontmatter['project-type']) {
    error(relPath, 'project-claude-md requires project-type: in frontmatter');
  }

  if (!validate(frontmatter)) {
    for (const err of validate.errors || []) {
      const where = err.instancePath || '(root)';
      error(relPath, `schema: ${where} ${err.message}`);
    }
  }

  if (frontmatter.name) {
    allFrontmatters.set(frontmatter.name, { fm: frontmatter, relPath });
  }
  filesValidated[category]++;
}

function checkCrossFileReferences() {
  for (const [name, { fm, relPath }] of allFrontmatters) {
    if (Array.isArray(fm['requires-companion'])) {
      for (const companion of fm['requires-companion']) {
        if (!allFrontmatters.has(companion)) {
          warn(relPath, `requires-companion: "${companion}" not found in repo`);
        }
      }
    }
    if (Array.isArray(fm['supersedes'])) {
      for (const sup of fm['supersedes']) {
        if (!allFrontmatters.has(sup)) {
          warn(relPath, `supersedes: "${sup}" not found in repo`);
        }
      }
    }
    if (Array.isArray(fm['conflicts-with'])) {
      for (const conflict of fm['conflicts-with']) {
        if (!allFrontmatters.has(conflict)) {
          warn(relPath, `conflicts-with: "${conflict}" not found in repo (may be intentional if the conflicting file is external)`);
        }
      }
    }
  }
}

async function walkCategory(category, validate, tagsVocab) {
  const dirPath = join(ROOT, category);
  let entries;
  try {
    entries = await readdir(dirPath);
  } catch {
    return; // Category dir missing; skip
  }

  for (const entry of entries) {
    if (entry === '.gitkeep') continue;

    if (category === 'hooks') {
      error(`hooks/${entry}`, 'hooks/ is reserved for v2; see SAFETY.md. v1 may only contain .gitkeep.');
      continue;
    }

    if (!entry.endsWith('.md')) continue;
    await validateFile(category, entry, validate, tagsVocab);
  }
}

async function main() {
  const schema = await loadSchema();
  const tagsVocab = await loadTagsVocab();

  const ajv = new Ajv({ allErrors: true, strict: false });
  addFormats(ajv);
  const validate = ajv.compile(schema);

  for (const category of CATEGORIES) {
    await walkCategory(category, validate, tagsVocab);
  }

  checkCrossFileReferences();

  if (warnings.length) {
    console.error(warnings.join('\n'));
  }

  const total = Object.values(filesValidated).reduce((a, b) => a + b, 0);
  const summary = Object.entries(filesValidated)
    .map(([c, n]) => `${c}=${n}`)
    .join(', ');

  if (errors.length) {
    console.error(errors.join('\n'));
    console.error(`\n${errors.length} error(s), ${warnings.length} warning(s).`);
    console.error(`Files validated: ${summary}`);
    process.exit(1);
  }

  console.log(`OK: ${total} file(s) validated, 0 errors${warnings.length ? `, ${warnings.length} warning(s)` : ''}.`);
  console.log(`Files validated: ${summary}`);
}

main().catch((e) => {
  console.error(`FATAL: ${e.message}`);
  process.exit(2);
});
