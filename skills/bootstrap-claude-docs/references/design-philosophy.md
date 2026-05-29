# 设计哲学

bootstrap-claude-docs 的 5 条可移植原则。每条都附「做什么 / 反例 / 为什么 / 怎么落到模板」。

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

## 3. 自维护索引（Self-Maintaining Index）

**做什么**：每个 `docs/<dir>/README.md` 是该子目录的索引；新增/删除文件必须同步更新表格。

**反例**：docs/ 目录下 30 份文件，没索引 → AI 检索时只能 grep，找不到的就当不存在；新人读不出脉络。

**为什么**：AI 和人都先看 README。索引漂移是"找不到 → 重写一份 → 重复"的根因。

**怎么落到模板**：所有 `docs-*-README.tmpl` 都明示「AI 须知：修改或新增文件后更新下方索引；检索本目录前先读此文件」；维护 skill 在 6 项清单里包含"索引同步了吗"。

## 4. 计划驱动开发（Plan-Driven）

**做什么**：中大型功能开工前先写 `docs/exec-plans/active/<topic>.md`，含 phases、状态、决策日志；完成后移到 `completed/`。纯研究进 `docs/research/`。技术债务进 `tech-debt-tracker.md`。

**反例**：直接开干 → 中途换需求、回滚、不知道为啥这么写；技术债务遍地无人收。

**为什么**：让 AI 和人都能从文档检索"这个项目目前在干嘛 / 为什么这么决定 / 哪里欠债"。

**怎么落到模板**：`docs-exec-plans-README.tmpl` 给出何时需要执行计划的判断标准 + 模板结构。

## 5. 自检纪律（Self-Check Discipline）

**做什么**：CLAUDE.md 自带「改动自查」清单（改动是否涉及 i18n / db / types / 文档？）；项目级 maintain-claude-docs skill 通过 description 主动触发。

**反例**：规则散落在 commit message / PR 模板 / wiki → AI 看不到，每次都要人提醒；新人入职第三个月才知道还要改 i18n。

**为什么**：CLAUDE.md 是项目入口，所有约束写这里才稳；项目级 skill 作为冗余保险，让"忘了"成本更低。

**怎么落到模板**：`CLAUDE.md.tmpl` 必含 `## 改动自查` 段；`maintain-claude-docs-SKILL.md.tmpl` 把同样的清单变成主动触发的 skill。

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
