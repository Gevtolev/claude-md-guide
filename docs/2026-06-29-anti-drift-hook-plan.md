# Anti-Drift Hook Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 给 `bootstrap-claude-docs` 增加「生成项目级防漂移 hook + 真相源映射表」的能力，让每个新项目自带「提交时低档模型自动检测文档漂移 → 按需开 subagent 修复 → 留工作区等 review」的闭环。

**Architecture:** 一个真相源映射表（人看 + 检测器规则，一份两用）喂给一个默认挂 pre-push 的两阶段 git hook（haiku 检测 / sonnet 修复）。bootstrap 新增 Phase 2.6 负责按项目生成这两样并处理降级。改动落到源仓库 `claude-md-guide` 后同步到全局副本。

**Tech Stack:** Markdown（skill 文档 / 模板）、Bash（hook 脚本 + 测试，stub `claude` 做逻辑单测）、`claude -p` headless CLI（端到端验收时真实调用，用 haiku 控成本）。

**设计依据：** [docs/2026-06-29-anti-drift-hook-design.md](./2026-06-29-anti-drift-hook-design.md)（spec）。

## Global Constraints

每个 task 的要求都隐含这一节，值逐字照搬：

- **默认不硬拦截**：hook 任何 LLM 分支结束都 `exit 0`，绝不阻断 push；仅 `critical` 项可选非零退出（默认关）。
- **自动改 vs 只提醒**：README 索引 / ARCHITECTURE 描述段 / glossary 可 `auto` 改；`docs/decisions` ADR、PRD 一律 `notify`，不自动改。
- **改两份 + 同步一致**：源 `claude-md-guide/skills/bootstrap-claude-docs/` 改完，同步到全局副本 `~/.claude/skills/bootstrap-claude-docs/`，`diff -rq` 必须零差异。
- **模型档位**：检测默认 `claude-haiku-4-5`，修复默认 `claude-sonnet-4-6`，均经环境变量可配；测试与端到端控成本时都用 haiku。
- **降级**：无 `git` → 不装 hook；无 `claude` CLI / 离线 → hook 跳过 LLM 仅做静态检查；LLM 失败/超时 → 放行。
- **语言**：文档与注释用中文，代码/命令/标识符用英文。
- **提交**：Conventional Commits（`feat:`/`docs:`/`test:`/`chore:`），**不带 Co-Authored-By 签名**。
- **克制**：不破坏 bootstrap 第 5/6 条哲学——触发点=提交、执行者=低档模型而非人、不每次改动跑。

## File Structure

工作目录均为源仓库根 `claude-md-guide/`。

**新增：**
- `skills/bootstrap-claude-docs/templates/source-of-truth-map.tmpl` — 真相源映射表模板（hook 的输入契约）
- `skills/bootstrap-claude-docs/templates/anti-drift-hook.sh.tmpl` — 可执行 pre-push hook 脚本模板
- `skills/bootstrap-claude-docs/references/anti-drift-hook.md` — hook 蓝图：两阶段 prompt、挂点选择、安装方式、降级
- `tests/anti-drift-hook.test.sh` — hook 逻辑测试（stub `claude`）

**修改：**
- `skills/bootstrap-claude-docs/SKILL.md` — 加 Phase 2.6 + Quick Reference / Common Mistakes 补行
- `skills/bootstrap-claude-docs/references/design-philosophy.md` — 加第 7 条「防漂移闭环」
- `skills/bootstrap-claude-docs/templates/maintain-claude-docs-SKILL.md.tmpl` — 加「hook 与 maintain 分工」节
- `skills/bootstrap-claude-docs/templates/CLAUDE.md.tmpl` — 改动自查加一行指向映射表/hook
- `skills/bootstrap-claude-docs/references/project-type-variants.md` — 各类型补一句聚焦提示
- `README.md` — 「6 条」→「7 条」原则 + 产出结构图补 hook/映射表
- `CHANGELOG.md` — 新增 `[0.4.0]` 条目

---

### Task 1: 真相源映射表模板

**Files:**
- Create: `skills/bootstrap-claude-docs/templates/source-of-truth-map.tmpl`

**Interfaces:**
- Consumes: 无（最上游）。
- Produces: 映射表的列契约 `| 代码路径/模式 | 应同步的文档 | 处置(auto|notify) |`——Task 2 的 hook、Task 3 的 reference 都按这个格式读取。

- [ ] **Step 1: 写模板文件**

