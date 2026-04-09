# Firebase セットアップ（flutterfire configure）

`firebase_options.dart` を生成し、実機・シミュレーターで Firebase を使うための手順です。

## 前提

- [Firebase Console](https://console.firebase.google.com/) でプロジェクトを作成済みであること
- 必要に応じて Android / iOS アプリを Firebase プロジェクトに登録済みであること  
  - **Android パッケージ名**: `jp.keygo.poigo`  
  - **iOS バンドル ID**: `jp.keygo.poigo`  
  変更後はコンソールにアプリを追加し、`google-services.json` / `GoogleService-Info.plist` を差し替えてください（手元ファイルの `package_name` / `BUNDLE_ID` が実 Firebase 設定と一致している必要があります）。

## 手順

### 1. FlutterFire CLI をグローバルに有効化

```bash
dart pub global activate flutterfire_cli
```

### 2. プロジェクトルートで configure を実行

**poigo** の Flutter プロジェクト（`pubspec.yaml` の `name: poigo` があるディレクトリ。フォルダ名は従来どおり `poikatsu_app` の場合があります）で:

```bash
cd /path/to/poikatsu_project/poikatsu_app
flutterfire configure
```

- 未ログインの場合はブラウザで Firebase にログインします
- 使用する Firebase プロジェクトを選択します
- 対象プラットフォーム（Android / iOS など）を選ぶと、自動で `lib/firebase_options.dart` が生成され、必要なネイティブ設定が追加されます

### 3. 生成されるファイル

- **lib/firebase_options.dart**  
  各プラットフォーム用の `FirebaseOptions`（apiKey, appId, projectId 等）が入ったファイル。既存の仮の内容は上書きされます。

### 4. 注意

- `firebase_options.dart` は Git にコミットして問題ありません（API キーはクライアント用で、制限は Firebase Console で行います）
- プロジェクトを変えた場合やアプリを追加した場合は、再度 `flutterfire configure` を実行してください
