/// 占いの運営設定（admin_settings/fortune ドキュメント）
class FortuneSettingsModel {
  const FortuneSettingsModel({
    this.globalMessage = '',
    this.luckyFactor = 1.0,
    this.specialEvent = '',
    this.updatedAt,
  });

  /// 全ユーザーの診断結果に表示する「今日の一言（運営からのお告げ）」
  final String globalMessage;

  /// その日の運勢スコアを底上げする倍率（例: 1.2）
  final double luckyFactor;

  /// 「大安」「一粒万倍日」などの特別ラベル
  final String specialEvent;

  /// 最終更新日時
  final DateTime? updatedAt;

  Map<String, dynamic> toMap() {
    return {
      'globalMessage': globalMessage,
      'luckyFactor': luckyFactor,
      'specialEvent': specialEvent,
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory FortuneSettingsModel.fromMap(Map<String, dynamic> map) {
    double factor = 1.0;
    final f = map['luckyFactor'];
    if (f != null) {
      if (f is num) {
        factor = f.toDouble();
      } else {
        factor = double.tryParse(f.toString()) ?? 1.0;
      }
    }
    factor = factor.clamp(0.1, 3.0);
    DateTime? updated;
    final u = map['updatedAt'];
    if (u != null) {
      updated = DateTime.tryParse(u.toString());
    }
    return FortuneSettingsModel(
      globalMessage: map['globalMessage'] as String? ?? '',
      luckyFactor: factor,
      specialEvent: map['specialEvent'] as String? ?? '',
      updatedAt: updated,
    );
  }

  FortuneSettingsModel copyWith({
    String? globalMessage,
    double? luckyFactor,
    String? specialEvent,
    DateTime? updatedAt,
  }) {
    return FortuneSettingsModel(
      globalMessage: globalMessage ?? this.globalMessage,
      luckyFactor: luckyFactor ?? this.luckyFactor,
      specialEvent: specialEvent ?? this.specialEvent,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
