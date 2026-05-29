# bootstrap-claude-docs 实现计划（v1 历史文档）

> **⚠️ 本文件是 v0.1.0 的实现计划，已全部完成。v0.2.0 引入了"decisions 取代 handover"的重构，本文件中的 handover 引用已过时，保留仅作历史参考。**

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 实现一个 Claude Code skill `bootstrap-claude-docs`，指导 Claude 为目标项目从 0 创建或重构一整套文档体系（CLAUDE.md / ARCHITECTURE.md / AGENTS.md / docs/ + 项目级维护 skill）。

**Architecture:** 仓库 = 一份可分享的 skill 包。`skills/bootstrap-claude-docs/` 镜像 `~/.claude/skills/`，`commands/` 镜像 `~/.claude/commands/`。SKILL.md 作为薄主流程（≤ 500 词），深度内容下沉到 `references/`，10 个模板放 `templates/`。设计哲学不在 SKILL.md 里展开，由 SKILL.md 按需引用 references。

**Tech Stack:** Markdown only。无需打包/构建。模板用 `{{占位符}}` 风格，由 skill 在运行时填充。

> **依赖说明：** 设计文档见 `docs/design.md`，plan 中的所有「具体内容应该是什么」都以 design.md 为准；plan 描述的是「按什么顺序创建什么文件 + 每一步如何自验」。

---

## 文件结构（最终态）

```
claude-md-guide/
├── README.md                                       # T1 + T16
├── LICENSE                                         # T1
├── CHANGELOG.md                                    # T1
├── .gitignore                                      # T1
├── docs/
│   ├── design.md                                   # 已存在（spec）
│   └── plan.md                                     # 本文件
├── skills/
│   └── bootstrap-claude-docs/
│       ├── SKILL.md                                # T13
│       ├── references/
│       │   ├── phase-1-checklist.md                # T2
│       │   ├── phase-2-checklist.md                # T3
│       │   ├── phase-3-checklist.md                # T4
│       │   ├── design-philosophy.md                # T5
│       │   ├── project-type-variants.md            # T6
│       │   ├── sample-CLAUDE.md                    # T7
│       │   ├── sample-ARCHITECTURE.md              # T7
│       │   └── sample-handover.md                  # T7
│       └── templates/
│           ├── CLAUDE.md.tmpl                      # T8
│           ├── ARCHITECTURE.md.tmpl                # T9
│           ├── AGENTS.md.tmpl                      # T9
│           ├── docs-handover-README.tmpl           # T10
│           ├── docs-insights-README.tmpl           # T10
│           ├── docs-research-README.tmpl           # T10
│           ├── docs-exec-plans-README.tmpl         # T10
│           ├── tech-debt-tracker.tmpl              # T11
│           ├── exec-plan.tmpl                      # T11
│           └── maintain-claude-docs-SKILL.md.tmpl  # T12
└── commands/
    └── bootstrap-docs.md                           # T14
```

每个 Task 一次提交。文件名前缀 T# 标明 task 归属。

---

## Task 1: 仓库骨架 + git init

**Files:**
- Create: `LICENSE`
- Create: `CHANGELOG.md`
- Create: `.gitignore`
- Create: `README.md`（占位骨架；T16 完善）

- [ ] **Step 1：检查 cwd 没有现有 git**

```bash
ls -la /data/lidongyu/projects/claude-md-guide/.git 2>/dev/null && echo "EXISTS" || echo "OK to init"
```
预期：`OK to init`

- [ ] **Step 2：创建 LICENSE（MIT）**

```text
MIT License

Copyright (c) 2026 小天

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

- [ ] **Step 3：创建 CHANGELOG.md**

```markdown
# Changelog

## [Unreleased]

### Added
- 项目初始化
```

- [ ] **Step 4：创建 .gitignore**

```
.DS_Store
*.bak.*
.claude-docs-staging/
node_modules/
.idea/
.vscode/
```

- [ ] **Step 5：创建 README.md 占位**

```markdown
# claude-md-guide

> bootstrap-claude-docs — 为项目构建可落地、可维护的 Claude Code 文档体系

（详细使用说明在 T16 补全）
```

- [ ] **Step 6：git init + 首次提交**

```bash
cd /data/lidongyu/projects/claude-md-guide
git init
git add LICENSE CHANGELOG.md .gitignore README.md docs/design.md docs/plan.md
git commit -m "chore: 初始化仓库骨架"
```

预期：commit 成功，`git log` 显示 1 条记录。

---

## Task 2: references/phase-1-checklist.md（Phase 1 自检）

**Files:**
- Create: `skills/bootstrap-claude-docs/references/phase-1-checklist.md`

> Phase 1 是"扫描与推断"。这份 checklist 由 skill 在 Phase 1 结束时执行，全部通过才能进入检查点 1。

- [ ] **Step 1：创建目录**

```bash
mkdir -p skills/bootstrap-claude-docs/references
```

- [ ] **Step 2：写文件**

```markdown
# Phase 1 Checklist：扫描与推断

> 本 checklist 在 Phase 1 末尾执行；任意一项不过 → 阻塞，必须修复后才能进入检查点 1。

## 必过项

- [ ] **项目类型已识别**：从 `package.json` / `pyproject.toml` / `Cargo.toml` / `go.mod` / `Gemfile` / `*.podspec` / `pubspec.yaml` 至少一处推断出类型，分类落入 `references/project-type-variants.md` 7 种之一
- [ ] **主语言已确认**：依据 `README*` 字符占比 + 抽样代码注释；若无法判断必须 ASK 用户
- [ ] **关键模块已列出**：识别 `src/` `lib/` `app/` `cmd/` `internal/` `pkg/` 等入口结构；对每个一级子目录给出"看起来是做什么的"猜测
- [ ] **现有文档已清点**：grep `**/CLAUDE.md` `**/AGENTS.md` `**/ARCHITECTURE.md` `docs/**` `README*`；列出存在的、缺失的
- [ ] **入口路径已分流**：greenfield / complete / restructure 三选一已确定
- [ ] **假设清单已生成**：每条推断都带"假设"标签，且呈交给用户审阅
- [ ] **用户已对假设清单做出回应**：确认 / 修正 / 追加

## 不应触发的事件

- [ ] 没写任何文件（Phase 1 严禁动盘）
- [ ] 没启动 `.claude-docs-staging/`（Phase 2 才用）
```

- [ ] **Step 3：自验**

```bash
test -f skills/bootstrap-claude-docs/references/phase-1-checklist.md && \
  grep -c '^- \[ \]' skills/bootstrap-claude-docs/references/phase-1-checklist.md
```

预期：≥ 8（7 个必过 + 至少 1 个不应触发）。

- [ ] **Step 4：commit**

```bash
git add skills/bootstrap-claude-docs/references/phase-1-checklist.md
git commit -m "feat(skill): add phase-1 scan checklist"
```

---

## Task 3: references/phase-2-checklist.md（Phase 2 自检）

**Files:**
- Create: `skills/bootstrap-claude-docs/references/phase-2-checklist.md`

- [ ] **Step 1：写文件**

```markdown
# Phase 2 Checklist：骨架生成