写入 `skills/bootstrap-claude-docs/templates/source-of-truth-map.tmpl`：

```markdown
# 真相源映射表 — {{PROJECT_NAME}}

> 一份两用：① 给人——同一事实只在「权威处」写，别处只**引用**不复述；② 给防漂移 hook——「代码动了 X → 该查文档 Y」的检测规则。
> `处置` 取值：`auto`（hook 可自动改，限机械低风险文档）/ `notify`（只提醒，人来改——决策/规格类）。

| 代码路径 / 模式 | 应同步的文档（权威处） | 处置 |
|---|---|---|
{{SOURCE_OF_TRUTH_ROWS}}
<!-- TODO bootstrap 按 Phase 1 扫描结果填充。每行一条规则，示例：
| `src/types/**`（字段增删） | 同步处的字段定义 + 字段文档 | notify |
| `src/api/**`、`app/api/**` | ARCHITECTURE.md 的「API / 错误码」表 | auto |
| 新增/删除 `docs/**/*.md` | 对应 `docs/<dir>/README.md` 索引 | auto |
| 核心计算/公式模块 | PRD 验收用例 + 对应 unit test | notify |
-->

## 红线
- `docs/decisions/`（ADR）、PRD/规格 → 永远 `notify`，hook 不自动改（避免 LLM 改错决策语义）。
- 运行时必须各写一份、消不掉的重复（如 schema↔types↔state）→ 列为 `notify`，并用**测试**锁一致，而非靠 hook。
```

- [ ] **Step 2: 校验模板结构**

Run:
```bash
grep -q 'SOURCE_OF_TRUTH_ROWS' skills/bootstrap-claude-docs/templates/source-of-truth-map.tmpl && \
grep -q '处置' skills/bootstrap-claude-docs/templates/source-of-truth-map.tmpl && \
grep -q 'auto|notify\|auto`（\|notify`（' skills/bootstrap-claude-docs/templates/source-of-truth-map.tmpl && echo OK
```
Expected: 打印 `OK`（含占位符、列头、处置取值说明）。

- [ ] **Step 3: 提交**

```bash
git add skills/bootstrap-claude-docs/templates/source-of-truth-map.tmpl
git commit -m "feat: add source-of-truth-map template for anti-drift"
```

---

### Task 2: 防漂移 hook 脚本模板 + 逻辑测试

**Files:**
- Create: `skills/bootstrap-claude-docs/templates/anti-drift-hook.sh.tmpl`
- Test: `tests/anti-drift-hook.test.sh`

**Interfaces:**
- Consumes: Task 1 的映射表（hook 运行时读 `docs/source-of-truth-map.md`）。
- Produces: hook 的行为契约——检测有漂移→调修复且 `exit 0`；无漂移→`exit 0` 不调修复；无 `claude`→降级 `exit 0`。Task 7 端到端依赖这些行为。

- [ ] **Step 1: 写失败测试**

写入 `tests/anti-drift-hook.test.sh`（stub `claude`，不烧 token）：

