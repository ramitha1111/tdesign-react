# 工作区检查

各类 PR 都先执行本章。本章不切换分支，不跑测试，不建 demo。

## §V-1 检查工作区

只将**遗留文件**视为未提交变更。`packages/common` 当前检出提交与父仓库记录的 gitlink 不一致时，允许切换。

```bash
# 父仓库遗留文件（忽略子模块；含修改与未跟踪）
git status --porcelain --ignore-submodules
# common 子仓库遗留文件
git -C packages/common status --porcelain
```

两条均为空时，记录下方恢复点，然后回到 SKILL §3 按 PR 类型继续。

任一非空则停止，执行 `AskQuestion`。`stash`、`commit`、`其它` 完成后再记录恢复点并继续。`静态审查` 结束本地流程：此时不切换分支，审查报告写完即停止，不建 demo，也不询问删除 `pr-<N>`。

| 选项 | 操作 |
| --- | --- |
| **stash** | 执行 `git stash push -u -m "cr: PR #<N> review"` |
| **commit** | 分析变更，生成 Commit Message，执行 `git add` 和 `git commit` |
| **静态审查** | 结束本地流程，直接写审查报告 |
| **其它** | 根据用户明确指定的操作执行 |

记录恢复点。`PRE_COMMON_BRANCH` 为 `HEAD` 表示当时处于游离提交：

```bash
# 记录当前分支
PRE_BRANCH="$(git branch --show-current)"

# 记录 common 当前提交
PRE_COMMON_HEAD="$(git -C packages/common rev-parse HEAD)"

# 记录 common 当前分支；游离时为 HEAD
PRE_COMMON_BRANCH="$(git -C packages/common rev-parse --abbrev-ref HEAD)"
```
