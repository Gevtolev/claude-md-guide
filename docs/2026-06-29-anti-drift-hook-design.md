# 设计：bootstrap 防漂移闭环（anti-drift hook）

> 状态：Draft（待 review）
> 日期：2026-06-29
> 关联：[design.md](./design.md)（总设计）、[design-philosophy.md](../skills/bootstrap-claude-docs/references/design-philosophy.md)（拟加第 7 条）
> 来源：对比 OpenSpec 的文档保鲜机制后提炼（不引入 OpenSpec 工具链，只借设计思想）

## 1. 背景与问题

现有 `maintain-claude-docs`（由 bootstrap 在 Phase 2.5 生成）是**按需 / 阶段性**的人主导文档体检。对照 OpenSpec 的文档保鲜机制后，暴露出 4 个结构性弱点：

1. **漂移没人发现**：代码改了、文档没跟上，没有任何检查或闸门兜底，直到某天有人发现文档是错的。
2. **多源重复同步累**：同一事实散落 ARCHITECTURE / PRD / decisions / 设计稿多处，改一处常忘改另一处（典型如「schema.ts / types.ts / Provider 三处必须同步」）。
3. **全靠自觉易忘**：maintain 明确「不每次改动跑」，好处是克制，代价是触发全靠人记。
4. **更新成本高 / 索引乱**：改文档要人肉找段落重写；README 索引手动维护，容易和实际文件对不上。

OpenSpec 的解法启发了本设计，但**不照搬**：它靠 `archive` 机械合并 delta、`verify` 做 code↔spec reconcile、`specs/` 单一真相源、delta 增量更新。我们取其**思想**（单一真相源、reconcile、确定触发点），落进 bootstrap 现有体系，而不引入 OpenSpec 的 CLI / 双写目录（论证见总对比，略）。

## 2. 目标与非目标

**目标**
- 给 bootstrap 增加「生成项目级**防漂移 hook**」的能力（类比已有的 Phase 2.5 生成 maintain skill）。
- 提炼一张**真相源映射表**，一份两用：给人看（别重复写）+ 喂给检测器（当规则）。
- 全程不破坏 bootstrap 的克制哲学：触发点 = 提交、执行者 = 低档模型而非人、**不每次改动跑**。

**非目标**
- 不引入 OpenSpec 工具链，不做 spec 生命周期管理。
- 不替换 maintain skill —— hook 与 maintain 互补。
- 默认不硬拦截提交（避免退化成「大家习惯性 `--no-verify`」）。

## 3. 总体架构（两层执行 + 一个规则源）

```
① 真相源映射表  (新增, 每项目一份)
   "代码动了 X → 该查文档 Y, 自动改 / 只提醒" 的规则表
        │ 同一份, 既给人看也喂给检测器
        ▼
② git hook (默认 pre-push, 生成时可配 pre-commit / CI)
   ├─ 阶段A 检测: haiku 读将推送的 diff + 映射表 → 漂移点列表   (便宜, 每次跑)
   └─ 阶段B 修复: 仅当检测到漂移 → 开 repair subagent (sonnet)
                  改"可自动改"的文档 → 留工作区不 commit
                  打印: 已修 N 处(待 review) + 仅提醒 M 处(ADR/PRD)
③ maintain skill (现有, 退为): 按需/阶段性的人主导深度体检
   (ADR 该不该写 / 季度审计 / 结构重组——hook 管不了的判断)
```

**三痛点如何被一次解掉**：映射表 = 单一来源总表（解 ②）；hook 自动在提交点检测 + 修复（解 ① + ③）；检测器顺带查「文档增删 vs README 索引一致」（解 ④）。

## 4. 组件设计

### 4.1 真相源映射表（source-of-truth-map）

**作用**：枢纽。既是给人的「同一事实只在权威处写、别处只引用」，又是喂给 haiku 检测器的规则「diff 碰了 X → 查 Y」。

**格式**（每行一条规则）：

