/// OpenAI API キー設定（コードにキーを書かない）
///
/// 設定方法: 実行時に --dart-define で渡す
///   flutter run --dart-define=OPENAI_API_KEY=sk-your-key
///   flutter build apk --dart-define=OPENAI_API_KEY=sk-your-key
///
/// VS Code の launch.json 例:
///   "args": ["--dart-define=OPENAI_API_KEY=sk-..."]
String get openAiApiKey =>
    const String.fromEnvironment('OPENAI_API_KEY', defaultValue: '');
