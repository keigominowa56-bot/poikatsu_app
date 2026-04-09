/// 交換メニュー: 他社ポイント（デジコ連携）の選択肢。
///
/// [id] はバックエンド `POST /api/digico/exchange` の `categoryId` と一致させる。
class ExternalPointProduct {
  const ExternalPointProduct({
    required this.id,
    required this.label,
    required this.assetPath,
  });

  final String id;
  final String label;

  /// pubspec に登録した assets パス
  final String assetPath;
}

/// 表示順。追加時は [externalPointProducts] とサーバ `_DIGICO_EXTERNAL_PRODUCT_IDS` を同期すること。
const List<ExternalPointProduct> externalPointProducts = [
  ExternalPointProduct(
    id: 'external_au_pay',
    label: 'au PAY',
    assetPath: 'assets/exchange/external/au_pay.png',
  ),
  ExternalPointProduct(
    id: 'external_rakuten_edy',
    label: '楽天Edy',
    assetPath: 'assets/exchange/external/rakuten_edy.png',
  ),
  ExternalPointProduct(
    id: 'external_nanaco_gift',
    label: 'nanacoギフト',
    assetPath: 'assets/exchange/external/nanaco_gift.png',
  ),
  ExternalPointProduct(
    id: 'external_paypay_money_lite',
    label: 'PayPayマネーライト',
    assetPath: 'assets/exchange/external/paypay_money_lite.png',
  ),
];
