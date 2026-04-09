/// 気象庁 3日分の1件（今日・明日・明後日）
class JmaThreeDayItem {
  const JmaThreeDayItem({
    required this.dateLabel,
    required this.weatherCode,
    required this.weatherText,
    this.tempMax,
    this.tempMin,
  });

  final String dateLabel;
  final String weatherCode;
  final String weatherText;
  final int? tempMax;
  final int? tempMin;

  /// 天気コードと気温から画像キーを決定（仕様に従う）
  String toAssetKey() {
    final code = int.tryParse(weatherCode) ?? 0;
    final maxT = tempMax ?? 0;

    if (code >= 100 && code < 200) {
      return maxT > 35 ? 'heavy_sunny' : 'sunny';
    }
    if (code >= 200 && code < 300) return 'cloudy';
    if (code >= 300 && code < 400) {
      if (code == 350 || (code >= 350 && code <= 359)) return 'thunder';
      if (code >= 306 && code <= 309) return 'heavy_rain'; // 大雨など
      return 'rain';
    }
    if (code >= 400 && code < 500) return 'heavy_snow';
    return 'sunny';
  }
}

/// 気象庁 週間予報の1件
class JmaWeeklyItem {
  const JmaWeeklyItem({
    required this.dateLabel,
    required this.weatherCode,
    this.tempMax,
    this.tempMin,
    this.pop,
  });

  final String dateLabel;
  final String weatherCode;
  final int? tempMax;
  final int? tempMin;
  final String? pop;

  String toAssetKey() {
    final code = int.tryParse(weatherCode) ?? 0;
    final maxT = tempMax ?? 0;
    if (code >= 100 && code < 200) return maxT > 35 ? 'heavy_sunny' : 'sunny';
    if (code >= 200 && code < 300) return 'cloudy';
    if (code >= 300 && code < 400) {
      if (code == 350 || (code >= 350 && code <= 359)) return 'thunder';
      if (code >= 306 && code <= 309) return 'heavy_rain';
      return 'rain';
    }
    if (code >= 400 && code < 500) return 'heavy_snow';
    return 'sunny';
  }
}

/// 気象庁APIの解析結果（3日＋週間）
class JmaForecastResult {
  const JmaForecastResult({
    required this.areaName,
    required this.threeDay,
    required this.weekly,
  });

  final String areaName;
  final List<JmaThreeDayItem> threeDay;
  final List<JmaWeeklyItem> weekly;
}