```bash
#!/usr/bin/env bash
# 用 stub claude 验证 anti-drift hook 的逻辑分支，不调真实 LLM。
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMPL="$ROOT/skills/bootstrap-claude-docs/templates/anti-drift-hook.sh.tmpl"
fail=0
check() { if eval "$2"; then echo "  ✓ $1"; else echo "  ✗ $1"; fail=1; fi; }

make_repo() {
  TMP="$(mktemp -d)"; ( cd "$TMP"
    git init -q && git config user.email t@t && git config user.name t
    mkdir -p docs bin .git/hooks
    cp "$TMPL" .git/hooks/pre-push && chmod +x .git/hooks/pre-push
    printf '| code | doc | action |\n|---|---|---|\n| `src/` | README.md | auto |\n' > docs/source-of-truth-map.md
    echo "v1" > src.txt && git add -A && git commit -qm init
    echo "v2" > src.txt && git add -A && git commit -qm change   # 制造一个待推送 commit
  ); echo "$TMP"
}
# stub claude：把每次 stdin 追加到 $CALLLOG，按 $STUB_DRIFT 输出检测结果
make_stub() {
  cat > "$1/bin/claude" <<'EOF'
#!/usr/bin/env bash
cat >> "$CALLLOG"
echo "---CALL---" >> "$CALLLOG"
echo "${STUB_DRIFT:-[]}"
EOF
  chmod +x "$1/bin/claude"
}

echo "Case 1: 有漂移 → 调修复 + exit 0"
R="$(make_repo)"; make_stub "$R"; export CALLLOG="$R/calls.log"; : > "$CALLLOG"
out="$( cd "$R" && PATH="$R/bin:$PATH" STUB_DRIFT='[{"file":"README.md","rule":"src/","action":"auto"}]' \
        .git/hooks/pre-push origin git@x 2>&1 )"; code=$?
check "exit 0（不阻断）" "[ $code -eq 0 ]"
check "检测+修复共两次 claude 调用" "[ \$(grep -c -- '---CALL---' "$CALLLOG") -eq 2 ]"
check "报告里打印了漂移" "echo \"\$out\" | grep -q 漂移"
rm -rf "$R"

echo "Case 2: 无漂移 → 不调修复"
R="$(make_repo)"; make_stub "$R"; export CALLLOG="$R/calls.log"; : > "$CALLLOG"
out="$( cd "$R" && PATH="$R/bin:$PATH" STUB_DRIFT='[]' \
        .git/hooks/pre-push origin git@x 2>&1 )"; code=$?
check "exit 0" "[ $code -eq 0 ]"
check "只 1 次 claude 调用（仅检测）" "[ \$(grep -c -- '---CALL---' "$CALLLOG") -eq 1 ]"
rm -rf "$R"

echo "Case 3: 无 claude CLI → 降级 exit 0"
R="$(make_repo)"   # 不装 stub
out="$( cd "$R" && PATH="/usr/bin:/bin" .git/hooks/pre-push origin git@x 2>&1 )"; code=$?
check "exit 0（降级放行）" "[ $code -eq 0 ]"
check "打印降级提示" "echo \"\$out\" | grep -qi 'claude'"
rm -rf "$R"

[ $fail -eq 0 ] && echo "ALL PASS" || { echo "SOME FAILED"; exit 1; }
```

- [ ] **Step 2: 跑测试，确认失败**

Run: `bash tests/anti-drift-hook.test.sh`
Expected: FAIL —— hook 模板还不存在，Case 1/2 的断言失败（`pre-push` 文件缺失或无输出）。

- [ ] **Step 3: 写 hook 脚本模板**

写入 `skills/bootstrap-claude-docs/templates/anti-drift-hook.sh.tmpl`：

```bash
#!/usr/bin/env bash
# anti-drift pre-push hook — generated by bootstrap-claude-docs (Phase 2.6)
# 默认软提醒：任何分支都 exit 0，绝不阻断 push。
set -uo pipefail

MAP_FILE="docs/source-of-truth-map.md"
DETECT_MODEL="${ANTI_DRIFT_DETECT_MODEL:-claude-haiku-4-5}"
REPAIR_MODEL="${ANTI_DRIFT_REPAIR_MODEL:-claude-sonnet-4-6}"

# 降级：无 claude CLI → 跳过 LLM（静态检查留待 reference 描述的可选扩展），放行
if ! command -v claude >/dev/null 2>&1; then
  echo "[anti-drift] claude CLI 不在 PATH，跳过 LLM 漂移检测。" >&2
  exit 0
fi

# 收集将推送的 diff
RANGE="$(git rev-parse --abbrev-ref --symbolic-full-name '@{push}' 2>/dev/null || true)"
if [ -n "$RANGE" ]; then
  DIFF="$(git diff "${RANGE}..HEAD" 2>/dev/null || true)"
else
  DEFAULT="$(git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null || echo origin/main)"
  DIFF="$(git diff "${DEFAULT}..HEAD" 2>/dev/null || git diff HEAD 2>/dev/null || true)"
fi
[ -z "${DIFF}" ] && exit 0

# 阶段 A 检测（haiku）
DETECT_PROMPT="你是文档漂移检测器。对照真相源映射表读 git diff，只输出命中的漂移点。
输出 JSON 数组，每项 {\"file\",\"rule\",\"action\"}，action 取映射表里的 auto|notify。无漂移输出 []。
=== 映射表 ===
$(cat "${MAP_FILE}" 2>/dev/null)
=== diff ===
${DIFF}"
DRIFT="$(printf '%s' "${DETECT_PROMPT}" | claude -p --model "${DETECT_MODEL}" 2>/dev/null || echo '[]')"

# 无漂移：放行
if ! printf '%s' "${DRIFT}" | grep -q '"file"'; then
  exit 0
fi

echo "[anti-drift] 检测到文档可能漂移：" >&2
printf '%s\n' "${DRIFT}" >&2

# 阶段 B 修复（sonnet）：只改 action=auto，notify 仅提醒；改动留工作区不 commit
REPAIR_PROMPT="根据漂移报告修复文档。规则：
- 只修改 action=auto 的文件；action=notify 的不要改，最后列出提醒。
- 改动保留在工作区，**不要** git add / git commit。
漂移报告：${DRIFT}"
printf '%s' "${REPAIR_PROMPT}" | claude -p --model "${REPAIR_MODEL}" --permission-mode acceptEdits >&2 2>/dev/null || true

echo "[anti-drift] 已尝试自动修复 auto 项（改动在工作区，请 review 后随下次提交带上）；notify 项见上。push 放行。" >&2
exit 0
```

