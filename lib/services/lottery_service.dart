import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:poigo/models/lottery_draw_model.dart';
import 'package:poigo/models/lottery_ticket_model.dart';
import 'package:poigo/services/user_firestore_service.dart';

/// ユーザー向け宝くじ：チケット発行・一覧・当選結果参照
class LotteryService {
  LotteryService._();
  static final LotteryService _instance = LotteryService._();
  static LotteryService get instance => _instance;

  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  static const String _ticketsCollection = 'lottery_tickets';
  static const String _drawsCollection = 'lottery_draws';
  static const String _lotterySettingsDocPath = 'admin_settings/lottery';

  /// チップで1枚購入するときの価格
  static const int lotteryTicketChipPrice = 10;

  /// 新規発行する回号。発表済みの最大回+1（発表が無ければ1）。発表済みの回には発行しない。
  Future<String> getCurrentRoundOnce() async {
    final drawsSnap = await _firestore.collection(_drawsCollection).get();
    int maxRound = 0;
    for (final doc in drawsSnap.docs) {
      final n = int.tryParse(doc.id);
      if (n != null && n > maxRound) maxRound = n;
    }
    return (maxRound + 1).toString();
  }

  /// チップで1枚購入。不足時は null、成功時は発行したチケット。
  Future<LotteryTicket?> buyTicketWithChips(String uid) async {
    final user = await UserFirestoreService.instance.getUserOnce(uid);
    final total = user?.totalPoints ?? 0;
    if (total < lotteryTicketChipPrice) return null;
    final ok = await UserFirestoreService.instance.tryConsumePoints(uid, lotteryTicketChipPrice);
    if (!ok) return null;
    return issueRandomTicket(uid);
  }

  /// 動画広告視聴1回につき1枚、ランダムな「組+6桁」を発行
  Future<LotteryTicket> issueRandomTicket(String userId) async {
    final round = await getCurrentRoundOnce();
    final group = 1 + math.Random().nextInt(10); // 1-10
    final number = math.Random().nextInt(1000000).toString().padLeft(6, '0');
    final ref = _firestore.collection(_ticketsCollection).doc();
    await ref.set({
      'userId': userId,
      'group': group,
      'number': number,
      'round': round,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return LotteryTicket(
      id: ref.id,
      userId: userId,
      group: group,
      number: number,
      round: round,
      createdAt: DateTime.now(),
    );
  }

  Stream<List<LotteryTicket>> streamMyTickets(String userId) {
    return _firestore
        .collection(_ticketsCollection)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snap) {
      final list = snap.docs.map((d) {
        final data = Map<String, dynamic>.from(d.data());
        final c = data['createdAt'];
        if (c is Timestamp) data['createdAt'] = c.toDate();
        return LotteryTicket.fromMap(d.id, data);
      }).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Stream<LotteryDraw?> streamDraw(String round) {
    return _firestore.collection(_drawsCollection).doc(round).snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) return null;
      final data = Map<String, dynamic>.from(snap.data()!);
      final p = data['publishedAt'];
      if (p is Timestamp) data['publishedAt'] = p.toDate();
      return LotteryDraw.fromMap(snap.id, data);
    });
  }

  /// 当選チップを受け取る（動画視聴後に呼ぶ）。チケットを「受け取り済み」にし、ユーザーにチップを付与する。
  /// 既に受け取り済みのチケットの場合は false。成功時 true。
  Future<bool> claimPrize(String ticketId, String uid, int prizeChips) async {
    if (prizeChips <= 0) return false;
    final ticketRef = _firestore.collection(_ticketsCollection).doc(ticketId);
    final snap = await ticketRef.get();
    if (!snap.exists || snap.data() == null) return false;
    final data = snap.data()!;
    if ((data['userId'] as String? ?? '') != uid) return false;
    if ((data['prizeClaimed'] as bool?) == true) return false;

    await ticketRef.update({
      'prizeClaimed': true,
      'prizeClaimedAt': FieldValue.serverTimestamp(),
    });

    await UserFirestoreService.instance.grantChips(uid, prizeChips, '宝くじ当選');
    return true;
  }
}

