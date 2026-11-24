#!/bin/sh
# このレポジトリの確認の入り口（SEC-056）。秘書の変更のジョブは、これが通らないとマージに進めない。
# ネットワークなしで動くこと。コードとテストが増えたら、ここから動かす。
set -eu
cd "$(dirname "$0")/.."

test -s .ai/brief.md
test -s LICENSE
for f in .ai/*.md .ai/adr/*.md .ai/reviews/*.md .ai/tickets/*.md; do
    [ -e "$f" ] || continue
    test -s "$f" || { echo "空の文書: $f" >&2; exit 1; }
done
# チケットの 1 行目は題、2 行目は状態
for f in .ai/tickets/*.md; do
    [ -e "$f" ] || continue
    head -n 1 "$f" | grep -q '^# [A-Z][A-Z]*-[0-9][0-9][0-9] ' || { echo "チケットの 1 行目が題でない: $f" >&2; exit 1; }
    sed -n 2p "$f" | grep -Eq '^状態: (open|done)$' || { echo "チケットの 2 行目が状態でない: $f" >&2; exit 1; }
done
sh scripts/test_check_requirements.sh
sh scripts/check_requirements.sh
sh scripts/test_check_roadmap.sh
sh scripts/check_roadmap.sh
echo "check: ok"
