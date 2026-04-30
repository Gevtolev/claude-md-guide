# Changelog

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
