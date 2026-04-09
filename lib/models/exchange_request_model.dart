import 'package:cloud_firestore/cloud_firestore.dart';

/// 交換申請（exchange_requests コレクション）
class ExchangeRequestModel {
  const ExchangeRequestModel({
    required this.id,
    required this.userId,
    required this.categoryId,
    required this.status,
    this.pointsRequested,
    this.createdAt,
    this.processedAt,
  });

  final String id;
  final String userId;
  /// items / externalPoints / giftCards / skins / donation
  final String categoryId;
  /// pending / approved / rejected
  final String status;
  final int? pointsRequested;
  final DateTime? createdAt;
  final DateTime? processedAt;

  factory ExchangeRequestModel.fromMap(String id, Map<String, dynamic> map) {
    DateTime? created;
    final c = map['createdAt'];
    if (c != null) {
      if (c is Timestamp) created = c.toDate();
      else created = DateTime.tryParse(c.toString());
    }
    DateTime? processed;
    final p = map['processedAt'];
    if (p != null) {
      if (p is Timestamp) processed = p.toDate();
      else processed = DateTime.tryParse(p.toString());
    }
    return ExchangeRequestModel(
      id: id,
      userId: map['userId'] as String? ?? '',
      categoryId: map['categoryId'] as String? ?? '',
      status: map['status'] as String? ?? 'pending',
      pointsRequested: (map['pointsRequested'] as num?)?.toInt(),
      createdAt: created,
      processedAt: processed,
    );
  }
}
