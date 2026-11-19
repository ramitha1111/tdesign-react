---
name: tdesign-code-review
description: This skill should be used when reviewing GitHub Pull Requests, analyzing code changes, identifying bugs, checking implementation quality in the TDesign React repository.
---

# TDesign 组件代码审查指南

## 0. 前置检查

本文中 `scripts/...` 均指当前 `SKILL.md` 同级目录下的同名相对路径，执行时需要定位至当前所在目录的对应脚本。

- **按需读取与直接执行**：`reference/*.md` 仅在流程推进到对应章节时按需读取；`scripts/*` 的入参、产物与输出行为已在本指南中明确约定，到达对应步骤时直接按命令执行即可，无需提前或额外读取脚本源码（仅在执行报错时查看排查）。
- **只读审查原则**：根据 [PREFLIGHT_CHECK.md](reference/PREFLIGHT_CHECK.md) 确认 `gh` 的安装与登录。默认只审查，不提交代码。

| 脚本 | 用途与输入输出 |
| --- | --- |
| `scripts/prepare-review.sh <N>` | 拉取 `origin/develop` 与 `PR #<N>` 创建 `pr-<N>` 分支并绑定 push remote；stdout 输出 `PRE_BRANCH`、`PRE_COMMON_HEAD`、`PRE_COMMON_BRANCH` |
| `scripts/pack-published.sh` | 下载解压 npm 最新版 `tdesign-react` 至 `.review/tdesign-react-<version>`（已存在则复用），写入 `.review/published-version`；stdout 输出解压路径 |
| `scripts/write-demo.mjs <N> <description> <demo-file>` | 读取 `.review/published-version` 与 `<demo-file>`（须声明 `function Demo`），生成 `.review/PrCompareView.tsx` 与 `.review/demos/pr-<N>.tsx`；stdout 输出生成文件路径 |
| `scripts/ensure-dev.sh` | 复用已有或后台启动 `pnpm dev` 服务，端口就绪后在 stdout 输出 `<port>` 并自动退出（失败或超时返回非 0） |
| `scripts/cleanup-review.sh <N>` | 删除 `.review/` 临时演示与包缓存，移除或还原 `TEST_PATH`，切回 `PRE_BRANCH`、删除 `pr-<N>` 与临时 remote，并恢复 `packages/common` |

---

## 1. 获取 PR 信息

### 1.1 解析编号

从用户输入提取 `N`：

| 输入                                        | 处理       |
| ------------------------------------------- | ---------- |
| 纯数字                                      | 即 `N`     |
| `github.com/Tencent/tdesign-react/pull/<N>` | 提取 `N`   |
| 其他仓库                                    | 停止       |
| 无法解析                                    | 向用户询问 |

### 1.2 拉取信息

```bash
# 读取 PR 标题、正文与目标分支
gh pr view "$N" --repo Tencent/tdesign-react --json title,body,baseRefName
```

`baseRefName` ≠ `develop` 时停止审查流程，并告知用户。

---

## 2. 静态审查

```bash
# 列出变更文件及增删行数
gh pr view "$N" --repo Tencent/tdesign-react --json files --jq '.files[] | "\(.path)\t+\(.additions)\t-\(.deletions)"'

# 展开源码变更（排除快照）
gh pr diff "$N" --repo Tencent/tdesign-react | awk '/^diff --git /{skip=($0 ~ /\.snap( |$)|\/__snapshots__\//)} !skip'
```

### 2.1 审查标准

#### 变更范围

是否存在大规模重构、意外删改、或偏离 PR 目标的变更。

#### 逻辑正确性

是否事件链、状态流转、生命周期、边界条件均正确。

#### API 契约

是否公开 API、类型、默认值、行为与文档及历史用法兼容。

#### 样式与结构

涉及类名、内联 `style` 或 `packages/common/style` 时，须对照该组件 `packages/common/style/web/components/<组件>/` 后再判断：

