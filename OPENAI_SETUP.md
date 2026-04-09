# OpenAI API キー設定（Lv.4+ キャラ生成）

APIキーは**コードやリポジトリに含めず**、実行時に渡してください。

## 方法: --dart-define

```bash
flutter run --dart-define=OPENAI_API_KEY=sk-your-key-here
flutter build apk --dart-define=OPENAI_API_KEY=sk-your-key-here
```

## VS Code の launch.json

`.vscode/launch.json` に Flutter の設定を追加する場合:

```json
{
  "configurations": [
    {
      "name": "Flutter (OpenAI付き)",
      "request": "launch",
      "type": "dart",
      "args": [
        "--dart-define=OPENAI_API_KEY=sk-your-key-here"
      ]
    }
  ]
}
```

※ `sk-your-key-here` を実際のキーに置き換えてください。**このファイルを Git にコミットする場合はキーを削除し、環境に応じて書き換えてください。**

## 参照

- 読み込み: `lib/config/openai_config.dart` の `openAiApiKey`
- 利用: `lib/services/openai_character_service.dart`（DALL-E 3）
