---
name: tdesign-code-review
description: This skill should be used when reviewing GitHub Pull Requests, analyzing code changes, identifying bugs, checking implementation quality in the TDesign React repository.
---

# TDesign 组件代码审查指南

## 0. 前置检查

根据 [PREFLIGHT_CHECK.md](reference/PREFLIGHT_CHECK.md) 确认 `gh` 的安装与登录。默认只审查，不提交代码。

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

先列文件，再只展开源码变更。忽略测试快照的变更，不需要展开分析。

```bash
# 列出变更文件及增删行数
gh pr view "$N" --repo Tencent/tdesign-react --json files --jq '.files[] | "\(.path)\t+\(.additions)\t-\(.deletions)"'

# 拉取 develop 与 PR 头
git fetch origin develop "+pull/${N}/head:pr-${N}"

# 只展开源码变更，排除快照
git diff origin/develop...pr-${N} -- . ':(exclude,glob)**/*.snap' ':(exclude,glob)**/__snapshots__/**'
```

**如果存在依赖上下文才能理解其意图，且代码附近缺少明确注释的改动，记录其 `路径:行号`。**已有清晰注释的改动无需记录。

### 变更范围

是否存在大规模重构、意外删改、或偏离 PR 目标的变更。

### 逻辑正确性

是否事件链、状态流转、生命周期、边界条件均正确。

### API 契约

是否公开 API、类型、默认值、行为与文档及历史用法兼容。

### 样式与结构

涉及类名、内联 `style` 或 `packages/common/style` 时，须对照该组件 `packages/common/style/web/components/<组件>/` 后再判断：

- **ClassName**：是否使用 `classPrefix`，且 BEM 与同组件 common Less 一致。
- **Inline style**：是否仅用于运行时测量或交互结果（如宽高、transform 等）。禁止将静态间距、颜色、对齐以内联补丁代替 common Less，从而破坏组件样式，导致观感与 TDesign 设计风格不一致。

### 测试质量

严格遵循 [tdesign-component-test](../tdesign-component-test/SKILL.md) **§3** 的规范。

### 2.1 合并判定

| 建议       | 条件                                           |
| ---------- | ---------------------------------------------- |
| 暂不合并   | 生产逻辑与 API 不通过、§3 已执行且验证未达标等 |
| 修改后合并 | 生产与 §3（若执行）通过，但存在代码建议        |
| 合并       | 无任何代码建议                                 |

---

## 3. 验证缺陷

从 PR 描述判定为 Bug Fix 时执行，否则跳过本章。

### 3.1 摘录要点

| 字段  | 来源                         |
| ----- | ---------------------------- |
| Issue | `Fixes #`、正文链接          |
| 组件  | 变更路径、标题               |
| 复现  | 正文代码、Stackblitz、截图等 |

### 3.2 本地测试

根据 [LOCAL_VERIFY.md](reference/LOCAL_VERIFY.md) 的流程进行测试。

| 阶段 | 分支      | 期望             |
| ---- | --------- | ---------------- |
| 复现 | `develop` | `TEST_PATH` 失败 |
| 修复 | `pr-<N>`  | `TEST_PATH` 通过 |

---

## 4. 输出报告

交付物**有且仅有** 下方 markdown 模版的填充结果。
§0–§3 的思考与验证过程只服务于填充模板，禁止补充额外细节进行汇报。

```markdown
# PR #<N> 代码审查

## 合并建议

合并 / 修改后合并 / 暂不合并

## 变更日志

中文简洁摘要（默认只使用一句话进行总结，仅当多个组件各自有独立的可见变更时，根据组件分类各写一句。）

## 代码解释

采用工程化、正式、严谨的技术文档表达，避免口语化描述及无关细节。

能对应到具体代码行时，按改动写，输出格式：

`packages/components/xxx/Foo.tsx:23-45`

- **场景**：说明程序状态如何使执行路径进入该改动。
- **原逻辑缺陷**：说明旧实现在该场景下的错误结果。
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

**禁止**在上方模版章节之外追加任何说明。
