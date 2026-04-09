/// 気象庁 府県予報区（天気予報APIで指定する地域コード一覧）
/// 参照: https://www.jma.go.jp/bosai/common/const/area.json
class JmaArea {
  const JmaArea({required this.code, required this.name, required this.region});

  final String code;
  final String name;
  final String region;

  String get displayName => '$region $name';
}

/// 全国の気象庁府県予報区リスト（地域選択用）
const List<JmaArea> jmaAreaList = [
  // 北海道地方
  JmaArea(code: '011000', name: '宗谷地方', region: '北海道'),
  JmaArea(code: '012000', name: '上川・留萌地方', region: '北海道'),
  JmaArea(code: '013000', name: '網走・北見・紋別地方', region: '北海道'),
  JmaArea(code: '014030', name: '十勝地方', region: '北海道'),
  JmaArea(code: '014100', name: '釧路・根室地方', region: '北海道'),
  JmaArea(code: '015000', name: '胆振・日高地方', region: '北海道'),
  JmaArea(code: '016000', name: '石狩・空知・後志地方', region: '北海道'),
  JmaArea(code: '017000', name: '渡島・檜山地方', region: '北海道'),
  // 東北地方
  JmaArea(code: '020000', name: '青森県', region: '東北'),
  JmaArea(code: '030000', name: '岩手県', region: '東北'),
  JmaArea(code: '040000', name: '宮城県', region: '東北'),
  JmaArea(code: '050000', name: '秋田県', region: '東北'),
  JmaArea(code: '060000', name: '山形県', region: '東北'),
  JmaArea(code: '070000', name: '福島県', region: '東北'),
  // 関東甲信
  JmaArea(code: '080000', name: '茨城県', region: '関東甲信'),
  JmaArea(code: '090000', name: '栃木県', region: '関東甲信'),
  JmaArea(code: '100000', name: '群馬県', region: '関東甲信'),
  JmaArea(code: '110000', name: '埼玉県', region: '関東甲信'),
  JmaArea(code: '120000', name: '千葉県', region: '関東甲信'),
  JmaArea(code: '130000', name: '東京都', region: '関東甲信'),
  JmaArea(code: '140000', name: '神奈川県', region: '関東甲信'),
  JmaArea(code: '190000', name: '山梨県', region: '関東甲信'),
  JmaArea(code: '200000', name: '長野県', region: '関東甲信'),
  // 北陸
  JmaArea(code: '150000', name: '新潟県', region: '北陸'),
  JmaArea(code: '160000', name: '富山県', region: '北陸'),
  JmaArea(code: '170000', name: '石川県', region: '北陸'),
  JmaArea(code: '180000', name: '福井県', region: '北陸'),
  // 東海
  JmaArea(code: '210000', name: '岐阜県', region: '東海'),
  JmaArea(code: '220000', name: '静岡県', region: '東海'),
  JmaArea(code: '230000', name: '愛知県', region: '東海'),
  JmaArea(code: '240000', name: '三重県', region: '東海'),
  // 近畿
  JmaArea(code: '250000', name: '滋賀県', region: '近畿'),
  JmaArea(code: '260000', name: '京都府', region: '近畿'),
  JmaArea(code: '270000', name: '大阪府', region: '近畿'),
  JmaArea(code: '280000', name: '兵庫県', region: '近畿'),
  JmaArea(code: '290000', name: '奈良県', region: '近畿'),
  JmaArea(code: '300000', name: '和歌山県', region: '近畿'),
  // 中国
  JmaArea(code: '310000', name: '鳥取県', region: '中国'),
  JmaArea(code: '320000', name: '島根県', region: '中国'),
  JmaArea(code: '330000', name: '岡山県', region: '中国'),
  JmaArea(code: '340000', name: '広島県', region: '中国'),
  // 四国
  JmaArea(code: '360000', name: '徳島県', region: '四国'),
  JmaArea(code: '370000', name: '香川県', region: '四国'),
  JmaArea(code: '380000', name: '愛媛県', region: '四国'),
  JmaArea(code: '390000', name: '高知県', region: '四国'),
  // 九州北部（山口含む）
  JmaArea(code: '350000', name: '山口県', region: '九州北部'),
  JmaArea(code: '400000', name: '福岡県', region: '九州北部'),
  JmaArea(code: '410000', name: '佐賀県', region: '九州北部'),
  JmaArea(code: '420000', name: '長崎県', region: '九州北部'),
  JmaArea(code: '430000', name: '熊本県', region: '九州北部'),
  JmaArea(code: '440000', name: '大分県', region: '九州北部'),
  // 九州南部・奄美
  JmaArea(code: '450000', name: '宮崎県', region: '九州南部'),
  JmaArea(code: '460040', name: '奄美地方', region: '九州南部'),
  JmaArea(code: '460100', name: '鹿児島県（奄美除く）', region: '九州南部'),
  // 沖縄
  JmaArea(code: '471000', name: '沖縄本島地方', region: '沖縄'),
  JmaArea(code: '472000', name: '大東島地方', region: '沖縄'),
  JmaArea(code: '473000', name: '宮古島地方', region: '沖縄'),
  JmaArea(code: '474000', name: '八重山地方', region: '沖縄'),
];

/// 都道府県コード（1〜47、例: 13=東京）に近い府県予報区コードを返す
String jmaAreaCodeFromPrefecture(String? prefectureCode) {
  if (prefectureCode == null || prefectureCode.isEmpty) return '130000';
  final n = int.tryParse(prefectureCode);
  if (n == null || n < 1 || n > 47) return '130000';
  // 都道府県番号と先頭2桁が一致するエリアを探す（複数ある場合は最初の1件）
  final prefix = n.toString().padLeft(2, '0');
  final matches = jmaAreaList.where((a) => a.code.startsWith(prefix)).toList();
  return matches.isNotEmpty ? matches.first.code : '130000';
}
