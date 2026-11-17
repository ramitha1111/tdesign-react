#!/usr/bin/env bash

# 把 npm 上的 tdesign-react@<version> 解压到仓库 .review/
# version 读 packages/tdesign-react/package.json（已解压则直接复用）
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel)"
VER="$(node -p "require('${ROOT}/packages/tdesign-react/package.json').version")"
DEST="${ROOT}/.review/tdesign-react-${VER}"

if [[ -f "${DEST}/es/index.js" ]]; then
  echo "${DEST}"
  exit 0
fi

mkdir -p "${ROOT}/.review"
# 在仓库外执行，避免 npm 解析到 workspace 里的同名包。
PACK_DIR="$(mktemp -d)"
npm pack "tdesign-react@${VER}" --pack-destination "${ROOT}/.review" --registry https://registry.npmjs.org/ >/dev/null
tar -xzf "${ROOT}/.review/tdesign-react-${VER}.tgz" -C "${PACK_DIR}"
rm -rf "${DEST}"
mv "${PACK_DIR}/package" "${DEST}"
rmdir "${PACK_DIR}"
echo "${DEST}"
