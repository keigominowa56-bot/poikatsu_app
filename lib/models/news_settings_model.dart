/// ニュース設定（admin_settings/news）。カテゴリ・地域ごとのRSS URL
class NewsSettingsModel {
  const NewsSettingsModel({
    this.categoryUrls = const {},
    this.prefectureUrls = const {},
    this.updatedAt,
  });

  /// カテゴリID -> RSS URL（1つ）。複数持たせる場合はカンマ区切り等で1文字列にしても可
  final Map<String, String> categoryUrls;

  /// 都道府県コード（1〜47の文字列）-> RSS URL
  final Map<String, String> prefectureUrls;

  final DateTime? updatedAt;

  static const String keyGeneral = 'general';
  static const String keyPolitics = 'politics';
  static const String keyEconomy = 'economy';
  static const String keyEntertainment = 'entertainment';
  static const String keySports = 'sports';
  static const String keyInternational = 'international';

  Map<String, dynamic> toMap() {
    return {
      'categoryUrls': Map<String, String>.from(categoryUrls),
      'prefectureUrls': Map<String, String>.from(prefectureUrls),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory NewsSettingsModel.fromMap(Map<String, dynamic> map) {
    Map<String, String> cat = {};
    final cu = map['categoryUrls'];
    if (cu is Map) {
      for (final e in cu.entries) {
        if (e.key is String && e.value != null) {
          cat[e.key as String] = e.value.toString();
        }
      }
    }
    Map<String, String> pref = {};
    final pu = map['prefectureUrls'];
    if (pu is Map) {
      for (final e in pu.entries) {
        if (e.key is String && e.value != null) {
          pref[e.key as String] = e.value.toString();
        }
      }
    }
    DateTime? updated;
    final u = map['updatedAt'];
    if (u != null) updated = DateTime.tryParse(u.toString());
    return NewsSettingsModel(
      categoryUrls: cat,
      prefectureUrls: pref,
      updatedAt: updated,
    );
  }
}
