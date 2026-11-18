# 本地验证准备

## 1. 检查工作区状态

仅将**遗留文件**视为未提交变更；`packages/common` 当前检出提交与父仓库记录的 gitlink 不一致时，允许执行分支切换。

```bash
# 父仓库遗留文件（忽略子模块）
git status --porcelain --ignore-submodules
# common 子仓库遗留文件
git -C packages/common status --porcelain
```

- **两条输出均为空**：直接进入 **2. 准备审查分支**。
- **任一输出非空**：暂停流程，调用 `AskQuestion` 由用户选择处置方式：

| 选项         | 处置操作                                                          | 后续流转                               |
| ------------ | ----------------------------------------------------------------- | -------------------------------------- |
| **stash**    | 执行 `git stash push -u -m "cr: PR #<N> review"`                  | 完成后进入 **2. 准备审查分支**         |
| **commit**   | 分析当前变更并生成 Commit Message，执行 `git add` 与 `git commit` | 完成后进入 **2. 准备审查分支**         |
| **其它**     | 依据用户明确指定的指令执行处理                                    | 完成后进入 **2. 准备审查分支**         |
| **静态审查** | 不处理工作区变更，不创建或切换分支                                | 终止当前子流程，转入 `SKILL.md` **§4** |

## 2. 准备审查分支

确认工作区就绪（第 1 步两条输出为空，或已按 **stash / commit / 其它** 处置完毕）后，执行以下脚本记录恢复点、拉取并创建 `pr-<N>` 分支，同时绑定其 `push` 目标至 PR 源分支：

```bash
bash scripts/prepare-review.sh "$N"
```

脚本将在标准输出打印后续清理所需的变量（`PRE_COMMON_BRANCH` 为 `HEAD` 时表示处于游离提交）：

- `PRE_BRANCH`
- `PRE_COMMON_HEAD`
- `PRE_COMMON_BRANCH`

执行完毕后，返回主流程并接续执行 `SKILL.md` **§3.2**。
