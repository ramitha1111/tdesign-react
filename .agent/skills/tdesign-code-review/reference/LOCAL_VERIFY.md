# Bug Fix 本地验证

## §V-1 检查工作区

只将**遗留文件**视为未提交变更。`packages/common` 当前检出提交与父仓库记录的 gitlink 不一致时，允许切换。

```bash
# 父仓库遗留文件（忽略子模块；含修改与未跟踪）
git status --porcelain --ignore-submodules
# common 子仓库遗留文件
git -C packages/common status --porcelain
```

两条均为空时，记录恢复点并进入下一节。当前不在 `develop` 时同样切换。

任一非空则停止，执行 `AskQuestion`。`stash`、`commit`、`其它` 完成后再记录恢复点并进入下一节。`静态审查` 结束本地验证。

| 选项         | 操作                                                          |
| ------------ | ------------------------------------------------------------- |
| **stash**    | 执行 `git stash push -u -m "cr: PR #<N> review"`              |
| **commit**   | 分析变更，生成 Commit Message，执行 `git add` 和 `git commit` |
| **静态审查** | 结束本地验证，直接写审查报告                                  |
| **其它**     | 根据用户明确指定的操作执行                                    |

记录恢复点。`PRE_COMMON_BRANCH` 为 `HEAD` 表示当时处于游离提交：

```bash
# 记录当前分支
PRE_BRANCH="$(git branch --show-current)"

# 记录 common 当前提交
PRE_COMMON_HEAD="$(git -C packages/common rev-parse HEAD)"

# 记录 common 当前分支；游离时为 HEAD
PRE_COMMON_BRANCH="$(git -C packages/common rev-parse --abbrev-ref HEAD)"
```

## §V-2 切换与同步 develop 分支

```bash
# 切到 develop
git switch develop

# 快进到远端 develop
git pull --ff-only origin develop

# 同步 common 子仓库
git submodule update --init packages/common
```

`pull --ff-only` 失败时，执行 `AskQuestion`，禁止自动 `merge`。

## §V-3 落地测试文件

**前提**：当前在 `develop` 分支，生产代码与 `origin/develop` 一致。仅允许变更 `TEST_PATH` 所指测试文件。

| 条件      | 操作                                                                                                                          |
| --------- | ----------------------------------------------------------------------------------------------------------------------------- |
| PR 含测试 | 将 `TEST_PATH` 设为 PR 变更中的测试文件路径                                                                                   |
| PR 无测试 | 将 `TEST_PATH` 设为 `packages/components/<component>/__tests__/review-pr-${N}.test.tsx`，并在该路径新建文件、编写最小复现用例 |

## §V-4 验证缺陷

### §V-4.1 develop 分支

```bash
# 在 develop 上运行复现用例
pnpm exec vitest run "${TEST_PATH}"
```

| 结果 | 判定与处理                                                             |
| ---- | ---------------------------------------------------------------------- |
| 失败 | 确认失败原因与 PR 描述的缺陷一致，接着处理测试文件并切到 PR 分支       |
| 通过 | 判定为未复现，检查测试用例是否充分覆盖缺陷触发条件，修改用例并重新执行 |

**修改用例后仍无法复现，则将该 PR 标记为无法复现，停止审查**。

验证通过后，执行下一步按需处理 `TEST_PATH`，避免产生冲突：

| 场景      | 操作                                                                                            |
| --------- | ----------------------------------------------------------------------------------------------- |
| PR 无测试 | 无                                                                                              |
| PR 有测试 | `git restore --staged --worktree -- "${TEST_PATH}" 2>/dev/null; git clean -f -- "${TEST_PATH}"` |

### §V-4.2 PR 分支

```bash
# 切到 PR 分支
git switch "pr-${N}" || git switch --recurse-submodules "pr-${N}"

# 同步 common 子仓库
git submodule update --init packages/common

# 在 PR 分支上运行同一用例
pnpm exec vitest run "${TEST_PATH}"
```

| 结果     | 判定与处理                                                                             |
| -------- | -------------------------------------------------------------------------------------- |
| **通过** | 修复验证通过，据此写审查报告                                                           |
| **失败** | 修复验证未通过，禁止合并。按测试失败堆栈定位问题，并在代码建议中列出具体问题及修改建议 |

## §V-5 恢复审查前状态

```bash
# 回到审查开始前所在分支
git switch "${PRE_BRANCH}" || git switch --recurse-submodules "${PRE_BRANCH}"

# 丢弃暂存区与工作区中对测试文件的修改
git restore --staged --worktree -- "${TEST_PATH}" 2>/dev/null || true

# 删除未跟踪的测试文件
git clean -f -- "${TEST_PATH}"

# 删除本地 PR 引用分支
git branch -d "pr-${N}" || git branch -D "pr-${N}"

# common 原先在分支上则切回，否则按原提交游离检出
if [ -n "${PRE_COMMON_BRANCH}" ] && [ "${PRE_COMMON_BRANCH}" != "HEAD" ]; then
  git -C packages/common switch "${PRE_COMMON_BRANCH}"
else
  git -C packages/common checkout --detach "${PRE_COMMON_HEAD}"
fi
```

**禁止 `commit` 审查过程中产生的测试变更。**
