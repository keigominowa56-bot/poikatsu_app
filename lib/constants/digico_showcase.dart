import 'package:flutter/material.dart';

/// デジコ経由で選べる交換先の例示（表示のみ。実際の手続きはデジコのギフト画面）。
class DigicoShowcaseTile {
  const DigicoShowcaseTile({
    required this.title,
    required this.caption,
    this.assetPath,
    this.gradient,
    this.fallbackIcon = Icons.card_giftcard_rounded,
  });

  final String title;
  final String caption;
  final String? assetPath;
  final Gradient? gradient;
  final IconData fallbackIcon;
}

/// 正方形カード用。公式ロゴの代替としてブランドに近い色・独自レイアウトを使用。
const List<DigicoShowcaseTile> kDigicoShowcaseTiles = [
  DigicoShowcaseTile(
    title: 'PayPay',
    caption: 'マネー・ライト等',
    assetPath: 'assets/exchange/external/paypay_money_lite.png',
  ),
  DigicoShowcaseTile(
    title: 'Amazonギフト',
    caption: 'デジコで選択',
    gradient: LinearGradient(
      colors: [Color(0xFF232F3E), Color(0xFFFF9900)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    fallbackIcon: Icons.shopping_bag_rounded,
  ),
  DigicoShowcaseTile(
    title: 'au PAY',
    caption: 'ポイント連携',
    assetPath: 'assets/exchange/external/au_pay.png',
  ),
  DigicoShowcaseTile(
    title: 'nanacoギフト',
    caption: '電子マネー',
    assetPath: 'assets/exchange/external/nanaco_gift.png',
  ),
];
