import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/openai_config.dart';

/// DALL-E 3 生成結果
class OpenAiImageResult {
  const OpenAiImageResult._({this.imageUrl, this.errorMessage});

  /// 成功時の画像 URL
  final String? imageUrl;

  /// 失敗理由（ユーザー向け短文。デバッグ用に API メッセージを含む場合あり）
  final String? errorMessage;

  bool get isSuccess =>
      imageUrl != null && imageUrl!.isNotEmpty;

  factory OpenAiImageResult.success(String url) =>
      OpenAiImageResult._(imageUrl: url);

  factory OpenAiImageResult.failure(String message) =>
      OpenAiImageResult._(errorMessage: message);
}

/// DALL-E 3 でユーザー用キャラ画像を生成し、画像URLを返す。
/// APIキーは --dart-define=OPENAI_API_KEY=sk-... でビルドに埋め込むこと。
class OpenAiCharacterService {
  OpenAiCharacterService._();
  static final OpenAiCharacterService instance = OpenAiCharacterService._();

  static const String _baseUrl = 'https://api.openai.com/v1/images/generations';

  /// プロンプトに基づき1枚生成。失敗時は [OpenAiImageResult.errorMessage] を参照。
  Future<OpenAiImageResult> generateCharacterImage(String prompt) async {
    final apiKey = openAiApiKey;
    if (apiKey.isEmpty) {
      return OpenAiImageResult.failure(
        'APIキーがありません。\n'
        '① assets/config/openai.env の「OPENAI_API_KEY=」の右に sk-... を貼り付けて保存\n'
        '② ホットリロードでは反映されません。アプリを完全終了してから flutter run し直す\n'
        '③ または flutter run --dart-define=OPENAI_API_KEY=sk-...',
      );
    }

    final body = jsonEncode({
      'model': 'dall-e-3',
      'prompt': prompt,
      'n': 1,
      'size': '1024x1024',
      'quality': 'standard',
      'response_format': 'url',
    });

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: body,
      );

      if (response.statusCode == 200) {
        final map = jsonDecode(response.body) as Map<String, dynamic>?;
        final data = map?['data'] as List?;
        if (data == null || data.isEmpty) {
          return OpenAiImageResult.failure('応答に画像データがありません');
        }
        final first = data.first as Map<String, dynamic>?;
        final url = first?['url'] as String?;
        if (url == null || url.isEmpty) {
          return OpenAiImageResult.failure('画像URLを取得できませんでした');
        }
        return OpenAiImageResult.success(url);
      }

      final hint = _parseErrorBody(response.statusCode, response.body);
      if (kDebugMode) {
        debugPrint(
          '[OpenAI] images/generations HTTP ${response.statusCode}: $hint',
        );
      }
      return OpenAiImageResult.failure(hint);
    } on Exception catch (e, st) {
      if (kDebugMode) {
        debugPrint('[OpenAI] request failed: $e\n$st');
      }
      return OpenAiImageResult.failure(
        '通信に失敗しました（ネットワークやプロキシを確認してください）: $e',
      );
    }
  }

  static String _parseErrorBody(int status, String rawBody) {
    String apiMsg = '';
    try {
      final map = jsonDecode(rawBody) as Map<String, dynamic>?;
      final err = map?['error'];
      if (err is Map<String, dynamic>) {
        apiMsg = (err['message'] as String?)?.trim() ?? '';
      }
    } catch (_) {
      apiMsg = rawBody.length > 120 ? '${rawBody.substring(0, 120)}…' : rawBody;
    }

    switch (status) {
      case 401:
        return 'APIキーが無効です（期限切れ・取り消し・打ち間違い）。OpenAI のダッシュボードでキーを確認してください。'
            '${apiMsg.isNotEmpty ? ' ($apiMsg)' : ''}';
      case 403:
        return '利用が拒否されました。$apiMsg';
      case 429:
        return 'リクエストが多すぎます。しばらく待ってから再試行してください。$apiMsg';
      case 400:
        return 'リクエストが不正です（プロンプトの内容制限の可能性）。$apiMsg';
      case 500:
      case 502:
      case 503:
        return 'OpenAI 側で一時的なエラーです（$status）。しばらくしてから再試行してください。';
      default:
        return '生成に失敗しました（HTTP $status）。$apiMsg';
    }
  }
}
