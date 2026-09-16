# タスク管理アプリ

タスク・スケジュール・メモなどを1つのホーム画面で俯瞰でき、サイドバーで各画面に切り替え、
ホーム画面はIDEのパネルのように自由に追加・削除・左右上下分割・リサイズできる Flutter アプリです。

## アーキテクチャ

- 状態管理: [flutter_riverpod](https://pub.dev/packages/flutter_riverpod)
- ローカル DB: [isar](https://pub.dev/packages/isar)（Task / Schedule / Memo の3コレクション、
  Memo ⇔ Task をリンクで連携。各コレクションは `tags`（タグ）を持つ）
- 画面遷移: [go_router](https://pub.dev/packages/go_router)（`ShellRoute` でサイドバーを共通化）
- 通知: [flutter_local_notifications](https://pub.dev/packages/flutter_local_notifications) +
  [timezone](https://pub.dev/packages/timezone)（タスクの期限・予定の開始時刻をリマインド）
- ホーム画面のレイアウト（`lib/providers/layout_provider.dart` の2分木 `LayoutNode` で管理）:
  - PC/タブレット幅: 自作の `TilingLayout`（`lib/views/home/widgets/tiling_layout.dart`）で、
    各ウィジェットを何度でも左右・上下に分割でき、ドラッグして別の位置へ移動（端に落とすと
    分割、中央に落とすと入れ替え）、境界線をドラッグしてサイズ変更できる
  - スマホ幅: ツリーを上から順に並べた縦積みリスト（追加・削除は可能、並び替えは非対応）
  - 配置は `shared_preferences` に保存され、次回起動時も復元される
  - ホーム画面に置けるウィジェットの種類は `lib/core/widget_catalog.dart` で管理:
    タスク/スケジュール/メモに加えて、ポモドーロタイマー・進捗ダッシュボード・
    クイックメモ（付箋）・締切カウントダウンを追加可能
- デザイン: Material 3 ベースのモダン＆ミニマルなテーマ（`lib/core/theme.dart`）。
  ウィジェット種別ごとのアクセントカラー・タグごとの色分けは `lib/core/pane_style.dart`
- スケジュール画面: [table_calendar](https://pub.dev/packages/table_calendar)
- 検索・タグ絞り込み: 各一覧画面共通の `SearchFilterBar`（`lib/widgets/search_filter_bar.dart`）

ディレクトリ構成は機能（ドメイン）ごとに分割しています。

```
lib/
 ┣ core/        # テーマ・ウィジェットカタログ・見た目定義など共通処理
 ┣ models/      # Isar コレクション (Task, Schedule, Memo)
 ┣ providers/   # Riverpod プロバイダー（DB接続、CRUD、レイアウト状態、通知、タイマー等）
 ┣ widgets/     # 画面共通ウィジェット（タグ編集・検索バー・通知選択）
 ┣ views/
 ┃ ┣ layout/    # サイドバー(Drawer/NavigationRail)を含む共通レイアウト
 ┃ ┣ home/      # ホーム画面（タイリングレイアウト・各種ウィジェット）
 ┃ ┣ tasks/     # タスク画面
 ┃ ┣ schedules/ # スケジュール画面
 ┃ ┗ memos/     # メモ画面
 ┗ main.dart
```

## セットアップ

```bash
# 1. プラットフォーム（android/ios/windows など）のひな形を生成（初回のみ）
flutter create .

# 2. 依存パッケージを取得
flutter pub get

# 3. Isar のコード生成 (models/*.g.dart を生成)
dart run build_runner build --delete-conflicting-outputs

# 4. 実行
flutter run
```

`*.g.dart`（Isar が生成するコレクション定義）は `.gitignore` していないため、
一度生成すればリポジトリにコミットして構いません。プラットフォームフォルダ
(`android/` `ios/` など)は `flutter create .` で再生成できるため `.gitignore` 済みです。

> **モデルに `tags` / 通知設定フィールドを追加した際、既存の `lib/models/*.g.dart` は
> 削除済みです。** `flutter pub get` の後、必ず手順3の `build_runner build` を
> 実行し直してください（実行しないとコンパイルエラーになります）。

## 実行ターゲットについて（Web は非対応）

`flutter run` でデバイス選択を聞かれたら **Chrome / Edge（Web）ではなく
Windows（デスクトップ）や Android/iOS 実機・エミュレータを選んでください**。

Isar が生成するコレクションのID（フィールドのハッシュ値）は64bit整数ですが、
Web（dart2js/dartdevc）でコンパイルすると JavaScript の数値は53bitまでしか
正確に表現できないため、`The integer literal ... can't be represented exactly
in JavaScript` というコンパイルエラーになります。これは既知の Isar v3 の制約で、
アプリのコード側では回避できません。

## 通知（リマインダー）について

タスクの期限・予定の開始時刻に対して「時刻ちょうど/10分前/1時間前/1日前」の
リマインダー通知を設定できます。

- **Android / iOS / macOS**: 実行時に通知の権限リクエストが表示されます。許可すれば
  そのまま動作します（追加のマニフェスト編集は不要です）。
- **Windows デスクトップ**: `flutter_local_notifications` が現時点で Windows に
  対応していないため、通知機能は自動的に無効化されます（アプリ自体はエラーなく
  動作し、タスク/予定の保存やタグ・検索などの機能はすべて使えます）。
  Windows でも通知を出したい場合は `local_notifier` など別パッケージへの
  差し替えが別途必要です。

## ホーム画面の自由配置について

- **追加**: 右下の「追加」ボタンからウィジェット一覧を開いて選ぶと、ホーム画面の下に
  新しいウィジェットが追加されます。
- **削除**: 各ウィジェット右上の「⋮」メニューから「削除」を選びます。
- **分割**: 各ウィジェットの「⋮」メニューの「右に分割」「下に分割」から、追加したい
  ウィジェットを選ぶと、その場で左右/上下に分割されます（IDEのパネル分割と同じ操作感）。
- **移動**: ヘッダー右側のドラッグアイコンをつかんで別のウィジェットの上にドラッグすると、
  ドロップした位置（端 = 分割して挿入、中央 = 入れ替え）に応じて配置が変わります。
- **リサイズ**: 分割の境界線をドラッグすると比率を変更できます。
- スマホ幅では追加・削除のみ対応し、並び順はPC/タブレット幅で組んだツリー構造の順序を
  そのまま縦に並べたものになります（同じデータを共有しているため、PC側の配置を変えると
  スマホ側の表示順にも反映されます）。
- 配置はアプリを再起動しても保持されます（`shared_preferences` に保存）。

## 今後の拡張予定（未実装）

「いつか他ユーザーと共有できるようにしたい」という要望がありますが、現状データは
完全にローカル（Isar）に閉じており、共有・同期機能は未実装です。将来的に対応する場合は
Firebase / Supabase などのバックエンド導入と、DBアクセスを Repository パターンで
抽象化する設計変更が必要になります（今回のリリースでは着手していません）。