> 注：`claude -p --permission-mode acceptEdits` 的 headless 编辑行为在 Task 7 端到端用真实 CLI 校准；若实际 flag 名不同，按真实修正并回跑本测试（stub 不依赖 flag 语义，仅看调用次数与退出码）。

- [ ] **Step 4: 跑测试，确认通过**

Run: `bash tests/anti-drift-hook.test.sh`
Expected: 三个 Case 全 `✓`，末行 `ALL PASS`。

- [ ] **Step 5: 提交**

```bash
git add skills/bootstrap-claude-docs/templates/anti-drift-hook.sh.tmpl tests/anti-drift-hook.test.sh
git commit -m "feat: add anti-drift pre-push hook template + logic tests"
```

---

### Task 3: hook 蓝图 reference

**Files:**
- Create: `skills/bootstrap-claude-docs/references/anti-drift-hook.md`

**Interfaces:**
- Consumes: Task 1 映射表格式、Task 2 hook 脚本。
- Produces: Phase 2.6（Task 4）引用的「如何生成 + 安装 + 适配 + 降级」权威说明。

- [ ] **Step 1: 写 reference**

写入 `skills/bootstrap-claude-docs/references/anti-drift-hook.md`，必须含这些小节（内容据 spec §4–6 展开）：

1. `## 这是什么` — 两阶段闭环一段话 + 与 maintain skill 的分工（hook=自动/提交时/机械漂移；maintain=按需/人主导/深度判断）。
2. `## 映射表是规则源` — 指向 `source-of-truth-map.tmpl`，说明「一份两用」。
3. `## 两阶段 prompt` — 检测 / 修复两段 prompt 模板（与 `anti-drift-hook.sh.tmpl` 内联的一致）。
4. `## 挂点选择` — 默认 pre-push；何时改 pre-commit（高频小项目）/ CI（团队 PR，需 `ANTHROPIC_API_KEY` secret + bot 推独立 docs commit）。
5. `## 安装方式` — 写 `.git/hooks/pre-push` + `chmod +x`；多人项目推荐 `git config core.hooksPath .githooks` 并把脚本纳入版本控制。
6. `## 降级矩阵` — 无 git / 无 claude / 离线 / LLM 失败 各自行为（对齐 Global Constraints）。
7. `## 模型与成本` — 检测 haiku / 修复 sonnet，环境变量 `ANTI_DRIFT_DETECT_MODEL` / `ANTI_DRIFT_REPAIR_MODEL`；无漂移即放行，成本主要在「有漂移」的少数提交。

- [ ] **Step 2: 校验小节齐全**

Run:
```bash
f=skills/bootstrap-claude-docs/references/anti-drift-hook.md
for s in 这是什么 映射表是规则源 两阶段 prompt 挂点选择 安装方式 降级矩阵 模型与成本; do
  grep -q "$s" "$f" || { echo "缺小节: $s"; exit 1; }; done; echo OK
```
Expected: `OK`。

- [ ] **Step 3: 提交**

```bash
git add skills/bootstrap-claude-docs/references/anti-drift-hook.md
git commit -m "docs: add anti-drift-hook reference (blueprint, install, degrade)"
```

---

### Task 4: SKILL.md 加 Phase 2.6

**Files:**
- Modify: `skills/bootstrap-claude-docs/SKILL.md`

**Interfaces:**
- Consumes: Task 1/2/3 的文件名（`source-of-truth-map.tmpl`、`anti-drift-hook.sh.tmpl`、`references/anti-drift-hook.md`）。
- Produces: bootstrap 流程中生成 hook + 映射表的编排步骤。

