# 设计哲学

bootstrap-claude-docs 的 5 条可移植原则。每条都附「做什么 / 反例 / 为什么 / 怎么落到模板」。

## 1. 关注点分离（Separation of Concerns）

**做什么**：CLAUDE.md 写规则与流程；ARCHITECTURE.md 写结构与数据流；docs/ 写深度。三者职责互斥。

**反例**：把目录结构、数据流图、API 列表全塞进 CLAUDE.md，文件膨胀到 800 行 → AI 读不完，规则被深埋。

**为什么**：CLAUDE.md 自动注入每次会话上下文；越短越容易被完整读到。架构会随代码漂移；放进 ARCHITECTURE.md 才能由专门的 audit 流程同步。

**怎么落到模板**：`CLAUDE.md.tmpl` 严禁出现"目录结构 / 数据库 schema / API 路由表"段落；这些段落只在 `ARCHITECTURE.md.tmpl`。

## 2. 双视角文档（Dual-Perspective）

**做什么**：每个重要功能配两份文档：`docs/handover/<feature>.md`（技术）+ `docs/insights/<feature>.md`（产品），文件名一致并互链。

**反例**：只写技术文档 → 半年后没人记得"为什么这么设计"，提需求的人换了，决策被反复推翻。

**为什么**：技术文档解决"怎么实现"，产品文档解决"为什么这么实现"。两者读者不同、生命周期不同。

**怎么落到模板**：`docs-handover-README.tmpl` 和 `docs-insights-README.tmpl` 各自独立索引，但格式对齐；维护 skill 在写新功能时同时提醒两份。

## 3. 自维护索引（Self-Maintaining Index）

**做什么**：每个 `docs/<dir>/README.md` 是该子目录的索引；新增/删除文件必须同步更新表格。

**反例**：docs/ 目录下 30 份文件，没索引 → AI 检索时只能 grep，找不到的就当不存在；新人读不出脉络。

**为什么**：AI 和人都先看 README。索引漂移是"找不到 → 重写一份 → 重复" 的根因。

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
