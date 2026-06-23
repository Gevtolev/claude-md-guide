---
name: bootstrap-claude-docs
description: |
  Use when initializing, creating, restructuring, or scaffolding a project's documentation
  system for Claude Code — covering CLAUDE.md, ARCHITECTURE.md, AGENTS.md, and docs/
  subdirectories with decisions/insights/research/exec-plans. Use when user says: 初始化文档体系,
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
按项目类型选模板（见 `references/project-type-variants.md`），只建**核心集**：
`CLAUDE.md`/`ARCHITECTURE.md`/`AGENTS.md`、`docs/decisions/`（README + ADR 模板）、`docs/exec-plans/`（README + plan 模板 + tech-debt）。
**lazy**：`docs/glossary.md` / `insights/` / `research/` 不预建，首次有内容才创建（空目录是净亏损）。
可选：`.ignore`（ripgrep 格式）。Monorepo 另为每个子包生成 `CLAUDE.md`。
✋ 检查点 2：用户审阅 staging → 确认后原子 mv 到正式位置。完整自检见 `references/phase-2-checklist.md`。

**Phase 2.5 — 生成项目级维护 skill**（核心创新）
实例化 `templates/maintain-claude-docs-SKILL.md.tmpl` → `.claude/skills/maintain-claude-docs/SKILL.md`。
description 按类型定制（见 `references/project-type-variants.md`），body 含按需文档体检清单，
让阶段性 / 显式触发时维护文档（非每改动自动跑）。

**Phase 3 — 深度填充与验证**
对用户标注的章节读源码深推；ARCHITECTURE 真实化；索引与 decisions 矩阵校验。
输出「日常如何维护这套体系」卡片。
完整自检见 `references/phase-3-checklist.md`。

## Quick Reference

docs 子目录，目的互斥不重叠（★=核心集，其余 lazy 按需建）：

| 目录 | 回答的问题 |
|------|-----------|
| ★ `decisions/` | **为什么是这样而不是另一种**（ADR 决策追溯） |
| ★ `exec-plans/` | **现在在做什么 / 进度**（active / completed） |
| `glossary.md` | **这个词指什么**（统一项目黑话；术语表，仅此而已） |
| `insights/` | **为什么做这个产品**（用户视角 / 商业理由 / 设计动机） |
| `research/` | **有什么备选 / 可行性如何**（调研，可能不落地） |

回答"项目现在长什么样"由顶层 `ARCHITECTURE.md` + 代码 docstring 承担，不再放 docs/。

| 项目类型 | docs/ 调整 |
|---------|-----------|
| Web | 全 4 类 |
| CLI | 默认无 insights |
| Library | decisions + research |
| Service | 全 4 类 |
| Monorepo | 顶层 + 每包轻量 |
| Mobile | decisions + insights |
| Data | research 重于 insights |

类型 → 模板映射的详细规则见 `references/project-type-variants.md`。

## Common Mistakes

| 错误 | 修正 |
|------|------|
| 直接覆盖现有 CLAUDE.md | 走 restructure，备份 `.bak.<ts>`，逐章确认 |
| 跳过检查点 | 三个检查点必须停下问用户 |
| 把架构写进 CLAUDE.md | 关注点分离——架构进 ARCHITECTURE.md |
| 忘了项目级维护 skill | Phase 2.5 必做；维护体系长期靠它 |
| 直接写到 cwd | 必须先 staging，用户确认后 mv |

## Design Philosophy

6 大可移植原则（关注点分离 / 决策追溯独立 / 自维护索引 / 计划驱动 / 自检纪律 / 克制）详见 `references/design-philosophy.md`。
