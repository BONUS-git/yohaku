#!/bin/sh
# 開発ロードマップ（.ai/roadmap.md）・持ち越し（.ai/gaps.md）・地図（.ai/INDEX.md）を確かめる（YOH-007）。
# 使い方: sh scripts/check_roadmap.sh [.ai のディレクトリ]（既定は .ai）。POSIX sh と awk だけで動く。
# - M の行は「- Mn: FR-001, FR-010〜FR-012」か「- Mn: なし」。FR-NNN は requirements.md のどれもが
#   ちょうど 1 つの M に出る。M1 の集合は mvp.md の「M1 に入れる FR」と同じ
# - roadmap の M ごとに「## Mn」の節と、その下に「### 目的」「### 依存」「### 受け入れ条件」がある
# - gaps の行は「| G-NNN | 仕分け | 向かう M | 理由 | 出どころ |」。仕分けは 今決める・暫定・後回し、向かう M は roadmap にある
# - INDEX は dir の下の .md をすべて `.ai/<パス>` で載せ、載せた `.ai/<パス>` はすべてある
set -eu
cd "$(dirname "$0")/.."
dir=${1:-.ai}
for f in roadmap.md mvp.md requirements.md gaps.md INDEX.md; do
    [ -s "$dir/$f" ] || { echo "roadmap: 文書がない: $dir/$f" >&2; exit 1; }
done

awk '
function trim(s) { gsub(/^[ \t]+|[ \t]+$/, "", s); return s }
function err(m) { print "roadmap: " FILENAME ":" FNR ": " m > "/dev/stderr"; bad = 1 }
function num(id) { return substr(id, 4) + 0 }
function fmt(n) { return sprintf("FR-%03d", n) }
FILENAME ~ /requirements\.md$/ && /^\|[ \t]*FR-[0-9][0-9][0-9][ \t]*\|/ {
    split($0, c, "|"); all[trim(c[2])] = 1; next
}
FILENAME ~ /mvp\.md$/ && /^## / { mvpsec = trim(substr($0, 4)); next }
FILENAME ~ /mvp\.md$/ && mvpsec == "M1 に入れる FR" && /^\|[ \t]*FR-[0-9][0-9][0-9][ \t]*\|/ {
    split($0, c, "|"); mvp1[trim(c[2])] = 1; next
}
FILENAME ~ /roadmap\.md$/ && /^- M[0-9]+:/ {
    m = substr($0, 3); p = index(m, ":"); name = substr(m, 1, p - 1); rest = trim(substr(m, p + 1))
    if (name in ms) err("M の行が重なる: " name)
    ms[name] = 1; morder[++nm] = name
    if (rest == "なし") next
    if (rest == "") { err(name " の FR が空（ないときは「なし」）"); next }
    k = split(rest, tok, ",")
    for (i = 1; i <= k; i++) {
        t = trim(tok[i])
        if (t ~ /^FR-[0-9][0-9][0-9]$/) { a = num(t); b = a }
        else if (t ~ /^FR-[0-9][0-9][0-9]〜FR-[0-9][0-9][0-9]$/) {
            split(t, r, "〜"); a = num(r[1]); b = num(r[2])
            if (a >= b) { err(name " の範囲が逆か 1 件: " t); continue }
        } else { err(name " の FR の書き方が違う: " t); continue }
        for (x = a; x <= b; x++) {
            id = fmt(x)
            if (id in owner) err(id " が 2 つの M に出る: " owner[id] "・" name)
            else owner[id] = name
        }
    }
    next
}
FILENAME ~ /roadmap\.md$/ && /^## M[0-9]+([ \t]|$)/ {
    cur = $2; sec[cur] = 1; next
}
FILENAME ~ /roadmap\.md$/ && /^## / { cur = ""; next }
FILENAME ~ /roadmap\.md$/ && /^### / && cur != "" { sub3[cur, trim(substr($0, 5))] = 1; next }
FILENAME ~ /gaps\.md$/ && /^\|[ \t]*G-/ {
    n = split($0, c, "|")
    id = trim(c[2])
    if (id !~ /^G-[0-9][0-9][0-9]$/) { err("番号の形が違う: " id); next }
    if (id in gids) err("番号が重なる: " id)
    gids[id] = 1
    if (n != 7) { err(id " の列が 5 つでない（ID・仕分け・向かう M・理由・出どころ）"); next }
    cls = trim(c[3]); gm = trim(c[4])
    if (cls != "今決める" && cls != "暫定" && cls != "後回し") err(id " の仕分けが 今決める・暫定・後回し のどれでもない: " cls)
    if (gm == "") err(id " の向かう M が空")
    else gaps_m[id] = gm
    if (trim(c[5]) == "") err(id " の理由が空")
    if (trim(c[6]) == "") err(id " の出どころが空")
    next
}
END {
    FILENAME = "roadmap.md"; FNR = 0
    if (nm == 0) err("M の行（- Mn: ...）がない")
    if (!("M1" in ms)) err("M1 の行がない")
    for (id in all) if (!(id in owner)) err(id " がどの M にも出ない")
    for (id in owner) if (!(id in all)) err(id " は requirements.md にない")
    for (id in mvp1) if (!(id in owner) || owner[id] != "M1") err(id " は mvp.md の M1 にあるのに roadmap の M1 にない")
    for (id in owner) if (owner[id] == "M1" && !(id in mvp1)) err(id " は roadmap の M1 にあるのに mvp.md の M1 にない")
    split("目的|依存|受け入れ条件", need, "|")
    for (i = 1; i <= nm; i++) {
        name = morder[i]
        if (!(name in sec)) { err(name " の節（## " name "）がない"); continue }
        for (j = 1; j <= 3; j++) if (!((name, need[j]) in sub3)) err(name " に「### " need[j] "」の節がない")
    }
    FILENAME = "gaps.md"
    for (id in gaps_m) if (!(gaps_m[id] in ms)) err(id " の向かう M が roadmap にない: " gaps_m[id])
    exit bad
}
' "$dir/requirements.md" "$dir/mvp.md" "$dir/roadmap.md" "$dir/gaps.md"

# INDEX: dir の下の .md がすべて載っていて、載せたパスがすべてある
bad=0
listed=$(grep -o '`\.ai/[^`]*`' "$dir/INDEX.md" | tr -d '`' | sort -u)
for p in $listed; do
    [ -e "$dir/${p#.ai/}" ] || { echo "roadmap: $dir/INDEX.md: 載せたパスがない: $p" >&2; bad=1; }
done
for f in $(cd "$dir" && find . -name '*.md' | sed 's|^\./||' | sort); do
    printf '%s\n' "$listed" | grep -qxF ".ai/$f" || { echo "roadmap: $dir/INDEX.md: 載っていない: .ai/$f" >&2; bad=1; }
done
exit "$bad"
