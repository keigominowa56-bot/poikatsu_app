import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:poigo/models/exchange_request_model.dart';

class AdminExchangeRequestsService {
  AdminExchangeRequestsService._();
  static final AdminExchangeRequestsService _instance = AdminExchangeRequestsService._();
  static AdminExchangeRequestsService get instance => _instance;

  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  static const String _collection = 'exchange_requests';

  Stream<List<ExchangeRequestModel>> streamRequests() {
    return _firestore
        .collection(_collection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => ExchangeRequestModel.fromMap(d.id, d.data() ?? {}))
            .toList());
  }

  Future<void> approve(String requestId) async {
    await _firestore.collection(_collection).doc(requestId).update({
      'status': 'approved',
      'processedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> reject(String requestId) async {
    await _firestore.collection(_collection).doc(requestId).update({
      'status': 'rejected',
      'processedAt': FieldValue.serverTimestamp(),
    });
  }
}