- **ClassName**：是否使用 `classPrefix`，且 BEM 与同组件 common Less 一致。
- **Inline style**：是否仅用于运行时测量或交互结果（例如宽高、transform 等）。禁止将静态间距、颜色、对齐以内联补丁代替 common Less，从而破坏组件样式，导致观感与 TDesign 设计风格不一致。

#### 测试质量

严格遵循 [tdesign-component-test](../tdesign-component-test/SKILL.md) **§3** 的规范。

### 2.2 合并判定

| 建议       | 条件                           |
| ---------- | ------------------------------ |
| 暂不合并   | 生产与测试通过未达标           |
| 修改后合并 | 生产与测试通过，但存在代码建议 |
| 合并       | 无任何代码建议                 |

---

## 3. 本地验证

### 3.1 检查工作区

依据 [LOCAL_VERIFY.md](reference/LOCAL_VERIFY.md) 检查工作区状态、记录恢复点变量，并创建且绑定 `pr-<N>` 分支。

- 若在工作区检查阶段选择**静态审查**，则终止本地验证与后续演示流程，直接进入 **§4 输出报告**，然后结束流程。
- 若工作区状态就绪，继续执行 **§3.2**。

### 3.2 编写测试用例

无论 PR 本身是否包含测试，均须依据 PR 需求编写验证测试用例；若 PR 已包含新增或修改的测试，须将对应测试场景一并整合至以下未跟踪文件中，以便跨分支复用：

```bash
TEST_PATH="packages/components/<component>/__tests__/review-pr-<N>.test.tsx"
```

### 3.3 执行测试与核验结果

根据 PR 类型，依次切换分支并执行测试命令，核验执行结果是否符合预期。本阶段结束时，当前工作分保持在 `pr-<N>`。

```bash
pnpm exec vitest run "${TEST_PATH}"
```

#### 修复类

1. 切换至基准分支（`git switch develop`），执行测试并确认**失败**，且失败原因与 PR 描述的缺陷一致；

2. 切换至审查分支 `pr-<N>`（`git switch "pr-${N}"`），再次执行测试并确认**通过**。

#### 功能类

1. 切换至审查分支 `pr-<N>`（`git switch "pr-${N}"`），执行测试并确认**通过**。

---

## 4. 输出报告

交付物**有且仅有**下方 Markdown 模板的填充结果。

```markdown
# PR #<N> 代码审查

## 合并建议

合并 / 修改后合并 / 暂不合并

## 变更日志

中文简洁摘要（默认使用一句话总结；仅当多个组件各自存在独立的可见变更时，按组件分别撰写一句话。）

## 代码解释

采用工程化、正式、严谨的技术文档表达，避免口语化描述及无关细节。

变更可定位至具体代码行时，根据代码段逐项输出，格式如下：

`packages/components/xxx/Foo.tsx:23-45`

- **场景**：说明触发该改动的具体条件及执行场景。
- **原始缺陷**：说明旧实现在该场景下的错误结果。
- **本段改动**：说明本次代码如何约束或修正上述行为。

当代码改动较为分散、单一修改点不足以说明变更动机时，无需引用具体行号，应从整体逻辑出发，以一段完整文字概述本次改动的设计意图，说明原有逻辑的设计原因、适用条件及其失效场景，以及本次改动如何在原有行为基础上进行衔接和完善，确保变更背景、问题原因与解决方案之间的逻辑关系清晰。

## 代码建议

从以下两个维度评估代码改进空间：

1. **更优方案**：判断当前实现是否存在更合理、高效或简洁的替代方案。
2. **书写逻辑**：判断现有逻辑是否存在可合并的分支、可提前返回的路径或可消除的重复逻辑。

仅输出实际成立的建议；两项均无改进空间时，仅输出：`无`。

每条建议必须对应一处具体代码，并标注文件路径及行号，输出格式：

`packages/components/xxx/Foo.tsx:42`

- **更优方案**：说明当前实现的局限性，并给出可替代的实现方案及其改进价值。
- **书写逻辑**：说明可合并的分支、可提前返回的路径或可消除的重复逻辑，并明确具体优化方式。
```

**报告正文严禁在模板之外追加任何说明。**

---

## 5. 示例演示

