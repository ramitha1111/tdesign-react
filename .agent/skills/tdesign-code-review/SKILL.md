---
name: tdesign-code-review
description: This skill should be used when reviewing GitHub Pull Requests, analyzing code changes, identifying bugs, checking implementation quality in the TDesign React repository.
---

# TDesign 组件代码审查指南

## 0. 前置检查

根据 [PREFLIGHT_CHECK.md](reference/PREFLIGHT_CHECK.md) 流程确认 `gh` 的安装与登录。默认只审查，不提交代码。

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

| 维度       | 检查内容                                           |
| ---------- | -------------------------------------------------- |
| 变更范围   | 是否存在大规模重构、文件变更或代码删除             |
| 逻辑正确性 | 是否正确处理事件调用链、状态流转、生命周期等       |
| API 契约   | 是否保持公开 API、类型定义、默认值等兼容性         |
| 样式与结构 | 是否引入非预期 DOM 结构变更                        |
| 测试质量   | **是否符合 `tdesign-component-test` SKILL 的规范** |

**如果 PR 类型为 Bug Fix 且含新增测试，记录相关文件路径为 `TEST_PATH`。**

---

## 3. 验证缺陷

从 PR 描述判定为 Bug Fix 时执行，否则跳过该部分。

### 3.1 摘录要点

| 字段  | 来源                       |
| ----- | -------------------------- |
| Issue | `Fixes #` / 正文链接       |
| 组件  | 变更路径 / 标题            |
| 复现  | 正文代码、StackBlitz、截图 |

### 3.2 本地跑测

全文 [LOCAL_VERIFY.md](reference/LOCAL_VERIFY.md)（含 `TEST_PATH`、分支与降级）。

| 阶段 | 分支      | 期望                  |
| ---- | --------- | --------------------- |
| 复现 | `develop` | `TEST_PATH` 失败      |
| 修复 | `pr-<N>`  | 同一 `TEST_PATH` 通过 |

---

## 4. 输出报告

```markdown
# PR #<N> 代码审查

## 结论

- 类型：Bug Fix / Feature / 混合
- 标题：<中文摘要>
- 合并建议：合并 / 修改后合并 / 暂不合并

## 代码建议

无建议则只写：`无`

`packages/components/xxx/Foo.tsx:42`

<问题描述、影响、建议>
```
