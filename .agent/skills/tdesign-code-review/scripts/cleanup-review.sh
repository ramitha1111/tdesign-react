#!/usr/bin/env bash

# 删除审查 demo、审查用例、线上包缓存、临时 remote 和本地 pr-<N>，并回到审查前的分支。

# 环境变量:
#   PRE_BRANCH           必填，审查前的分支
#   PRE_COMMON_HEAD      必填，审查前 common 的提交
#   PRE_COMMON_BRANCH    选填，审查前 common 的分支；空或 HEAD 表示游离提交
#   TEST_PATH            选填，审查测试文件路径；已跟踪则还原到 HEAD，未跟踪则删除

set -euo pipefail

N="${1:?usage: cleanup-review.sh <N>}"
: "${PRE_BRANCH:?PRE_BRANCH required}"
: "${PRE_COMMON_HEAD:?PRE_COMMON_HEAD required}"

PRE_COMMON_BRANCH="${PRE_COMMON_BRANCH:-}"
TEST_PATH="${TEST_PATH:-}"

ROOT="$(git rev-parse --show-toplevel)"
cd "${ROOT}"

rm -f ".review/demos/pr-${N}.tsx"
rm -rf .review/tdesign-react-* .review/published-version
rm -f ".review/PrCompareView.tsx"

if [[ -n "${TEST_PATH}" ]]; then
  if git ls-files --error-unmatch -- "${TEST_PATH}" >/dev/null 2>&1; then
    git restore --source=HEAD --staged --worktree -- "${TEST_PATH}" 2>/dev/null || true
  else
    rm -f -- "${TEST_PATH}"
  fi
fi

git switch "${PRE_BRANCH}" || git switch --recurse-submodules "${PRE_BRANCH}"
git branch -D "pr-${N}"
git remote remove "pr-${N}" 2>/dev/null || true

if [[ -n "${PRE_COMMON_BRANCH}" && "${PRE_COMMON_BRANCH}" != "HEAD" ]]; then
  git -C packages/common switch "${PRE_COMMON_BRANCH}"
else
  git -C packages/common checkout --detach "${PRE_COMMON_HEAD}"
fi
