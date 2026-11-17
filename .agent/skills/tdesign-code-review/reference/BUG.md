# Bug Fix

工作区检查完成后进入本章。本章包含缺陷验证和对比演示，按节顺序执行，不要插入其他流程。

`<component>` 取本次缺陷所在的组件目录名。`<version>` 取 `packages/tdesign-react/package.json` 的 `version`。

先摘录要点，供测试和对比 demo 使用。

| 字段 | 来源 |
| --- | --- |
| Issue | `Fixes #`、正文链接 |
| 组件 | 变更路径、标题 |
| 复现 | 正文代码、Stackblitz、截图等 |

| 阶段 | 分支 | 期望 |
| --- | --- | --- |
| 复现 | `develop` | `TEST_PATH` 失败 |
| 修复 | `pr-<N>` | `TEST_PATH` 通过 |

§B-1 至 §B-4 做完后回到 SKILL §4 写审查报告。报告发出后从 §B-5 继续。禁止在此之前切回 `PRE_BRANCH` 或删除 `pr-<N>`。

---

## §B-1 同步 develop

当前不在 `develop` 时同样切换。

```bash
git switch develop
git pull --ff-only origin develop
git submodule update --init packages/common
```

`pull --ff-only` 失败时，执行 `AskQuestion`，禁止自动 `merge`。

## §B-2 落地测试文件

**前提**：当前在 `develop` 分支，生产代码与 `origin/develop` 一致。仅允许变更 `TEST_PATH` 所指测试文件。

| 条件 | 操作 |
| --- | --- |
| PR 含测试 | 将 `TEST_PATH` 设为 PR 变更中的测试文件路径 |
| PR 无测试 | 将 `TEST_PATH` 设为 `packages/components/<component>/__tests__/review-pr-${N}.test.tsx`，并在该路径新建文件、编写最小复现用例 |

## §B-3 在 develop 上验证

```bash
pnpm exec vitest run "${TEST_PATH}"
```

| 结果 | 判定与处理 |
| --- | --- |
| 失败 | 确认失败原因与 PR 描述的缺陷一致，接着处理测试文件并切到 PR 分支 |
| 通过 | 判定为未复现，检查测试用例是否充分覆盖缺陷触发条件，修改用例并重新执行 |

**修改用例后仍无法复现，则将该 PR 标记为无法复现，停止审查。** 此时停在 `develop`，不切回 `PRE_BRANCH`，不写审查报告，不建对比 demo。

验证失败后，按需处理 `TEST_PATH`，避免切分支时冲突：

| 场景 | 操作 |
| --- | --- |
| PR 无测试 | 无 |
| PR 有测试 | `git restore --staged --worktree -- "${TEST_PATH}" 2>/dev/null; git clean -f -- "${TEST_PATH}"` |

## §B-4 在 PR 分支上验证

```bash
git switch "pr-${N}" || git switch --recurse-submodules "pr-${N}"
git submodule update --init packages/common
pnpm exec vitest run "${TEST_PATH}"
```

| 结果 | 判定与处理 |
| --- | --- |
| **通过** | 修复验证通过 |
| **失败** | 修复验证未通过，禁止合并。按测试失败堆栈定位问题，并在代码建议中列出具体问题及修改建议 |

结束后停在 `pr-<N>`。禁止 `commit` 审查过程中产生的测试变更。回到 SKILL §4 写审查报告。

变更不在 `packages/components/<component>/` 时，报告发出后不建对比页，直接执行 [DEMO_FINISH.md](DEMO_FINISH.md) §D-2。否则从 §B-5 继续。

---

## §B-5 取得线上包

站点里的 `tdesign-react` 会被 Vite 指到 `packages/components`，`node_modules/tdesign-react` 又是 workspace 构建产物，二者都不是 npm 上的发布包。线上包由脚本下载到 `.review/`（已 gitignore）。

在仓库根目录执行，不要手写 `npm pack`：

```bash
bash .cursor/skills/tdesign-code-review/scripts/pack-published.sh
```

脚本读取 `packages/tdesign-react/package.json` 的 `version`，把 `tdesign-react@<version>` 解压到 `.review/tdesign-react-<version>/`。目录里已有 `es/index.js` 时直接复用。

抽查解压目录里对应组件的 `es` 产物，确认仍是修复前逻辑。已经包含修复时，仍然把对比页地址交给用户。

## §B-6 区分两个包

不要修改 `packages/tdesign-react/site/vite.config.js`，不要新增 Vite 插件，不要改全局 alias，不要写 `import()`，不要使用 `tdesign-react-pr-<N>` 这种包名。

Vite 6 的内置 alias 排在全部用户插件之前，包括 `enforce: 'pre'`。假包名必须靠插件改写，而插件赶在 alias 之前执行不到。`import()` 还会把同步渲染的 demo 变成异步组件。

两行 import 写在 `templates/CompareColumns.tsx` 里。脚本把 `__VERSION__` 换成 `package.json` 的版本，把 `__PR__` 换成 PR 编号，再写入 `.review/CompareColumns.tsx`。agent 不补这两行，也不传 `version`、`pr` 或两个包。调用处只留一对内容参数：`description` 和 `demo`。线上栏标题为 `tdesign-react@<version>`，当前栏标题为 `tdesign-react#<N>`。

| 栏 | 导入 | 解析目标 |
| --- | --- | --- |
| 左 | `./tdesign-react-<version>/es/index.js` | npm 发布包 |
| 右 | `tdesign-react` | `packages/components`（当前 PR） |

两侧拿到的是整包命名空间，复现函数从 `components.Menu` 这类导出名取值。一次 PR 用到多个组件时，仍是这一对导入。

## §B-7 临时 demo

站点用文件名直接打开，不要改组件 markdown：

`http://127.0.0.1:15000/react/demos/<component>/review-pr-<N>`

只手写复现函数。它接收整包 `components`，返回一份 JSX；脚本把同一函数分别绑到线上包和当前源码。函数内不要 import `tdesign-react` 或 `.review`。复现结构来自 PR 正文。描述写成一句可执行的操作，例如要点击的标题、要观察的裁剪。

```tsx
function Demo({ components }: { components: Record<string, any> }) {
  const { Menu } = components;
  const { SubMenu, MenuItem } = Menu;
  return null;
}
```

把函数存成临时文件后，在仓库根目录执行。`<description>` 用 PR 正文里的那句复现操作替换：

```bash
node .cursor/skills/tdesign-code-review/scripts/write-compare-demo.js \
  <component> <N> "<description>" <demo-function-file>
```

脚本读取 `package.json` 的版本，生成 `.review/CompareColumns.tsx`（含上述两行 import），并写入 `packages/components/<component>/_example/review-pr-<N>.tsx`。生成的页面只传入 `description` 和 `demo`。

不要手改 `.review/CompareColumns.tsx`，也不要手改生成文件里的 import 和默认导出。用户在确认页选择「还有问题」并说明原因后，只改 `function Demo`，再执行一次脚本。

然后启动站点。已有 `pnpm dev` 时先停掉再启动，避免模块图仍停在旧分支。`15000` 被占用时使用 Vite 打印出的实际端口，路径不变。

```bash
pnpm dev
```

Vite 打印出 Local 地址后停止。不要打开浏览器，不要请求该地址，不要检查两侧模块解析，不要截图或查看渲染结果。下一条消息只给出实际地址，例如 `http://127.0.0.1:<port>/react/demos/<component>/review-pr-<N>`，并立刻执行 [DEMO_FINISH.md](DEMO_FINISH.md) §D-1。
