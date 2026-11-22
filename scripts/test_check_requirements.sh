#!/bin/sh
# check_requirements.sh のテスト。正しい文書が通り、受け入れ確認に反する文書が落ちることを見る。
set -eu
cd "$(dirname "$0")/.."
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT INT TERM

# 正しい最小の文書を作る。引数の sed の式で 1 か所だけ壊した版を作る。
make() {
    cat > "$tmp/base.md" <<'EOF'
# 要求仕様書（テスト用）

## 目的と利用者

テスト用の文書。

## 機能要件

### まとまり

| ID | 要求 | 区分 | 根拠 |
|----|------|------|------|
| FR-001 | 例の要求 | [explicit] | brief.md 4.1 お金の記録（エントリ） |
| FR-002 | 例の読み取った要求 | [inferred] | brief.md 4.2 から |

## 非機能要件

| ID | 要求 | 区分 | 根拠 |
|----|------|------|------|
| NFR-001 | 例の非機能要求 | [assumed] | 既定 |

## 範囲外

| 項目 | 扱い |
|------|------|
| 通知 | 入れない |

## 未決定事項

| 項目 | 扱い |
|------|------|
| 支払い日が土日祝の場合の調整 | 未決定 |
| 技術スタック | 未決定 |
| アプリ名・ブランド | 未決定 |
| 無料 / 有料の境界と料金 | 未決定 |
| データ移行（機種変更時） | 未決定 |
| 開発のロードマップ | 未決定 |
EOF
    sed "$1" "$tmp/base.md" > "$tmp/case.md"
}

fail=0
expect() { # expect <pass|fail> <説明> <sed の式>
    make "$3"
    if sh scripts/check_requirements.sh "$tmp/case.md" 2> "$tmp/err"; then got=pass; else got=fail; fi
    if [ "$got" = "$1" ]; then :; else
        echo "test_check_requirements: NG: $2（期待 $1、結果 $got）" >&2
        cat "$tmp/err" >&2
        fail=1
    fi
}

expect pass "正しい文書"                 's/^$//'
expect fail "非機能要件の節がない"       's/^## 非機能要件$/## 品質/'
expect fail "FR が非機能要件の節にある"  's/^| NFR-001 /| FR-003 /'
expect fail "番号が重なる"               's/^| FR-002 /| FR-001 /'
expect fail "区分がない"                 's/| \[inferred\] |/| |/'
expect fail "区分が 2 つ"                's/例の読み取った要求/例 [assumed]/'
expect fail "explicit に節の名前がない"  's/brief.md 4.1 お金の記録（エントリ）/構想/'
expect fail "未決定事項の項目が未決定でない" 's/^| アプリ名・ブランド | 未決定 |/| アプリ名・ブランド | 例の名前 |/'
expect fail "土日祝の調整を前提にする"   's/例の要求/休日なら前倒し/'
expect fail "番号の形が違う"             's/^| FR-002 /| FR-2 /'

[ "$fail" = 0 ] || exit 1
echo "test_check_requirements: ok"
