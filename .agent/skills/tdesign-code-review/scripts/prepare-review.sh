#!/usr/bin/env bash

# 记录当前工作区恢复点，拉取 pr-<N> 分支并绑定其 push 目标至 PR 源分支

set -euo pipefail

N="${1:?usage: prepare-review.sh <N>}"
REPO="Tencent/tdesign-react"

ROOT="$(git rev-parse --show-toplevel)"
cd "${ROOT}"

PRE_BRANCH="$(git branch --show-current)"
PRE_COMMON_HEAD="$(git -C packages/common rev-parse HEAD)"
PRE_COMMON_BRANCH="$(git -C packages/common rev-parse --abbrev-ref HEAD)"

git fetch origin develop "+pull/${N}/head:pr-${N}"

read -r HEAD_OWNER HEAD_REPO HEAD_REF <<< "$(
  gh pr view "${N}" --repo "${REPO}" \
    --json headRepositoryOwner,headRepository,headRefName \
    --jq '[.headRepositoryOwner.login // "", .headRepository.name // "", .headRefName // ""] | @tsv'
)"

if [[ -n "${HEAD_OWNER}" && -n "${HEAD_REPO}" && -n "${HEAD_REF}" ]]; then
  if [[ "$(git remote get-url origin)" == git@github.com:* ]]; then
    HEAD_URL="git@github.com:${HEAD_OWNER}/${HEAD_REPO}.git"
  else
    HEAD_URL="https://github.com/${HEAD_OWNER}/${HEAD_REPO}.git"
  fi
  git remote remove "pr-${N}" 2>/dev/null || true
  git remote add "pr-${N}" "${HEAD_URL}"
  git config "remote.pr-${N}.push" "refs/heads/pr-${N}:refs/heads/${HEAD_REF}"
  git config "branch.pr-${N}.pushRemote" "pr-${N}"
  echo "[prepare-review] 已绑定 pr-${N} 推送目标 -> ${HEAD_URL} (${HEAD_REF})" >&2
else
  echo "[prepare-review] 未获取到 PR 源分支信息，跳过 push 目标绑定" >&2
fi

printf 'PRE_BRANCH=%s\n' "${PRE_BRANCH}"
printf 'PRE_COMMON_HEAD=%s\n' "${PRE_COMMON_HEAD}"
printf 'PRE_COMMON_BRANCH=%s\n' "${PRE_COMMON_BRANCH}"
