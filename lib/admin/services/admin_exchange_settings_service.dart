import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:poigo/models/exchange_settings_model.dart';

/// 管理画面用: admin_settings/exchange の読み書き
class AdminExchangeSettingsService {
  AdminExchangeSettingsService._();
  static final AdminExchangeSettingsService _instance = AdminExchangeSettingsService._();
  static AdminExchangeSettingsService get instance => _instance;

  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  static const String _collection = 'admin_settings';
  static const String _docId = 'exchange';

  Stream<ExchangeSettingsModel> streamExchangeSettings() {
    return _firestore.collection(_collection).doc(_docId).snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) return const ExchangeSettingsModel();
      return ExchangeSettingsModel.fromMap(snap.data()!);
    });
  }

  Future<void> save(ExchangeSettingsModel settings) async {
    await _firestore.collection(_collection).doc(_docId).set({
      ...settings.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
