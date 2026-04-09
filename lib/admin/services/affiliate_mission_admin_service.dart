import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:poigo/models/affiliate_mission_model.dart';

/// 管理画面用：アフィリエイト案件のCRUD
class AffiliateMissionAdminService {
  AffiliateMissionAdminService._();
  static final AffiliateMissionAdminService _instance = AffiliateMissionAdminService._();
  static AffiliateMissionAdminService get instance => _instance;

  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  static const String _missionsCollection = 'affiliate_missions';
  static const String _clickLogCollection = 'affiliate_click_logs';

  /// 全案件のストリーム（管理用：公開・非公開含む）
  Stream<List<AffiliateMission>> streamAllMissions() {
    return _firestore
        .collection(_missionsCollection)
        .snapshots()
        .map((snap) {
          final list = snap.docs.map((d) => _missionFromDoc(d)).where((m) => m.id.isNotEmpty).toList();
          list.sort((a, b) {
            final pointCompare = b.pointAmount.compareTo(a.pointAmount);
            if (pointCompare != 0) return pointCompare;
            final ca = a.createdAt ?? DateTime(0);
            final cb = b.createdAt ?? DateTime(0);
            return cb.compareTo(ca);
          });
          return list;
        });
  }

  /// 案件を追加
  Future<void> addMission(AffiliateMission mission) async {
    final now = FieldValue.serverTimestamp();
    await _firestore.collection(_missionsCollection).doc(mission.id).set({
      ...mission.toMap(),
      'createdAt': now,
      'updatedAt': now,
    });
  }

  /// 案件を更新
  Future<void> updateMission(AffiliateMission mission) async {
    final map = mission.toMap();
    map['updatedAt'] = DateTime.now().toIso8601String();
    await _firestore.collection(_missionsCollection).doc(mission.id).set(map, SetOptions(merge: true));
  }

  /// 非公開化（isPublished = false）。削除せず残す
  Future<void> unpublishMission(String missionId) async {
    await _firestore.collection(_missionsCollection).doc(missionId).update({
      'isPublished': false,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// ドキュメント削除（完全削除）
  Future<void> deleteMission(String missionId) async {
    await _firestore.collection(_missionsCollection).doc(missionId).delete();
  }

  /// 新規IDを発行（ドキュメントID用）
  String generateId() {
    return _firestore.collection(_missionsCollection).doc().id;
  }

  AffiliateMission _missionFromDoc(DocumentSnapshot doc) {
    final data = doc.data();
    if (data == null || data is! Map) {
      return AffiliateMission(id: doc.id, title: '', pointAmount: 0, affiliateUrl: '');
    }
    final map = Map<String, dynamic>.from(data);
    map['id'] ??= doc.id;
    final created = map['createdAt'];
    if (created is Timestamp) map['createdAt'] = created.toDate().toIso8601String();
    final updated = map['updatedAt'];
    if (updated is Timestamp) map['updatedAt'] = updated.toDate().toIso8601String();
    return AffiliateMission.fromMap(map);
  }

  /// クリックログ一覧（将来的に管理画面で「承認」ボタン→ユーザーへポイント付与で使用）
  Stream<QuerySnapshot> streamClickLogs() {
    return _firestore
        .collection(_clickLogCollection)
        .orderBy('clickedAt', descending: true)
        .limit(200)
        .snapshots();
  }
}
