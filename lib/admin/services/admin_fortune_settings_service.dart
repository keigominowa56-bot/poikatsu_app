import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:poigo/models/fortune_settings_model.dart';

/// 管理画面用: admin_settings/fortune の読み書き
class AdminFortuneSettingsService {
  AdminFortuneSettingsService._();
  static final AdminFortuneSettingsService _instance = AdminFortuneSettingsService._();
  static AdminFortuneSettingsService get instance => _instance;

  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  static const String _collection = 'admin_settings';
  static const String _docId = 'fortune';

  /// ストリームで購読（編集フォームの初期値・リアルタイム反映用）
  Stream<FortuneSettingsModel> streamFortuneSettings() {
    return _firestore.collection(_collection).doc(_docId).snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) {
        return const FortuneSettingsModel();
      }
      return FortuneSettingsModel.fromMap(snap.data()!);
    });
  }

  /// 配信: Firestore を更新
  Future<void> publish(FortuneSettingsModel settings) async {
    final ref = _firestore.collection(_collection).doc(_docId);
    await ref.set({
      ...settings.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
