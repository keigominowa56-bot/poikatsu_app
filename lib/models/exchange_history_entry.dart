import 'package:cloud_firestore/cloud_firestore.dart';

/// `users/{uid}/exchange_history` の1件
class ExchangeHistoryEntry {
  const ExchangeHistoryEntry({
    required this.id,
    this.categoryId,
    required this.amount,
    this.yen,
    required this.managementNo,
    required this.giftUrl,
    this.provider,
    this.createdAt,
  });

  final String id;
  final String? categoryId;
  /// 消費チップ数
  final int amount;
  /// 交換額（円）。旧データには無い場合あり。
  final int? yen;
  final String managementNo;
  final String giftUrl;
  final String? provider;
  final DateTime? createdAt;

  static ExchangeHistoryEntry fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    DateTime? at;
    final raw = data['createdAt'];
    if (raw is Timestamp) {
      at = raw.toDate();
    } else if (raw != null) {
      at = DateTime.tryParse(raw.toString());
    }
    return ExchangeHistoryEntry(
      id: doc.id,
      categoryId: data['categoryId'] as String?,
      amount: (data['amount'] as num?)?.toInt() ?? 0,
      yen: (data['yen'] as num?)?.toInt(),
      managementNo: (data['managementNo'] ?? '').toString(),
      giftUrl: (data['giftUrl'] ?? '').toString(),
      provider: data['provider'] as String?,
      createdAt: at,
    );
  }
}
