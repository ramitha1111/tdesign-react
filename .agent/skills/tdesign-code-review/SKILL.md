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
gh pr view "$N" --repo Tencent/tdesign-react --json title,body,baseRefName
```

`baseRefName` ≠ `develop` 时停止审查流程，并告知用户。

---

## 2. 静态审查

```bash
gh pr diff "$N" --repo Tencent/tdesign-react
```

**如果存在依赖上下文才能理解其意图，且代码附近缺少明确注释的改动，记录其 `路径:行号`。**已有清晰注释的改动无需记录。

### 变更范围

是否存在大规模重构、意外删改、或偏离 PR 目标的变更。

### 逻辑正确性

事件链、状态流转、生命周期、边界条件是否正确。

### API 契约

公开 API、类型、默认值、行为是否与文档及历史用法兼容。

### 样式与结构

- **ClassName**：是否使用 `classPrefix`、BEM 是否与组件既有命名风格一致。
- **Inline style**：是否确有运行时计算必要；是否用内联间距、颜色等补丁替代设计体系，导致观感或交互与 TDesign 不一致。

### 测试质量

涉及测试时，**必须先完整阅读** [tdesign-component-test](../tdesign-component-test/SKILL.md) 的 **§3**，按其中规范逐项核对。

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

| 阶段 | 分支                 | 期望                                                            |
| ---- | -------------------- | --------------------------------------------------------------- |
| 复现 | `develop`            | `TEST_PATH` 失败                                                |
| 切换 | `develop` → `pr-<N>` | 同一份 `TEST_PATH`；按需完成 §V-5.1 末尾切换说明，再进入 §V-5.2 |
| 修复 | `pr-<N>`             | 同一 `TEST_PATH` 通过                                           |

---

## 4. 输出报告

交付物**有且仅有** 下方 markdown 模版的填充结果。
§0–§3 的思考与验证过程只服务于填模板，禁止补充额外细节进行汇报。

```markdown
# PR #<N> 代码审查

## 合并建议

合并 / 修改后合并 / 暂不合并

## 变更日志

<中文摘要>

## 代码解释

针对 §2 识别出的关键改动，记录 PR 中未提供明确动机说明的改动，并结合代码上下文分析其设计动机。

`packages/components/xxx/Foo.tsx:23-45`

- **场景**：说明程序状态如何使执行路径进入该改动。
- **原逻辑缺陷**：说明旧实现在该场景下的错误结果。
- **本段改动**：说明本次代码如何约束或修正上述行为。

## 代码建议

无建议则只写：`无`

`packages/components/xxx/Foo.tsx:42`

<问题描述、可优化的方案>
```

**禁止**在上方模版章节之外追加任何说明。
