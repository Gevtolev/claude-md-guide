# 设计哲学

bootstrap-claude-docs 的可移植原则。每条都附「做什么 / 反例 / 为什么 / 怎么落到模板」。

## 1. 关注点分离（Separation of Concerns）

**做什么**：CLAUDE.md 写规则与流程；ARCHITECTURE.md 写结构与数据流；docs/ 写深度。三者职责互斥。

**反例**：把目录结构、数据流图、API 列表全塞进 CLAUDE.md，文件膨胀到 800 行 → AI 读不完，规则被深埋。

**为什么**：CLAUDE.md 自动注入每次会话上下文；越短越容易被完整读到。架构会随代码漂移；放进 ARCHITECTURE.md 才能由专门的 audit 流程同步。

**怎么落到模板**：`CLAUDE.md.tmpl` 严禁出现"目录结构 / 数据库 schema / API 路由表"段落；这些段落只在 `ARCHITECTURE.md.tmpl`。

## 2. 决策追溯独立（Independent Decision Trail）

**做什么**：关键架构与产品决策用 ADR（Architecture Decision Record）形式记录在 `docs/decisions/`，每份决策一个文件，含 `Status / Context / Decision / Consequences / Related` 标准结构。新决策按时间追加，不修改旧 ADR；推翻时新增 `Superseded by D##`。

**反例**：决策散落在 commit message / wiki / chat 记录 / handover 文档里 → 半年后没人能完整还原"为什么是这样而不是另一种"，提需求的人换了，决策被反复推翻。

**为什么**：
- 决策追溯（why）和现状描述（how）是不同时间维度的内容——前者按时间追加，后者随代码漂移改写
- 把它们混在 handover 一类目录里会让 handover 变成大杂烩，失去"快速上手"的聚焦
- ADR 标准格式让新人能 5 分钟读完一份决策，比读完整 PRD 快得多
- 监管合规场景（金融 / 医疗）要求决策可审计——独立目录 + 不可变历史 + 电子签名是标准做法

**怎么落到模板**：`docs/decisions/` 是必选目录；模板含 `docs-decisions-README.tmpl`（决策矩阵索引 + 写作规范）+ `adr.tmpl`（单份 ADR 标准格式）。

## 3. 索引（Index，按需维护）

**做什么**：每个 `docs/<dir>/README.md` 是该子目录的索引。新增**长期文档**时顺手更新表格；脚手架 / 状态文档、空目录不建也不维护索引。

**反例**：① docs/ 下 30 份长期文档没索引 → AI 检索只能 grep，找不到的当不存在。② 反向过度——为每个临时脚手架、每个空目录都维护索引表，增删一个文件就改一次（与原则 6 冲突）。

**为什么**：AI 和人都先看 README，索引对**长期文档**有真实导航价值；但为会被删的脚手架维护索引是净亏损。

**怎么落到模板**：`docs-*-README.tmpl` 明示「新增长期文档后更新索引；检索本目录前先读此文件」，不要求为脚手架 / 空目录维护。

## 4. 计划驱动开发（Plan-Driven，粗粒度）

**做什么**：中大型 / 多会话功能开工前先写 `docs/exec-plans/active/<topic>.md`——**粗粒度**即可（phases + 当前状态 + 关键决策日志），不逐行写实现；**做完直接移到 `completed/` 即可，移动本身就是收口**（不必逐条勾验收 / 写收口叙述）。`active/` 与 `completed/` 本身就是给人和 AI 的"现在在做什么 / 什么做完了"信号——**这是 exec-plan 的核心价值，值得留**。

**反例**：① 直接开干 → 中途换需求、回滚、不知道为啥这么写。② 反向过度——把计划写成逐 Task 的实现叙述、每完成一步回去更新一堆 checkbox，最后文档比代码还细、还易腐烂（与原则 6 冲突）。

**为什么**：粗粒度的 active/completed 让人一眼看出项目在干嘛、进度到哪，这层状态信号有真实价值；但耐久的"为什么"属于 ADR，代码级细节属于代码——计划只承担"现在 / 做完了"这一层，写细了就成负债。

**怎么落到模板**：`docs-exec-plans-README.tmpl` 给出何时需要计划的判断标准（中大型 / 多会话才需）+ 粗粒度模板结构；明示"耐久决策进 ADR，别在计划里复述代码"。

## 5. 自检纪律（Self-Check Discipline）

**做什么**：CLAUDE.md 自带**精简**的「改动自查」清单（≤4 条核心，如 UI / 计算 / secret / 关键决策），其余写成一行「软提示·按需」；项目级 maintain-claude-docs skill 作为**按需 / 阶段性**的文档体检入口，不在每次改动后自动跑。

**反例**：① 规则散落在 commit message / PR 模板 / wiki → AI 看不到，每次要人提醒。② 反向过度——自查列 9 条、skill 每次提交都跑，一个小改动触发一堆文档维护，纯烧 token。

**为什么**：CLAUDE.md 是项目入口，核心约束写这里才稳；但清单越长越没人逐条走，skill 跑得越勤维护成本越高。核心项必查 + 其余按需，才可持续。

**怎么落到模板**：`CLAUDE.md.tmpl` 的 `## 改动自查` 默认只给 ≤4 核心项 + 一行软提示；`maintain-claude-docs-SKILL.md.tmpl` 默认按需触发、ADR 只记难逆转 + 非显而易见的决策。

## 6. 克制：文档为回查服务，不为完整性（Restraint）

**做什么**：只记「将来真会回头查」的东西——难逆转 + 非显而易见的决策。能从代码 / git / ARCHITECTURE 推出来的不记；ADR 能写短就写短（20–30 行）；可选目录（insights / research / exec-plans）空着也没关系，别为填而填。

**反例**：为「目录完整」给每个改动补 insights、维护永远空着的 research/、AGENTS.md 逐条镜像 CLAUDE.md、每次提交跑全量文档同步 → 维护成本超过文档价值，纯烧 token。

**为什么**：文档的收益是「将来省下重新搞清楚的时间」。一条将来没人会查的记录，写它和维护它都是净亏损。文档体系是决策追溯的工具，不是要被填满的表格。

**怎么落到模板**：`adr.tmpl` 提示「可写短」；自查清单与生成的维护 skill 都默认「只记难逆转 + 非显而易见」；`AGENTS.md.tmpl` 只做指针不做镜像。可选目录的「按首次需要才建」是后续可选增强（见 `SKILL.md` Phase 2）。

---

## 关于已废弃的"双视角"原则

早期版本曾有第 6 条"双视角文档"原则——每个功能配对 `docs/handover/<feature>.md`（技术）+ `docs/insights/<feature>.md`（产品）。实践中发现：

- 多数项目实际只填一边（要么只 handover 要么只 insights）
- handover 与"决策追溯"边界模糊，导致决策记录散落在 handover 中难以追踪
- "成对维护"对小到中型项目过重，对大型项目又因为粒度问题不易实施

现已废弃。改为：
- **决策追溯**独立到 `docs/decisions/`（ADR 体系）
- **产品视角**留在 `docs/insights/`（PRD / 用户问题 / 商业理由），不再要求与 handover 配对
- **现状描述 / 模块级深入**由顶层 `ARCHITECTURE.md` + 代码 docstring 承担，不再设独立 `handover/` 目录
