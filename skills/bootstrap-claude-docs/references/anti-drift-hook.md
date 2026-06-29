# anti-drift hook 蓝图

> **角色**：bootstrap Phase 2.6 的权威操作手册。本文档告诉你如何生成、安装、调整和降级防漂移 hook；设计动机和架构决策见 [docs/2026-06-29-anti-drift-hook-design.md](../../../docs/2026-06-29-anti-drift-hook-design.md)。

---

## 这是什么

防漂移 hook 是一套**自动、提交点触发的两阶段文档闭环**：阶段 A 用低成本 haiku 模型对比 git diff 与真相源映射表，输出漂移点列表；阶段 B 仅当检测到漂移时唤起 sonnet 修复「可自动改」的机械文档（如索引、描述段），改动留工作区等人 review，任何情况都 exit 0 放行 push。

与 **maintain skill 的分工**：

| | 防漂移 hook | maintain skill |
|---|---|---|
| 触发 | 自动，推送时 | 按需 / 阶段性，人主导 |
| 管的事 | 机械漂移（索引、描述段、字段一致） | 深度判断（ADR 该不该写、季度审计、结构重组） |
| 关系 | 兜底高频漂移 | hook 够不到的判断留给它 |

简单说：**hook = 自动 / 提交时 / 机械漂移**；**maintain = 按需 / 人主导 / 深度判断**。

---

## 映射表是规则源

真相源映射表位于项目根下 `docs/source-of-truth-map.md`（由 bootstrap Phase 2.6 按 Phase 1 扫描结果生成，模板见 [`templates/source-of-truth-map.tmpl`](../templates/source-of-truth-map.tmpl)）。

它**一份两用**：

1. **给人看**：同一事实只在「权威处」写，别处只引用，不复述。  
2. **喂给检测器**：hook 阶段 A 把整张表注入 prompt，作为「代码动了 X → 该查文档 Y」的检测规则。

`处置` 列取值：
- `auto`：hook 可自动修复（机械、低风险文档，如 README 索引、ARCHITECTURE 描述段）。
- `notify`：只提醒，不改文件（决策 / 规格类，如 ADR、PRD；LLM 易改错语义）。

**红线**（来自映射表模板）：`docs/decisions/` ADR 和 PRD 永远 `notify`；运行时必须各写一份的重复（如 schema↔types↔state）列 `notify` 并用测试锁一致。

---

## 两阶段 prompt

以下两段 prompt 即 `templates/anti-drift-hook.sh.tmpl` 中内联的完整版本，保持一致。

**阶段 A — 检测 prompt（发给 `${ANTI_DRIFT_DETECT_MODEL}`，默认 `claude-haiku-4-5`）**

```
你是文档漂移检测器。对照真相源映射表读 git diff，只输出命中的漂移点。
输出 JSON 数组，每项 {"file","rule","action"}，action 取映射表里的 auto|notify。无漂移输出 []。
=== 映射表 ===
<映射表内容>
=== diff ===
<git diff 内容>
```

- 无漂移（输出不含字符串 `"action"`）→ 直接放行，不进入阶段 B。
- 有漂移 → 把 JSON 打印到 stderr 并进入阶段 B。

**阶段 B — 修复 prompt（发给 `${ANTI_DRIFT_REPAIR_MODEL}`，默认 `claude-sonnet-4-6`）**

```
根据漂移报告修复文档。规则：
- 只修改 action=auto 的文件；action=notify 的不要改，最后列出提醒。
- 改动保留在工作区，**不要** git add / git commit。
漂移报告：<阶段 A 的 JSON 输出>
```

**调用方式**：`claude -p --model <model> --permission-mode acceptEdits`，确保 LLM 可写文件。

- 无论 repair 成功与否，hook 最终 exit 0 放行。

---

## 挂点选择

| 挂点 | 适用场景 | 注意事项 |
|---|---|---|
| **pre-push**（默认） | 绝大多数项目 | 频率低，等 LLM 响应不烦人 |
| **pre-commit** | 高频小提交、小型独立项目 | 每次提交都要等，慎用 |
| **CI（GitHub Actions 等）** | 多人团队、PR 合并门控 | 需要把 `ANTHROPIC_API_KEY` 加为 repo secret；bot 推的 docs 修复要独立 commit，否则触发循环 |

**默认选 pre-push**。只有「团队共享分支 + 人人本地都装 claude CLI 不现实」时才考虑 CI 挂点。

---

## 安装方式

bootstrap Phase 2.6 渲染模板后**直接写到以下位置**，不存在 `docs/generated/...` 这样的中间产物。

### 单人项目（默认：写入 `.git/hooks/`，不纳入版本控制）

```bash
# bootstrap Phase 2.6 渲染模板后直接写到此路径并 chmod +x
# 默认安装位置：
.git/hooks/pre-push   # chmod +x 已由 bootstrap 完成
```

### 多人 / 团队项目（推荐：纳入版本控制）

```bash
# bootstrap Phase 2.6 渲染模板后直接写到此路径并 chmod +x
# 共享安装位置：
.githooks/pre-push    # chmod +x 已由 bootstrap 完成

# 让 git 使用该目录（每位开发者克隆后需跑一次）
git config core.hooksPath .githooks
```

> **为什么推荐 `core.hooksPath`**：`.git/` 不进版本控制，团队成员各自克隆后 hook 丢失；`core.hooksPath` 把脚本纳入仓库，配合 `git config` 或 onboarding 脚本一次性搞定，保持团队一致。

---

## 降级矩阵

| 场景 | 行为 | 依据（脚本实际逻辑） |
|---|---|---|
| **无 git**（非 git 仓库） | 不生成 hook；防漂移退回 maintain skill 的手动 verify 步骤 | bootstrap Phase 2.6 检测 `git rev-parse` 失败则跳过生成 |
| **无 claude CLI**（`claude` 不在 PATH） | hook 打印提示 `[anti-drift] claude CLI 不在 PATH，跳过 LLM 漂移检测。` 后 exit 0 放行 | 脚本开头 `command -v claude` 检查（不在 PATH 即提示并 exit 0） |
| **离线 / 网络不通** | `claude -p` 返回非零或超时 → `DRIFT` 被设为 `[]`（fallback）→ 无漂移分支 → exit 0 放行 | `... 2>/dev/null \|\| echo '[]'` |
| **LLM 失败**（任意阶段报错） | 同上；repair 阶段失败同样 exit 0 放行，并打印警告 | 阶段 B `\|\| true` 兜底 + 最终 exit 0 |

**核心原则**：任何降级路径都**绝不阻断 push**，最多丢掉一次漂移检测机会。

---

## 模型与成本

| 阶段 | 默认模型 | 环境变量覆盖 |
|---|---|---|
| A 检测 | `claude-haiku-4-5` | `ANTI_DRIFT_DETECT_MODEL` |
| B 修复 | `claude-sonnet-4-6` | `ANTI_DRIFT_REPAIR_MODEL` |

**成本逻辑**：

- 阶段 A（haiku）每次 push 都跑，但 haiku 极便宜；**无漂移即放行，不进入阶段 B**——绝大多数「日常业务提交」在 A 结束后直接放行。
- 阶段 B（sonnet）仅当检测到漂移才唤起，即「有问题的少数提交」才花 sonnet 成本。
- 两阶段合计：正常开发流水下，成本主要集中在真正有文档漂移的提交，日常推送几乎可忽略不计。

如需进一步压成本，可把 `ANTI_DRIFT_REPAIR_MODEL` 也设为 haiku；如需更高修复质量，可改为 `claude-opus-4-5`（成本相应上升）。
