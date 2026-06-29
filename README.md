# claude-md-guide

> 为项目搭建可落地、可维护的 Claude Code 文档体系。
> 比内置 `/init` 产出更完整：CLAUDE.md / ARCHITECTURE.md / AGENTS.md / docs/ + 项目级维护 skill。

## 这个仓库提供什么

- **`bootstrap-claude-docs` skill** — 三阶段三检查点流程，把一个项目（空的 / 已有代码的 / 已有旧 CLAUDE.md 的）引导成一整套文档体系
- **`/bootstrap-claude-docs` slash command** — skill 自动发现的命令入口
- **7 条可移植设计原则** — 关注点分离 / 决策追溯独立 / 自维护索引 / 计划驱动 / 自检纪律 / 克制 / 防漂移闭环
- **7 种项目类型变体** — Web / CLI / Library / Service / Monorepo / Mobile / Data
- **14 个模板 + 2 份样例** — 拿去就能填

## 产出什么

在目标项目里生成。**核心集**一次建好，可选层 lazy（有内容才建）：

```
项目根/
├── CLAUDE.md                                   # 规则、流程、改动自查（≤4 核心项）
├── ARCHITECTURE.md                             # 结构、数据流、技术栈
├── AGENTS.md                                   # CLAUDE.md 的镜像（给非 Claude 的 AI）
├── docs/
│   ├── decisions/README.md                     # 架构决策记录索引（ADR）
│   ├── decisions/adr-template.md               # 极简 ADR 模板（标题 + 1-3 句）
│   ├── exec-plans/
│   │   ├── README.md                           # 执行计划索引
│   │   ├── tech-debt-tracker.md                # 技术债务追踪
│   │   └── exec-plan-template.md               # 执行计划模板（含 Blocked by 依赖）
│   ├── glossary.md          （lazy）           # 项目术语表（统一黑话）
│   ├── insights/            （lazy）           # 产品思考
│   ├── research/            （lazy）           # 调研
│   └── source-of-truth-map.md                 # 真相源映射表（防漂移用）
├── .claude/skills/maintain-claude-docs/
│   └── SKILL.md                                # 项目级维护 skill —— 按需 / 阶段性文档体检
└── .git/hooks/pre-push                         # 防漂移 hook（Phase 2.6 生成）
```

最后那个「项目级维护 skill」是核心创新：CLAUDE.md 是静态规则文件，在长对话里偶尔被埋；项目级 skill 有 description 触发机制，形成静动双份冗余——按需 / 阶段性触发（非每次改动）。

## 安装

### 方式 1：手动拷贝（最稳）

```bash
git clone https://github.com/Gevtolev/claude-md-guide.git
cd claude-md-guide
cp -r skills/bootstrap-claude-docs ~/.claude/skills/
```

### 方式 2：Symlink（开发者，改源即生效）

```bash
git clone https://github.com/Gevtolev/claude-md-guide.git
cd claude-md-guide
ln -sfn "$PWD/skills/bootstrap-claude-docs" ~/.claude/skills/bootstrap-claude-docs
```

### 方式 3：让 Claude 帮你装

```bash
git clone https://github.com/Gevtolev/claude-md-guide.git
```

clone 后进入仓库，跟 Claude Code 说："帮我安装这个仓库里的 skill 到 `~/.claude/skills/`"。Claude 会读 README 并自动拷贝。

## 使用

进入要搭文档体系的项目：

```bash
cd ~/projects/your-project
```

在 Claude Code 里输入 slash command：

```
/bootstrap-claude-docs
```

或者用自然语言："帮我为这个项目搭一套 Claude Code 文档体系"（skill 的 description 会自动命中）。

接下来会走三阶段：

| Phase | 做什么 | 你要做什么 |
|-------|--------|----------|
| 0 | 检测项目状态，告诉你走哪条路径（greenfield / complete / restructure） | 确认路径 |
| 1 | 扫描代码，识别项目类型，列假设清单 | 审阅假设，修正错误推断 |
| 2 | 按模板生成骨架到 `.claude-docs-staging/` | 审阅 staging，确认后 skill 原子 mv 到正式位置 |
| 3 | 深填 ARCHITECTURE 的真实数据，校验索引完整性 | 最终确认 |

每个检查点都会停下等你确认——不会一把梭哈。

## 和相邻工具的关系

| 工具 | 职责 | 关系 |
|------|------|------|
| Claude Code 内置 `/init` | 生成单 CLAUDE.md | 本 skill 是升级版（体系化） |
| [`claude-md-improver`](https://github.com/anthropics/claude-plugins-official) | 审计已有 CLAUDE.md | 互补：本 skill 建造，它体检 |
| 本 skill 生成的项目级 `maintain-claude-docs` | 日常维护提醒 | 本 skill 的产物，长期生效 |

## 进一步阅读

- [docs/design.md](./docs/design.md) — 完整设计文档（理念、架构、决策日志）
- [docs/plan.md](./docs/plan.md) — 实现计划（17 task）
- [skills/bootstrap-claude-docs/SKILL.md](./skills/bootstrap-claude-docs/SKILL.md) — skill 主流程
- [skills/bootstrap-claude-docs/references/design-philosophy.md](./skills/bootstrap-claude-docs/references/design-philosophy.md) — 7 大设计哲学详述
- [skills/bootstrap-claude-docs/references/project-type-variants.md](./skills/bootstrap-claude-docs/references/project-type-variants.md) — 7 种项目类型适配
- [skills/bootstrap-claude-docs/references/sample-CLAUDE.md](./skills/bootstrap-claude-docs/references/sample-CLAUDE.md) / [sample-ARCHITECTURE.md](./skills/bootstrap-claude-docs/references/sample-ARCHITECTURE.md) — 去标识化样例

## License

MIT — 见 [LICENSE](./LICENSE)。
