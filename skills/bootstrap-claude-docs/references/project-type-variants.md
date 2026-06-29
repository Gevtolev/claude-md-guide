# 项目类型变体

7 种项目类型的差异化指引。Phase 1 识别后用对应变体填模板。

## 总览表

| 类型 | 检测信号 | ARCHITECTURE 必填 | docs/ 调整 |
|------|----------|-------------------|-----------|
| Web 应用 | Next.js / Vite / Django / Rails | 路由 / 数据流 / DB schema / API / 前后端边界 | 全 4 类（decisions / insights / research / exec-plans） |
| CLI 工具 | bin 入口 / cobra / click / commander | 命令树 / IO 协议 / 配置加载 | 主用 decisions + research + exec-plans（默认无 insights） |
| 库 / SDK | 主导出 / 多版本支持 | 公共 API 表面 / 版本兼容矩阵 / 扩展点 | 主用 decisions + research + exec-plans |
| 后端服务 | Dockerfile + 长进程 | 服务边界 / 队列 / 数据流 / SLO | 全 4 类 |
| Monorepo | workspaces / lerna / nx / turborepo | 工作区图 / 包依赖图 / 发布流 | 顶层 + 每包轻量 CLAUDE.md |
| 移动 App | iOS / Android / RN / Flutter | 平台分支 / 状态管理 / 原生桥 | decisions + insights + exec-plans |
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
保留全部 4 类（decisions / insights / research / exec-plans）。

### maintain-claude-docs 审计聚焦（填入 description；按需触发，非每改动）
`This is a web app — focus the doc audit on route / API / page / DB-schema changes and the front/back boundary.`

### 防漂移映射表聚焦（填入 `docs/source-of-truth-map.md`）
API 路由、DB schema、前后端 API 契约——这三类变更最易在代码里静默漂移，优先纳入真相源映射表。

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
默认不要 `insights/`（CLI 工具产品决策少；让用户自己开启）；其余保留 decisions / research / exec-plans。

### maintain-claude-docs 审计聚焦（填入 description；按需触发，非每改动）
`This is a CLI tool — focus the doc audit on command / flag / config-option changes.`

### 防漂移映射表聚焦（填入 `docs/source-of-truth-map.md`）
命令树（新增/废弃命令、flag 重命名）和 IO 协议（exit code / stdout 格式）——CLI 行为契约是真相源，入映射表。

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
默认 `decisions/` + `research/` + `exec-plans/`；`insights/` 可选。

### maintain-claude-docs 审计聚焦（填入 description；按需触发，非每改动）
`This is a library/SDK — focus the doc audit on public API surface, exports, and extension points (note SemVer impact).`

### 防漂移映射表聚焦（填入 `docs/source-of-truth-map.md`）
公共 API 表面（导出符号 + 稳定性等级）是库的生命线——SemVer 破坏性变更最易被遗漏，优先入映射表。

---

## 4. 后端服务

### 检测信号
- 存在 `Dockerfile` 且 `CMD` 是长进程（非一次性任务）
- `package.json` / `pyproject.toml` 的入口是 server（`fastify` / `koa` / `fastapi` 等）
- `go.mod` + 入口文件含 `http.ListenAndServe` 或 `grpc.NewServer`

### ARCHITECTURE 必填章节
1. 服务边界（对外提供的 endpoints / gRPC methods / 队列 topic）
2. 队列 / 消息（生产 / 消费关系）
3. 数据流（请求生命周期）
4. SLO / 可观测性（日志 / 指标 / tracing 约定）
5. 部署拓扑（instance 数、依赖的中间件）

### docs/ 调整
保留全部 4 类。

### maintain-claude-docs 审计聚焦（填入 description；按需触发，非每改动）
`This is a backend service — focus the doc audit on endpoints, queue contracts, and service boundaries.`

### 防漂移映射表聚焦（填入 `docs/source-of-truth-map.md`）
服务边界（endpoints / gRPC methods / 队列 topic）和 SLO 约定——跨团队契约是服务真相源的核心。

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
顶层全 4 类；每个 package 生成一份子包级 CLAUDE.md（模板：`templates/sub-package-CLAUDE.md.tmpl`），
含该子包的职责、专属 dev 命令、本地约定、关键入口。Claude 进入子目录时自动加载——
这是文章 "Scoping test and lint commands per subdirectory" 最佳实践的落地。

### Phase 2 额外步骤（monorepo 专属）
1. 识别所有 workspace packages（从 `workspaces` / `pnpm-workspace.yaml` 等读取）
2. 每个 package 目录生成 `CLAUDE.md`（用 `sub-package-CLAUDE.md.tmpl`）
3. 根 ARCHITECTURE.md `## 目录结构` 里列出每个 package 一句话职责

### maintain-claude-docs 审计聚焦（填入 description；按需触发，非每改动）
`This is a monorepo — focus the doc audit on new packages, workspace dependencies, and the release flow.`

---

## 6. 移动 App

### 检测信号
- `Podfile` / `*.xcodeproj` / `build.gradle` / `pubspec.yaml`
- `package.json` 含 `react-native` / `expo`

### ARCHITECTURE 必填章节
1. 平台分支（iOS / Android 差异点）
2. 状态管理（Redux / Riverpod / Provider 等）
3. 原生桥（如有 native module / platform channel）

### docs/ 调整
保留 `decisions/` + `insights/` + `exec-plans/`；`research/` 视情况。

### maintain-claude-docs 审计聚焦（填入 description；按需触发，非每改动）
`This is a mobile app — focus the doc audit on screens, native bridges, and state-management changes.`

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
`research/` 比 `insights/` 重要；建议把 `insights/` 与 `research/` 合并为单目录；`exec-plans/` 保留；`decisions/` 保留。

### maintain-claude-docs 审计聚焦（填入 description；按需触发，非每改动）
`This is a data/notebook project — focus the doc audit on pipeline stages, data contracts, and experiment records.`
