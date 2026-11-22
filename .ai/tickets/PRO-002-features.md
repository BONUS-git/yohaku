# PRO-002 機能一覧と優先順位を書く
状態: done

## 目的

目標の条件 2（`.ai/features.md` に機能一覧と優先順位）を満たす。`.ai/requirements.md` の機能要件を機能に
まとめ、構想の MVP（`brief.md` 6 に挙げたもの以外のすべて）の中を、最初に動かす最小の範囲とその後の 2 つの段階に
分けて、作る順を決められる状態にする。どちらの段階の機能も MVP に入る。

## 範囲

- `.ai/features.md` を新しく書く（機能一覧・最初に動かす最小の範囲・その後・どの段階にも置かないもの）
- それと食い違う既存の文書（`.ai/requirements.md`・`.ai/open-questions.md`・`.ai/status.md`・`.ai/README.md`）を今の状態に直す
- 受け入れ確認を自動で確かめる検査を `sh scripts/check.sh` から動かす

範囲外: 設計・技術選定・実装。段階ごとの時期（`brief.md` 7 の「開発のロードマップ」は未決定）。`.ai/brief.md` の書き換え。

## 受け入れ確認

- `.ai/features.md` に機能一覧の表があり、各行に FR 番号が書かれている
- FR-001〜FR-038 のどれもが `.ai/features.md` に一度以上出てくる
- `.ai/features.md` に「最初に動かす最小の範囲」と「その後」の節があり、各機能がどちらかに置かれ理由が書かれている
- `sh scripts/check.sh` が通る
- チケットの 2 行目が `状態: done`
