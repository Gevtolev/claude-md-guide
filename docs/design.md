# bootstrap-claude-docs — 设计文档

> 创建时间：2026-04-29
> 作者：小天
> 状态：草稿（待用户复审）

## 1. 概述

**bootstrap-claude-docs** 是一个 Claude Code skill，指导 Claude 为目标项目生成一整套**可落地、可维护**的文档体系，比内置 `/init` 命令的产出更完整、更结构化。

灵感来源是 [insilico-pilot](https://github.com/Gevtolev/insilico-pilot) 项目的文档实践，提炼了 5 条可移植的设计哲学：

1. **关注点分离**：CLAUDE.md（规则） / ARCHITECTURE.md（结构） / docs/（深度）
2. **决策追溯独立**：架构/产品决策独立到 `docs/decisions/`（ADR 格式），不混在其他目录
3. **自维护索引**：每个 docs/<dir>/README.md 是入口，新增/删文件必须同步
4. **计划驱动**：中大型功能进 exec-plans/active/，完成后归档到 completed/；纯研究进 research/
5. **自检纪律**：CLAUDE.md 自带「改动自查」清单 + 项目级维护 skill 主动提醒

### 1.1 与现有工具的关系

| 工具 | 职责 | 与本 skill 的关系 |
|------|------|------|
| Claude Code `/init` | 一次性生成单文件 CLAUDE.md | 本 skill 的"超集"——产出整套体系 |
| `claude-md-improver` skill | 周期性审计 CLAUDE.md 是否落后于代码 | 互补——improver 做日常体检，本 skill 做创建/重构 |
| 本 skill | 创建 / 补全 / 重构整套文档体系 | — |

## 2. 用户故事

| 编号 | 场景 | 用户输入 | 期望产出 |
|------|------|----------|----------|
| US-1 | 空项目初始化 | `/bootstrap-claude-docs` 在新建空目录里 | 完整骨架（占位 + TODO），让用户跟着填 |
| US-2 | 已有项目补全 | `/bootstrap-claude-docs` 在已有代码、缺文档的项目里 | 扫描代码后推断架构，生成顶层文件 + docs/ 子目录索引 |
| US-3 | 重构已有 CLAUDE.md | `/bootstrap-claude-docs` 在已有 CLAUDE.md 但不符合体系的项目 | 拆分 CLAUDE.md → ARCHITECTURE.md + 规则段落，备份原文件 |
| US-4 | 自动触发（非显式） | "帮我搭一套像 insilico-pilot 那样的文档结构" | skill description 命中，自动进入 Phase 0 |
| US-5 | 安装后日常维护 | 用户在被 bootstrap 过的项目里写新功能 | 项目级 `maintain-claude-docs` skill 自动提醒该写哪份文档 |

## 3. 仓库结构与发布约定

### 3.1 仓库结构

```
claude-md-guide/
├── README.md                                  # 项目介绍 + 安装方式 + 使用示例
├── LICENSE                                     # MIT
├── skills/
│   └── bootstrap-claude-docs/                  # ↔ ~/.claude/skills/bootstrap-claude-docs/
│       ├── SKILL.md                            # 主流程，≤ 500 词（社区惯例）
│       ├── references/                         # 深度文档（被 SKILL.md 按需引用）
│       │   ├── design-philosophy.md            # 5 大设计哲学详述
│       │   ├── project-type-variants.md        # 7 种项目类型差异化指引
│       │   ├── phase-1-checklist.md            # 扫描完成判定标准
│       │   ├── phase-2-checklist.md            # 骨架完整性检查
│       │   ├── phase-3-checklist.md            # 内容质量门
│       │   ├── sample-CLAUDE.md                # 去标识化样例
│       │   └── sample-ARCHITECTURE.md
│       └── templates/                          # 顶层 templates/，符合社区惯例
│           ├── CLAUDE.md.tmpl
│           ├── ARCHITECTURE.md.tmpl
│           ├── AGENTS.md.tmpl
│           ├── docs-decisions-README.tmpl
│           ├── docs-insights-README.tmpl
│           ├── docs-research-README.tmpl
│           ├── docs-exec-plans-README.tmpl
│           ├── adr.tmpl
│           ├── tech-debt-tracker.tmpl
│           ├── exec-plan.tmpl
│           ├── claudeignore.tmpl
│           ├── sub-package-CLAUDE.md.tmpl
│           └── maintain-claude-docs-SKILL.md.tmpl   # 目标项目里的维护 skill 模板
├── tests/
│   └── fixtures/                               # 第二期添加（参考第 10.2 节）
│       ├── empty/
│       ├── nextjs-app/
│       └── python-cli/
├── docs/
│   └── design.md                               # 本文件（skill 自身的 meta 设计文档）
└── CHANGELOG.md
```

仓库的 `skills/` 镜像 `~/.claude/skills/` 的目录结构，安装即 1:1 拷贝。

### 3.2 安装方式

README 提供三种装法：

```bash
# 1. 手动拷贝（最稳）
cp -r skills/bootstrap-claude-docs ~/.claude/skills/

# 2. Symlink（开发者，改源即生效）
ln -s "$PWD/skills/bootstrap-claude-docs" ~/.claude/skills/bootstrap-claude-docs

# 3. 让 Agent 自己装
# 在 Claude Code 里说："帮我安装这个仓库里的 skill"
```

不提供 install.sh——遵循 Claude Code skill 社区惯例（拷贝即用）。

### 3.3 触发协同

| 方式 | 触发点 |
|------|--------|
| Slash command | 用户输入 `/bootstrap-claude-docs` |
| Description 自动触发 | SKILL.md 的 description 命中 "initialize project docs" / "create CLAUDE.md system" / "搭建文档体系" / "初始化文档" 等关键词 |
| 明示调用 | "用 bootstrap-claude-docs skill" |

## 3.4 SKILL.md 自身格式约束（社区规范）

遵循 [Claude Code skill 社区写作规范](https://agentskills.io/specification) 与 superpowers/writing-skills 指南：

**Frontmatter 字段**：

```yaml
---
name: bootstrap-claude-docs
description: |
  Use when initializing, creating, restructuring, or scaffolding a project's documentation
  system for Claude Code — covering CLAUDE.md, ARCHITECTURE.md, AGENTS.md, and docs/
  subdirectories. Use when user says: 初始化文档体系, 搭建 CLAUDE.md 体系, 建立项目文档框架,
  bootstrap project docs, scaffold CLAUDE.md system. Use also when /init output feels too thin
  or when an existing CLAUDE.md needs restructuring into a multi-file system.
---
```

**关键纪律：**

| 约束 | 原因 |
|------|------|
| description 只写**何时用**，不摘要工作流 | 摘要 workflow 会让 Claude 跳过读 SKILL.md，直接按 description 操作。多次社区测试已证 |
| description 第三人称，"Use when..." 起手 | 注入到系统提示，统一句式 |
| 总长度 ≤ 1024 字符 | 平台限制 |
| name 仅含字母/数字/连字符 | 与 slash command 命名规则一致 |
| SKILL.md 正文 ≤ 500 词 | Token 效率；深内容下沉到 references/ |
| 引用其他 skill 用名字而非 `@` | `@` 会强制加载耗 200k 上下文 |

**SKILL.md 正文骨架（占位）**：

```markdown
# Bootstrap Claude Docs

## Overview
（1-2 句核心原则）

## When to Use / Skip
（症状清单 + 不适用场景）

## Workflow
Phase 0 → Phase 1 → Phase 2 → Phase 3
（每步一句话；详细 checklist 见 references/phase-N-checklist.md）

## Quick Reference
（项目类型 → 模板变体的查询表）

## Common Mistakes
（常见错误 + 修正）
```

深度内容（5 大哲学 / 7 种变体 / 3 个 phase 清单 / 3 份去标识化样例）通通在 `references/`，SKILL.md 按需 link。

## 4. 工作流

三个 Phase，三个检查点，每次对话都在检查点处暂停等用户确认。每个 Phase 开始时，把 `checklists/phase-N.md` 转成 TodoWrite 项跟踪。

### 4.1 Phase 0：入口分流

```
┌─────────────────────────────────────────────────┐
│ 检测 cwd 状态：                                   │
│  - 是否空目录（仅含 .git）？                       │
│  - 是否已有 CLAUDE.md / AGENTS.md / ARCHITECTURE.md？│
│  - 是否已有部分 docs/ 子目录？                     │
│  → 三种路径：greenfield / complete / restructure │
└─────────────────────────────────────────────────┘
              ★ 检查点 0：用户确认走哪条路径
                （检测出 restructure 时必须明示 ASK
                 用户：要重构吗？还是只补全缺失部分？）
```

### 4.2 Phase 1：扫描与推断（不动文件）

| 步骤 | 动作 | 工具 |
|------|------|------|
| 1.1 | 项目类型识别 | 读 package.json / pyproject.toml / Cargo.toml / go.mod / Gemfile 等 |
| 1.2 | 主语言识别 | 读 README + 抽样代码注释；若 ≥ 1 个中文 README/注释比例高 → 中文，否则 ask |
| 1.3 | 关键模块推断 | 列目录、识别 src/ / lib/ / app/ / cmd/ 等入口结构 |
| 1.4 | 现有文档清点 | grep `**/CLAUDE.md` `**/AGENTS.md` `docs/**` `README*` |
| 1.5 | 输出扫描报告 | 项目类型 / 推断架构 / 缺口清单 / **假设列表** |

```
              ★ 检查点 1：用户审阅"假设列表"
                - 修正项目类型
                - 追加未被识别的关键模块
                - 确认主语言
```

### 4.3 Phase 2：骨架生成（先写到 staging，确认后落盘）

| 步骤 | 产出 |
|------|------|
| 2.1 选模板变体 | 根据 Phase 1 类型选 `templates/<variant>.tmpl` |
| 2.2 顶层文件 | CLAUDE.md / ARCHITECTURE.md / AGENTS.md（CLAUDE.md 必含「改动自查清单」+「文档索引」+「工作流纪律」段落） |
| 2.3 docs 索引 | docs/{decisions, insights, research, exec-plans}/README.md |
| 2.4 模板辅助文件 | docs/exec-plans/tech-debt-tracker.md（空表）、docs/exec-plans/exec-plan-template.md |
| 2.5 ★ 项目级维护 skill | 在**目标项目**里生成 `.claude/skills/maintain-claude-docs/SKILL.md`（与本 skill 的源仓库无关），description 适配项目类型 |

> **Staging 时序**：步骤 2.1–2.5 全部先写到目标项目下的 `.claude-docs-staging/` 临时目录，**不直接落盘**到最终位置。

```
              ★ 检查点 2：用户审阅 .claude-docs-staging/ 里的骨架
                - 标注哪些章节让 skill 深填
                - 标注哪些章节自己写
                - 标注哪些子目录不需要（删除）
                - 用户确认 → 原子 mv 到正式位置 → 删除 staging
                - 用户拒绝 → 删 staging，回 Phase 1
```

### 4.4 Phase 3：深度填充与验证

| 步骤 | 动作 |
|------|------|
| 3.1 深推断 | 对用户在检查点 2 标注的章节读源码、grep、推数据流 |
| 3.2 ARCHITECTURE 真实化 | 「目录结构 / 数据流 / 技术栈」用扫描数据填充，不再占位 |
| 3.3 索引校验 | decisions/README 决策矩阵与文件对齐；各目录 README 索引与实际文件对齐 |
| 3.4 索引校验 | 每个 docs/<dir>/README.md 与目录内文件对齐 |
| 3.5 输出使用指南 | 终端打印「日常如何维护这套体系」简短卡片 |

> **若用户在检查点 2 没标任何章节**：跳过 3.1，仍执行 3.2–3.5（保留骨架的占位符 + TODO，后续靠 maintain-claude-docs 填）。

```
              ★ 检查点 3：用户最终确认
                - 失败项 → 回到 Phase 2 修正
                - 全通过 → 完成
```

## 5. 5 大设计哲学（详见 references/design-philosophy.md）

每条原则在 references 文档里都附 **做什么 / 反例 / 为什么 / 怎么落到模板** 四节。

| # | 名称 | 一句话 |
|---|------|--------|
| 1 | 关注点分离 | CLAUDE.md 不写架构，ARCHITECTURE.md 不写规则，docs/ 不写流程 |
| 2 | 决策追溯独立 | 架构/产品决策进 `docs/decisions/`（ADR 格式），不混在其他目录 |
| 3 | 自维护索引 | 每个 docs 子目录的 README.md 是它的目录索引，文件增删必须同步 |
| 4 | 计划驱动 | 中大型功能、研究、债务都进 docs/ 留痕，AI 和人都能从中检索 |
| 5 | 自检纪律 | CLAUDE.md 写"改完代码 commit 前要确认 X / Y / Z"，AI 也守 |

## 6. 项目类型变体（references/project-type-variants.md）

| 类型 | 检测信号 | ARCHITECTURE 必填 | docs/ 调整 |
|------|----------|-------------------|-----------|
| Web 应用 | Next.js / Vite / Django / Rails | 路由 / 数据流 / DB schema / API / 前后端边界 | 全 4 类 |
| CLI 工具 | bin 入口 / cobra / click / commander | 命令树 / IO 协议 / 配置加载 | decisions + research + exec-plans（默认无 insights） |
| 库 / SDK | 主导出 / 多版本支持 | 公共 API 表面 / 版本兼容矩阵 / 扩展点 | decisions + research + exec-plans |
| 后端服务 | Dockerfile + 长进程 | 服务边界 / 队列 / 数据流 / SLO | 全 4 类 |
| Monorepo | workspaces / lerna / nx / turborepo | 工作区图 / 包依赖图 / 发布流 | 顶层 + 每包轻量 CLAUDE.md |
| 移动 App | iOS / Android / RN / Flutter | 平台分支 / 状态管理 / 原生桥 | decisions + insights + exec-plans |
| 数据 / Notebook | .ipynb 多 / DAG 文件 | Pipeline DAG / 数据契约 / 实验记录 | research 比 insights 重要 |

## 7. 项目级维护 skill（核心创新）

bootstrap-claude-docs 在 Phase 2.5 会在**目标项目**（不是源仓库）里生成 `.claude/skills/maintain-claude-docs/SKILL.md`。这是一个**项目级**（project-scoped）skill，会随项目入 git，在那个项目内对所有协作者生效。该 skill 的作用：**让那个项目之后的每次 Claude 会话都能自动想起来维护文档体系**。

```yaml
---
name: maintain-claude-docs
description: |
  Use when adding a new feature, fixing a bug, completing an exec-plan, finding tech debt,
  or modifying files in src/. Reminds Claude to update the documentation system
  (decisions/ADRs, insights, research, exec-plans, README indexes, tech debt tracker).
---
```

触发后跑一遍清单：

1. 是否产生新的架构/产品决策 → 是否需在 `docs/decisions/` 新增 ADR？
2. 是否构成新功能或新模块 → `ARCHITECTURE.md` 对应章节是否需更新？
3. 是否涉及产品视角的"为什么" → 是否需在 `docs/insights/` 写一份？
4. 是否增删了文档文件 → `docs/<dir>/README.md` 索引同步了吗？
5. 发现技术债务 → 进 `docs/exec-plans/tech-debt-tracker.md` 了吗？
6. 中大型功能开工 → 起 `docs/exec-plans/active/<topic>.md` 了吗？
7. 完成 exec-plan → 移到 `completed/` 了吗？
8. 季度审计 → CLAUDE.md 是否有过时规则需清理？

清单内容由 bootstrap 时根据项目变体定制（Library 类型项目 description 改为"修改公共 API 表面时"等）。

## 8. 重构路径（restructure existing CLAUDE.md）

适用 US-3。流程：

1. 读现有 CLAUDE.md，按段落语义分类：
   - **规则 / 流程类** → 留在 CLAUDE.md
   - **架构 / 数据流 / 技术栈** → 搬 ARCHITECTURE.md
   - **某具体功能详解** → 模块级深入由 ARCHITECTURE.md 或代码 docstring 承担
2. 输出 diff 预览给用户（每段去哪一目了然）
3. 备份原文件 `CLAUDE.md.bak.<timestamp>`
4. 执行迁移
5. 走标准 Phase 2/3 后续步骤补齐缺失的部分

> 检查点：每个章节的搬迁去向**逐项让用户确认**，不批量自动决定。

## 9. 边界 / Edge cases

| 场景 | 处理 |
|------|------|
| 现有 ARCHITECTURE.md | 不覆盖；展示差异并提示用户合并 |
| Monorepo 多 package | 先处理根层，子包下沉为 follow-up（不阻塞） |
| 用户拒绝某些产出（如不要 insights） | 跳过；CLAUDE.md 显式注明"该项目不维护 insights" |
| 生成失败 | 原子化——先全写到 `.claude-docs-staging/`，全部成功才 mv |
| 国际化 | 模板用 `{{...}}` 占位；按检测到的项目语言填中/英 |
| 用户已有 `.claude/skills/maintain-claude-docs/` | 提示并 ask：覆盖 / 合并 / 跳过 |
| Git 未初始化 | 不强制 git init；只在文件层面工作；提示用户后续可 git init |

## 10. 测试与验证

### 10.1 自检 checklist

每个 phase 结束时由 `checklists/phase-N.md` 自动校验：

- **phase-1-scan.md**：项目类型已识别 / 主语言已确认 / 假设列表已生成 / 用户已确认
- **phase-2-skeleton.md**：所有顶层文件已生成 / 索引 README.md 完整 / 维护 skill 已生成 / staging 已 mv
- **phase-3-content.md**：索引与目录对齐 / decisions 矩阵完整 / 使用指南已输出

任何一项不通过 → 阻塞继续，必须先修复。

### 10.2 Fixture 项目测试

仓库 `tests/fixtures/` 提供 3 个示例项目供回归测试：

| Fixture | 类型 | 期望产出 |
|---------|------|----------|
| `tests/fixtures/empty/` | Greenfield | 完整骨架 + 占位 TODO |
| `tests/fixtures/nextjs-app/` | Web 应用 | ARCHITECTURE.md 含路由/API 真实化 |
| `tests/fixtures/python-cli/` | CLI 工具 | docs/insights 缺省、decisions/research 完整 |

每个 fixture 在 `expected/` 下放期望产出，`run-tests.sh` 跑 skill 后 diff 对比。

> Fixture 测试不阻塞首版发布——首版先靠 1 次 insilico-pilot 真实跑通 + 1 次 empty 跑通验收，fixture 套件在第一个 patch 版本里加。

## 11. 验收标准（首版发布门）

- [ ] `/bootstrap-claude-docs` 在 `tests/fixtures/empty/` 上跑通，产出符合 phase-3 checklist
- [ ] `/bootstrap-claude-docs` 在某真实 Next.js 项目（claude-md-guide 自身）上跑通
- [ ] 重构路径在一份"无体系的旧 CLAUDE.md"上跑通，diff 预览正确
- [ ] 生成的项目级 maintain-skill 在被 bootstrap 过的项目里能被 Claude Code 加载并自动触发
- [ ] README.md 的三种安装方式至少有一种被验证
- [ ] design-philosophy.md 全文写完，每条原则四节齐全
- [ ] project-type-variants.md 7 种变体都有最简模板差异

## 12. 非目标 / 未来工作

- **不做**：跨语言文档同步（用户改了 ARCHITECTURE.md 中文版，自动同步英文版）
- **不做**：周期性体检（已有 `claude-md-improver` 负责）
- ~~**未来**：多 package monorepo 子包级 CLAUDE.md 自动生成~~ ✅ v0.2.0 已实现（sub-package-CLAUDE.md.tmpl）
- **未来**：与 git hooks 集成（commit 前自动跑 maintain-claude-docs 清单）
- **未来**：把 design-philosophy.md 翻成英文版给国际用户用

## 13. 决策日志

| 日期 | 决策 | 原因 |
|------|------|------|
| 2026-04-29 | 不提供 install.sh | 不符合 [Claude Code skill 社区惯例](https://www.skillsdirectory.com/docs/installing-skills)，agent 自身可代装 |
| 2026-04-29 | 双轨维护：CLAUDE.md + 项目级 skill | 单纯 CLAUDE.md 在大上下文下偶尔被忽略；项目级 skill 通过 description 主动触发更稳 |
| 2026-04-29 | 模板用 `{{...}}` + 项目类型变体表 | 既保持设计哲学统一，又不强迫所有项目长得一样 |
| 2026-04-29 | Phase 2 用 staging tmp 目录 | 失败原子回滚，不污染用户项目 |
| 2026-04-29 | 重构路径走逐章节确认而非批量 | CLAUDE.md 是项目"心脏"，错搬一段成本高 |
| 2026-04-29 | 用户可见产物不引用 insilico-pilot | design.md 是 meta 文档可保留参考；README.md / SKILL.md / templates / examples 全部去标识化，避免泄露真实项目并保持 skill 通用 |
| 2026-04-29 | skill 目录改为顶层 `references/` + 顶层 `templates/`，去掉 `checklists/` 顶层 | 遵循 [社区惯例](https://agentskills.io/specification)：约定顶层只有 references/ scripts/ templates/ assets/ 四种；checklists 归入 references/ |
| 2026-04-29 | description 只写"何时用"不摘要工作流 | superpowers/writing-skills 实测：description 摘要 workflow 会让 Claude 跳过读 SKILL.md。同时 description ≤ 1024 字符 |
| 2026-04-29 | SKILL.md 正文 ≤ 500 词 | Token 效率；深内容下沉 references/。引用其他 skill 用名字不用 @ 路径，避免强制加载 200k 上下文 |
