#!/bin/sh
# 機能一覧と優先順位（.ai/features.md）の受け入れ確認（PRO-002）を確かめる。
# 使い方: sh scripts/check_features.sh [features のパス] [requirements のパス]
#         （既定は .ai/features.md と .ai/requirements.md）
# 機能一覧は「| F-NNN | 機能 | 中身 | 機能要件 | 段階 |」、段階の節は「| F-NNN | 機能 | 理由 | 区分 |」の
# 表の行で書く。FR の番号は requirements の「機能要件」の節から集める。POSIX sh と awk だけで動く。
set -eu
cd "$(dirname "$0")/.."
doc=${1:-.ai/features.md}
req=${2:-.ai/requirements.md}
[ -s "$doc" ] || { echo "features: 文書がない: $doc" >&2; exit 1; }
[ -s "$req" ] || { echo "features: 要求仕様書がない: $req" >&2; exit 1; }

awk -v doc="$doc" '
function trim(s) { gsub(/^[ \t]+|[ \t]+$/, "", s); return s }
function err(m) { print "features: " doc ":" FNR ": " m > "/dev/stderr"; bad = 1 }
function fin(m) { print "features: " doc ": " m > "/dev/stderr"; bad = 1 }
function count(s, re,   t) { t = s; return gsub(re, "", t) }
# 1 つ目のファイル（requirements）: 機能要件の節の FR 番号を集める
FNR == NR {
    if ($0 ~ /^## /) { rsec = trim(substr($0, 4)); next }
    if (rsec == "機能要件" && $0 ~ /^\|[ \t]*FR-[0-9][0-9][0-9][ \t]*\|/) {
        split($0, c, "|"); id = trim(c[2])
        if (!(id in fr)) { fr[id] = 1; frs[++nfr] = id }
    }
    next
}
# 2 つ目のファイル（features）
/^## / { sec = trim(substr($0, 4)); seen[sec] = 1; next }
/^\|[ \t]*F-/ {
    n = split($0, c, "|")
    id = trim(c[2])
    if ($0 ~ /前倒し|翌営業日/) err(id " が未決定の土日祝の調整を前提にしている")
    if (sec == "機能一覧") {
        if (id !~ /^F-[0-9][0-9][0-9]$/) { err("番号の形が違う: " id); next }
        if (id in stage) err("番号が重なる: " id)
        if (n < 7) err(id " の列が足りない（ID・機能・中身・機能要件・段階）")
        cols = trim(c[5]); st = trim(c[6])
        stage[id] = st; order[++nf] = id
        k = 0; s = cols
        while (match(s, /FR-[0-9][0-9][0-9]/)) {
            f = substr(s, RSTART, RLENGTH); s = substr(s, RSTART + RLENGTH); k++
            if (!(f in fr)) err(id " の " f " が要求仕様書の機能要件にない")
            used[f] = 1
        }
        if (k == 0) err(id " の機能要件の列に FR 番号がない")
        if (st != "最初に動かす最小の範囲" && st != "その後") err(id " の段階が「最初に動かす最小の範囲」か「その後」でない: " st)
    } else if (sec == "最初に動かす最小の範囲" || sec == "その後") {
        if (id !~ /^F-[0-9][0-9][0-9]$/) { err("番号の形が違う: " id); next }
        if (n < 6) err(id " の列が足りない（ID・機能・理由・区分）")
        reason = trim(c[4]); tag = trim(c[5])
        placed[id] = placed[id] (placed[id] == "" ? "" : "・") sec
        nplaced[id]++; nstage[sec]++
        if (reason == "") err(id " の理由が空")
        tags = count($0, "\\[explicit\\]") + count($0, "\\[inferred\\]") + count($0, "\\[assumed\\]")
        if (tags != 1) err(id " の区分がちょうど 1 つでない（" tags " 個）")
        else if (tag != "[explicit]" && tag != "[inferred]" && tag != "[assumed]") err(id " の区分の列に区分がない")
    }
    next
}
END {
    split("機能一覧|最初に動かす最小の範囲|その後", need, "|")
    for (i = 1; i <= 3; i++) if (!(need[i] in seen)) fin("節がない: " need[i])
    if (nfr == 0) fin("要求仕様書に FR の要件がない")
    if (nf == 0) fin("機能一覧に機能がない")
    for (id in placed) if (!(id in stage)) fin(id " は段階の節にあるが機能一覧にない")
    for (i = 1; i <= nf; i++) {
        id = order[i]
        if (nplaced[id] == 0) fin(id " がどの段階にも置かれていない")
        else if (nplaced[id] > 1) fin(id " が 2 か所以上に置かれている（" placed[id] "）")
        else if (placed[id] != stage[id]) fin(id " の段階の列（" stage[id] "）と置いた節（" placed[id] "）が違う")
    }
    for (i = 1; i <= nfr; i++) if (!(frs[i] in used)) fin(frs[i] " がどの機能にも出てこない")
    if (nstage["最初に動かす最小の範囲"] == 0) fin("最初に動かす最小の範囲に機能がない")
    if (nstage["その後"] == 0) fin("その後に機能がない")
    exit bad
}
' "$req" "$doc"
