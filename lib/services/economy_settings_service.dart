import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/economy_settings_model.dart';

/// アプリ用: admin_settings/economy を読み取り
class EconomySettingsService {
  EconomySettingsService._();
  static final EconomySettingsService _instance = EconomySettingsService._();
  static EconomySettingsService get instance => _instance;

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

  Future<EconomySettingsModel> getEconomySettingsOnce() async {
    final snap = await _firestore.collection(_collection).doc(_docId).get();
    if (!snap.exists || snap.data() == null) {
      return const EconomySettingsModel();
    }
    return EconomySettingsModel.fromMap(snap.data()!);
  }
}
