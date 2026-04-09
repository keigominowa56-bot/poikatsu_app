import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:poigo/models/economy_settings_model.dart';

/// 管理画面用: admin_settings/economy の読み書き
class AdminEconomySettingsService {
  AdminEconomySettingsService._();
  static final AdminEconomySettingsService _instance = AdminEconomySettingsService._();
  static AdminEconomySettingsService get instance => _instance;

  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  static const String _collection = 'admin_settings';
  static const String _docId = 'economy';

  Stream<EconomySettingsModel> streamEconomySettings() {
    return _firestore.collection(_collection).doc(_docId).snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) {
        return const EconomySettingsModel();
      }
      return EconomySettingsModel.fromMap(snap.data()!);
    });
  }

  Future<void> save(EconomySettingsModel settings) async {
    final ref = _firestore.collection(_collection).doc(_docId);
    await ref.set({
      ...settings.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
