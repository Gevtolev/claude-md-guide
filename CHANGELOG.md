# Changelog

## [0.3.0] - 2026-06-23

### Changed

吸收 [mattpocock/skills](https://github.com/mattpocock/skills) 文档管理实践（调研其全部 ~60 个 skill 后提炼）：

- **ADR 极简化**：`adr.tmpl` 重写为「标题 + 1-3 句话」，状态/候选/影响降为可选段——修正与「克制」原则的矛盾
- **durability 规则**：ADR 禁写文件路径/行号/代码片段（会过时），写理由/契约——Matt 语料里重复最多的一条
- **ADR 三段判据**：补全为「难逆转 + 没上下文会困惑 + 真有取舍」（三者同时成立才记）+ what-qualifies 分类
- **lazy 创建**：greenfield 只建核心集（CLAUDE/ARCHITECTURE/AGENTS/decisions/exec-plans + maintain skill）；glossary/insights/research 首次有内容才建，不预建空目录
- **exec-plan 增强**（借 decision-mapping）：加 `Blocked by` 依赖 DAG + 「链接不复制、保持紧凑」纪律

### Added

- **新增 `templates/glossary.tmpl`**：项目术语表层（`术语: 定义 + _Avoid_: 同义词`），统一黑话、命名一致、AI 导航更准；lazy 创建，绑定代码/决策而非对话刮取

## [0.2.0] - 2026-05-29

### Changed

**v2 文档体系重构**：`docs/handover/` 废弃，改为 `docs/decisions/`（ADR 决策追溯）。

- 设计哲学第 2 条从"双视角文档"改为"决策追溯独立"（ADR 独立目录，不混在 handover 里）
- 4 类 docs 子目录：decisions / insights / research / exec-plans
- 新增 `templates/adr.tmpl`（ADR 模板）+ `templates/docs-decisions-README.tmpl`
- 删除 `templates/docs-handover-README.tmpl` + `references/sample-handover.md`
- 新增 `templates/ignore.tmpl`（生成 `.ignore`，ripgrep 格式）+ `templates/sub-package-CLAUDE.md.tmpl`（monorepo 子包）
- maintain skill 清单从 6 项扩展为 8 项（含 ADR 提醒 + 季度审计）
- ARCHITECTURE.md 目录结构段强制每个顶层目录附一句话职责（codebase map）

参考来源：[How Claude Code works in large codebases](https://claude.com/blog/how-claude-code-works-in-large-codebases-best-practices-and-where-to-start)

## [0.1.0] - 2026-04-30

### Added

**首版发布**：bootstrap-claude-docs skill + `/bootstrap-docs` slash command。

Skill 产出：
- `skills/bootstrap-claude-docs/SKILL.md` — 三阶段三检查点主流程（≤ 500 词）
- `references/design-philosophy.md` — 5 大设计哲学（关注点分离 / 双视角 / 自维护索引 / 计划驱动 / 自检纪律）
- `references/project-type-variants.md` — 7 种项目类型变体（Web / CLI / 库 / 后端 / Monorepo / 移动 / 数据）
- `references/phase-{1,2,3}-checklist.md` — 三阶段自检清单
- `references/sample-{CLAUDE,ARCHITECTURE,handover}.md` — 去标识化样例（acme-app 虚构项目）
- `templates/*.tmpl` — 10 个模板（CLAUDE / ARCHITECTURE / AGENTS / 4× docs README / tech-debt / exec-plan / 项目级 maintain skill）
- `commands/bootstrap-docs.md` — slash command
- `tests/fixtures/empty/` — 空目录冒烟测试 fixture + 期望结构清单

核心创新：在目标项目里生成 `.claude/skills/maintain-claude-docs/SKILL.md` 项目级维护 skill，让每次相关改动自动提醒同步文档体系。

### 延期验证

以下项留待首位用户（包括作者自己）手动跑一次：
- `/bootstrap-docs` 在 `tests/fixtures/empty/` 上的实际端到端
- `/bootstrap-docs` 在已有项目上的扫描推断
- `/bootstrap-docs` 在无体系旧 CLAUDE.md 上的 restructure 路径 + diff 预览 + 备份
