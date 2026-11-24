#!/bin/sh
# プロダクト要求仕様書（.ai/requirements.md）の受け入れ確認（YOH-001）を確かめる。
# 使い方: sh scripts/check_requirements.sh [文書のパス]（既定は .ai/requirements.md）
# 要件は「| FR-NNN | 要求 | 区分 | 根拠 |」の表の行で書く。POSIX sh と awk だけで動く。
set -eu
cd "$(dirname "$0")/.."
doc=${1:-.ai/requirements.md}
[ -s "$doc" ] || { echo "requirements: 文書がない: $doc" >&2; exit 1; }

awk -v doc="$doc" '
function trim(s) { gsub(/^[ \t]+|[ \t]+$/, "", s); return s }
function err(m) { print "requirements: " doc ":" NR ": " m > "/dev/stderr"; bad = 1 }
function count(s, re,   t) { t = s; return gsub(re, "", t) }
/^## / {
    sec = trim(substr($0, 4))
    seen[sec] = 1
    next
}
/^\|[ \t]*N?FR-/ {
    n = split($0, c, "|")
    id = trim(c[2]); req = trim(c[3]); tag = trim(c[4]); src = trim(c[5])
    if (id ~ /^FR-[0-9][0-9][0-9]$/) {
        kind = "FR"; nfr++
        if (sec != "機能要件") err(id " が機能要件の節の外にある")
    } else if (id ~ /^NFR-[0-9][0-9][0-9]$/) {
        kind = "NFR"; nnfr++
        if (sec != "非機能要件") err(id " が非機能要件の節の外にある")
    } else {
        err("番号の形が違う: " id); next
    }
    if (id in ids) err("番号が重なる: " id)
    ids[id] = 1
    if (n < 6) err(id " の列が足りない（ID・要求・区分・根拠）")
    if (req == "") err(id " の要求が空")
    tags = count($0, "\\[explicit\\]") + count($0, "\\[inferred\\]") + count($0, "\\[assumed\\]")
    if (tags != 1) err(id " の区分がちょうど 1 つでない（" tags " 個）")
    else if (tag != "[explicit]" && tag != "[inferred]" && tag != "[assumed]") err(id " の区分の列に区分がない")
    if (tag == "[explicit]" && src !~ /brief\.md [0-9]+(\.[0-9]+)? [^ ]/) err(id " は [explicit] なのに brief.md の節（番号と名前）がない")
    if ($0 ~ /前倒し|翌営業日/) err(id " が未決定の土日祝の調整を前提にしている")
    next
}
sec == "未決定事項" && /^\|/ {
    split($0, c, "|"); k = trim(c[2]); v = trim(c[3])
    # 扱いは「未決定」で始めるか、「決定。」か「入れない。」で始めて決めた先（FR・ADR・文書のパス）を指す
    if (v ~ /^未決定/ || (v ~ /^(決定|入れない)。/ && v ~ /FR-[0-9][0-9][0-9]|ADR|`[^`]+\.md`/)) state[k] = "ok"
    else if (!(k in state)) state[k] = "bad"
}
END {
    split("目的と利用者|機能要件|非機能要件|範囲外|未決定事項", need, "|")
    for (i = 1; i <= 5; i++) if (!(need[i] in seen)) { print "requirements: " doc ": 節がない: " need[i] > "/dev/stderr"; bad = 1 }
    if (nfr == 0) { print "requirements: " doc ": FR の要件がない" > "/dev/stderr"; bad = 1 }
    if (nnfr == 0) { print "requirements: " doc ": NFR の要件がない" > "/dev/stderr"; bad = 1 }
    split("支払い日が土日祝の場合の調整|技術スタック|アプリ名・ブランド|無料 / 有料の境界と料金|データ移行（機種変更時）|開発のロードマップ", item, "|")
    for (i = 1; i <= 6; i++) {
        if (!(item[i] in state)) { print "requirements: " doc ": 未決定事項に「" item[i] "」の行がない" > "/dev/stderr"; bad = 1 }
        else if (state[item[i]] != "ok") { print "requirements: " doc ": 未決定事項の「" item[i] "」が「未決定」でも、決めた先（FR・ADR・文書）を指す「決定。」「入れない。」でもない" > "/dev/stderr"; bad = 1 }
    }
    exit bad
}
' "$doc"
