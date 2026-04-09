/// Yahoo!天気RSSの1件分（<item> の <title> から抽出）
class YahooWeatherItem {
  const YahooWeatherItem({
    required this.dateText,
    required this.weatherText,
    this.tempHigh,
    this.tempLow,
  });

  /// 日付の表示用テキスト（例: 2/4(火)）
  final String dateText;
  /// 天気の表示用テキスト（例: 晴れ）
  final String weatherText;
  /// 最高気温（℃）
  final int? tempHigh;
  /// 最低気温（℃）
  final int? tempLow;

  /// 天気テキストから画像キーを決定（仕様に従う）
  String get weatherAssetKey {
    final t = weatherText;
    if (t.contains('強い雨')) return 'heavy_rain';
    if (t.contains('雷')) return 'thunder';
    if (t.contains('晴')) return 'sunny';
    if (t.contains('曇')) return 'cloudy';
    if (t.contains('雨')) return 'rain';
    if (t.contains('雪')) return 'heavy_snow';
    return 'sunny';
  }
}
