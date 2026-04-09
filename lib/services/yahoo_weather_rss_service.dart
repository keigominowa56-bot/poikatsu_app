import 'package:http/http.dart' as http;
import 'package:poigo/models/yahoo_weather_item.dart';
import 'package:xml/xml.dart';

/// Yahoo!天気RSS（days）の取得・解析
/// 例: https://rss-weather.yahoo.co.jp/rss/days/4410.xml （東京）
class YahooWeatherRssService {
  YahooWeatherRssService._();
  static final YahooWeatherRssService instance = YahooWeatherRssService._();

  static const String _baseUrl = 'https://rss-weather.yahoo.co.jp/rss/days';

  /// 地域コード（4410=東京など）でRSSを取得し、<item> の <title> から日付・天気・気温を抽出
  Future<List<YahooWeatherItem>> fetchForecast(int areaCode) async {
    final url = '$_baseUrl/$areaCode.xml';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) {
      throw Exception('RSS取得失敗: ${response.statusCode}');
    }
    try {
      return _parseXml(response.body);
    } catch (e) {
      throw Exception('RSSの解析に失敗しました: $e');
    }
  }

  List<YahooWeatherItem> _parseXml(String xmlString) {
    final document = XmlDocument.parse(xmlString);
    final items = document.findAllElements('item');
    final list = <YahooWeatherItem>[];
    for (final item in items) {
      final titleEl = item.findElements('title').firstOrNull;
      final title = titleEl?.innerText.trim() ?? '';
      if (title.isEmpty) continue;
      list.add(_parseTitle(title));
    }
    return list;
  }

  /// <title> の文字列から日付・天気・気温を抽出
  YahooWeatherItem _parseTitle(String title) {
    String dateText = '';
    String weatherText = '';
    int? tempHigh;
    int? tempLow;

    // 気温: 「12℃/5℃」「最高12℃ 最低5℃」「12℃ 5℃」などを検出
    final tempRegex = RegExp(r'(\d+)\s*℃');
    final temps = tempRegex.allMatches(title).map((m) => int.tryParse(m.group(1) ?? '')).whereType<int>().toList();
    if (temps.isNotEmpty) {
      tempHigh = temps.length >= 1 ? temps.first : null;
      tempLow = temps.length >= 2 ? temps[1] : null;
      if (temps.length >= 2 && temps[0] < temps[1]) {
        tempHigh = temps[1];
        tempLow = temps[0];
      }
    }

    // 天気: キーワード検出（順序: 強い雨 → 雷 → 晴 → 曇 → 雨 → 雪）
    if (title.contains('強い雨')) {
      weatherText = '強い雨';
    } else if (title.contains('雷')) {
      weatherText = '雷';
    } else if (title.contains('晴')) {
      weatherText = '晴れ';
    } else if (title.contains('曇')) {
      weatherText = '曇り';
    } else if (title.contains('雨')) {
      weatherText = '雨';
    } else if (title.contains('雪')) {
      weatherText = '雪';
    } else {
      weatherText = '晴れ';
    }

    // 日付: 先頭の「数字/数字(曜)」や「○月○日」などを抜き出す
    final dateMatch = RegExp(r'(\d+/\d+[\s(（]?\w*[)）]?|\d+月\d+日[^の]*)').firstMatch(title);
    dateText = dateMatch?.group(1)?.trim() ?? title.split(RegExp(r'\s+')).firstOrNull ?? '';

    return YahooWeatherItem(
      dateText: dateText,
      weatherText: weatherText,
      tempHigh: tempHigh,
      tempLow: tempLow,
    );
  }
}
