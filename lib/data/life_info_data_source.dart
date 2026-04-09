import 'package:poigo/models/news_model.dart';
import 'package:poigo/models/news_settings_model.dart';
import 'package:poigo/services/rss_service.dart';

/// ライフ情報タブごとのデータ取得を抽象化。
abstract class LifeInfoDataSource {
  Future<List<NewsItem>> getItems();
}

/// ニュースタブ（従来の複数フィードマージ）
class RssNewsDataSource implements LifeInfoDataSource {
  @override
  Future<List<NewsItem>> getItems() => RssService.instance.fetchNewsItems();
}

/// カテゴリ別ニュース（総合・政治・経済・エンタメ・スポーツ・国際）
class NewsCategoryDataSource implements LifeInfoDataSource {
  NewsCategoryDataSource(this.categoryId);
  final String categoryId;

  @override
  Future<List<NewsItem>> getItems() =>
      RssService.instance.fetchNewsItemsByCategory(categoryId);
}

/// 地域（都道府県）別ニュース
class NewsRegionDataSource implements LifeInfoDataSource {
  NewsRegionDataSource(this.prefectureCode);
  final String prefectureCode;

  @override
  Future<List<NewsItem>> getItems() =>
      RssService.instance.fetchNewsItemsByPrefecture(prefectureCode);
}

/// カテゴリ一覧（タブ用）
class NewsCategories {
  static const List<({String id, String label})> items = [
    (id: NewsSettingsModel.keyGeneral, label: '総合'),
    (id: NewsSettingsModel.keyPolitics, label: '政治'),
    (id: NewsSettingsModel.keyEconomy, label: '経済'),
    (id: NewsSettingsModel.keyEntertainment, label: 'エンタメ'),
    (id: NewsSettingsModel.keySports, label: 'スポーツ'),
    (id: NewsSettingsModel.keyInternational, label: '国際'),
  ];
}

/// 天気タブ：ダミー。将来は天気 API に差し替え
class WeatherDataSource implements LifeInfoDataSource {
  @override
  Future<List<NewsItem>> getItems() async => _DemoWeatherData.items;
}

/// 交通情報タブ：ダミー。将来は交通 API に差し替え
class TrafficDataSource implements LifeInfoDataSource {
  @override
  Future<List<NewsItem>> getItems() async => _DemoTrafficData.items;
}

/// 天気ダミーデータ（API 接続時に差し替え）
class _DemoWeatherData {
  static final List<NewsItem> items = [
    NewsItem(
      id: 'weather_1',
      title: '東京・明日は晴れのち曇り、最高気温25度',
      description: '関東は高気圧に覆われておおむね晴れ。明日は午後から雲が増える見込みです。',
      sourceName: '天気',
    ),
    NewsItem(
      id: 'weather_2',
      title: '週末は全国的に荒れた天気に',
      description: '低気圧の影響で土日は雨や強風のおそれ。外出の際はご注意を。',
      sourceName: '天気',
    ),
    NewsItem(
      id: 'weather_3',
      title: '梅雨入りは平年並みの見込み',
      description: '気象庁によると、関東の梅雨入りは例年どおり6月上旬の予想です。',
      sourceName: '天気',
    ),
    NewsItem(
      id: 'weather_4',
      title: '紫外線が強い季節です。日焼け対策を',
      description: '本日の紫外線指数は「非常に強い」ランク。帽子や日焼け止めをおすすめします。',
      sourceName: '天気',
    ),
  ];
}

/// 交通ダミーデータ（API 接続時に差し替え）
class _DemoTrafficData {
  static final List<NewsItem> items = [
    NewsItem(
      id: 'traffic_1',
      title: '山手線 内回り 5分遅延',
      description: '人身事故の影響で山手線内回りに遅れが出ています。復旧見込みは未定です。',
      sourceName: '交通',
    ),
    NewsItem(
      id: 'traffic_2',
      title: '首都高 環状線 渋滞中',
      description: '首都高速環状線は大井南JCT付近で渋滞が発生しています。',
      sourceName: '交通',
    ),
    NewsItem(
      id: 'traffic_3',
      title: '新幹線 東海道線 平常運転',
      description: '東海道・山陽新幹線は本日、平常どおり運転しています。',
      sourceName: '交通',
    ),
    NewsItem(
      id: 'traffic_4',
      title: '地下鉄 銀座線 終電後の工事',
      description: '銀座線は終電後、表参道〜渋谷間で設備工事を実施します。',
      sourceName: '交通',
    ),
  ];
}
