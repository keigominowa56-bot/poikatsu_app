import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:poigo/models/lottery_draw_model.dart';

/// 管理画面用：宝くじの回号設定・当選番号/等級チップ数の発表
class AdminLotteryService {
  AdminLotteryService._();
  static final AdminLotteryService _instance = AdminLotteryService._();
  static AdminLotteryService get instance => _instance;

  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  static const String _drawsCollection = 'lottery_draws';
  static const String _settingsDocPath = 'admin_settings/lottery';

  Stream<String> streamCurrentRound() {
    return _firestore.doc(_settingsDocPath).snapshots().map((snap) {
      final r = snap.data()?['currentRound']?.toString();
      return (r == null || r.trim().isEmpty) ? '1' : r.trim();
    });
  }

  Future<void> setCurrentRound(String round) async {
    await _firestore.doc(_settingsDocPath).set({
      'currentRound': round,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// 指定回が既に発表済みか
  Future<bool> hasDraw(String round) async {
    final snap = await _firestore.collection(_drawsCollection).doc(round).get();
    return snap.exists;
  }

  Stream<List<LotteryDraw>> streamDraws() {
    return _firestore.collection(_drawsCollection).snapshots().map((snap) {
      final list = snap.docs.map((d) {
        final data = Map<String, dynamic>.from(d.data());
        final p = data['publishedAt'];
        if (p is Timestamp) data['publishedAt'] = p.toDate();
        return LotteryDraw.fromMap(d.id, data);
      }).toList();
      list.sort((a, b) => b.round.compareTo(a.round));
      return list;
    });
  }

  Future<void> publishDraw({
    required String round,
    required int winningGroup,
    required String winningNumber,
    required int prizeFirst,
    required int prizeSecond,
    required int prizeThird,
  }) async {
    await _firestore.collection(_drawsCollection).doc(round).set({
      'winningGroup': winningGroup,
      'winningNumber': winningNumber,
      'prizeFirst': prizeFirst,
      'prizeSecond': prizeSecond,
      'prizeThird': prizeThird,
      'publishedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}

