import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:poigo/models/jma_forecast_model.dart';

/// 曜日番号(1=月〜7=日)を1文字に変換
String _weekdayToChar(int weekday) {
  switch (weekday) {
    case DateTime.monday: return '月';
    case DateTime.tuesday: return '火';
    case DateTime.wednesday: return '水';
    case DateTime.thursday: return '木';
    case DateTime.friday: return '金';
    case DateTime.saturday: return '土';
    case DateTime.sunday: return '日';
    default: return '?';
  }
}

/// ISO日付文字列（例: 2026-03-05T00:00:00+09:00）から "3/5(火)" 形式に
String _formatDateWithWeekday(String? isoDate) {
  if (isoDate == null || isoDate.isEmpty) return '';
  try {
    final datePart = isoDate.split('T').first;
    if (datePart.isEmpty) return '';
    final dt = DateTime.parse(datePart);
    final w = _weekdayToChar(dt.weekday);
    return '${dt.month}/${dt.day}($w)';
  } catch (_) {
    return '';
  }
}

/// 気象庁 天気予報JSON 取得・解析
/// https://www.jma.go.jp/bosai/forecast/data/forecast/{地域コード}.json
/// 例: 130000=東京都
class JmaForecastService {
  JmaForecastService._();
  static final JmaForecastService instance = JmaForecastService._();

  static const String _baseUrl = 'https://www.jma.go.jp/bosai/forecast/data/forecast';

