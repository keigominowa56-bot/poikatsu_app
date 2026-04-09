/// 交換メニューON/OFF（admin_settings/exchange）。管理画面から切り替え
class ExchangeSettingsModel {
  const ExchangeSettingsModel({
    this.itemsEnabled = true,
    this.externalPointsEnabled = true,
    this.giftCardsEnabled = true,
    this.skinsEnabled = true,
    this.donationEnabled = true,
    this.updatedAt,
  });

  /// アイテム（ガチャチケ等）
  final bool itemsEnabled;
  /// 他社ポイント（ドットマネー等）
  final bool externalPointsEnabled;
  /// 商品券（Amazonギフト券等）
  final bool giftCardsEnabled;
  /// 着せ替え（アプリ内スキン）
  final bool skinsEnabled;
  /// 寄付
  final bool donationEnabled;

  final DateTime? updatedAt;

  Map<String, dynamic> toMap() {
    return {
      'itemsEnabled': itemsEnabled,
      'externalPointsEnabled': externalPointsEnabled,
      'giftCardsEnabled': giftCardsEnabled,
      'skinsEnabled': skinsEnabled,
      'donationEnabled': donationEnabled,
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory ExchangeSettingsModel.fromMap(Map<String, dynamic> map) {
    bool b(String key, bool def) {
      final v = map[key];
      if (v == null) return def;
      if (v is bool) return v;
      return v.toString().toLowerCase() == 'true';
    }
    DateTime? updated;
    final u = map['updatedAt'];
    if (u != null) updated = DateTime.tryParse(u.toString());
    return ExchangeSettingsModel(
      itemsEnabled: b('itemsEnabled', true),
      externalPointsEnabled: b('externalPointsEnabled', true),
      giftCardsEnabled: b('giftCardsEnabled', true),
      skinsEnabled: b('skinsEnabled', true),
      donationEnabled: b('donationEnabled', true),
      updatedAt: updated,
    );
  }
}
