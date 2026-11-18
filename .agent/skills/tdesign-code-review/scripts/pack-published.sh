#!/usr/bin/env bash

# 从 npm 下载并解压最新版本的 tdesign-react 包至 .review/tdesign-react-<version>

set -euo pipefail

ROOT="$(git rev-parse --show-toplevel)"
REGISTRY="https://registry.npmjs.org/"

VER="$(npm view tdesign-react@latest version --registry "${REGISTRY}")"
DEST="${ROOT}/.review/tdesign-react-${VER}"

mkdir -p "${ROOT}/.review"

if [[ -f "${DEST}/es/index.js" ]]; then
  printf '%s\n' "${VER}" > "${ROOT}/.review/published-version"
  echo "${DEST}"
  exit 0
fi

PACK_DIR="$(mktemp -d)"

npm pack "tdesign-react@${VER}" --pack-destination "${ROOT}/.review" --registry "${REGISTRY}" >/dev/null
tar -xzf "${ROOT}/.review/tdesign-react-${VER}.tgz" -C "${PACK_DIR}"
rm -rf "${DEST}"
mv "${PACK_DIR}/package" "${DEST}"
rmdir "${PACK_DIR}"

printf '%s\n' "${VER}" > "${ROOT}/.review/published-version"
echo "${DEST}"
