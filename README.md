# poigo

Flutter パッケージ名は `poigo` です。リポジトリ上のフォルダ名（`poikatsu_app`）とは別です。

A new Flutter project.

## SKYFLAG（オファーウォール）

- テスト / 本番の切り替え: `--dart-define=SKYFLAG_ENV=stg` または `prod`（既定は `prod`）。
- メディアID（`_owp`）: `lib/services/skyflag_service.dart` の `mediaIdStg` / `mediaIdProd` を発行値に差し替えるか、`SKYFLAG_MEDIA_ID_STG` / `SKYFLAG_MEDIA_ID_PROD` / `SKYFLAG_MEDIA_ID` で dart-define 指定。
- 連携シート用のキックバックURL・IP一覧はリポジトリ直下の **`SKYFLAG_FORM.md`** を参照。

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