> 本 checklist 在 Phase 2 末尾执行；全部通过 + 用户审阅 staging 后，才能 mv 到正式位置。

## 文件存在性（写到 .claude-docs-staging/）

- [ ] `CLAUDE.md`
- [ ] `ARCHITECTURE.md`
- [ ] `AGENTS.md`
- [ ] `docs/handover/README.md`
- [ ] `docs/insights/README.md`
- [ ] `docs/research/README.md`
- [ ] `docs/exec-plans/README.md`
- [ ] `docs/exec-plans/tech-debt-tracker.md`
- [ ] `docs/exec-plans/exec-plan-template.md`
- [ ] `.claude/skills/maintain-claude-docs/SKILL.md`

## CLAUDE.md 必含段落

- [ ] `## 改动自查` 或同义节
- [ ] `## 文档` 索引节（链接所有 docs/<dir>/）
- [ ] `## 工作流` 或 `## 开发规则` 节

## 维护 skill 必含字段

- [ ] frontmatter 有 `name: maintain-claude-docs`
- [ ] description 以 `Use when` 开头，包含项目类型相关触发词
- [ ] 正文包含至少 6 项检查清单

## 内容真实性

- [ ] 所有 `{{占位符}}` 已被填或被显式标 `<!-- TODO: -->`
- [ ] 没有遗留 `lorem ipsum` 或英文模板词残留（中文项目）

## 双链先验

- [ ] handover/README.md 与 insights/README.md 在索引格式上对齐
- [ ] 暂无具体功能文档，但 README 已给出"未来怎么对齐反链"的写法说明
```

- [ ] **Step 2：自验**

```bash
grep -c '^- \[ \]' skills/bootstrap-claude-docs/references/phase-2-checklist.md
```

预期：≥ 16

- [ ] **Step 3：commit**

```bash
git add skills/bootstrap-claude-docs/references/phase-2-checklist.md
git commit -m "feat(skill): add phase-2 skeleton checklist"
```

---

## Task 4: references/phase-3-checklist.md（Phase 3 自检）

**Files:**
- Create: `skills/bootstrap-claude-docs/references/phase-3-checklist.md`

- [ ] **Step 1：写文件**

```markdown
# Phase 3 Checklist：深度填充与验证

> 本 checklist 在 Phase 3 末尾执行；全部通过即首版完成。任何一项不过 → 回 Phase 2 修正。

## 内容质量

- [ ] ARCHITECTURE.md 的「目录结构」基于实际 `ls`/`tree` 输出，不是模板占位
- [ ] ARCHITECTURE.md 的「数据流」/「技术栈」至少有一段实质内容（即使是骨架）
- [ ] 用户在检查点 2 标注的章节均已深填；未标注的章节保留 `<!-- TODO: -->` 占位

## 索引与双链

- [ ] 每个 `docs/<dir>/README.md` 的索引表与该目录实际文件对齐（无遗漏、无幻觉）
- [ ] 若已有 handover 文档：对应 insights 文件名一致，且互相反向链接
- [ ] CLAUDE.md 文档索引节的链接全部存在且可点击

## 维护 skill 健全

- [ ] 项目级 maintain-claude-docs/SKILL.md 已落到 `.claude/skills/`
- [ ] 该 skill 的 description 适配本项目类型（不是通用模板）

## 收尾产物

- [ ] 已打印「使用指南」卡片：日常该往哪写什么、维护 skill 何时触发
- [ ] `.claude-docs-staging/` 已清理
- [ ] 无原文件被覆盖（重构路径除外，且备份已存在）
```

- [ ] **Step 2：commit**

```bash
git add skills/bootstrap-claude-docs/references/phase-3-checklist.md
git commit -m "feat(skill): add phase-3 content checklist"
```

---

## Task 5: references/design-philosophy.md（5 大设计哲学）

**Files:**
- Create: `skills/bootstrap-claude-docs/references/design-philosophy.md`

> 内容来源：design.md §5。每条原则按 4 节展开：**做什么 / 反例 / 为什么 / 怎么落到模板**。

- [ ] **Step 1：写文件骨架并填充**

文件大纲：
```markdown
# 设计哲学

bootstrap-claude-docs 的 5 条可移植原则。每条都附「做什么 / 反例 / 为什么 / 怎么落到模板」。

## 1. 关注点分离（Separation of Concerns）

**做什么**：CLAUDE.md 写规则与流程；ARCHITECTURE.md 写结构与数据流；docs/ 写深度。三者职责互斥。

**反例**：把目录结构、数据流图、API 列表全塞进 CLAUDE.md，文件膨胀到 800 行 → AI 读不完，规则被深埋。

**为什么**：CLAUDE.md 自动注入每次会话上下文；越短越容易被完整读到。架构会随代码漂移；放进 ARCHITECTURE.md 才能由专门的 audit 流程同步。

**怎么落到模板**：`CLAUDE.md.tmpl` 严禁出现"目录结构 / 数据库 schema / API 路由表"段落；这些段落只在 `ARCHITECTURE.md.tmpl`。

## 2. 双视角文档（Dual-Perspective）

**做什么**：每个重要功能配两份文档：`docs/handover/<feature>.md`（技术）+ `docs/insights/<feature>.md`（产品），文件名一致并互链。

**反例**：只写技术文档 → 半年后没人记得"为什么这么设计"，提需求的人换了，决策被反复推翻。

**为什么**：技术文档解决"怎么实现"，产品文档解决"为什么这么实现"。两者读者不同、生命周期不同。

**怎么落到模板**：`docs-handover-README.tmpl` 和 `docs-insights-README.tmpl` 各自独立索引，但格式对齐；维护 skill 在写新功能时同时提醒两份。

## 3. 自维护索引（Self-Maintaining Index）

**做什么**：每个 `docs/<dir>/README.md` 是该子目录的索引；新增/删除文件必须同步更新表格。

**反例**：docs/ 目录下 30 份文件，没索引 → AI 检索时只能 grep，找不到的就当不存在；新人读不出脉络。

**为什么**：AI 和人都先看 README。索引漂移是"找不到 → 重写一份 → 重复" 的根因。

**怎么落到模板**：所有 `docs-*-README.tmpl` 都明示「AI 须知：修改或新增文件后更新下方索引；检索本目录前先读此文件」；维护 skill 在 6 项清单里包含"索引同步了吗"。

## 4. 计划驱动开发（Plan-Driven）

**做什么**：中大型功能开工前先写 `docs/exec-plans/active/<topic>.md`，含 phases、状态、决策日志；完成后移到 `completed/`。纯研究进 `docs/research/`。技术债务进 `tech-debt-tracker.md`。

**反例**：直接开干 → 中途换需求、回滚、不知道为啥这么写；技术债务遍地无人收。

**为什么**：让 AI 和人都能从文档检索"这个项目目前在干嘛 / 为什么这么决定 / 哪里欠债"。

