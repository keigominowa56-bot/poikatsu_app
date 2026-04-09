class SlotSettings {
  const SlotSettings({
    required this.winProbabilityPercent,
    required this.payoutMultiplier,
  });

  /// 当たり確率（0〜100）
  final double winProbabilityPercent;
  /// 配当倍率（例: 2.0）
  final double payoutMultiplier;

  factory SlotSettings.fromMap(Map<String, dynamic>? map) {
    final p = (map?['winProbabilityPercent'] as num?)?.toDouble() ?? 10.0;
    final m = (map?['payoutMultiplier'] as num?)?.toDouble() ?? 2.0;
    return SlotSettings(
      winProbabilityPercent: p.clamp(0.0, 100.0),
      payoutMultiplier: m.clamp(0.0, 100.0),
    );
  }

  Map<String, dynamic> toMap() => {
        'winProbabilityPercent': winProbabilityPercent,
        'payoutMultiplier': payoutMultiplier,
      };
}

