# ポイ活 管理画面（Admin Frontend）

同一 Firebase プロジェクトを管理するための Web 用管理画面です。

## 構成（おすすめ）

- **同一リポジトリ内**で `lib/admin/` に管理画面を配置しています。
- モバイルアプリは `lib/main.dart`、管理画面は `lib/admin/main_admin.dart` がエントリポイントです。
- 共通の `firebase_options.dart` を利用するため、**Web 用の Firebase 設定**は `flutterfire configure` で Web を有効にすると自動で含まれます。

## 起動方法

```bash
cd poikatsu_app
# ↑ リポジトリ上のフォルダ名。pubspec のパッケージ名は `poigo` です。
flutter run -d chrome -t lib/admin/main_admin.dart
```

ビルドして静的ホスティングする場合:

```bash
flutter build web -t lib/admin/main_admin.dart
# 出力: build/web/
```

## Firebase Web 設定

- `flutterfire configure` 実行時に **Web** を選択していると、`lib/firebase_options.dart` に `DefaultFirebaseOptions.web` が含まれます。
- Web で実行すると `Firebase.apps.isEmpty` のあと `DefaultFirebaseOptions.currentPlatform` が `web` を返すため、そのまま利用できます。
- 未設定の場合はプロジェクトルートで再度 `flutterfire configure` を実行し、Web を有効にしてください。

## 機能

- **ユーザー一覧**: Firestore の `users` コレクションを一覧表示（totalPoints・今日の歩数）
- **ポイント操作**: 各ユーザーに +10P / -10P のテスト用ボタン

## 拡張

- `lib/admin/features/` に、ゴミ出し・占い・ゲーム・レシートなどの CRUD 用モジュールを追加する想定です。
- 詳細は `lib/admin/features/README.md` を参照してください。