| 代码路径 / 模式 | 应同步的文档 | 处置 |
|---|---|---|
| `lib/types.ts`（字段增删） | `lib/schema.ts` / `state/*Provider` 一致性 + 字段文档 | 提醒（运行时必须各写一份，用测试锁） |
| `app/api/*/route.ts` | `ARCHITECTURE.md` 的 API / 错误码表 | 自动改 |
| 新增 / 删除 `docs/**/*.md` | 对应 `docs/<dir>/README.md` 索引 | 自动改 |
| `lib/calc.ts`（公式） | PRD 验收用例 + 对应 unit test | 提醒 |

（上为 Mingo 风格示例；bootstrap 生成时按项目类型 + Phase 1 扫描结果填充。）

**放哪**：默认独立文件 `docs/source-of-truth-map.md`（便于 hook 单独读取）；小项目可内联到 `ARCHITECTURE.md` 顶部。

### 4.2 防漂移 hook（两阶段）

**挂点**：默认 **pre-push**（频率比 pre-commit 低，等待 LLM 不烦；比 CI 少依赖 secret/网络）。生成时可按项目改为 pre-commit 或 CI。

**阶段 A · 检测（haiku，每次推送都跑）**
- 输入：将推送的 diff（`git diff @{push}..HEAD` 回退到 `origin/<default>..HEAD`）+ 真相源映射表。
- 调用：`claude -p --model <haiku>`，prompt 模板内置于 hook。
- 输出：结构化漂移点列表（命中的映射规则 + 涉及文档 + 处置）。无漂移则直接放行（绝大多数提交，几乎不花钱）。

**阶段 B · 修复（默认 sonnet 求质量，模型可配；仅当检测到漂移）**
- 对「自动改」类文档：开 repair subagent 针对性改，**改动留工作区，不 `git add`、不 commit**。
- 对「只提醒」类文档（ADR / PRD）：只在报告里列出，不动文件。
- 收尾：打印报告「已自动修复 N 处（待 review）/ 仅提醒 M 处」，**放行 push**（exit 0）。

**修复落地**：留工作区等人 review —— 自动化但你始终能看一眼，改错不会被静默固化进提交。

### 4.3 与 maintain skill 的分工

| | 防漂移 hook | maintain skill |
|---|---|---|
| 触发 | 自动，提交 / 推送时 | 按需 / 阶段性，人主导 |
| 管的事 | 机械漂移（索引、描述段、字段一致） | 深度判断（ADR 该不该写、季度审计、结构重组） |
| 关系 | 兜底高频漂移 | hook 够不到的留给它 |

maintain 模板的 checklist 第 4 项（索引）与真相源部分改注：「由 hook 兜底，maintain 只复查 hook 够不到的」。

## 5. 边界与数据流

**自动改 vs 只提醒**
- 自动改（机械、低风险）：README 索引、ARCHITECTURE 描述段、glossary。
- 只提醒不自动改（承载决策 / 规格，LLM 易改错语义）：`docs/decisions` ADR、PRD。
- 硬拦截：默认**无**；映射表可把个别项标 `critical`，漂移则 hook 非零退出——默认关，按项目开。

**数据流**
```
开发者 git push
  → pre-push hook 触发
  → 阶段A 检测(haiku): diff + 映射表 → 漂移点
  → 无漂移: 放行
  → 有漂移: 阶段B(sonnet) 改可自动改的 → 留工作区
            → 打印报告(已修/仅提醒) → 放行 push
  → 开发者 review 工作区文档改动 → 下次提交带上
```

## 6. 错误处理与降级（保住 bootstrap 通用性，7 类项目都能用）

- **无 git** → 不生成 hook，防漂移落回 maintain skill 的手动 verify 步骤。
- **无 claude CLI / 离线** → hook 跳过 LLM 阶段，只跑能静态检查的项（如索引文件数一致性）。
- **LLM 超时 / 失败** → 放行（绝不阻断 push）+ 打印「检测跳过」提示。
- **假阳性** → 因为「只提醒 + 留 review + 不硬拦」，误判不会固化错误，最多多看一眼报告。

