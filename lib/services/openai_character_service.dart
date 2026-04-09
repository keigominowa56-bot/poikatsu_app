import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/openai_config.dart';

/// DALL-E 3 でユーザー用キャラ画像を生成し、画像URLを返す。
/// APIキーは --dart-define=OPENAI_API_KEY=sk-... で渡すこと。
class OpenAiCharacterService {
  OpenAiCharacterService._();
  static final OpenAiCharacterService instance = OpenAiCharacterService._();

  static const String _baseUrl = 'https://api.openai.com/v1/images/generations';

  /// プロンプトに基づき1枚生成し、URLを返す。失敗時は null。
  Future<String?> generateCharacterImage(String prompt) async {
    final apiKey = openAiApiKey;
    if (apiKey.isEmpty) return null;

    final body = jsonEncode({
      'model': 'dall-e-3',
      'prompt': prompt,
      'n': 1,
      'size': '1024x1024',
      'quality': 'standard',
      'response_format': 'url',
    });

    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: body,
    );

    if (response.statusCode != 200) return null;
    final map = jsonDecode(response.body) as Map<String, dynamic>?;
    final data = map?['data'] as List?;
    if (data == null || data.isEmpty) return null;
    final first = data.first as Map<String, dynamic>?;
    return first?['url'] as String?;
  }
}
