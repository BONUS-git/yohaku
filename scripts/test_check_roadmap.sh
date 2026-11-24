#!/bin/sh
# check_roadmap.sh のテスト。正しい一式が通り、1 か所だけ壊した一式が落ちることを見る。
set -eu
cd "$(dirname "$0")/.."
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT INT TERM

# 正しい最小の一式を $tmp/base に作る
b="$tmp/base"
mkdir -p "$b/diagrams"
cat > "$b/requirements.md" <<'EOF'
# 要求仕様書（テスト用）

## 機能要件

| ID | 要求 | 区分 | 根拠 |
|----|------|------|------|
| FR-001 | 例の要求 1 | [assumed] | 既定 |
| FR-002 | 例の要求 2 | [assumed] | 既定 |
| FR-003 | 例の要求 3 | [assumed] | 既定 |
| FR-004 | 例の要求 4 | [assumed] | 既定 |
EOF
cat > "$b/mvp.md" <<'EOF'
# MVP（テスト用）

## M1 に入れる FR

| ID | 理由 |
|---|---|
| FR-001 | 例 |
| FR-002 | 例 |
| FR-003 | 例 |

## M1 に入れない FR

| ID | 理由 |
|---|---|
| FR-004 | 例 |
EOF
cat > "$b/roadmap.md" <<'EOF'
# ロードマップ（テスト用）

## M ごとの FR

- M1: FR-001〜FR-002, FR-003
- M2: FR-004
- M3: なし

## M1 — 例

### 目的
例
### 依存
例
### 受け入れ条件
例

## M2 — 例

### 目的
例
### 依存
例
### 受け入れ条件
例

## M3 — 例

### 目的
例
### 依存
例
### 受け入れ条件
例
EOF
cat > "$b/gaps.md" <<'EOF'
# 持ち越し（テスト用）

| ID | 仕分け | 向かう M | 理由 | 出どころ |
|----|--------|----------|------|----------|
| G-001 | 今決める | M1 | 例 | 例 |
| G-002 | 後回し | M3 | 例 | 例 |
EOF
cat > "$b/diagrams/flow.md" <<'EOF'
# 図（テスト用）
EOF
cat > "$b/INDEX.md" <<'EOF'
# 地図（テスト用）

- `.ai/INDEX.md`
- `.ai/requirements.md`
- `.ai/mvp.md`
- `.ai/roadmap.md`
- `.ai/gaps.md`
- `.ai/diagrams/flow.md`
EOF

fail=0
expect() { # expect <pass|fail> <説明> <壊すファイル> <sed の式>
    rm -rf "$tmp/case"
    cp -R "$b" "$tmp/case"
    sed "$4" "$b/$3" > "$tmp/case/$3"
    if sh scripts/check_roadmap.sh "$tmp/case" 2> "$tmp/err"; then got=pass; else got=fail; fi
    if [ "$got" = "$1" ]; then :; else
        echo "test_check_roadmap: NG: $2（期待 $1、結果 $got）" >&2
        cat "$tmp/err" >&2
        fail=1
    fi
}

expect pass "正しい一式"                       roadmap.md 's/^$//'
expect fail "M1 の行がない"                    roadmap.md 's/^- M1: .*$//'
expect fail "FR の書き方が違う"                roadmap.md 's/FR-001〜FR-002/FR-1〜FR-2/'
expect fail "範囲が逆"                         roadmap.md 's/FR-001〜FR-002/FR-002〜FR-001/'
expect fail "FR が 2 つの M に出る"            roadmap.md 's/^- M3: なし/- M3: FR-003/'
expect fail "FR がどの M にも出ない"           roadmap.md 's/^- M2: FR-004/- M2: なし/'
expect fail "M1 が mvp.md と違う"              mvp.md     's/^| FR-003 | 例 |$/| FR-004 | 例 |/'
expect fail "M の節に依存がない"               roadmap.md '/^## M3/,$s/^### 依存$/### 前提/'
expect fail "M の節がない"                     roadmap.md 's/^## M3 — 例$/## 例/'
expect fail "gaps の仕分けが違う"              gaps.md    's/| 後回し |/| 保留 |/'
expect fail "gaps の向かう M が roadmap にない" gaps.md    's/| M3 |/| M9 |/'
expect fail "gaps の列が足りない"              gaps.md    's/^| G-002 | 後回し | M3 | 例 | 例 |$/| G-002 | 後回し | M3 | 例 |/'
expect fail "INDEX に載っていない文書がある"   INDEX.md   '/flow\.md/d'
expect fail "INDEX に載せたパスがない"         INDEX.md   's/flow\.md/none.md/'

[ "$fail" = 0 ] || exit 1
echo "test_check_roadmap: ok"
