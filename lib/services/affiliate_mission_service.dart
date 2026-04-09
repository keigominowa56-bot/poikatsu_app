import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:poigo/models/affiliate_mission_model.dart';

/// アフィリエイト案件の取得（ユーザー向け：公開のみ）とクリックログ保存
class AffiliateMissionService {
  AffiliateMissionService._();
  static final AffiliateMissionService _instance = AffiliateMissionService._();
  static AffiliateMissionService get instance => _instance;

  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  static const String _missionsCollection = 'affiliate_missions';
  static const String _clickLogCollection = 'affiliate_click_logs';

  /// 公開中の案件一覧のストリーム（作成日時の新しい順でソート）
  Stream<List<AffiliateMission>> streamPublishedMissions() {
    return _firestore
        .collection(_missionsCollection)
        .where('isPublished', isEqualTo: true)
        .snapshots()
        .map((snap) {
          final list = snap.docs
              .map((d) => _missionFromDoc(d))
              .where((m) => m.id.isNotEmpty)
              .toList();
          list.sort((a, b) {
            final ca = a.createdAt ?? DateTime(0);
            final cb = b.createdAt ?? DateTime(0);
            return cb.compareTo(ca);
          });
          return list;
        });
  }

  /// リンクを踏んだ履歴を click_log として保存。将来的に管理画面から「承認」でポイント付与する土台。
  Future<void> logClick({required String userId, required String missionId}) async {
    await _firestore.collection(_clickLogCollection).add({
      'userId': userId,
      'missionId': missionId,
      'clickedAt': FieldValue.serverTimestamp(),
      'approvedAt': null,
      'pointsGranted': null,
    });
  }

  AffiliateMission _missionFromDoc(DocumentSnapshot doc) {
    final data = doc.data();
    if (data == null || data is! Map) {
      return AffiliateMission(id: doc.id, title: '', pointAmount: 0, affiliateUrl: '');
    }
    final map = Map<String, dynamic>.from(data);
    map['id'] ??= doc.id;
    _parseTimestamps(map);
    return AffiliateMission.fromMap(map);
  }

  void _parseTimestamps(Map<String, dynamic> map) {
    final created = map['createdAt'];
    if (created is Timestamp) {
      map['createdAt'] = created.toDate().toIso8601String();
    }
    final updated = map['updatedAt'];
    if (updated is Timestamp) {
      map['updatedAt'] = updated.toDate().toIso8601String();
    }
  }
}
