# 演示收尾

Bug Fix 做完 [BUG.md](BUG.md) 的演示后进入本章。功能类做完 [FEAT.md](FEAT.md) 的演示后进入本章。没有演示页的 PR 直接执行 §D-2。

进入时当前分支必须已经是 `pr-<N>`。本章结束前，在用户做出选择之前禁止切走。

---

## §D-1 请用户确认页面

用 `AskQuestion` 提问。不要把问题和地址写进审查报告。

| 选项 | 含义 |
| --- | --- |
| **没问题** | 用户已看过页面，继续 §D-2 |
| **还有问题** | 停在 `pr-<N>`。不询问删除，不删除任何文件。按用户说明改 demo 后，重新给出地址，再次执行本节 |

用户选择前禁止删除分支、禁止切走、禁止进入 §D-2。

---

## §D-2 询问是否删除审查产物

仅在 §D-1 得到「没问题」后执行。没有演示页的 PR 直接执行本节。用另一次 `AskQuestion` 提问，不要写进审查报告。

| 选项 | 含义 |
| --- | --- |
| **删除** | 清掉审查 demo、`.review` 产物和本地 `pr-<N>`，切回 `PRE_BRANCH` |
| **保留** | 停在 `pr-<N>`，demo 与 `.review` 留在工作区 |

用户选择前禁止删除分支、禁止切走。

### 删除

```bash
# 删掉审查新建的 demo。PR 自带的 _example 不要删
rm -f "packages/components/<component>/_example/review-pr-<N>.tsx"

# 删掉审查新建的测试文件
git clean -f -- "packages/components/<component>/__tests__/review-pr-<N>.test.tsx"

# 还原审查追加进已有测试文件的内容。PR 自己的测试会回到 pr-<N> 上的版本
if [ -n "${TEST_PATH}" ]; then
  git restore --source=HEAD --staged --worktree -- "${TEST_PATH}" 2>/dev/null || true
fi

# 线上包缓存与对比外壳。功能类没有这些文件时，命令无效果
rm -rf ".review/tdesign-react-<version>" ".review/tdesign-react-<version>.tgz"
rm -f ".review/CompareColumns.tsx"

# 离开 pr 分支后才能删除它
git switch "${PRE_BRANCH}" || git switch --recurse-submodules "${PRE_BRANCH}"

git branch -D "pr-<N>"

# common 原先在分支上则切回，否则按原提交游离检出
if [ -n "${PRE_COMMON_BRANCH}" ] && [ "${PRE_COMMON_BRANCH}" != "HEAD" ]; then
  git -C packages/common switch "${PRE_COMMON_BRANCH}"
else
  git -C packages/common checkout --detach "${PRE_COMMON_HEAD}"
fi
```

### 保留

不执行上面的命令。当前分支保持 `pr-<N>`。demo、`.review/CompareColumns.tsx` 和线上包缓存都留下。