**怎么落到模板**：`docs-exec-plans-README.tmpl` 给出何时需要执行计划的判断标准 + 模板结构。

## 5. 自检纪律（Self-Check Discipline）

**做什么**：CLAUDE.md 自带「改动自查」清单（改动是否涉及 i18n / db / types / 文档？）；项目级 maintain-claude-docs skill 通过 description 主动触发。

**反例**：规则散落在 commit message / PR 模板 / wiki → AI 看不到，每次都要人提醒；新人入职第三个月才知道还要改 i18n。

**为什么**：CLAUDE.md 是项目入口，所有约束写这里才稳；项目级 skill 作为冗余保险，让"忘了"成本更低。

**怎么落到模板**：`CLAUDE.md.tmpl` 必含 `## 改动自查` 段；`maintain-claude-docs-SKILL.md.tmpl` 把同样的清单变成主动触发的 skill。
```

- [ ] **Step 2：自验**

```bash
grep -c '^## ' skills/bootstrap-claude-docs/references/design-philosophy.md
```
预期：≥ 6（5 条哲学 + 文件总览节）

```bash
grep -c '\*\*做什么\*\*' skills/bootstrap-claude-docs/references/design-philosophy.md
```
预期：5

- [ ] **Step 3：commit**

```bash
git add skills/bootstrap-claude-docs/references/design-philosophy.md
git commit -m "feat(skill): add design philosophy reference"
```

---

## Task 6: references/project-type-variants.md（7 种项目类型变体）

**Files:**
- Create: `skills/bootstrap-claude-docs/references/project-type-variants.md`

> 内容来源：design.md §6。7 种类型 × 3 个轴：检测信号 / ARCHITECTURE 必填章节 / docs/ 调整。

- [ ] **Step 1：写文件**

模式：
```markdown
# 项目类型变体

7 种项目类型的差异化指引。Phase 1 识别后用对应变体填模板。

## 总览表

| 类型 | 检测信号 | ARCHITECTURE 必填 | docs/ 调整 |
|------|----------|-------------------|-----------|
| Web 应用 | Next.js / Vite / Django / Rails | 路由 / 数据流 / DB schema / API / 前后端边界 | 全 4 类 |
| CLI 工具 | bin 入口 / cobra / click / commander | 命令树 / IO 协议 / 配置加载 | 主用 handover + research |
| 库 / SDK | 主导出 / 多版本支持 | 公共 API 表面 / 版本兼容矩阵 / 扩展点 | 主用 handover + research |
| 后端服务 | Dockerfile + 长进程 | 服务边界 / 队列 / 数据流 / SLO | 全 4 类 |
| Monorepo | workspaces / lerna / nx / turborepo | 工作区图 / 包依赖图 / 发布流 | 顶层 + 每包轻量 CLAUDE.md |
| 移动 App | iOS / Android / RN / Flutter | 平台分支 / 状态管理 / 原生桥 | handover + insights |
| 数据 / Notebook | .ipynb 多 / DAG 文件 | Pipeline DAG / 数据契约 / 实验记录 | research 比 insights 重要 |

## 1. Web 应用

### 检测信号
- `package.json` 含 `next` / `vite` / `react-router` / `@remix-run`
- `requirements.txt` / `pyproject.toml` 含 `django` / `flask` / `fastapi`
- `Gemfile` 含 `rails`

### ARCHITECTURE 必填章节
1. 路由表（页面路由 + API 路由）
2. 数据流（用户输入 → 渲染或持久化的关键链路）
3. 数据库 schema（如有 ORM，列出主表）
4. 部署模式（开发 / 生产 / 多环境差异）
5. 前后端边界（API 契约约定）

### docs/ 调整
保留全部 4 类（handover / insights / research / exec-plans）。

### maintain-claude-docs description 起手
`Use when adding a route, API endpoint, page, or modifying database schema...`

---

## 2. CLI 工具

### 检测信号
- `package.json` 含 `bin` 字段
- 入口文件 import `cobra` / `click` / `commander` / `clap`

### ARCHITECTURE 必填章节
1. 命令树（命令 + 子命令 + flag）
2. IO 协议（stdin / stdout / stderr / exit code 约定）
3. 配置加载链（env / file / flag 优先级）
4. 依赖的外部工具（如有 shell out）

### docs/ 调整
默认不要 `insights/`（CLI 工具产品决策少；让用户自己开启）；其余保留。

### maintain-claude-docs description 起手
`Use when adding or modifying a command, flag, or configuration option...`

---

## 3. 库 / SDK

### 检测信号
- `package.json` 含 `main`/`exports` 字段且**不**含 `bin`
- `setup.py` / `pyproject.toml` 的 `packages`
- `Cargo.toml` 含 `[lib]`

### ARCHITECTURE 必填章节
1. 公共 API 表面（导出符号清单 + 稳定性等级）
2. 版本兼容矩阵（支持的语言版本 / 平台 / 上游依赖）
3. 扩展点（plugin / hook / middleware 设计）

### docs/ 调整
默认 `handover/` + `research/`；`insights/` 可选；`exec-plans/` 保留。

### maintain-claude-docs description 起手
`Use when modifying public API surface, exports, or extension points...`

---

## 4. 后端服务

（参照 Web 应用，去掉前端相关，加 SLO / 队列 / 服务边界）

---

## 5. Monorepo

### 检测信号
- `package.json` 含 `workspaces`
- 根有 `lerna.json` / `nx.json` / `turbo.json` / `pnpm-workspace.yaml`

### ARCHITECTURE 必填章节
1. 工作区图（每个 package 一句话职责）
2. 包依赖图（相互引用关系）
3. 发布流（独立发布 vs 统一发布）

### docs/ 调整
顶层全 4 类；建议每个 package 一份轻量 CLAUDE.md（指向根 CLAUDE.md + 自己的特殊点）。

---

## 6. 移动 App

### 检测信号
- `Podfile` / `*.xcodeproj` / `build.gradle` / `pubspec.yaml` / `package.json` 含 `react-native`

### ARCHITECTURE 必填章节
1. 平台分支（iOS / Android 差异点）
2. 状态管理（Redux / Riverpod / Provider 等）
3. 原生桥（如有 native module）

### docs/ 调整
保留 `handover/` + `insights/`；`research/` 视情况。

---

## 7. 数据 / Notebook

### 检测信号
- `**/*.ipynb` 数量 > 3
- 有 `airflow/` / `prefect/` / `dagster/` 目录

### ARCHITECTURE 必填章节
1. Pipeline DAG
2. 数据契约（输入 / 输出 schema）
3. 实验记录约定

