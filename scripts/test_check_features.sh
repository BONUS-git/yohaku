#!/bin/sh
# check_features.sh のテスト。正しい文書が通り、受け入れ確認に反する文書が落ちることを見る。
set -eu
cd "$(dirname "$0")/.."
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT INT TERM

cat > "$tmp/req.md" <<'EOF'
# 要求仕様書（テスト用）

## 機能要件

| ID | 要求 | 区分 | 根拠 |
|----|------|------|------|
| FR-001 | 例の要求 | [explicit] | brief.md 4.1 お金の記録（エントリ） |
| FR-002 | 例の要求 | [explicit] | brief.md 4.1 お金の記録（エントリ） |
| FR-003 | 例の要求 | [inferred] | brief.md 4.2 から |

## 非機能要件

| ID | 要求 | 区分 | 根拠 |
|----|------|------|------|
| NFR-001 | 例の非機能要求 | [assumed] | 既定 |
EOF

cat > "$tmp/feat.md" <<'EOF'
# 機能一覧と優先順位（テスト用）

## 機能一覧

| ID | 機能 | 中身 | 機能要件 | 段階 |
|----|------|------|----------|------|
| F-001 | 例の機能 | 例の中身 | FR-001・FR-002 | 最初に動かす最小の範囲 |
| F-002 | 例の後の機能 | 例の中身 | FR-003 | その後 |

## 最初に動かす最小の範囲

| ID | 機能 | 理由 | 区分 |
|----|------|------|------|
| F-001 | 例の機能 | 例の理由 | [inferred] |

## その後

| ID | 機能 | 理由 | 区分 |
|----|------|------|------|
| F-002 | 例の後の機能 | 例の後の理由 | [assumed] |
EOF

fail=0
expect() { # expect <pass|fail> <説明> <features の sed 式> [requirements の sed 式]
    sed "$3" "$tmp/feat.md" > "$tmp/case_feat.md"
    sed "${4:-s/^$//}" "$tmp/req.md" > "$tmp/case_req.md"
    if sh scripts/check_features.sh "$tmp/case_feat.md" "$tmp/case_req.md" 2> "$tmp/err"; then got=pass; else got=fail; fi
    if [ "$got" = "$1" ]; then :; else
        echo "test_check_features: NG: $2（期待 $1、結果 $got）" >&2
        cat "$tmp/err" >&2
        fail=1
    fi
}

expect pass "正しい文書"                         's/^$//'
expect fail "その後の節がない"                   's/^## その後$/## 後で/'
expect fail "機能一覧の節がない"                 's/^## 機能一覧$/## 一覧/'
expect fail "一覧の行に FR 番号がない"           's/| FR-003 |/| なし |/'
expect fail "どの機能にも出てこない FR がある"   's/^$//' 's/^| FR-003 \(.*\)$/| FR-003 \1\
| FR-004 | 例の要求 | [assumed] | 既定 |/'
expect fail "要求仕様書にない FR を書く"         's/| FR-003 |/| FR-003・FR-009 |/'
expect fail "どの段階にも置かれていない"         '/^| F-002 | 例の後の機能 | 例の後の理由/d'
expect fail "2 か所に置かれている"               's/^| F-001 | 例の機能 | 例の理由 | \[inferred\] |$/&\
| F-002 | 例の後の機能 | 例の理由 | [assumed] |/'
expect fail "段階の列と置いた節が違う"           's/| FR-003 | その後 |/| FR-003 | 最初に動かす最小の範囲 |/'
expect fail "段階の列が決まった値でない"         's/| FR-003 | その後 |/| FR-003 | 後で |/'
expect fail "理由が空"                           's/| 例の後の理由 |/| |/'
expect fail "区分がない"                         's/| 例の後の理由 | \[assumed\] |/| 例の後の理由 | |/'
expect fail "区分が 2 つ"                        's/例の後の理由/例 [inferred]/'
expect fail "番号の形が違う"                     's/^| F-002 | 例の後の機能 | 例の中身/| F-2 | 例の後の機能 | 例の中身/'
expect fail "番号が重なる"                       's/^| F-002 | 例の後の機能 | 例の中身/| F-001 | 例の後の機能 | 例の中身/'
expect fail "理由が土日祝の調整を前提にする"     's/例の後の理由/休日なら前倒し/'

[ "$fail" = 0 ] || exit 1
echo "test_check_features: ok"
