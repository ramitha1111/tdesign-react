# Bug Fix 本地验证

## §V-1 拉取 PR 引用

```bash
N=<PR编号>

git fetch origin develop "pull/${N}/head:pr-${N}"
```

## §V-2 检查工作区

```bash
git status --porcelain
```

工作区干净后记录当前分支 **`PRE_BRANCH`**：

```bash
PRE_BRANCH="$(git branch --show-current)"
```

如果存在未提交变更，**停止切换分支**，并执行 `AskQuestion`：

| 选项         | 操作                                                          |
| ------------ | ------------------------------------------------------------- |
| **stash**    | 执行 `git stash push -u -m "cr: PR #<N> review"`              |
| **commit**   | 分析变更，生成 Commit Message，执行 `git add` 和 `git commit` |
| **静态审查** | 仅完成审查 SKILL §0–§2、§4，跳过 §V-3 及之后                  |
| **其它**     | 根据用户明确指定的操作执行                                    |

流程结束后，继续执行下一步。

## §V-3 切换与同步 develop 分支

```bash
git fetch origin develop
git switch develop
git pull --ff-only origin develop
```

`pull --ff-only` 失败时，执行 `AskQuestion`，禁止自动 `merge`。

## §V-4 落地测试文件

**前提**：当前在 `develop` 分支，生产代码与 `origin/develop` 一致。仅允许变更 `TEST_PATH` 所指测试文件。

| 条件      | 操作                                                                                                                                                                                                                        |
| --------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| PR 含测试 | 将 `TEST_PATH` 设为审查 SKILL §2 记录的路径。若 PR 在该路径**已有提交**，优先 `git checkout "pr-${N}" -- "${TEST_PATH}"`；若 `checkout` 报错（路径在 PR 中不存在），改用 `git show "pr-${N}:${TEST_PATH}" > "${TEST_PATH}"` |
| PR 无测试 | 将 `TEST_PATH` 设为 `packages/components/<component>/__tests__/review-pr-${N}.test.tsx`，并在该路径新建文件、编写最小复现用例（**仅此路径**，PR 分支上不存在，供 §V-5.1 / §V-5.2 共用）                                     |

说明：

- §V-5.1 与 §V-5.2 应使用**同一份** `TEST_PATH` 内容验证「develop 失败 → PR 通过」，无需在切分支后重写用例。
- `git checkout "pr-${N}" -- …` 只替换测试文件，不改变 develop 上的生产代码；文件会进入暂存区。
- `git show … > …` 在 develop 尚无该路径时会产生**未跟踪**文件。

## §V-5 验证缺陷

### §V-5.1 develop 分支

```bash
pnpm exec vitest run "${TEST_PATH}"
```

| 结果 | 判定与处理                                                             |
| ---- | ---------------------------------------------------------------------- |
| 失败 | 确认失败原因与 PR 描述的缺陷一致，继续 §V-5.2                          |
| 通过 | 判定为未复现，检查测试用例是否充分覆盖缺陷触发条件，修改用例并重新执行 |

**修改用例后仍无法复现，则将该 PR 标记为无法复现，停止审查**。

验证通过后，执行下一步按需处理 `TEST_PATH`，避免产生冲突：

| 场景      | 操作                                                                                            |
| --------- | ----------------------------------------------------------------------------------------------- |
| PR 无测试 | 无                                                                                              |
| PR 有测试 | `git restore --staged --worktree -- "${TEST_PATH}" 2>/dev/null; git clean -f -- "${TEST_PATH}"` |

### §V-5.2 PR 分支

```bash
git switch "pr-${N}"
pnpm exec vitest run "${TEST_PATH}"
```

| 结果     | 判定与处理                                                                                                       |
| -------- | ---------------------------------------------------------------------------------------------------------------- |
| **通过** | 修复验证通过，结合 §V-5.1 结果确定审查报告                                                                       |
| **失败** | 修复验证未通过，禁止合并。结合审查 SKILL §2 的 diff 与测试失败堆栈定位问题，并在代码建议中列出具体问题及修改建议 |

## §V-6 恢复审查前状态

```bash
# 回到审查开始前所在分支
git switch "${PRE_BRANCH}"
# 丢弃暂存区与工作区中对测试文件的修改
git restore --staged --worktree -- "${TEST_PATH}" 2>/dev/null || true
# 删除未跟踪的测试文件（含 review-pr-${N}.test.tsx）
git clean -f -- "${TEST_PATH}"
# 删除本地 PR 引用分支；未合并时用 -D 强制删除
git branch -d "pr-${N}" || git branch -D "pr-${N}"
```

**禁止 `commit` 审查过程中产生的测试变更。**