- [ ] **Step 1: 在 Phase 2.5 之后插入 Phase 2.6**

在 `## Workflow` 的 `Phase 2.5` 段之后插入：

```markdown
**Phase 2.6 — 生成项目级防漂移 hook（防漂移闭环）**
检测 `git` 与 `claude` CLI：
- 有 git → 用 `templates/source-of-truth-map.tmpl` 生成 `docs/source-of-truth-map.md`（按 Phase 1 扫描填规则行），并用 `templates/anti-drift-hook.sh.tmpl` 安装 pre-push hook（默认 `.git/hooks/pre-push`，多人项目用 `core.hooksPath`）。
- 无 git → 跳过 hook，把防漂移落回 maintain skill 的手动 reconcile 步骤。
完整蓝图（两阶段 prompt / 挂点 / 安装 / 降级）见 `references/anti-drift-hook.md`。✋ 检查点 2.6：把生成的映射表规则给用户确认（哪些 `auto` 哪些 `notify`）。
```

- [ ] **Step 2: 更新 Quick Reference 与 Common Mistakes**

在 `## Quick Reference` 的 docs 子目录表后补一行说明真相源映射表；在 `## Common Mistakes` 表加一行：

```markdown
| 忘了生成防漂移 hook/映射表 | Phase 2.6：有 git 就装 pre-push hook + 映射表，无 git 落回 maintain |
```

- [ ] **Step 3: 校验**

Run:
```bash
f=skills/bootstrap-claude-docs/SKILL.md
grep -q 'Phase 2.6' "$f" && grep -q 'source-of-truth-map' "$f" && \
grep -q 'anti-drift-hook' "$f" && echo OK
```
Expected: `OK`。

- [ ] **Step 4: 提交**

```bash
git add skills/bootstrap-claude-docs/SKILL.md
git commit -m "feat: add Phase 2.6 (generate anti-drift hook) to bootstrap SKILL"
```

---

### Task 5: 设计哲学第 7 条 + maintain/CLAUDE 衔接

**Files:**
- Modify: `skills/bootstrap-claude-docs/references/design-philosophy.md`
- Modify: `skills/bootstrap-claude-docs/templates/maintain-claude-docs-SKILL.md.tmpl`
- Modify: `skills/bootstrap-claude-docs/templates/CLAUDE.md.tmpl`

**Interfaces:**
- Consumes: Task 1–4 的概念与文件名。
- Produces: 生成出来的项目里，maintain skill 与 CLAUDE.md 对 hook/映射表的引用。

- [ ] **Step 1: design-philosophy 加第 7 条**

在「## 6. 克制」之后、「## 关于已废弃」之前插入 `## 7. 防漂移闭环（Anti-Drift Loop）`，含「做什么 / 反例 / 为什么 / 怎么落到模板」四段，并**显式调和与第 5/6 条的关系**：触发点=提交（非每次改动）、执行者=低档模型（非人）、默认软提醒（不硬拦），所以不违背克制。

- [ ] **Step 2: maintain 模板加分工节**

在 `maintain-claude-docs-SKILL.md.tmpl` 的 `## When to Use` 后加一节 `## 与防漂移 hook 的分工`：hook 兜底机械漂移（索引/描述段/字段一致），maintain 只管 hook 够不到的深度判断（ADR 该不该写、季度审计、结构重组）；checklist 第 4 项（索引）注明「由 hook 兜底」。

- [ ] **Step 3: CLAUDE.md.tmpl 改动自查加一行**

在 `{{CHANGE_REVIEW_CHECKLIST}}` 的 TODO 注释样例里加一行引导：
```
> 软提示：本项目有真相源映射表 `docs/source-of-truth-map.md` + pre-push 防漂移 hook 兜底；改代码顺手看一眼映射表对应文档。
```

- [ ] **Step 4: 校验**

Run:
```bash
grep -q '## 7' skills/bootstrap-claude-docs/references/design-philosophy.md && \
grep -q '防漂移 hook 的分工\|防漂移 hook' skills/bootstrap-claude-docs/templates/maintain-claude-docs-SKILL.md.tmpl && \
grep -q 'source-of-truth-map' skills/bootstrap-claude-docs/templates/CLAUDE.md.tmpl && echo OK
```
Expected: `OK`。

- [ ] **Step 5: 提交**

