import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

/// デジコ（digi-co）ギフト発行API。
///
/// **重要**: デジコの API 用パスワード等の機密情報はサーバー側にのみ保持し、
/// アプリは自社バックエンド（FastAPI）のエンドポイントを呼び出します。
class DigicoGiftResult {
  const DigicoGiftResult({
    required this.giftUrl,
    required this.managementNo,
    this.expireDate,
    this.tradeId,
    this.rawResponse,
  });

  final String giftUrl;
  final String managementNo;
  final String? expireDate;
  final String? tradeId;
  final Map<String, dynamic>? rawResponse;
}

class DigicoService {
  DigicoService._();
  static final DigicoService instance = DigicoService._();

  /// 自社バックエンドのベースURL。
  /// - 本番: `https://poigo.keygo.jp`
  /// - ローカル: `http://127.0.0.1:8080` 等
  static const String backendBaseUrl =
      String.fromEnvironment('BACKEND_BASE_URL', defaultValue: 'https://poigo.keygo.jp');

  /// 自社APIに交換リクエスト。
  /// [chips] は **消費チップ数**（100チップ=1円）。
  Future<DigicoGiftResult> exchange({
    required int chips,
    required String categoryId,
  }) async {
    if (chips <= 0) {
      throw ArgumentError('chips must be greater than zero');
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('not signed in');
    }

    final idToken = await user.getIdToken();

    final payload = {
      'chips': chips,
      'categoryId': categoryId,
    };

    final uri = Uri.parse('$backendBaseUrl/api/digico/exchange');
    final response = await http.post(uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode(payload));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('exchange failed: ${response.statusCode} ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final giftUrl = (data['giftUrl'] ?? '').toString();
    final managementNo = (data['managementNo'] ?? '').toString();
    final expireDate = (data['expireDate'] ?? '').toString();
    final tradeId = (data['tradeId'] ?? '').toString();
    if (giftUrl.isEmpty || managementNo.isEmpty) {
      throw Exception('exchange response missing required fields');
    }
    return DigicoGiftResult(
      giftUrl: giftUrl,
      managementNo: managementNo,
      expireDate: expireDate.isEmpty ? null : expireDate,
      tradeId: tradeId.isEmpty ? null : tradeId,
      rawResponse: data,
    );
  }
}

