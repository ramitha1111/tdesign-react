#!/usr/bin/env node

// 生成 review-pr-<N>.tsx。外壳、导入路径和版本号由脚本写入。
// 用法: node write-compare-demo.js <component> <pr> <description> <demo-function-file>
const { execSync } = require('child_process');
const { mkdirSync, readFileSync, writeFileSync } = require('fs');
const path = require('path');

const [component, pr, description, demoFile] = process.argv.slice(2);

if (!component || !/^\d+$/.test(pr || '') || !description || !demoFile) {
  console.error('usage: node write-compare-demo.js <component> <pr> <description> <demo-function-file>');
  process.exit(1);
}

const root = execSync('git rev-parse --show-toplevel', { encoding: 'utf8' }).trim();
const version = JSON.parse(readFileSync(path.join(root, 'packages/tdesign-react/package.json'), 'utf8')).version;
const demoFn = readFileSync(demoFile, 'utf8').trim();

if (!/function\s+Demo\s*\(/.test(demoFn)) {
  console.error('demo function file must declare function Demo');
  process.exit(1);
}

const columnsDest = path.join(root, '.review/CompareColumns.tsx');
mkdirSync(path.dirname(columnsDest), { recursive: true });
const columns = readFileSync(path.join(__dirname, '../templates/CompareColumns.tsx'), 'utf8')
  .replaceAll('__VERSION__', version)
  .replaceAll('__PR__', pr);
writeFileSync(columnsDest, columns);

const exampleDir = path.join(root, 'packages/components', component, '_example');
mkdirSync(exampleDir, { recursive: true });
const out = path.join(exampleDir, `review-pr-${pr}.tsx`);

const source = `import React from 'react';

import { CompareColumns } from '../../../../.review/CompareColumns';

${demoFn}

export default function ReviewPr${pr}() {
  return (
    <CompareColumns
      description=${JSON.stringify(description)}
      demo={Demo}
    />
  );
}
`;

writeFileSync(out, source);
console.log(out);