## 7. bootstrap 改动面（文件清单）

| 文件 | 改动 |
|---|---|
| `references/anti-drift-hook.md`（新） | hook 蓝图 + 两阶段 prompt 模板 + `claude -p` 调用方式 + 挂点选择 + 降级规则 |
| `templates/source-of-truth-map.tmpl`（新） | 真相源映射表模板 |
| `templates/anti-drift-hook.sh.tmpl`（新） | 可执行 hook 脚本模板（两阶段骨架，含降级分支） |
| `SKILL.md` | 加 **Phase 2.6 — 生成项目级防漂移 hook**（检测 git / claude CLI，缺则降级） |
| `references/design-philosophy.md` | 加**第 7 条「防漂移闭环」**，显式调和与第 5 / 6 条克制的关系 |
| `templates/maintain-claude-docs-SKILL.md.tmpl` | 加「hook 与 maintain 分工」节；checklist 引用映射表 |
| `templates/CLAUDE.md.tmpl` | 改动自查加一行指向映射表 / hook |
| `references/project-type-variants.md` | 各类型补一句映射表 / hook 聚焦提示（轻量） |
| `README.md` | 「6 条设计原则」→「7 条」；产出结构图补 hook + 映射表 |
| `CHANGELOG.md` | 新增版本条目（建议 0.4.0） |

## 8. 落地范围（两份 + 同步验证）

- 主改：`claude-md-guide/skills/bootstrap-claude-docs/`（源仓库）。
- 同步：`~/.claude/skills/bootstrap-claude-docs/`（全局副本，非 symlink，需手动同步）。
- 收口：`diff -rq` 两份确认零差异（回到当前一致状态）；在 claude-md-guide 提交 + 更新 CHANGELOG。

## 9. 验收：mock 项目跑通整套闭环（end-to-end）

作为实现 plan 的独立阶段：

1. 建最小 mock 项目（`git init` + `package.json`，可被识别为某类型）。
2. 在其上跑 bootstrap → 验证生成了文档体系 + **Phase 2.6 的 hook + 真相源映射表**。
3. **故意制造漂移**：改一个源文件（命中映射表某条规则）但不改对应文档，触发 push。
4. 观察 hook：阶段A 检出漂移 → 阶段B 改「自动改」类文档 + 对 ADR/PRD 只提醒 → 改动留工作区、未自动提交 → 打印报告。
5. 断言：该修的修了、该提醒的提醒了、无静默 commit；**另测降级**：删掉 claude CLI 路径 / 无 git 时正确退化。

> hook 真实调 `claude -p`，测试时把两阶段模型都设为 haiku 控成本，会消耗少量 token —— 与「低档模型消耗点 token 防漂移」的设定一致。模型档位在 hook 中可配（默认：检测 haiku / 修复 sonnet）。

## 10. 已确定的关键决策

1. **软提醒 + 自动修 + 留 review**，默认不硬拦截（critical 项可选开）。
2. **两阶段流水线**：haiku 检测（每次）/ sonnet 修复（仅漂移时），榨干「低档模型省 token」。
3. **真相源映射表一份两用**（人看 + 检测器规则）—— 本设计的核心创新。
4. **改源 + 同步全局副本**，diff 验证一致。
5. spec / 产物归属 `claude-md-guide`，遵循其扁平 `docs/` 惯例。

## 11. 风险与未决

- **hook 延迟 / 成本**：pre-push 调 LLM 增加数秒等待；用 haiku + 「无漂移即放行」控制。
- **检测准确率**：LLM 有假阳 / 假阴；靠「只提醒 + 留 review」缓冲，不追求 100%。
- **跨平台 hook 脚本**：`anti-drift-hook.sh.tmpl` 的 bash 依赖（`git diff @{push}`、`claude` 在 PATH）需在 plan 阶段定清兼容性与安装方式（`core.hooksPath` 还是直接写 `.git/hooks/`）。
