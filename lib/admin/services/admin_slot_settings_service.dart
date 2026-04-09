import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:poigo/models/slot_settings_model.dart';

class AdminSlotSettingsService {
  AdminSlotSettingsService._();
  static final AdminSlotSettingsService _instance = AdminSlotSettingsService._();
  static AdminSlotSettingsService get instance => _instance;

  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  static const String _docPath = 'admin_settings/slot';

  Stream<SlotSettings> stream() {
    return _firestore.doc(_docPath).snapshots().map((snap) => SlotSettings.fromMap(snap.data()));
  }

  Future<void> save(SlotSettings settings) async {
    await _firestore.doc(_docPath).set({
      ...settings.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}

