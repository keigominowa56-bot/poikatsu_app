import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/fortune_settings_model.dart';

/// アプリ本体用: admin_settings/fortune を読み取り（ストリーム・1回取得）
class FortuneSettingsService {
  FortuneSettingsService._();
  static final FortuneSettingsService _instance = FortuneSettingsService._();
  static FortuneSettingsService get instance => _instance;

  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  static const String _collection = 'admin_settings';
  static const String _docId = 'fortune';

  /// リアルタイム購読。管理画面で更新すると即反映される
  Stream<FortuneSettingsModel> streamFortuneSettings() {
    return _firestore.collection(_collection).doc(_docId).snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) {
        return const FortuneSettingsModel();
      }
      return FortuneSettingsModel.fromMap(snap.data()!);
    });
  }

  /// 1回だけ取得（リロード時など）
  Future<FortuneSettingsModel> getFortuneSettingsOnce() async {
    final snap = await _firestore.collection(_collection).doc(_docId).get();
    if (!snap.exists || snap.data() == null) {
      return const FortuneSettingsModel();
    }
    return FortuneSettingsModel.fromMap(snap.data()!);
  }
}
