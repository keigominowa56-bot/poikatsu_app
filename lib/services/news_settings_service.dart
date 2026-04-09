import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/news_settings_model.dart';

/// アプリ用: admin_settings/news を読み取り（ストリーム・1回取得）
class NewsSettingsService {
  NewsSettingsService._();
  static final NewsSettingsService _instance = NewsSettingsService._();
  static NewsSettingsService get instance => _instance;

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

  Future<NewsSettingsModel> getNewsSettingsOnce() async {
    final snap = await _firestore.collection(_collection).doc(_docId).get();
    if (!snap.exists || snap.data() == null) {
      return const NewsSettingsModel();
    }
    return NewsSettingsModel.fromMap(snap.data()!);
  }
}
