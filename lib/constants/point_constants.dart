/// アプリ内チップ（ポイント）の換算・付与定義。
///
/// **100チップ = 1円**（1チップ = 0.01円相当）
///
/// SKYFLAG（オファーウォール）の付与はサーバー側の `wallpoint` をそのまま加算するため、
/// ここでは数値を変更しない（アプリ側の定数は参照しない）。
class PointConstants {
  PointConstants._();

  /// 1円あたりのチップ数
  static const int chipsPerYen = 100;

  /// 動画広告（AdMob Reward）1回あたりの付与チップ
  static const int admobRewardChipsPerView = 25;

  // ─── 歩数タンク（500歩で1タンク満タン時の受取）※上記 AdMob 一般報酬とは別定義 ───

  /// 動画なしで即受け取り（1タンク消費あたり）
  static const int stepTankPlainChips = 1;

  /// リワード広告視聴後の受け取り（1タンク消費あたり）
  static const int stepTankVideoChips = 30;

  /// UI の「◯倍」表記（1チップ基準の見せ方）
  static const int stepTankVideoMultiplierDisplay = 30;

  /// デジコ交換: 交換額（円）と消費チップ数（最低 200 円 = 20,000 チップ）
  static const List<DigicoExchangeTier> digicoExchangeTiers = [
    DigicoExchangeTier(yen: 200, chips: 20000),
    DigicoExchangeTier(yen: 300, chips: 30000),
    DigicoExchangeTier(yen: 500, chips: 50000),
    DigicoExchangeTier(yen: 1000, chips: 100000),
    DigicoExchangeTier(yen: 3000, chips: 300000),
    DigicoExchangeTier(yen: 5000, chips: 500000),
  ];

  /// 円 → チップ（常に [chipsPerYen] 倍）
  static int yenToChips(int yen) => yen * chipsPerYen;

  /// チップ数をカンマ区切りで表示（例: 50000 → 50,000）
  static String formatChips(int value) {
    final neg = value < 0;
    final v = neg ? -value : value;
    final digits = v.toString();
    final buf = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) {
        buf.write(',');
      }
      buf.write(digits[i]);
    }
    return neg ? '-$buf' : buf.toString();
  }
}

/// デジコギフト交換の1段階
class DigicoExchangeTier {
  const DigicoExchangeTier({required this.yen, required this.chips});

  /// 交換額（円）
  final int yen;

  /// 消費チップ数（= yen × [PointConstants.chipsPerYen]）
  final int chips;
}
