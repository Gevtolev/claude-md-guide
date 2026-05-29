# Phase 2 Checklist：骨架生成

> 本 checklist 在 Phase 2 末尾执行；全部通过 + 用户审阅 staging 后，才能 mv 到正式位置。

## 文件存在性（以下路径均以 `.claude-docs-staging/` 为根）

- [ ] `CLAUDE.md`
- [ ] `ARCHITECTURE.md`
- [ ] `AGENTS.md`
- [ ] `docs/decisions/README.md`
- [ ] `docs/decisions/adr-template.md`
- [ ] `docs/insights/README.md`
- [ ] `docs/research/README.md`
- [ ] `docs/exec-plans/README.md`
- [ ] `docs/exec-plans/tech-debt-tracker.md`
- [ ] `docs/exec-plans/exec-plan-template.md`
- [ ] `.claude/skills/maintain-claude-docs/SKILL.md`

## CLAUDE.md 必含段落

- [ ] `## 改动自查` 或同义节
- [ ] `## 文档` 索引节（链接所有 docs/<dir>/，4 个子目录）
- [ ] `## 工作流` 或 `## 开发规则` 节

## 维护 skill 必含字段

- [ ] frontmatter 有 `name: maintain-claude-docs`
- [ ] description 以 `Use when` 开头，包含项目类型相关触发词
- [ ] 正文包含至少 6 项检查清单（其中含"是否产生新决策 → 新增 ADR"项）

## 内容真实性

- [ ] 所有 `{{占位符}}` 已被填或被显式标 `<!-- TODO: -->`
- [ ] 没有遗留 `lorem ipsum` 或英文模板词残留（中文项目）

## 索引先验

- [ ] decisions/README.md 含决策矩阵（即便目前为空，也要有表头）
- [ ] insights/README.md / research/README.md 索引格式齐全
- [ ] exec-plans/README.md 区分 active / completed