> **流转规则**：输出 **§4** 报告后（且未在 **§3.1** 选择**静态审查**），**不要结束对话**，紧接着在同一流程中完成 **§5.1** 准备文件，然后另起一条消息执行 **§5.2** 输出演示地址，并在**该消息结尾立即调用 `AskQuestion`** 进入 **§5.3**。

### 5.1 准备文件

确保当前位于 `pr-<N>` 分支，根据 PR 类型选择对应流程：

#### 修复类

1. 下载并解压当前最新的版本包（已缓存时自动复用，结果写入 `.review/published-version`）：

   ```bash
   bash scripts/pack-published.sh
   ```

2. 编写复现函数文件 `/tmp/review-pr-<N>-demo.tsx`：
   - 仅定义 `function Demo`，禁止包含 `import` / `export`；
   - TDesign 组件统一从 `components` 解构，子组件通过主组件访问（例如 `Form.FormItem`）。

   ```tsx
   function Demo({ components }: { components: Record<string, any> }) {
     const { Button } = components;
     return <Button>Click</Button>;
   }
   ```

3. 生成对比演示页面 `.review/demos/pr-<N>.tsx`（同时基于模板生成 `.review/PrCompareView.tsx`）：

   ```bash
   node scripts/write-demo.mjs \
     "$N" "<description>" "/tmp/review-pr-${N}-demo.tsx"
   ```

   `<description>` 须写明 UI 页面上的操作步骤及预期现象。

#### 功能类

1. 检查 PR 是否已新增或变更组件示例文件：

   ```bash
   git diff --name-only origin/develop...HEAD -- "packages/components/**/_example/*.tsx"
   ```

2. 若已存在匹配文件，不需要重复新建，从文件路径提取 `<component>` 与去除 `.tsx` 扩展名后的 `<demo-name>`

3. 若不存在匹配文件，新建 `.review/demos/pr-<N>.tsx`

### 5.2 启动服务

1. 执行服务检测与启动脚本（复用已有或后台拉起 `pnpm dev`，就绪后在 stdout 打印 `<port>` 并自动退出）：

   ```bash
   bash scripts/ensure-dev.sh
   ```

2. 另起一条消息，向用户输出完整演示地址（存在多个时逐条列出），并在**同一轮响应末尾立即调用 §5.3 第 1 步的 `AskQuestion`**（严禁只输出演示地址后结束回合等待用户手动回复）：

   - 临时审查演示：`http://127.0.0.1:<port>/react/demos/_review/pr-<N>`
   - PR 自带示例：`http://127.0.0.1:<port>/react/demos/<component>/<demo-name>`

### 5.3 确认效果

1. **演示页面**

   紧接 **§5.2** 输出演示地址后，**必须立即调用 `AskQuestion`** 提示用户核验：

   | 选项         | 操作                                             |
   | ------------ | ------------------------------------------------ |
   | **符合预期** | 进入第 2 步                                      |
   | **存在问题** | 保持停留在 `pr-<N>` 分支，依据用户反馈修改并验证 |

2. **清理环境**：

   用户选择 **符合预期** 后，另行调用 `AskQuestion` 询问是否清理审查产物并恢复工作区状态：

   | 选项     | 操作                                                         |
   | -------- | ------------------------------------------------------------ |
   | **保留** | 停留在 `pr-<N>` 分支，保留当前测试与演示文件，不执行其他操作 |
   | **删除** | 执行 `scripts/cleanup-review.sh` 清理并还原                  |

   选择**删除**时，使用 **§3.1** 记录的 `PRE_BRANCH`、`PRE_COMMON_HEAD`、`PRE_COMMON_BRANCH` 执行清理脚本：

   ```bash
   PRE_BRANCH="$PRE_BRANCH" \
   PRE_COMMON_HEAD="$PRE_COMMON_HEAD" \
   PRE_COMMON_BRANCH="${PRE_COMMON_BRANCH:-}" \
   TEST_PATH="${TEST_PATH:-}" \
   bash scripts/cleanup-review.sh "$N"
   ```
