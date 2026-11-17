# 修复对比演示

本章从 SKILL §5 进入。进入时当前分支必须已经是 `pr-<N>`。本章结束前禁止切走。

只处理基础组件 `packages/components/<component>/`。变更不在该目录时，跳过 §C-1 至 §C-3，直接执行 §C-4。非 Bug Fix 同样直接执行 §C-4。

`<component>` 取本次缺陷所在的组件目录名。`<version>` 取 `packages/tdesign-react/package.json` 的 `version`。

---

## §C-1 取得线上包

站点里的 `tdesign-react` 会被 Vite 指到 `packages/components`，`node_modules/tdesign-react` 又是 workspace 构建产物，二者都不是 npm 上的发布包。线上包单独下载到 `.review/`（已 gitignore）。

在**仓库目录之外**执行，避免打到 workspace 里的同名包：

```bash
# ROOT 为仓库绝对路径，VER 为 package.json 的 version
mkdir -p "${ROOT}/.review"
npm pack "tdesign-react@${VER}" --pack-destination "${ROOT}/.review" --registry https://registry.npmjs.org/
tar -xzf "${ROOT}/.review/tdesign-react-${VER}.tgz" -C "${ROOT}/.review"
rm -rf "${ROOT}/.review/tdesign-react-${VER}"
mv "${ROOT}/.review/package" "${ROOT}/.review/tdesign-react-${VER}"
```

抽查解压目录里对应组件的 `es` 产物，确认仍是修复前逻辑。已经包含修复时，页面照常打开。

---

## §C-2 用 alias 区分两个包

Vite 只把 alias 当成完整包名或 `包名/` 子路径。`tdesign-react` 不会命中 `tdesign-react-pr-<N>`。

全局 alias 仍把站点其余页面的 `tdesign-react` 指到当前源码。审查 demo 要的语义相反，因此只在 `review-pr-<N>.tsx` 上用 `enforce: 'pre'` 的 `resolveId` 抢先改写：

| 导入                   | 解析目标                                                  |
| ---------------------- | --------------------------------------------------------- |
| `tdesign-react`        | `.review/tdesign-react-<version>/es/index.js`（线上版本） |
| `tdesign-react-pr-<N>` | `packages/components/index.ts`（当前 PR）                 |

把下面的插件插到 `packages/tdesign-react/site/vite.config.js` 的 `plugins` 数组**第一项**。`<version>` 写成实际版本号。

```js
{
  name: 'review-compare-alias',
  enforce: 'pre',
  resolveId(source, importer) {
    if (!importer || !importer.replace(/\\/g, '/').includes('/_example/review-pr-')) return null;
    const published = path.resolve(__dirname, '../../../.review/tdesign-react-<version>/es/index.js');
    const sourceEntry = path.resolve(__dirname, '../../components/index.ts');
    if (source === 'tdesign-react') return published;
    const matched = importer.match(/review-pr-(\d+)\.tsx$/);
    if (matched && source === `tdesign-react-pr-${matched[1]}`) return sourceEntry;
    return null;
  },
},
```

不要 `pnpm add` 线上包，不要改全局 `tdesign-react` alias，不要提交这次 vite 改动。

---

## §C-3 临时 demo

新建 `packages/components/<component>/_example/review-pr-<N>.tsx`。不要改组件 markdown。站点用文件名直接打开：

`http://127.0.0.1:15000/react/demos/<component>/review-pr-<N>`

同一份复现结构渲染两次。左侧线上包，右侧 PR。标题写明导入名。复现结构来自 PR 正文，不要换成无关示例。

从 PR 涉及的组件里各导入一份：`tdesign-react` 为线上包，`tdesign-react-pr-<N>` 为当前 PR。把这份复现收成一个只接收组件引用的函数，左右各调用一次。不要在文件里写死某个组件的具体用法。

文件写完后启动站点。已有 `pnpm dev` 时先停掉再启动，避免模块图仍停在旧分支。

```bash
pnpm dev
```

在浏览器打开上面的地址，确认左右两栏都渲染出来，并且能看出修复前后的差异。页面打不开或两侧解析到同一份代码时，先修正别名或 demo，再进入 §C-4。

---

## §C-4 询问是否删除本地分支

页面确认后立刻 `AskQuestion`。不要把这个问题写进审查报告。

| 选项     | 含义                                                           |
| -------- | -------------------------------------------------------------- |
| **删除** | 清掉审查产生的未提交文件，切回 `PRE_BRANCH`，删除本地 `pr-<N>` |
| **保留** | 停在 `pr-<N>`，demo 和别名留在工作区                           |

用户选择前禁止删除分支、禁止切走。

### 删除

```bash
# 删掉临时 demo
rm -f "packages/components/<component>/_example/review-pr-<N>.tsx"

# 撤销 vite.config.js 里的审查插件
git restore --staged --worktree -- packages/tdesign-react/site/vite.config.js

# 删掉未提交的复现测试（仅 PR 原本没有该测试文件时）
git restore --staged --worktree -- "${TEST_PATH}" 2>/dev/null || true
git clean -f -- "${TEST_PATH}"

# 线上包缓存
rm -rf ".review/tdesign-react-<version>" ".review/tdesign-react-<version>.tgz"

# 离开 pr 分支后才能删除它
git switch "${PRE_BRANCH}" || git switch --recurse-submodules "${PRE_BRANCH}"

git branch -D "pr-<N>"

# common 原先在分支上则切回，否则按原提交游离检出
if [ -n "${PRE_COMMON_BRANCH}" ] && [ "${PRE_COMMON_BRANCH}" != "HEAD" ]; then
  git -C packages/common switch "${PRE_COMMON_BRANCH}"
else
  git -C packages/common checkout --detach "${PRE_COMMON_HEAD}"
fi
```

### 保留

不执行上面的命令。当前分支保持 `pr-<N>`。
