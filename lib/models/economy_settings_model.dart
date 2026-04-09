/// 経済圏設定（admin_settings/economy）。動画連動・くじのパラメータ
class EconomySettingsModel {
  const EconomySettingsModel({
    this.newsReadBonusMaxPerDay = 5,
    this.newsRefillCount = 5,
    this.readBonusBasePoints = 1,
    this.readBonusVideoMultiplier = 25,
    this.lotteryMinPt = 1,
    this.lotteryMaxPt = 5,
    this.referralPointsInviter = 10,
    this.referralPointsInvitee = 10,
    this.videoLotteryMaxPerDay = 5,
    this.updatedAt,
  });

  /// ニュース読了ボーナス 1日最大回数
  final int newsReadBonusMaxPerDay;

  /// 動画視聴で追加する読了ボーナス回数（おかわり）
  final int newsRefillCount;

  /// 読了ボーナス そのまま受け取る場合のポイント
  final int readBonusBasePoints;

  /// 動画視聴で受け取る場合のポイント（倍増）
  final int readBonusVideoMultiplier;

  /// 動画くじの最小ポイント
  final int lotteryMinPt;

  /// 動画くじの最大ポイント
  final int lotteryMaxPt;

  /// 紹介報酬: 紹介者に付与するポイント
  final int referralPointsInviter;
  /// 紹介報酬: 被紹介者に付与するポイント
  final int referralPointsInvitee;
  /// 動画くじ 24時間あたりの最大視聴回数
  final int videoLotteryMaxPerDay;

  final DateTime? updatedAt;

  Map<String, dynamic> toMap() {
    return {
      'newsReadBonusMaxPerDay': newsReadBonusMaxPerDay,
      'newsRefillCount': newsRefillCount,
      'readBonusBasePoints': readBonusBasePoints,
      'readBonusVideoMultiplier': readBonusVideoMultiplier,
      'lotteryMinPt': lotteryMinPt,
      'lotteryMaxPt': lotteryMaxPt,
      'referralPointsInviter': referralPointsInviter,
      'referralPointsInvitee': referralPointsInvitee,
      'videoLotteryMaxPerDay': videoLotteryMaxPerDay,
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory EconomySettingsModel.fromMap(Map<String, dynamic> map) {
    int i(key, int def) {
      final v = map[key];
      if (v == null) return def;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString()) ?? def;
    }
    DateTime? updated;
    final u = map['updatedAt'];
    if (u != null) updated = DateTime.tryParse(u.toString());
    return EconomySettingsModel(
      newsReadBonusMaxPerDay: i('newsReadBonusMaxPerDay', 5).clamp(1, 20),
      newsRefillCount: i('newsRefillCount', 5).clamp(1, 20),
      readBonusBasePoints: i('readBonusBasePoints', 1).clamp(1, 10),
      readBonusVideoMultiplier: i('readBonusVideoMultiplier', 25).clamp(1, 999999),
      lotteryMinPt: i('lotteryMinPt', 1).clamp(0, 99),
      lotteryMaxPt: i('lotteryMaxPt', 5).clamp(1, 99),
      referralPointsInviter: i('referralPointsInviter', 10).clamp(0, 999),
      referralPointsInvitee: i('referralPointsInvitee', 10).clamp(0, 999),
      videoLotteryMaxPerDay: i('videoLotteryMaxPerDay', 5).clamp(1, 50),
      updatedAt: updated,
    );
  }
}
