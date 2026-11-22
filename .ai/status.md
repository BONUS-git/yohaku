# 状態

段階: 設計（機能一覧と優先順位まで）。

## 実装済み

- プロダクト要求仕様書（`requirements.md`。FR-001〜FR-038、NFR-001〜NFR-018）— PRO-001
- 受け入れ確認の検査（`scripts/check_requirements.sh`。`sh scripts/check.sh` から動く）— PRO-001
- 機能一覧と優先順位（`features.md`。F-001〜F-018 を「最初に動かす最小の範囲」と「その後」に分ける）— PRO-002
- 受け入れ確認の検査（`scripts/check_features.sh`。`sh scripts/check.sh` から動く）— PRO-002

## 未実装

- `architecture.md`・`db.md`・`api.md`・`async.md`・`security.md`・`roadmap.md`・`environment.md`
- ADR（技術選定などの設計判断はまだない）
- アプリのコード

## 暫定対応

- FR-038（金額が空欄のエントリの表示と合計の扱い）: OQ-001 の答えを待つ暫定。答えで FR-002・FR-028・FR-036・FR-038 が変わりうる。
  `features.md` の F-003・F-006・F-007・F-008・F-018 の中身も変わりうる（段階は変わらない）