### docs/ 调整
`research/` 比 `insights/` 重要；建议把 `insights/` 与 `research/` 合并为单目录。
```

- [ ] **Step 2：自验**

```bash
grep -c '^## [0-9]\.' skills/bootstrap-claude-docs/references/project-type-variants.md
```
预期：7

- [ ] **Step 3：commit**

```bash
git add skills/bootstrap-claude-docs/references/project-type-variants.md
git commit -m "feat(skill): add project type variants reference"
```

---

## Task 7: references/sample-*.md（去标识化样例 × 3）

**Files:**
- Create: `skills/bootstrap-claude-docs/references/sample-CLAUDE.md`
- Create: `skills/bootstrap-claude-docs/references/sample-ARCHITECTURE.md`
- Create: `skills/bootstrap-claude-docs/references/sample-handover.md`

> **重要**：这 3 份样例必须去标识化——不引用 insilico-pilot 或任何真实项目。设计假想项目 `acme-app`（虚构 SaaS）作为样例项目。

- [ ] **Step 1：sample-CLAUDE.md（约 100 行）**

骨架：
```markdown
# CLAUDE.md

acme-app — 虚构样例项目（仅作 bootstrap-claude-docs 演示用）。

> 架构细节见 [ARCHITECTURE.md](./ARCHITECTURE.md)。本文件只含规则与流程。

## 开发规则
- 提交前必须跑 `npm test`
- UI 改动必须截图自验
- 新功能必须先写计划

## 改动自查
1. 改动是否涉及类型 → 是否更新 `src/types/`
2. 改动是否涉及 schema → 是否更新迁移
3. 改动是否涉及文档 → 是否同步 `docs/`

## 工作流
新功能：调研 → 计划 → 实现 → 验证 → 文档

## 文档
- [ARCHITECTURE.md](./ARCHITECTURE.md)
- `docs/handover/` — 技术交接
- `docs/insights/` — 产品思考
- `docs/research/` — 调研
- `docs/exec-plans/` — 执行计划
```

- [ ] **Step 2：sample-ARCHITECTURE.md（约 80 行）**

骨架：
```markdown
# ARCHITECTURE.md

acme-app 是一个虚构的 SaaS 看板工具。

## 目录结构
（虚构示例 src/ 树）

## 数据流
（用户操作 → API → DB → 渲染的链路图）

## 数据库
（虚构 3 张主表）

## 技术栈
（Next.js + PostgreSQL + Redis 等）
```

- [ ] **Step 3：sample-handover.md（约 60 行）**

骨架：
```markdown
# 评论系统 — 技术交接文档

> 产品思考见 [docs/insights/comments.md](../insights/comments.md)

## 核心思路
## 目录结构
## 数据流
## 关键设计决策
```

- [ ] **Step 4：自验**

```bash
ls skills/bootstrap-claude-docs/references/sample-*.md | wc -l
```
预期：3

```bash
grep -l 'insilico\|silicopilot' skills/bootstrap-claude-docs/references/sample-*.md
```
预期：空（不应匹配任何文件）

- [ ] **Step 5：commit**

```bash
git add skills/bootstrap-claude-docs/references/sample-*.md
git commit -m "feat(skill): add anonymized sample CLAUDE/ARCHITECTURE/handover"
```

---

## Task 8: templates/CLAUDE.md.tmpl（核心模板）

**Files:**
- Create: `skills/bootstrap-claude-docs/templates/CLAUDE.md.tmpl`

- [ ] **Step 1：创建目录**

```bash
mkdir -p skills/bootstrap-claude-docs/templates
```

- [ ] **Step 2：写模板**

```markdown
# CLAUDE.md

{{PROJECT_NAME}} — {{ONE_LINE_DESCRIPTION}}

> 架构细节见 [ARCHITECTURE.md](./ARCHITECTURE.md)。本文件只含规则与流程。

## 开发规则

{{DEV_RULES_SECTION}}
<!-- TODO: 列出本项目特有的开发规则。例：提交前必须跑 X / UI 改动必须 Y / 新功能必须 Z -->

## 自检命令

{{SELF_CHECK_COMMANDS}}
<!-- TODO: 列出本地可跑的检查命令，按耗时由短到长排序 -->

## 改动自查

完成代码修改后，在提交前确认：

{{CHANGE_REVIEW_CHECKLIST}}
<!-- TODO: 5-8 条本项目专属的自查项。参考样例：
1. 改动是否涉及类型 → 是否需要更新 `src/types/`
2. 改动是否涉及 schema → 是否需要更新迁移
3. 改动是否涉及国际化 → 是否需要同步翻译文件
4. 改动是否涉及文档 → 是否需要同步 docs/handover/
-->

## 工作流

{{WORKFLOW_SECTION}}
<!-- TODO: 描述本项目的标准开发工作流 -->

## 文档

- [ARCHITECTURE.md](./ARCHITECTURE.md) — 项目架构、目录结构、数据流
- `docs/handover/` — 技术交接文档（架构、数据流、设计决策）
- `docs/insights/` — 产品思考文档（用户问题、设计理由）
- `docs/research/` — 调研文档（技术方案、可行性分析）
- `docs/exec-plans/` — 执行计划（进度状态、决策日志、技术债务）

**检索前先读对应目录的 README.md；增删文件后更新索引。**
```

- [ ] **Step 3：自验**

```bash
grep -c '{{[A-Z_]\+}}' skills/bootstrap-claude-docs/templates/CLAUDE.md.tmpl
```
预期：≥ 5（5 个占位符）

```bash
grep -c '## ' skills/bootstrap-claude-docs/templates/CLAUDE.md.tmpl
```
预期：≥ 5（5 个二级节）

- [ ] **Step 4：commit**

```bash
git add skills/bootstrap-claude-docs/templates/CLAUDE.md.tmpl
git commit -m "feat(skill): add CLAUDE.md template"
```

---

## Task 9: templates/ARCHITECTURE.md.tmpl + AGENTS.md.tmpl

**Files:**
- Create: `skills/bootstrap-claude-docs/templates/ARCHITECTURE.md.tmpl`
- Create: `skills/bootstrap-claude-docs/templates/AGENTS.md.tmpl`

- [ ] **Step 1：写 ARCHITECTURE.md.tmpl**

```markdown
# ARCHITECTURE.md

{{PROJECT_NAME}} — {{ONE_LINE_ARCHITECTURE_OVERVIEW}}

## 目录结构

```
{{DIRECTORY_TREE}}
```
<!-- TODO: 用 tree 或 ls 输出实际目录，每个一级子目录加一句话职责注释 -->

## 数据流

{{DATA_FLOW_SECTION}}
<!-- TODO: 描述用户操作 → 数据持久化的关键链路。可用 ASCII 流程图 -->

## 数据库 / 持久化

{{PERSISTENCE_SECTION}}
<!-- TODO: 列主要数据存储与 schema；如无持久化层可删本节 -->

## 关键模块

{{KEY_MODULES_SECTION}}
<!-- TODO: 5-8 个最核心的模块/包，每个 1-3 句职责 -->

## 技术栈

| 层 | 技术 |
|----|------|
{{TECH_STACK_TABLE}}
<!-- TODO: 至少 5 行（前端 / 后端 / 数据库 / 测试 / 部署） -->

## 项目类型专属节

