# CLAUDE.md

acme-app — 一个虚构的 SaaS 看板工具（仅作 bootstrap-claude-docs 演示用）。

> 架构细节见 [ARCHITECTURE.md](./ARCHITECTURE.md)，本文件只包含规则和流程。

## 开发规则

**提交前必须跑 `npm test`：**
- 每次提交前，必须在本地跑完整测试套件，确认无回归
- 涉及 UI 的改动需在浏览器中实际验证一次
- 涉及数据库 schema 的改动需跑一次迁移演练

**新功能必须先写计划：**
- 跨 3+ 模块或 schema 变更的功能，开工前写 `docs/exec-plans/active/<topic>.md`
- 纯调研不落代码的，进 `docs/research/`

**Commit 信息规范：**
- 标题行使用 conventional commits 格式（feat/fix/refactor/chore）
- body 说明改了什么、为什么改、影响范围

## 自检命令

- `npm test` — 单元测试（~3s，无需数据库）
- `npm run test:integration` — 集成测试（~15s，需要 docker compose up）
- `npm run test:e2e` — Playwright 端到端（~60s，需要 dev server）

修改代码后 commit 前至少跑 `npm test`；涉及 API 改动额外跑集成。

## 改动自查

完成代码修改后，在提交前确认：
1. 改动是否涉及类型 → 是否需要更新 `src/types/`
2. 改动是否涉及 schema → 是否需要写 `migrations/` 下的新迁移
3. 改动是否涉及 API 契约 → 是否需要同步 OpenAPI 定义
4. 改动是否涉及国际化 → 是否需要同步 `src/i18n/{en,zh}.ts`
5. 改动是否构成新功能 → 是否需要写 `docs/handover/` + `docs/insights/` 双份

## 工作流

**功能开发：** 需求分析 → 设计 → TDD 实现 → 浏览器验证 → 双份文档

**调试：** 收集信息 → 最小复现 → 根因分析 → 修复 + 回归测试

## 文档

- [ARCHITECTURE.md](./ARCHITECTURE.md) — 项目架构、目录结构、数据流
- `docs/handover/` — 技术交接文档（架构、数据流、设计决策）
- `docs/insights/` — 产品思考文档（用户问题、设计理由）
- `docs/research/` — 调研文档（技术方案、可行性分析）
- `docs/exec-plans/` — 执行计划（进度状态、决策日志、技术债务）

**检索前先读对应目录的 README.md；增删文件后更新索引。**
