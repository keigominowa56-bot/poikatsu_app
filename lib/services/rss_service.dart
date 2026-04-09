import 'package:http/http.dart' as http;
import 'package:poigo/models/news_model.dart';
import 'package:poigo/models/news_settings_model.dart';
import 'package:poigo/services/news_settings_service.dart';
import 'package:webfeed_plus/webfeed_plus.dart';

/// RSS フィードの URL 一覧（Yahoo! は2020年以降の新URLを使用）
class RssUrls {
  static const String _yahooBase = 'https://news.yahoo.co.jp/rss/topics';
  /// 総合
  static const String general = '$_yahooBase/top-picks.xml';
  /// 政治
  static const String politics = '$_yahooBase/domestic.xml';
  /// 経済
  static const String economy = '$_yahooBase/business.xml';
  /// エンタメ
  static const String entertainment = '$_yahooBase/entertainment.xml';
  /// スポーツ
  static const String sports = '$_yahooBase/sports.xml';
  /// 国際
  static const String international = '$_yahooBase/world.xml';

  static const String yahooTopics = general;
  static const String itmediaNews = 'https://rss.itmedia.co.jp/rss/2.0/news_bursts.xml';
  static const String appleNewsroom = 'https://www.apple.com/jp/newsroom/rss-feed.rss';

  static String defaultForCategory(String categoryId) {
    switch (categoryId) {
      case NewsSettingsModel.keyGeneral:
        return general;
      case NewsSettingsModel.keyPolitics:
        return politics;
      case NewsSettingsModel.keyEconomy:
        return economy;
      case NewsSettingsModel.keyEntertainment:
        return entertainment;
      case NewsSettingsModel.keySports:
        return sports;
      case NewsSettingsModel.keyInternational:
        return international;
      default:
        return general;
    }
  }

  /// 地域用デフォルト（都道府県別RSSが無い場合は総合を使用）
  static String defaultForPrefecture(String prefectureCode) => general;
}

/// 取得用の User-Agent（Yahoo! 等はこれがないと拒否することがある）
const String _rssUserAgent =
    'Mozilla/5.0 (iPhone; CPU iPhone OS 15_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.0 Mobile/15E148 Safari/604.1';

/// 1フィードあたりの最大リトライ回数
const int _maxRetries = 3;

/// 接続タイムアウト（秒）
const Duration _timeout = Duration(seconds: 10);

/// RSS を取得・解析して NewsItem のリストを返すサービス
class RssService {
  RssService._();
  static final RssService _instance = RssService._();
  static RssService get instance => _instance;

  final _client = http.Client();

  /// カテゴリIDに応じたRSSを取得。設定(admin_settings/news)を参照し、未設定時はデフォルトURLを使用。
  Future<List<NewsItem>> fetchNewsItemsByCategory(String categoryId) async {
    final settings = await NewsSettingsService.instance.getNewsSettingsOnce();
    final url = settings.categoryUrls[categoryId]?.trim();
    final feedUrl = (url != null && url.isNotEmpty) ? url : RssUrls.defaultForCategory(categoryId);
    final sourceName = _categoryDisplayName(categoryId);
    final list = await _fetchFeed(feedUrl, sourceName);
    if (list.isEmpty) {
      final fallback = await _fetchFeed(RssUrls.yahooTopics, 'Yahoo!ニュース');
      if (fallback.isNotEmpty) return _sortByDate(fallback);
      throw Exception('RSSから記事を取得できませんでした。');
    }
    return _sortByDate(list);
  }

  /// 都道府県コードに応じたRSSを取得。設定に無い場合はデフォルト（総合）を使用。
  Future<List<NewsItem>> fetchNewsItemsByPrefecture(String prefectureCode) async {
    final settings = await NewsSettingsService.instance.getNewsSettingsOnce();
    final url = settings.prefectureUrls[prefectureCode]?.trim();
    final feedUrl = (url != null && url.isNotEmpty) ? url : RssUrls.defaultForPrefecture(prefectureCode);
    final sourceName = '地域';
    final list = await _fetchFeed(feedUrl, sourceName);
    if (list.isEmpty) {
      final fallback = await _fetchFeed(RssUrls.general, 'ニュース');
      if (fallback.isNotEmpty) return _sortByDate(fallback);
      throw Exception('RSSから記事を取得できませんでした。');
    }
    return _sortByDate(list);
  }

