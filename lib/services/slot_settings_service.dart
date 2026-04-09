import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:poigo/models/slot_settings_model.dart';

class SlotSettingsService {
  SlotSettingsService._();
  static final SlotSettingsService _instance = SlotSettingsService._();
  static SlotSettingsService get instance => _instance;

  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  static const String _docPath = 'admin_settings/slot';

  Future<SlotSettings> getOnce() async {
    final snap = await _firestore.doc(_docPath).get();
    return SlotSettings.fromMap(snap.data());
  }
}