  /// 地域コード（130000=東京、または都道府県番号13など）で予報を取得
  Future<JmaForecastResult> fetchForecast(String areaCode) async {
    final code = _normalizeAreaCode(areaCode.trim());
    final url = '$_baseUrl/$code.json';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) {
      throw Exception('取得失敗: ${response.statusCode}');
    }
    final list = json.decode(response.body) as List<dynamic>;
    if (list.isEmpty) throw Exception('データがありません');
    return _parse(list);
  }

  /// 都道府県コード（1〜47）または既に130000形式ならそのまま
  String _normalizeAreaCode(String? code) {
    if (code == null || code.isEmpty) return '130000';
    final n = int.tryParse(code);
    if (n == null) return '130000';
    if (n >= 10000) return code; // すでに130000形式
    if (n >= 1 && n <= 47) return '${n.toString().padLeft(2, '0')}0000';
    return '130000';
  }

  JmaForecastResult _parse(List<dynamic> root) {
    final data0 = root[0] as Map<String, dynamic>;
    final data1 = root.length > 1 ? root[1] as Map<String, dynamic> : null;

    final ts0 = data0['timeSeries'] as List<dynamic>? ?? [];
    if (ts0.isEmpty) throw Exception('timeSeriesがありません');

    final shortTerm = ts0[0] as Map<String, dynamic>;
    final timeDefines = List<String>.from(shortTerm['timeDefines'] as List? ?? []);
    final areas = shortTerm['areas'] as List<dynamic>? ?? [];
    final area0 = areas.isNotEmpty ? areas[0] as Map<String, dynamic> : null;
    final areaObj = area0?['area'];
    final areaName = (areaObj is Map ? (areaObj['name']?.toString() ?? '') : '');

    final weatherCodes = List<String>.from(area0?['weatherCodes'] as List? ?? []);
    final weathers = List<String>.from(area0?['weathers'] as List? ?? []);

    final dayLabels = ['今日', '明日', '明後日'];
    List<int?> tMaxByDay = [null, null, null];
    List<int?> tMinByDay = [null, null, null];
    if (ts0.length > 2) {
      final tempBlock = ts0[2] as Map<String, dynamic>?;
      final tempAreas = tempBlock?['areas'] as List<dynamic>? ?? [];
      for (final a in tempAreas) {
        final ta = a as Map<String, dynamic>;
        final t = (ta['temps'] as List<dynamic>?)?.map((e) => int.tryParse(e?.toString() ?? '')).toList() ?? [];
        if (t.length >= 4) {
          final t0 = t[0]; final t1 = t[1]; final t2 = t[2]; final t3 = t[3];
          if (t0 != null && t1 != null) {
            tMaxByDay[0] = t0 >= t1 ? t0 : t1;
            tMinByDay[0] = t0 <= t1 ? t0 : t1;
          }
          if (t2 != null && t3 != null) {
            tMaxByDay[1] = t2 >= t3 ? t2 : t3;
            tMinByDay[1] = t2 <= t3 ? t2 : t3;
          }
          break;
        }
        if (t.length >= 2 && t[0] != null && t[1] != null) {
          final a = t[0]!; final b = t[1]!;
          tMaxByDay[0] = a >= b ? a : b;
          tMinByDay[0] = a <= b ? a : b;
          break;
        }
      }
    }

    if (data1 != null) {
      final ts1 = data1['timeSeries'] as List<dynamic>? ?? [];
      if (ts1.length > 1) {
        final weekTemps = ts1[1] as Map<String, dynamic>?;
        final weekAreas = weekTemps?['areas'] as List<dynamic>? ?? [];
        if (weekAreas.isNotEmpty) {
          final wa = weekAreas[0] as Map<String, dynamic>;
          final maxList = (wa['tempsMax'] as List<dynamic>?)?.map((e) {
            final s = e?.toString() ?? '';
            return s.isEmpty ? null : int.tryParse(s);
          }).toList() ?? [];
          final minList = (wa['tempsMin'] as List<dynamic>?)?.map((e) {
            final s = e?.toString() ?? '';
            return s.isEmpty ? null : int.tryParse(s);
          }).toList() ?? [];
          if (maxList.length > 2 && maxList[2] != null) tMaxByDay[2] = maxList[2];
          if (minList.length > 2 && minList[2] != null) tMinByDay[2] = minList[2];
        }
      }
    }

    final threeDay = <JmaThreeDayItem>[];
    for (int i = 0; i < 3 && i < weatherCodes.length; i++) {
      String dateLabel = dayLabels[i];
      if (timeDefines.length > i) {
        final withW = _formatDateWithWeekday(timeDefines[i] as String?);
        if (withW.isNotEmpty) dateLabel = '$dateLabel ${withW}';
      }
      threeDay.add(JmaThreeDayItem(
        dateLabel: dateLabel,
        weatherCode: weatherCodes.length > i ? weatherCodes[i] : '100',
        weatherText: weathers.length > i ? weathers[i] : '晴れ',
        tempMax: tMaxByDay[i],
        tempMin: tMinByDay[i],
      ));
    }

    List<JmaWeeklyItem> weekly = [];
    if (data1 != null) {
      final ts1 = data1['timeSeries'] as List<dynamic>? ?? [];
      if (ts1.isNotEmpty) {
        final week0 = ts1[0] as Map<String, dynamic>;
        final wDefines = List<String>.from(week0['timeDefines'] as List? ?? []);
        final wAreas = week0['areas'] as List<dynamic>? ?? [];
        final wArea = wAreas?.isNotEmpty == true ? wAreas![0] as Map<String, dynamic> : null;
        final wCodes = List<String>.from(wArea?['weatherCodes'] as List? ?? []);
        final wPops = (wArea?['pops'] as List<dynamic>?)?.map((e) => e?.toString()).toList() ?? [];

        List<int?> wMax = [];
        List<int?> wMin = [];
        if (ts1.length > 1) {
          final week1 = ts1[1] as Map<String, dynamic>;
          final tAreas = week1['areas'] as List<dynamic>? ?? [];
          if (tAreas.isNotEmpty) {
            final tw = tAreas[0] as Map<String, dynamic>;
            wMax = (tw['tempsMax'] as List<dynamic>?)?.map((e) {
              final s = e?.toString() ?? '';
              return s.isEmpty ? null : int.tryParse(s);
            }).toList() ?? [];
            wMin = (tw['tempsMin'] as List<dynamic>?)?.map((e) {
              final s = e?.toString() ?? '';
              return s.isEmpty ? null : int.tryParse(s);
            }).toList() ?? [];
          }
        }

        for (int i = 0; i < wCodes.length; i++) {
          String label = '${i + 1}日後';
          if (wDefines.length > i) {
            final withW = _formatDateWithWeekday(wDefines[i] as String?);
            if (withW.isNotEmpty) label = withW;
          }
          weekly.add(JmaWeeklyItem(
            dateLabel: label,
            weatherCode: wCodes[i],
            tempMax: wMax.length > i ? wMax[i] : null,
            tempMin: wMin.length > i ? wMin[i] : null,
            pop: wPops.length > i ? wPops[i] : null,
          ));
        }
      }
    }

    return JmaForecastResult(areaName: areaName, threeDay: threeDay, weekly: weekly);
  }
}