  static String _categoryDisplayName(String id) {
    switch (id) {
      case NewsSettingsModel.keyGeneral: return '総合';
      case NewsSettingsModel.keyPolitics: return '政治';
      case NewsSettingsModel.keyEconomy: return '経済';
      case NewsSettingsModel.keyEntertainment: return 'エンタメ';
      case NewsSettingsModel.keySports: return 'スポーツ';
      case NewsSettingsModel.keyInternational: return '国際';
      default: return 'ニュース';
    }
  }

  static List<NewsItem> _sortByDate(List<NewsItem> list) {
    list.sort((a, b) {
      final da = a.publishedAt ?? DateTime(0);
      final db = b.publishedAt ?? DateTime(0);
      return db.compareTo(da);
    });
    return list;
  }

  /// 複数フィードを取得してマージしたリストを返す（重複は link で除外）。
  /// いずれか1つでも取得できれば表示する。全て失敗した場合のみ例外を投げる。
  Future<List<NewsItem>> fetchNewsItems() async {
    try {
      final results = await Future.wait([
        _fetchFeed(RssUrls.yahooTopics, 'Yahoo!ニュース'),
        _fetchFeed(RssUrls.itmediaNews, 'ITmedia'),
        _fetchFeed(RssUrls.appleNewsroom, 'Apple'),
      ]);
      final all = <NewsItem>[];
      final seenLinks = <String>{};
      for (final list in results) {
        for (final item in list) {
          final link = item.link;
          if (link != null && link.isNotEmpty && !seenLinks.contains(link)) {
            seenLinks.add(link);
            all.add(item);
          }
        }
      }
      if (all.isEmpty) {
        print('[RssService] fetchNewsItems: 全フィードで記事が取得できませんでした');
        throw Exception('RSSから記事を取得できませんでした。');
      }
      return _sortByDate(all);
    } catch (e, st) {
      print('[RssService] fetchNewsItems 失敗: $e');
      print(st);
      rethrow;
    }
  }

  /// 1フィードを取得。最大 _maxRetries 回までリトライし、失敗時は空リストを返す（例外は投げない）。
  Future<List<NewsItem>> _fetchFeed(String url, String sourceName) async {
    Object? lastError;
    for (var attempt = 1; attempt <= _maxRetries; attempt++) {
      try {
        final response = await _client
            .get(
              Uri.parse(url),
              headers: {'User-Agent': _rssUserAgent},
            )
            .timeout(_timeout);
        if (response.statusCode != 200) {
          print('[RssService] _fetchFeed $url: HTTP ${response.statusCode} (試行 $attempt/$_maxRetries)');
          lastError = Exception('HTTP ${response.statusCode}');
          continue;
        }
        final feed = RssFeed.parse(response.body);
        if (feed.items == null || feed.items!.isEmpty) {
          print('[RssService] _fetchFeed $url: 記事0件 (試行 $attempt/$_maxRetries)');
          continue;
        }
        return feed.items!.map((e) => _rssItemToNewsItem(e, sourceName)).toList();
      } catch (e, st) {
        lastError = e;
        print('[RssService] _fetchFeed 失敗 url=$url sourceName=$sourceName 試行 $attempt/$_maxRetries: $e');
        print(st);
      }
    }
    print('[RssService] _fetchFeed 全リトライ失敗 url=$url lastError=$lastError');
    return [];
  }

  NewsItem _rssItemToNewsItem(RssItem item, String sourceName) {
    final link = item.link?.trim();
    final id = link ?? item.guid ?? '${sourceName}_${item.title.hashCode}';
    final description = _stripHtml(item.description ?? '');
    return NewsItem(
      id: id,
      title: (item.title ?? '').trim(),
      link: link?.isEmpty == true ? null : link,
      description: description.isEmpty ? null : description,
      publishedAt: item.pubDate,
      sourceName: sourceName,
    );
  }

  /// 簡易 HTML タグ除去（RSS の description 用）
  static String _stripHtml(String html) {
    if (html.isEmpty) return html;
    String t = html
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'</p>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"');
    return t.trim().replaceAll(RegExp(r'\n+'), '\n');
  }
}
