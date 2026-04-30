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