```bash
git add skills/bootstrap-claude-docs/references/design-philosophy.md \
        skills/bootstrap-claude-docs/templates/maintain-claude-docs-SKILL.md.tmpl \
        skills/bootstrap-claude-docs/templates/CLAUDE.md.tmpl
git commit -m "feat: add anti-drift design principle + maintain/CLAUDE wiring"
```

---

### Task 6: 周边同步（类型变体 + README + CHANGELOG）

**Files:**
- Modify: `skills/bootstrap-claude-docs/references/project-type-variants.md`
- Modify: `README.md`
- Modify: `CHANGELOG.md`

**Interfaces:**
- Consumes: 前述全部改动。
- Produces: 对外文档与变更记录一致。

- [ ] **Step 1: 类型变体补提示**

在 `project-type-variants.md` 的总览表加一列或在每类型「maintain 审计聚焦」旁补一句「防漂移映射表聚焦」（例：Web → API/路由/DB schema 入映射表；Library → 公共 API 表面）。至少覆盖 Web / CLI / Library / Service 四类。

- [ ] **Step 2: README 更新**

`README.md`：将「6 条可移植设计原则」改为「7 条」并补「防漂移闭环」；在「产出什么」结构图补 `docs/source-of-truth-map.md` 与 `.git/hooks/pre-push`（防漂移 hook）两行。

- [ ] **Step 3: CHANGELOG 加条目**

在 `CHANGELOG.md` 顶部加：
```markdown
## [0.4.0] - 2026-06-29

### Added

- **防漂移闭环**：新增 Phase 2.6，按项目生成真相源映射表（`source-of-truth-map.tmpl`）+ pre-push 防漂移 hook（`anti-drift-hook.sh.tmpl`，两阶段：haiku 检测 / sonnet 修复，自动改机械文档、ADR/PRD 只提醒、改动留工作区不 commit）。蓝图见 `references/anti-drift-hook.md`。
- 设计哲学第 7 条「防漂移闭环」；maintain skill 增「与 hook 分工」节。

### Changed

- README 原则数 6 → 7；maintain checklist 索引项改为「hook 兜底」。
```

- [ ] **Step 4: 校验**

Run:
```bash
grep -q '7 条\|7 条可移植\|7 大' README.md && grep -q 'source-of-truth-map' README.md && \
grep -q '0.4.0' CHANGELOG.md && echo OK
```
Expected: `OK`。

- [ ] **Step 5: 提交**

```bash
git add skills/bootstrap-claude-docs/references/project-type-variants.md README.md CHANGELOG.md
git commit -m "docs: wire anti-drift into type-variants, README, CHANGELOG (0.4.0)"
```

---

### Task 7: mock 项目端到端验收（真实 claude，haiku 控成本）

**Files:**
- 仅在临时目录操作，不入源仓库。

**Interfaces:**
- Consumes: Task 1–6 的全部产物。
- Produces: 整套闭环的真实运行证据。

- [ ] **Step 1: 建 mock 项目并安装产物**

```bash
MOCK="$(mktemp -d)"; cd "$MOCK"
git init -q && git config user.email t@t && git config user.name t
git remote add origin git@example.com:mock/mock.git
npm init -y >/dev/null 2>&1 || echo '{"name":"mock"}' > package.json
mkdir -p src docs
printf '# README\n\n## API\n- GET /ping\n' > README.md
printf 'export const api = ["/ping"];\n' > src/api.ts
# 装映射表（渲染：把 ROWS 占位换成一条 auto 规则）
SRC=~/projects/claude-md-guide/skills/bootstrap-claude-docs/templates
sed 's#{{PROJECT_NAME}}#mock#; s#{{SOURCE_OF_TRUTH_ROWS}}#| `src/api.ts` | README.md 的「API」节 | auto |#' \
  "$SRC/source-of-truth-map.tmpl" > docs/source-of-truth-map.md
cp "$SRC/anti-drift-hook.sh.tmpl" .git/hooks/pre-push && chmod +x .git/hooks/pre-push
git add -A && git commit -qm "init mock"
```

- [ ] **Step 2: 制造漂移并触发 hook（真实 haiku）**

```bash
cd "$MOCK"
# 改 API 源但不改 README → 命中映射表 auto 规则
printf 'export const api = ["/ping","/health"];\n' > src/api.ts
git add -A && git commit -qm "feat: add /health endpoint"
# 直接跑 hook（不真 push）；修复也降到 haiku 控成本
ANTI_DRIFT_REPAIR_MODEL=claude-haiku-4-5 \
  .git/hooks/pre-push origin git@example.com:mock/mock.git; echo "exit=$?"
```
Expected: 退出码 0；stderr 打印检测到的漂移（README 的 API 节）+「已尝试自动修复」。