{{TYPE_SPECIFIC_SECTIONS}}
<!-- TODO: 根据 references/project-type-variants.md 对应类型的"必填章节"补全 -->
```

- [ ] **Step 2：写 AGENTS.md.tmpl**

```markdown
<!--
  AGENTS.md 是 CLAUDE.md 的镜像，给非 Claude 的 AI 工具读。
  内容应与 CLAUDE.md 完全一致；建议用同步脚本或 symlink。
-->

# AGENTS.md

{{COPY_OF_CLAUDE_MD}}
<!-- TODO: 默认与 CLAUDE.md 完全一致。bootstrap-claude-docs 在生成时直接复制 CLAUDE.md 内容；
     用户后续可按需 diverge -->
```

- [ ] **Step 3：自验**

```bash
ls skills/bootstrap-claude-docs/templates/ARCHITECTURE.md.tmpl skills/bootstrap-claude-docs/templates/AGENTS.md.tmpl
```
预期：两个文件均存在。

- [ ] **Step 4：commit**

```bash
git add skills/bootstrap-claude-docs/templates/ARCHITECTURE.md.tmpl \
        skills/bootstrap-claude-docs/templates/AGENTS.md.tmpl
git commit -m "feat(skill): add ARCHITECTURE and AGENTS templates"
```

---

## Task 10: templates/docs-*-README.tmpl × 4（docs 子目录索引模板）

**Files:**
- Create: `skills/bootstrap-claude-docs/templates/docs-handover-README.tmpl`
- Create: `skills/bootstrap-claude-docs/templates/docs-insights-README.tmpl`
- Create: `skills/bootstrap-claude-docs/templates/docs-research-README.tmpl`
- Create: `skills/bootstrap-claude-docs/templates/docs-exec-plans-README.tmpl`

- [ ] **Step 1：docs-handover-README.tmpl**

```markdown
# Handover / 交接文档

系统架构、数据流、关键设计决策的持久化记录，供后续开发者（含 AI）快速上手。

**AI 须知：修改或新增文件后更新下方索引；检索本目录前先读此文件。**

## 索引

| 文件 | 主题 |
|------|------|
{{HANDOVER_INDEX_ROWS}}
<!-- TODO: 每行格式：| filename.md | 一句话主题描述 | -->

## 写作规范

- 每份 handover 文档对应一份 [insights](../insights/) 同名文档；互相反向链接
- 文档开头必填：`> 产品思考见 [docs/insights/<name>.md](../insights/<name>.md)`
- 内容侧重「怎么实现」：架构、目录、数据流、设计决策
- 目标读者：接手的开发者，需要能仅靠文档理解模块全貌
```

- [ ] **Step 2：docs-insights-README.tmpl**

```markdown
# 产品思考文档

记录功能设计背后的"为什么"——用户问题、设计理由、外部趋势、已知局限和未来方向。

每份文档对应一份 [handover](../handover/) 中的技术交接文档，文件名保持一致，互相反向链接。

## 索引

| 文档 | 对应交接文档 | 主题 |
|------|------------|------|
{{INSIGHTS_INDEX_ROWS}}
<!-- TODO: 每行格式：| [name.md](./name.md) | [handover/name.md](../handover/name.md) | 主题 | -->

## 写作规范

- 文档开头必填：`> 技术实现见 [docs/handover/<name>.md](../handover/<name>.md)`
- 内容侧重「为什么这么实现」：用户问题、设计理由、参考的外部资料
- 目标读者：产品决策者、未来的自己
```

- [ ] **Step 3：docs-research-README.tmpl**

```markdown
# Research / 调研文档

技术方案调研、可行性分析、POC 验证记录。

**AI 须知：修改或新增文件后更新下方索引；检索本目录前先读此文件。**

## 索引

| 文件 | 主题 |
|------|------|
{{RESEARCH_INDEX_ROWS}}
<!-- TODO: 每行格式：| filename.md | 一句话主题描述 | -->

## 与 exec-plans 的区别

