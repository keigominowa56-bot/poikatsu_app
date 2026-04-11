/// キャラクターカードの表示用データ（枠・名前・星・属性・説明文）
class CharacterCard {
  const CharacterCard({
    required this.level,
    required this.name,
    required this.stars,
    required this.attribute,
    required this.description,
    this.imageAssetPath,
    this.imageUrl,
  });

  final int level;
  final String name;
  final int stars;
  final String attribute;
  final String description;
  /// Lv.1〜3用: 共通アセット（assets/images/lv1.gif 等）
  final String? imageAssetPath;
  /// Lv.4以上: カスタム画像URL（DALL-E等で取得 or 手動追加）
  final String? imageUrl;

  bool get isRare => level >= 3;
  bool get isCustom => level >= 4 && (imageUrl != null && imageUrl!.isNotEmpty);

  /// Lv.1〜3の共通カードデータ
  static CharacterCard forLevel(int level, {String? customName, String? customImageUrl}) {
    switch (level) {
      case 1:
        return const CharacterCard(
          level: 1,
          name: 'ポイポイ',
          stars: 1,
          attribute: 'ノーマル',
          description: '歩いてチップを貯めると成長するよ。',
          imageAssetPath: 'assets/images/lv1.gif',
        );
      case 2:
        return const CharacterCard(
          level: 2,
          name: 'ポイポイ',
          stars: 2,
          attribute: 'ノーマル',
          description: 'だんだんパワーアップしてきた！',
          imageAssetPath: 'assets/images/lv2.gif',
        );
      case 3:
        return const CharacterCard(
          level: 3,
          name: 'ポイポイ',
          stars: 3,
          attribute: 'レア',
          description: '進化してキラキラになってきた！',
          imageAssetPath: 'assets/images/lv3.gif',
        );
      default:
        return CharacterCard(
          level: level,
          name: customName ?? 'マイキャラ',
          stars: level.clamp(4, 5),
          attribute: 'スペシャル',
          description: 'あなただけのキャラクター。',
          imageUrl: customImageUrl,
        );
    }
  }
}
