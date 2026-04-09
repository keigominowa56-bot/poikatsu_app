/// 自社発行「数字選択式宝くじ」チケット（lottery_tickets コレクション）
class LotteryTicket {
  const LotteryTicket({
    required this.id,
    required this.userId,
    required this.group,
    required this.number,
    required this.round,
    required this.createdAt,
    this.prizeClaimed = false,
  });

  final String id;
  final String userId;
  /// 組（1-10）
  final int group;
  /// 6桁（例: "012345"）
  final String number;
  /// 回号（例: "2026-03" / "1" など）
  final String round;
  final DateTime createdAt;
  /// 当選チップを受け取り済みか
  final bool prizeClaimed;

  factory LotteryTicket.fromMap(String id, Map<String, dynamic> map) {
    DateTime createdAt = DateTime.now();
    final c = map['createdAt'];
    if (c is DateTime) createdAt = c;
    return LotteryTicket(
      id: id,
      userId: map['userId'] as String? ?? '',
      group: (map['group'] as num?)?.toInt() ?? 1,
      number: map['number'] as String? ?? '000000',
      round: map['round'] as String? ?? '1',
      createdAt: createdAt,
      prizeClaimed: (map['prizeClaimed'] as bool?) ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'group': group,
      'number': number,
      'round': round,
      'createdAt': createdAt,
      'prizeClaimed': prizeClaimed,
    };
  }
}