- **research/**：纯调研、可行性分析、技术对比；可能不落地
- **exec-plans/**：明确决定要做、有分阶段步骤、有进度状态
```

- [ ] **Step 4：docs-exec-plans-README.tmpl**

```markdown
# Exec Plans / 执行计划

中大型功能的执行计划，包含分阶段目标、进度状态和决策日志。

**AI 须知：**
- 新建执行计划放在 `active/`，完成后移至 `completed/`
- 纯调研放 `../research/`
- 修改或新增文件后更新下方索引

## 什么时候需要执行计划

- 涉及数据库 schema 变更
- 跨 3 个以上模块的功能
- 需要分阶段交付的中大型功能
- 重构或迁移类任务

## 执行计划模板

见 [exec-plan-template.md](./exec-plan-template.md)。

## 索引

### Active

| 文件 | 主题 | 状态 |
|------|------|------|
{{ACTIVE_PLANS_INDEX}}

### Completed

| 文件 | 主题 | 完成日期 |
|------|------|----------|
{{COMPLETED_PLANS_INDEX}}

## 技术债务

见 [tech-debt-tracker.md](./tech-debt-tracker.md)。
```

- [ ] **Step 5：自验**

```bash
ls skills/bootstrap-claude-docs/templates/docs-*-README.tmpl | wc -l
```
预期：4

- [ ] **Step 6：commit**

```bash
git add skills/bootstrap-claude-docs/templates/docs-*-README.tmpl
git commit -m "feat(skill): add docs/{handover,insights,research,exec-plans} README templates"
```

---

## Task 11: templates/tech-debt-tracker.tmpl + exec-plan.tmpl

**Files:**
- Create: `skills/bootstrap-claude-docs/templates/tech-debt-tracker.tmpl`
- Create: `skills/bootstrap-claude-docs/templates/exec-plan.tmpl`

- [ ] **Step 1：tech-debt-tracker.tmpl**

```markdown
# Tech Debt Tracker / 技术债务追踪

已知技术债务清单。每项标注优先级、影响范围和初步解决思路。

**AI 须知：发现新的技术债务时添加到此文件；解决后标注完成日期。**

## 活跃项

| # | 描述 | 优先级 | 影响范围 | 发现日期 |
|---|------|--------|----------|----------|
| — | （暂无） | | | |

## 已解决

| # | 描述 | 解决日期 | 解决方式 |
|---|------|----------|----------|
| — | （暂无） | | |
```

- [ ] **Step 2：exec-plan.tmpl**

```markdown
# {{TOPIC}}

> 创建时间：{{YYYY-MM-DD}}
> 最后更新：{{YYYY-MM-DD}}

## 状态

| Phase | 内容 | 状态 | 备注 |
|-------|------|------|------|
| Phase 0 | {{PHASE_0_DESC}} | 📋 待开始 / 🔄 进行中 / ✅ 已完成 / ⏸ 暂缓 | |
| Phase 1 | ... | ... | |

## 决策日志

- {{YYYY-MM-DD}}: 决策内容及原因

## 详细设计

### 目标
### 技术方案
### 拆分步骤
### 依赖项
### 验收标准
```

- [ ] **Step 3：commit**

```bash
git add skills/bootstrap-claude-docs/templates/tech-debt-tracker.tmpl \
        skills/bootstrap-claude-docs/templates/exec-plan.tmpl
git commit -m "feat(skill): add tech-debt-tracker and exec-plan templates"
```

---

## Task 12: templates/maintain-claude-docs-SKILL.md.tmpl（核心创新：项目级维护 skill）

**Files:**
- Create: `skills/bootstrap-claude-docs/templates/maintain-claude-docs-SKILL.md.tmpl`

> 这个模板会被实例化到目标项目的 `.claude/skills/maintain-claude-docs/SKILL.md`。description 适配项目类型（来自 references/project-type-variants.md "maintain-claude-docs description 起手"）。

- [ ] **Step 1：写模板**

```markdown
---
name: maintain-claude-docs
description: |
  {{TYPE_SPECIFIC_TRIGGER_SENTENCE}}
  Reminds Claude to keep the documentation system in sync (handover docs, insights docs,
  README indexes, tech debt tracker, exec-plans). Use also when user mentions
  "更新文档", "doc maintenance", or finishes a substantive change.
---

# Maintain Claude Docs

确保本项目的文档体系与代码改动同步演进。

## When to Use

- 完成一个新功能或重要修改后
- 完成或更新 `docs/exec-plans/active/<topic>.md` 后
- 发现技术债务后
- 修改了 `src/` 中的关键模块后
- 用户主动要求"更新文档"

## When to Skip

- 仅修改注释、格式化、变量名
- 仅修文档拼写错误
- 修复明确不影响行为的 bug

## Maintenance Checklist

完成本次改动后，逐项检查：

1. **是否构成新功能？** → 是否需要写 `docs/handover/<feature>.md`？
2. **是否涉及产品决策？** → 是否需要写 `docs/insights/<feature>.md`？两份文档文件名一致并互相反链了吗？
3. **是否增删了文档文件？** → 对应 `docs/<dir>/README.md` 索引同步了吗？
4. **是否发现了技术债务？** → 已添加到 `docs/exec-plans/tech-debt-tracker.md` 了吗？
5. **是否在做中大型功能？** → 已起 `docs/exec-plans/active/<topic>.md` 了吗？
6. **是否完成了 exec-plan？** → 已移到 `docs/exec-plans/completed/` 了吗？

## How to Apply

针对清单中需要补做的项，提示用户并按序补齐。每补完一项标注 ✅ 给用户看。

## Project-Specific Hints

{{PROJECT_SPECIFIC_HINTS}}
<!-- TODO: bootstrap 时根据项目类型填充。例：
- Web 应用：API 改动是否同步了 OpenAPI 文档？
- CLI 工具：新命令是否更新了 README 命令表？
- 库：API 改动是否标记了 SemVer 影响等级？
-->
```

- [ ] **Step 2：自验**

```bash
grep -c '^[0-9]\.' skills/bootstrap-claude-docs/templates/maintain-claude-docs-SKILL.md.tmpl
```
预期：≥ 6（6 项清单）

```bash
head -1 skills/bootstrap-claude-docs/templates/maintain-claude-docs-SKILL.md.tmpl
```
预期：`---`

- [ ] **Step 3：commit**

```bash
git add skills/bootstrap-claude-docs/templates/maintain-claude-docs-SKILL.md.tmpl
git commit -m "feat(skill): add project-level maintain-claude-docs skill template"
```

---

## Task 13: skills/bootstrap-claude-docs/SKILL.md（主流程，≤ 500 词）

**Files:**
- Create: `skills/bootstrap-claude-docs/SKILL.md`

> 严格遵守 design.md §3.4 约束：description 只写"何时用"、≤ 500 词、深内容下沉到 references/。

- [ ] **Step 1：写 SKILL.md**

```markdown
---
name: bootstrap-claude-docs
description: |
  Use when initializing, creating, restructuring, or scaffolding a project's documentation
  system for Claude Code — covering CLAUDE.md, ARCHITECTURE.md, AGENTS.md, and docs/
  subdirectories with handover/insights/research/exec-plans. Use when user says: 初始化文档体系,
  搭建 CLAUDE.md 体系, 建立项目文档框架, bootstrap project docs, scaffold CLAUDE.md system.
  Use also when /init output feels too thin or when an existing CLAUDE.md needs restructuring
  into a multi-file system.
---

# Bootstrap Claude Docs

为目标项目从零搭建（或重构）一整套可落地、可维护的 Claude Code 文档体系。比 `/init` 产出更完整、更结构化。

## When to Use / Skip

**Use when:**
- 新项目初始化，需要文档骨架
- 已有项目代码丰富但文档稀薄
- 已有 CLAUDE.md 但全堆一文件，需拆分为体系

**Skip when:**
- 只需更新单个 CLAUDE.md 段落 → 直接 Edit
- 已有完整体系，只需审计 → 用 claude-md-improver
- 项目极小（单文件脚本） → 不必上完整体系

## Workflow

三阶段，三检查点。每个 phase 用 TodoWrite 跟踪。

**Phase 0 — 入口分流**
检测 cwd → 三种路径：greenfield / complete / restructure。✋ 检查点 0：用户确认走哪条。

**Phase 1 — 扫描与推断**（不动文件）
读 manifest（package.json/pyproject.toml/Cargo.toml/...）→ 识别类型；列模块；清点现有文档。
输出"假设清单"。✋ 检查点 1：用户确认假设。
完整自检见 `references/phase-1-checklist.md`。

**Phase 2 — 骨架生成**（写到 `.claude-docs-staging/`）
按项目类型选模板（见 `references/project-type-variants.md`），实例化 10 个 `templates/*.tmpl`：
顶层 `CLAUDE.md`/`ARCHITECTURE.md`/`AGENTS.md`、4 个 `docs/<dir>/README.md`、2 个 exec-plan 辅助、
**项目级 `.claude/skills/maintain-claude-docs/SKILL.md`**（核心创新）。
✋ 检查点 2：用户审阅 staging → 确认后原子 mv 到正式位置。
完整自检见 `references/phase-2-checklist.md`。

**Phase 3 — 深度填充与验证**
对用户标注的章节读源码深推；ARCHITECTURE 真实化；双链与索引校验。
输出「日常如何维护这套体系」卡片。
完整自检见 `references/phase-3-checklist.md`。

## Quick Reference

| 项目类型 | 模板变体 | docs/ 调整 |
|---------|---------|-----------|
| Web | 全套 | 全 4 类 |
| CLI | 简化 | 默认无 insights |
| Library | API 中心 | handover + research |
| Service | 服务中心 | 全 4 类 |
| Monorepo | 顶层 + 包 | 顶层全 4 类 |
| Mobile | 平台中心 | handover + insights |
| Data | 实验中心 | research 重于 insights |

类型→模板映射的详细规则见 `references/project-type-variants.md`。

## Common Mistakes

| 错误 | 修正 |
|------|------|
| 直接覆盖现有 CLAUDE.md | 走 restructure 路径，备份 `.bak.<ts>`，逐章确认搬迁 |
| 跳过检查点 | 三个检查点必须停下问用户，不能批量自动完成 |
| 把架构内容写进 CLAUDE.md | 关注点分离原则——架构进 ARCHITECTURE.md |
| 忘记生成项目级维护 skill | Phase 2.5 必做；维护体系长期靠它 |
| 直接写到 cwd | 必须先写 `.claude-docs-staging/`，用户确认后原子 mv |

## Design Philosophy

5 大可移植原则（关注点分离 / 双视角文档 / 自维护索引 / 计划驱动 / 自检纪律）详见 `references/design-philosophy.md`。
```

- [ ] **Step 2：自验长度**

```bash
# frontmatter 之后的正文字符数（中英混排）
awk '/^---$/{n++; next} n==2' skills/bootstrap-claude-docs/SKILL.md | wc -m
# description 字段长度
awk '/^description:/,/^---$/' skills/bootstrap-claude-docs/SKILL.md | head -c 1100 | wc -c
```
预期：
- 正文 ≤ 3000 字符（中文混排 ~ 500-800 词上限）
- description ≤ 1024 字符

若超：优先压缩 Quick Reference 表格（保留 2 行样例 + 指向 `references/project-type-variants.md`），次选压 Common Mistakes。

- [ ] **Step 3：自验 frontmatter**

```bash
head -10 skills/bootstrap-claude-docs/SKILL.md | grep -E '^(name|description):'
```
预期：name 和 description 都存在。

```bash
awk '/^---$/{n++; next} n==1' skills/bootstrap-claude-docs/SKILL.md | head -20
```
预期：description 以 "Use when" 起手；不出现 "scan / generate / write" 等动词描述工作流。

- [ ] **Step 4：自验 cross-reference 风格**

```bash
grep -c '@skills/\|@\.\./skills/' skills/bootstrap-claude-docs/SKILL.md
```
预期：0（不能用 `@` 强制加载语法）。

- [ ] **Step 5：commit**

```bash
git add skills/bootstrap-claude-docs/SKILL.md
git commit -m "feat(skill): add main SKILL.md orchestrator"
```

---

## Task 14: commands/bootstrap-docs.md（slash command）

**Files:**
- Create: `commands/bootstrap-docs.md`

> Slash command 的 body 会作为 prompt 注入。这里只需写一句指令调用 skill。

- [ ] **Step 1：创建目录**

```bash
mkdir -p commands
```

- [ ] **Step 2：写 command**

```markdown
---
description: 为当前项目搭建或重构完整的 Claude Code 文档体系（CLAUDE.md / ARCHITECTURE.md / docs/ + 项目级维护 skill）
---

请用 bootstrap-claude-docs skill 为当前工作目录搭建完整的文档体系。

按 skill 定义的三阶段流程执行：
1. Phase 0 检测项目状态并让我确认走哪条路径（greenfield / complete / restructure）
2. Phase 1 扫描与推断，输出假设清单让我审阅
3. Phase 2 生成骨架到 `.claude-docs-staging/`，让我审阅后再 mv 到正式位置
4. Phase 3 深度填充与验证

每个检查点都要停下来等我确认。
```

- [ ] **Step 3：自验**

```bash
test -f commands/bootstrap-docs.md && head -3 commands/bootstrap-docs.md
```
预期：第一行 `---`，含 frontmatter description 字段。

- [ ] **Step 4：commit**

```bash
git add commands/bootstrap-docs.md
git commit -m "feat: add /bootstrap-docs slash command"
```

---

## Task 15: 端到端验收（empty fixture + 真实项目）

**Files:**
- Create: `tests/fixtures/empty/.gitkeep`
- Create: `tests/fixtures/empty/expected-structure.txt`

> 第一次完整跑通验收。手动模拟 `/bootstrap-docs` 在空目录的执行，对比期望产出。

- [ ] **Step 1：建空 fixture**

```bash
mkdir -p tests/fixtures/empty
touch tests/fixtures/empty/.gitkeep
```

- [ ] **Step 2：写期望结构清单**

```text
# tests/fixtures/empty/expected-structure.txt

期望产出（greenfield 路径）：

CLAUDE.md
ARCHITECTURE.md
AGENTS.md
docs/handover/README.md
docs/insights/README.md
docs/research/README.md
docs/exec-plans/README.md
docs/exec-plans/tech-debt-tracker.md
docs/exec-plans/exec-plan-template.md
.claude/skills/maintain-claude-docs/SKILL.md

每个文件必含的关键标记：
- CLAUDE.md：包含 "## 改动自查" "## 文档"
- ARCHITECTURE.md：包含 "## 目录结构" "## 技术栈"
- maintain-claude-docs/SKILL.md：frontmatter name 等于 maintain-claude-docs；body 含 6 项编号清单
```

- [ ] **Step 3：人工跑一次端到端**

在仓库 root 安装 skill：
```bash
mkdir -p ~/.claude/skills ~/.claude/commands
ln -sfn "$PWD/skills/bootstrap-claude-docs" ~/.claude/skills/bootstrap-claude-docs
ln -sf "$PWD/commands/bootstrap-docs.md" ~/.claude/commands/bootstrap-docs.md
```

进入空 fixture：
```bash
cd tests/fixtures/empty
```

在 Claude Code 里跑 `/bootstrap-docs`，按 phase 走一遍。

- [ ] **Step 4：对比期望结构**

```bash
cd tests/fixtures/empty
ls -1 CLAUDE.md ARCHITECTURE.md AGENTS.md \
       docs/handover/README.md docs/insights/README.md \
       docs/research/README.md docs/exec-plans/README.md \
       docs/exec-plans/tech-debt-tracker.md \
       .claude/skills/maintain-claude-docs/SKILL.md \
  2>&1 | grep -c '^docs\|CLAUDE\|ARCH\|AGENT\|.claude'
```
预期：≥ 9

逐一打开关键文件确认 grep 命中：
```bash
grep -l '改动自查' CLAUDE.md && \
  grep -l '目录结构' ARCHITECTURE.md && \
  grep -l 'maintain-claude-docs' .claude/skills/maintain-claude-docs/SKILL.md
```
预期：三行均匹配成功。

- [ ] **Step 5：清理 fixture**

```bash
cd /data/lidongyu/projects/claude-md-guide
git checkout tests/fixtures/empty/.gitkeep tests/fixtures/empty/expected-structure.txt
git clean -fd tests/fixtures/empty/
```

> Fixture 自动化测试套件留 follow-up。本步是一次手动 smoke test。

- [ ] **Step 6：commit**

```bash
git add tests/fixtures/empty/.gitkeep tests/fixtures/empty/expected-structure.txt
git commit -m "test: add empty fixture and expected structure for smoke test"
```

---

## Task 16: README.md 完善（去标识化 + 三种安装方式 + 使用示例）

**Files:**
- Modify: `README.md`

- [ ] **Step 1：写完整 README**

```markdown
# claude-md-guide

> 为项目搭建可落地、可维护的 Claude Code 文档体系。
> 比内置 `/init` 产出更完整：CLAUDE.md / ARCHITECTURE.md / AGENTS.md / docs/ + 项目级维护 skill。

## 这个仓库提供什么

- **`bootstrap-claude-docs`** — 一个 Claude Code skill，三阶段三检查点流程
- **`/bootstrap-docs`** — 对应 slash command
- **设计哲学** —— 5 条可移植原则（关注点分离 / 双视角文档 / 自维护索引 / 计划驱动 / 自检纪律）

## 安装

### 方式 1：手动拷贝（最稳）

```bash
git clone <this-repo> claude-md-guide
cd claude-md-guide
cp -r skills/bootstrap-claude-docs ~/.claude/skills/
cp commands/bootstrap-docs.md ~/.claude/commands/
```

### 方式 2：Symlink（开发者，改源即生效）

```bash
ln -sfn "$PWD/skills/bootstrap-claude-docs" ~/.claude/skills/bootstrap-claude-docs
ln -sf  "$PWD/commands/bootstrap-docs.md" ~/.claude/commands/bootstrap-docs.md
```

### 方式 3：让 Agent 自己装

clone 后，跟 Claude Code 说："帮我安装这个仓库里的 skill"。

## 使用

进入要搭文档体系的项目，在 Claude Code 里输入：

```
/bootstrap-docs
```

或自然语言："帮我搭一套完整的 CLAUDE.md 文档体系"。

skill 会带你走三阶段：
1. 扫描项目，列假设清单让你确认
2. 生成骨架到 staging，让你审阅后原子 mv
3. 深度填充 + 验证，输出日常使用指南

## 文档

- [docs/design.md](./docs/design.md) — 设计文档（理念、架构、决策日志）
- [skills/bootstrap-claude-docs/SKILL.md](./skills/bootstrap-claude-docs/SKILL.md) — 主流程
- [skills/bootstrap-claude-docs/references/design-philosophy.md](./skills/bootstrap-claude-docs/references/design-philosophy.md) — 5 大设计哲学详述
- [skills/bootstrap-claude-docs/references/project-type-variants.md](./skills/bootstrap-claude-docs/references/project-type-variants.md) — 7 种项目类型适配

## License

MIT
```

- [ ] **Step 2：自验**

```bash
grep -c 'insilico\|silicopilot' README.md
```
预期：0

```bash
grep -c '^## ' README.md
```
预期：≥ 5

- [ ] **Step 3：commit**

```bash
git add README.md
git commit -m "docs: complete README with install methods, usage, and pointers"
```

---

## Task 17: 最终验收 + tag

**Files:** 无

- [ ] **Step 1：核对 design.md §11 验收标准**

```markdown
- [x] /bootstrap-docs 在 tests/fixtures/empty/ 上跑通（T15 已做）
- [ ] /bootstrap-docs 在某真实项目（claude-md-guide 自身）上跑通 ← 现在做
- [ ] 重构路径在一份"无体系的旧 CLAUDE.md"上跑通，diff 预览正确 ← 现在做
- [x] 项目级 maintain-skill 在被 bootstrap 过的项目里能被加载（T15 已验）
- [x] README.md 三种安装方式至少一种被验证（T16）
- [x] design-philosophy.md 全文写完，每条原则四节齐全（T5）
- [x] project-type-variants.md 7 种变体都有最简模板差异（T6）
```

- [ ] **Step 2：在仓库自身跑一次 /bootstrap-docs**

进入 `claude-md-guide/` 自身（已有 docs/ 但无 CLAUDE.md），跑 `/bootstrap-docs`，应走 complete 路径。

预期：
- skill 不应覆盖现有 `docs/design.md` `docs/plan.md`
- 应生成 CLAUDE.md / ARCHITECTURE.md / AGENTS.md
- 应生成 `.claude/skills/maintain-claude-docs/`

完成后用 `git diff` 检查；不满意 `git checkout` 回滚。

- [ ] **Step 3：在一份"旧 CLAUDE.md"上跑 restructure**

构造测试目录：
```bash
mkdir -p /tmp/restructure-test
cd /tmp/restructure-test
cat > CLAUDE.md <<'EOF'
# old-project

技术栈：Next.js + Postgres
src/api/auth.ts 实现登录
src/db/schema.ts 主表 user / session

提交前必须跑 npm test
EOF
```

在 Claude Code 里跑 `/bootstrap-docs`，应识别为 restructure，生成 diff 预览：
- 「技术栈」「src/api」「src/db/schema」段落 → 搬到 ARCHITECTURE.md
- 「提交前必须跑 npm test」 → 留 CLAUDE.md
- 备份 `CLAUDE.md.bak.<ts>` 已生成

- [ ] **Step 4：更新 CHANGELOG.md**

```markdown
# Changelog

## [0.1.0] - 2026-04-29

### Added
- bootstrap-claude-docs skill：三阶段三检查点的文档体系生成流程
- /bootstrap-docs slash command
- 5 大设计哲学（design-philosophy.md）
- 7 种项目类型变体（project-type-variants.md）
- 3 phase 自检 checklist
- 10 个模板（CLAUDE.md / ARCHITECTURE.md / AGENTS.md / 4×docs README / tech-debt / exec-plan / 项目级维护 skill）
- 3 份去标识化样例
```

- [ ] **Step 5：tag + commit**

```bash
git add CHANGELOG.md
git commit -m "chore: bump to v0.1.0"
git tag v0.1.0
```

---

## 任务总览

| Task | 文件数 | 主题 | 依赖 |
|------|--------|------|------|
| T1 | 4 | 仓库骨架 + git init | — |
| T2 | 1 | phase-1 checklist | T1 |
| T3 | 1 | phase-2 checklist | T1 |
| T4 | 1 | phase-3 checklist | T1 |
| T5 | 1 | 5 大设计哲学 | T1 |
| T6 | 1 | 7 种项目变体 | T1 |
| T7 | 3 | 去标识化样例 | T1 |
| T8 | 1 | CLAUDE.md.tmpl | T5 |
| T9 | 2 | ARCHITECTURE.md.tmpl + AGENTS.md.tmpl | T5 |
| T10 | 4 | docs/ README 模板 ×4 | T5 |
| T11 | 2 | tech-debt + exec-plan 模板 | T5 |
| T12 | 1 | 项目级维护 skill 模板 | T5 |
| T13 | 1 | SKILL.md 主流程 | T2-T12 |
| T14 | 1 | /bootstrap-docs slash command | T13 |
| T15 | 2 | 端到端 smoke test | T14 |
| T16 | 1 | README 完善 | T15 |
| T17 | — | 最终验收 + tag | T16 |

**总计：27 文件 / 17 task / 1 tag。**

T2-T7 之间无依赖，可并行；T8-T12 之间无依赖，可并行；其余串行。
