import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:poigo/models/exchange_history_entry.dart';

/// ユーザーの交換履歴（`users/{uid}/exchange_history`）
class ExchangeHistoryService {
  ExchangeHistoryService._();
  static final ExchangeHistoryService instance = ExchangeHistoryService._();

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  Stream<List<ExchangeHistoryEntry>> streamExchangeHistory(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('exchange_history')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(ExchangeHistoryEntry.fromDoc).toList());
  }
}
