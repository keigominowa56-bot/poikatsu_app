import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:poigo/models/point_history_entry_model.dart';

/// point_history への追記は UserFirestoreService 内で実施。ここでは取得のみ。
class PointHistoryService {
  PointHistoryService._();
  static final PointHistoryService _instance = PointHistoryService._();
  static PointHistoryService get instance => _instance;

  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  static const String _collection = 'point_history';

  /// 指定ユーザーの履歴を新しい順でストリーム
  Stream<List<PointHistoryEntry>> streamPointHistory(String userId) {
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snap) {
          final list = snap.docs.map((d) {
            final data = Map<String, dynamic>.from(d.data());
            final c = data['createdAt'];
            if (c is Timestamp) data['createdAt'] = c.toDate();
            return PointHistoryEntry.fromMap(d.id, data);
          }).toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list.take(200).toList();
        });
  }

  /// 直近N件を1回取得（グラフ用など）
  Future<List<PointHistoryEntry>> getPointHistoryOnce(String userId, {int limit = 200}) async {
    final snap = await _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .get();
    final list = snap.docs.map((d) {
      final data = Map<String, dynamic>.from(d.data());
      final c = data['createdAt'];
      if (c is Timestamp) data['createdAt'] = c.toDate();
      return PointHistoryEntry.fromMap(d.id, data);
    }).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list.take(limit).toList();
  }
}
