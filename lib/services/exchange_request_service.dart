import 'package:cloud_firestore/cloud_firestore.dart';

/// ユーザー用: 交換申請の送信
class ExchangeRequestService {
  ExchangeRequestService._();
  static final ExchangeRequestService _instance = ExchangeRequestService._();
  static ExchangeRequestService get instance => _instance;

  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  static const String _collection = 'exchange_requests';

  /// 交換申請を1件作成（status: pending）
  Future<void> submitRequest({required String userId, required String categoryId, int? pointsRequested}) async {
    await _firestore.collection(_collection).add({
      'userId': userId,
      'categoryId': categoryId,
      'status': 'pending',
      if (pointsRequested != null) 'pointsRequested': pointsRequested,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
