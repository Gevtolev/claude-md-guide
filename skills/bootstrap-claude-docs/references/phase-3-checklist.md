# Phase 3 Checklist：深度填充与验证

> 本 checklist 在 Phase 3 末尾执行；全部通过即首版完成。任何一项不过 → 回 Phase 2 修正。

## 内容质量

- [ ] ARCHITECTURE.md 的「目录结构」基于实际 `ls`/`tree` 输出，不是模板占位
- [ ] ARCHITECTURE.md 的「数据流」/「技术栈」至少有一段实质内容（即使是骨架）
- [ ] 用户在检查点 2 标注的章节均已深填；未标注的章节保留 `<!-- TODO: -->` 占位

## 索引与校验

- [ ] 每个**已创建**的 `docs/<dir>/README.md` 索引表与该目录实际文件对齐（无遗漏、无幻觉）
- [ ] decisions/README.md 的决策矩阵与 `docs/decisions/` 中实际 ADR 文件对齐
- [ ] CLAUDE.md 文档索引节：核心集（decisions / exec-plans）链接存在且可点击；lazy 项（glossary / insights / research）已标「可选」，**不要求文件已存在**
- [ ] 未预建任何空的 lazy 目录（glossary / insights / research 无内容则不应存在）

## 维护 skill 健全

- [ ] 项目级 maintain-claude-docs/SKILL.md 已落到 `.claude/skills/`
- [ ] 该 skill 的 description 适配本项目类型（不是通用模板）

## 收尾产物

- [ ] 已打印「使用指南」卡片：日常该往哪写什么、维护 skill 何时触发
- [ ] `.claude-docs-staging/` 已清理
- [ ] 无原文件被覆盖（重构路径除外，且备份已存在）
- [ ] （仅 restructure 路径）`CLAUDE.md.bak.<ts>` 存在；所有从旧 CLAUDE.md 迁出的段落都有去向标注
