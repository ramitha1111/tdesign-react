# 功能类

工作区检查完成后进入本章。功能类指不是日常 bug 修复，且改动了组件的对外行为、新增 API，或有可见的交互、样式变更。

本章包含场景测试和演示，按节顺序执行。不切换到 `develop`，也不要求用例在修复前失败。不下载线上包，不使用 `CompareColumns`，不执行 `write-compare-demo.js`。新 API 在已发布包中不存在，对比页左侧会直接失败。

`<component>` 取本次变更所在的组件目录名。进入本章前记下新增或变更的 API，以及 PR 是否包含该组件的 `_example/*.tsx`。

§A-1 至 §A-2 做完后回到 SKILL §4 写审查报告。报告发出后从 §A-3 继续。禁止在此之前切回 `PRE_BRANCH` 或删除 `pr-<N>`。禁止 `commit` 审查过程中产生的测试变更。

---

## §A-1 切到 PR 分支

```bash
git switch "pr-${N}" || git switch --recurse-submodules "pr-${N}"
git submodule update --init packages/common
```

结束后停在 `pr-<N>`。

## §A-2 场景测试

| PR 测试 | 操作 |
| --- | --- |
| 变更里已有该组件的测试文件 | 将 `TEST_PATH` 设为这些文件，直接运行。不追加用例 |
| 没有该组件的测试变更 | 按 [tdesign-component-test](../../tdesign-component-test/SKILL.md) §3 补测试，覆盖本次新增或变更的各个场景。已有测试文件时写入该文件；没有时才新建 `packages/components/<component>/__tests__/review-pr-<N>.test.tsx` |

```bash
pnpm exec vitest run "${TEST_PATH}"
```

| 结果 | 判定与处理 |
| --- | --- |
| **通过** | 场景验证通过 |
| **失败** | 验证未通过，禁止合并。按失败堆栈在代码建议中列出问题 |

补上的测试留在工作区。删除阶段：追加到已有文件的用 `git restore` 还原该文件；新建的 `review-pr-<N>.test.tsx` 直接删除。

回到 SKILL §4 写审查报告。变更不在 `packages/components/<component>/` 时，报告发出后不建页，直接执行 [DEMO_FINISH.md](DEMO_FINISH.md) §D-2。否则从 §A-3 继续。

---

## §A-3 使用已有 demo 或新建

```bash
git diff --name-only origin/develop...HEAD -- "packages/components/<component>/_example/*.tsx"
```

| 结果 | 操作 |
| --- | --- |
| 有 `_example/*.tsx` | 不新建文件。每个文件名去掉扩展名即 demo 名 |
| 没有 | 新建 `packages/components/<component>/_example/review-pr-<N>.tsx`，默认导出一个只使用当前 `tdesign-react` 的示例，展示本次新增或变更的用法。不要改组件 markdown |

## §A-4 启动站点并给出地址

已有 `pnpm dev` 时先停掉再启动。`15000` 被占用时使用 Vite 打印出的实际端口。

```bash
pnpm dev
```

Vite 打印出 Local 地址后停止。不要打开浏览器，不要请求该地址，不要截图或查看渲染结果。下一条消息给出实际地址：

`http://127.0.0.1:<port>/react/demos/<component>/<demoName>`

PR 自带多个 demo 时逐条列出。新建的 demo 名为 `review-pr-<N>`。给出地址后立刻执行 [DEMO_FINISH.md](DEMO_FINISH.md) §D-1。
