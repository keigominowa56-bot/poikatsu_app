/// RSS 等から取得するニュース1件の型。
/// 将来的に RSS パース結果をこの型に流し込む想定。
class NewsItem {
  const NewsItem({
    required this.id,
    required this.title,
    this.link,
    this.description,
    this.publishedAt,
    this.sourceName,
  });

  /// 一意ID（RSS では link や guid を利用可能）
  final String id;

  /// タイトル
  final String title;

  /// 記事URL（RSS の link）
  final String? link;

  /// 本文または要約（RSS の description 等）
  final String? description;

  /// 公開日時（RSS の pubDate 等）
  final DateTime? publishedAt;

  /// 配信元名（任意）
  final String? sourceName;

  /// 詳細画面用本文。description がなければ title を返す。
  String get body => (description != null && description!.isNotEmpty)
      ? description!
      : title;

  /// ダミー用：本文が空のときに表示する長文を生成（RSS 取得後は description で上書き可能）
  String bodyOrPlaceholder() {
    if (description != null && description!.isNotEmpty) return description!;
    return '$title\n\n'
        'ここに記事の本文が表示されます。\n\n'
        'ポイ活アプリでは、ニュースや天気・交通情報を読むことでチップを貯められます。'
        'この画面で3秒間滞在すると読了となり、チップを受け取れます。';
  }

  NewsItem copyWith({
    String? id,
    String? title,
    String? link,
    String? description,
    DateTime? publishedAt,
    String? sourceName,
  }) {
    return NewsItem(
      id: id ?? this.id,
      title: title ?? this.title,
      link: link ?? this.link,
      description: description ?? this.description,
      publishedAt: publishedAt ?? this.publishedAt,
      sourceName: sourceName ?? this.sourceName,
    );
  }
}
