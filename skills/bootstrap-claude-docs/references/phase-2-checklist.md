# Phase 2 Checklist：骨架生成

> 本 checklist 在 Phase 2 末尾执行；全部通过 + 用户审阅 staging 后，才能 mv 到正式位置。

## 文件存在性（核心集，以下路径均以 `.claude-docs-staging/` 为根）

- [ ] `CLAUDE.md`
- [ ] `ARCHITECTURE.md`
- [ ] `AGENTS.md`
- [ ] `docs/decisions/README.md`
- [ ] `docs/decisions/adr-template.md`
- [ ] `docs/exec-plans/README.md`
- [ ] `docs/exec-plans/tech-debt-tracker.md`
- [ ] `docs/exec-plans/exec-plan-template.md`
- [ ] `.claude/skills/maintain-claude-docs/SKILL.md`

## 不应预建（lazy，首次有内容才创建）

- [ ] **未**创建 `docs/glossary.md`（除非已识别出值得统一的领域术语）
- [ ] **未**创建 `docs/insights/`（除非已有要写的产品思考）
- [ ] **未**创建 `docs/research/`（除非已有要落的调研）
- [ ] 空目录 = 净亏损：不为"目录完整"预建任何空目录

## CLAUDE.md 必含段落

- [ ] `## 改动自查` 或同义节（≤4 核心项 + 一行软提示，不列长清单）
- [ ] `## 文档` 索引节（列出 decisions / exec-plans，及 glossary / insights / research 并标「可选」）
- [ ] `## 工作流` 或 `## 开发规则` 节

## 维护 skill 必含字段

- [ ] frontmatter 有 `name: maintain-claude-docs`
- [ ] description 含按需 / 阶段性触发条件 + 项目类型相关触发词（明示「非每改动」）
- [ ] 正文包含文档体检清单（含"难逆转+没上下文会困惑+真有取舍 → 新增极简 ADR"项）

## 内容真实性

- [ ] 所有 `{{占位符}}` 已被填或被显式标 `<!-- TODO: -->`
- [ ] 没有遗留 `lorem ipsum` 或英文模板词残留（中文项目）

## 索引先验

- [ ] decisions/README.md 含决策矩阵（即便目前为空，也要有表头）
- [ ] exec-plans/README.md 区分 active / completed
- [ ]（仅当 lazy 目录已因有内容而创建时）其 README 索引格式齐全
