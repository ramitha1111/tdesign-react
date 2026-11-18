#!/usr/bin/env node

/* 生成 .review/demos/pr-<N>.tsx */

import { execSync } from 'node:child_process';
import { existsSync, mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const [pr, description, demoFile] = process.argv.slice(2);

if (!/^\d+$/.test(pr || '') || !description || !demoFile) {
  console.error('usage: node write-demo.mjs <pr> <description> <demo-function-file>');
  process.exit(1);
}

const root = execSync('git rev-parse --show-toplevel', { encoding: 'utf8' }).trim();
const versionFile = path.join(root, '.review/published-version');
if (!existsSync(versionFile)) {
  console.error('published-version not found; run scripts/pack-published.sh first');
  process.exit(1);
}
const version = readFileSync(versionFile, 'utf8').trim();
const demoFn = readFileSync(demoFile, 'utf8').trim();

if (!/function\s+Demo\s*\(/.test(demoFn)) {
  console.error('demo function file must declare function Demo');
  process.exit(1);
}

const viewDest = path.join(root, '.review/PrCompareView.tsx');
mkdirSync(path.dirname(viewDest), { recursive: true });
const viewSource = readFileSync(path.join(__dirname, '../templates/PrCompareView.tsx'), 'utf8')
  .replace(/^\/\/ @ts-expect-error.*\n/m, '')
  .replaceAll('__VERSION__', version)
  .replaceAll('__PR__', pr);
writeFileSync(viewDest, viewSource);

const demosDir = path.join(root, '.review/demos');
mkdirSync(demosDir, { recursive: true });
const out = path.join(demosDir, `pr-${pr}.tsx`);

const source = `import React from 'react';

import { PrCompareView } from '../PrCompareView';

${demoFn}

export default function ReviewPr${pr}() {
  return (
    <PrCompareView
      description=${JSON.stringify(description)}
      demo={Demo}
    />
  );
}
`;

writeFileSync(out, source);
console.log(out);
