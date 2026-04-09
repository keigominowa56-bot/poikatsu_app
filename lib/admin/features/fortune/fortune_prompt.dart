/// 占いコンテンツのAI生成時に使用するプロンプト指示文。
/// 管理画面のAI生成機能から参照する。
class FortunePrompt {
  FortunePrompt._();

  /// AI生成プロンプトの追加指示（各星座・各血液型に加え、365日分のバイオリズムを含める）
  static const String aiGenerationInstruction =
      '各星座・各血液型に加え、365日すべての人に当てはまる「今日の全体的な運気のバイオリズム」も生成してください。';
}
