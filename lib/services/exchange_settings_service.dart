import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/exchange_settings_model.dart';

/// アプリ用: admin_settings/exchange を読み取り
class ExchangeSettingsService {
  ExchangeSettingsService._();
  static final ExchangeSettingsService _instance = ExchangeSettingsService._();
  static ExchangeSettingsService get instance => _instance;

  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  static const String _collection = 'admin_settings';
  static const String _docId = 'exchange';

  Future<ExchangeSettingsModel> getExchangeSettingsOnce() async {
    final snap = await _firestore.collection(_collection).doc(_docId).get();
    if (!snap.exists || snap.data() == null) {
      return const ExchangeSettingsModel();
    }
    return ExchangeSettingsModel.fromMap(snap.data()!);
  }
}
