/// 回号ごとの当選発表（lottery_draws/{round}）
class LotteryDraw {
  const LotteryDraw({
    required this.round,
    required this.winningGroup,
    required this.winningNumber,
    required this.prizeFirst,
    required this.prizeSecond,
    required this.prizeThird,
    required this.publishedAt,
  });

  final String round;
  final int winningGroup;
  final String winningNumber;
  /// 1等（組+6桁完全一致）
  final int prizeFirst;
  /// 2等（6桁一致）
  final int prizeSecond;
  /// 3等（下4桁一致）
  final int prizeThird;
  final DateTime? publishedAt;

  factory LotteryDraw.fromMap(String round, Map<String, dynamic> map) {
    DateTime? publishedAt;
    final p = map['publishedAt'];
    if (p is DateTime) publishedAt = p;
    return LotteryDraw(
      round: round,
      winningGroup: (map['winningGroup'] as num?)?.toInt() ?? 1,
      winningNumber: map['winningNumber'] as String? ?? '000000',
      prizeFirst: (map['prizeFirst'] as num?)?.toInt() ?? 0,
      prizeSecond: (map['prizeSecond'] as num?)?.toInt() ?? 0,
      prizeThird: (map['prizeThird'] as num?)?.toInt() ?? 0,
      publishedAt: publishedAt,
    );
  }
}

