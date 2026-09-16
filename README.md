# タスク管理アプリ

タスク・スケジュール・メモを1つのホーム画面で俯瞰でき、サイドバーで各画面に切り替え、
ホーム画面の各ペインは自由に並び替え・サイズ変更ができる Flutter アプリです。

## アーキテクチャ

- 状態管理: [flutter_riverpod](https://pub.dev/packages/flutter_riverpod)
- ローカル DB: [isar](https://pub.dev/packages/isar)（Task / Schedule / Memo の3コレクション、
  Memo ⇔ Task をリンクで連携）
- 画面遷移: [go_router](https://pub.dev/packages/go_router)（`ShellRoute` でサイドバーを共通化）
- ホーム画面のレイアウト:
  - スマホ幅: `ReorderableListView` で縦積みのペインをドラッグして並び替え
  - タブレット/PC幅: [multi_split_view](https://pub.dev/packages/multi_split_view) で
    境界線をドラッグしてサイズ変更
  - 並び順・サイズ比率は `shared_preferences` に保存され、次回起動時も復元される
- スケジュール画面: [table_calendar](https://pub.dev/packages/table_calendar)

ディレクトリ構成は機能（ドメイン）ごとに分割しています。

```
lib/
 ┣ core/        # テーマなど共通処理
 ┣ models/      # Isar コレクション (Task, Schedule, Memo)
 ┣ providers/   # Riverpod プロバイダー（DB接続、CRUD、レイアウト状態）
 ┣ views/
 ┃ ┣ layout/    # サイドバー(Drawer/NavigationRail)を含む共通レイアウト
 ┃ ┣ home/      # ホーム画面（分割・ドラッグ配置）
 ┃ ┣ tasks/     # タスク画面
 ┃ ┣ schedules/ # スケジュール画面
 ┃ ┗ memos/     # メモ画面
 ┗ main.dart
```

## セットアップ

このリポジトリには Dart/Flutter SDK が含まれる開発環境が無い状態で `lib/` 以下の
ソースコードのみ作成されているため、初回は以下の手順が必要です。

```bash
# 1. プラットフォーム（android/ios/web など）のひな形を生成
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