- [ ] **Step 3: 断言闭环正确**

```bash
cd "$MOCK"
git diff --name-only            # 期望: README.md 出现在工作区改动里（被自动改）
git status --porcelain | grep -q '^ M README.md\|^.M README.md' && echo "✓ README 已改且未 commit"
git log --oneline -1 | grep -q health && echo "✓ 未产生额外自动 commit（HEAD 仍是业务 commit）"
grep -q health README.md && echo "✓ README 已补 /health"
```
Expected: 三条 `✓`。若修复阶段因 `--permission-mode` flag 差异未改文件，回 Task 2 Step 3 按真实 `claude` CLI 修正 flag，再重跑本 Task。

- [ ] **Step 4: 降级冒烟**

```bash
cd "$MOCK"
PATH="/usr/bin:/bin" .git/hooks/pre-push origin git@example.com:mock/mock.git; echo "exit=$?"
```
Expected: 退出码 0 + 打印「claude CLI 不在 PATH，跳过」。

- [ ] **Step 5: 记录结果并清理**

把 Step 2–4 的实际输出贴进本 plan 的「验收记录」附录（或单独 commit 一份 `docs/anti-drift-e2e-log.md` 到源仓库），然后 `rm -rf "$MOCK"`。

---

### Task 8: 同步全局副本 + 一致性收口

**Files:**
- Sync: `~/.claude/skills/bootstrap-claude-docs/` ← 源
- Modify: 无（仅同步与验证）

**Interfaces:**
- Consumes: Task 1–6 已提交的源改动。
- Produces: 源与全局副本字节一致。

- [ ] **Step 1: 同步源到全局副本**

```bash
rsync -a --delete ~/projects/claude-md-guide/skills/bootstrap-claude-docs/ \
                  ~/.claude/skills/bootstrap-claude-docs/
```
（无 rsync 则 `rm -rf` 目标后 `cp -r`。）

- [ ] **Step 2: 验证零差异**

Run:
```bash
diff -rq ~/projects/claude-md-guide/skills/bootstrap-claude-docs \
         ~/.claude/skills/bootstrap-claude-docs && echo "IN SYNC"
```
Expected: 无输出 + `IN SYNC`。

- [ ] **Step 3: 跑一遍 hook 测试确认全局副本可用（可选）**

Run: `bash ~/projects/claude-md-guide/tests/anti-drift-hook.test.sh`
Expected: `ALL PASS`。

- [ ] **Step 4: 收口提交**

```bash
cd ~/projects/claude-md-guide
git add -A && git commit -m "chore: sync anti-drift to global skill copy" --allow-empty
git log --oneline -8
```

---

## Self-Review

**1. Spec coverage（spec 各节 → task）：**
- §4.1 映射表 → Task 1 ✓；§4.2 hook 两阶段 → Task 2 ✓；§4.3 与 maintain 分工 → Task 5 ✓
- §5 边界（auto/notify、不硬拦） → Task 1（红线）+ Task 2（脚本逻辑）✓
- §6 降级 → Task 2（Case 3）+ Task 7（Step 4）✓
- §7 改动面 9 文件 → Task 1–6 全覆盖 ✓
- §8 两份同步 → Task 8 ✓；§9 mock 端到端 → Task 7 ✓

**2. Placeholder scan：** hook 脚本、测试、映射表模板均给出完整内容；文档类 task 给出「必含小节 + 校验命令」而非整篇逐字（文档无跨 task 类型契约，校验用 grep 锁关键内容）。无 TBD/TODO 残留（模板内的 `{{...}}` 是 bootstrap 渲染占位，非 plan 占位）。

**3. Type/名称一致性：** 环境变量 `ANTI_DRIFT_DETECT_MODEL` / `ANTI_DRIFT_REPAIR_MODEL`、文件名 `source-of-truth-map.tmpl` / `anti-drift-hook.sh.tmpl` / `references/anti-drift-hook.md`、映射表列 `处置(auto|notify)` 在各 task 间一致。

**已知需实测校准点（非占位）：** `claude -p --permission-mode acceptEdits` 的 headless 编辑 flag 在 Task 7 用真实 CLI 验证；stub 测试不依赖该 flag 语义，故 Task 2 可独立通过。
