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
    # 建立本地 bare upstream，让 @{push} 能解析
    git init -q --bare "$TMP/up.git"
    git remote add origin "$TMP/up.git"
    git push -q -u origin HEAD 2>/dev/null     # baseline：@{push} 指向 init commit
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

make_repo_no_upstream() {
  TMP="$(mktemp -d)"; ( cd "$TMP"
    git init -q && git config user.email t@t && git config user.name t
    mkdir -p docs bin .git/hooks
    cp "$TMPL" .git/hooks/pre-push && chmod +x .git/hooks/pre-push
    printf '| code | doc | action |\n|---|---|---|\n| `src/` | README.md | auto |\n' > docs/source-of-truth-map.md
    echo "v1" > src.txt && git add -A && git commit -qm init
    echo "v2" > src.txt && git add -A && git commit -qm change   # 制造一个待推送 commit，无任何 remote
  ); echo "$TMP"
}

echo "Case 1: 有漂移 → 调修复 + exit 0"
R="$(make_repo)"; make_stub "$R"; export CALLLOG="$R/calls.log"; : > "$CALLLOG"
out="$( cd "$R" && PATH="$R/bin:$PATH" STUB_DRIFT='[{"file":"README.md","rule":"src/","action":"auto"}]' \
        .git/hooks/pre-push origin git@x < /dev/null 2>&1 )"; code=$?
check "exit 0（不阻断）" "[ $code -eq 0 ]"
check "检测+修复共两次 claude 调用" "[ \$(grep -c -- '---CALL---' "$CALLLOG") -eq 2 ]"
check "报告里打印了漂移" "echo \"\$out\" | grep -q 漂移"
rm -rf "$R"

echo "Case 2: 无漂移 → 不调修复"
R="$(make_repo)"; make_stub "$R"; export CALLLOG="$R/calls.log"; : > "$CALLLOG"
out="$( cd "$R" && PATH="$R/bin:$PATH" STUB_DRIFT='[]' \
        .git/hooks/pre-push origin git@x < /dev/null 2>&1 )"; code=$?
check "exit 0" "[ $code -eq 0 ]"
check "只 1 次 claude 调用（仅检测）" "[ \$(grep -c -- '---CALL---' "$CALLLOG") -eq 1 ]"
rm -rf "$R"

echo "Case 3: 无 claude CLI → 降级 exit 0"
R="$(make_repo)"   # 不装 stub
out="$( cd "$R" && PATH="/usr/bin:/bin" .git/hooks/pre-push origin git@x < /dev/null 2>&1 )"; code=$?
check "exit 0（降级放行）" "[ $code -eq 0 ]"
check "打印降级提示" "echo \"\$out\" | grep -qi 'claude'"
rm -rf "$R"

echo "Case 4: 无 @{push} 基线 + pre-push stdin 提供范围 → 仍检测"
R="$(make_repo_no_upstream)"; make_stub "$R"; export CALLLOG="$R/calls.log"; : > "$CALLLOG"
HEAD_SHA="$(git -C "$R" rev-parse HEAD)"
out="$( cd "$R" && printf 'refs/heads/main %s refs/heads/main %s\n' "$HEAD_SHA" "0000000000000000000000000000000000000000" \
        | PATH="$R/bin:$PATH" STUB_DRIFT='[{"file":"README.md","rule":"src/","action":"auto"}]' .git/hooks/pre-push origin git@x 2>&1 )"; code=$?
check "exit 0（不阻断）" "[ $code -eq 0 ]"
check "检测+修复共两次 claude 调用（stdin 范围生效）" "[ \$(grep -c -- '---CALL---' "$CALLLOG") -eq 2 ]"
rm -rf "$R"

[ $fail -eq 0 ] && echo "ALL PASS" || { echo "SOME FAILED"; exit 1; }
