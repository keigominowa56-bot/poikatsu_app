import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:poigo/models/news_settings_model.dart';

/// 管理画面用: admin_settings/news の読み書き
class AdminNewsSettingsService {
  AdminNewsSettingsService._();
  static final AdminNewsSettingsService _instance = AdminNewsSettingsService._();
  static AdminNewsSettingsService get instance => _instance;

  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  static const String _collection = 'admin_settings';
  static const String _docId = 'news';

  Stream<NewsSettingsModel> streamNewsSettings() {
    return _firestore.collection(_collection).doc(_docId).snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) {
        return const NewsSettingsModel();
      }
      return NewsSettingsModel.fromMap(snap.data()!);
    });
  }

  Future<void> save(NewsSettingsModel settings) async {
    final ref = _firestore.collection(_collection).doc(_docId);
    await ref.set({
      ...settings.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
