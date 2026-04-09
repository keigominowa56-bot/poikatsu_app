/// 生年月日を軸にした運勢ロジック（星座・数秘・その日生まれへの一言）
class FortuneLogic {
  FortuneLogic._();

  /// 星座の境界（月・日）。各星座の終わり日
  static const List<({int month, int day})> _zodiacEnds = [
    (month: 1, day: 19),   // 山羊座
    (month: 2, day: 18),   // 水瓶座
    (month: 3, day: 20),   // 魚座
    (month: 4, day: 19),   // 牡羊座
    (month: 5, day: 20),   // 牡牛座
    (month: 6, day: 21),   // 双子座
    (month: 7, day: 22),   // 蟹座
    (month: 8, day: 22),   // 獅子座
    (month: 9, day: 22),   // 乙女座
    (month: 10, day: 23),  // 天秤座
    (month: 11, day: 21),  // 蠍座
    (month: 12, day: 21),  // 射手座
  ];

  static const List<String> _zodiacNames = [
    '山羊座', '水瓶座', '魚座', '牡羊座', '牡牛座', '双子座',
    '蟹座', '獅子座', '乙女座', '天秤座', '蠍座', '射手座',
  ];

  /// 生年月日から星座を返す
  static String zodiacSign(DateTime birthDate) {
    final m = birthDate.month;
    final d = birthDate.day;
    for (var i = 0; i < _zodiacEnds.length; i++) {
      final end = _zodiacEnds[i];
      if (m < end.month || (m == end.month && d <= end.day)) {
        return _zodiacNames[i];
      }
    }
    return _zodiacNames[0];
  }

  /// 数秘術的なライフパスナンバー（1〜9、 Master number 11/22 は単数化しない簡易版）
  static int lifePathNumber(DateTime birthDate) {
    int n = birthDate.year + birthDate.month + birthDate.day;
    while (n > 9 && n != 11 && n != 22) {
      n = _digitSum(n);
    }
    return n.clamp(1, 9);
  }

  static int _digitSum(int n) {
    int s = 0;
    while (n > 0) {
      s += n % 10;
      n ~/= 10;
    }
    return s;
  }

  /// 数秘の短いメッセージ
  static String numerologyMessage(int lifePath) {
    const messages = {
      1: 'リーダーシップと新しい一歩の日。先頭に立つと運が開けます。',
      2: '協調とバランス。誰かと一緒に動くと良い結果に。',
      3: '表現とコミュニケーション。言葉や創作で運気アップ。',
      4: '土台づくりと努力。コツコツが実を結ぶ日。',
      5: '変化と自由。新しいことに手を伸ばしてみて。',
      6: '家庭や身近な人を大切に。癒しのエネルギーが高い日。',
      7: '内省と学び。静かに考える時間が開運の鍵。',
      8: '実りと達成。努力が形になりやすい日。',
      9: '区切りと次のステージ。手放すことで流れが良くなります。',
    };
    return messages[lifePath] ?? '今日もあなたらしく。';
  }

  /// 年間通し日（1〜366）で「その日生まれの人への一言」の種を返す（同じ日は同じメッセージになる）
  static String dayOfYearMessage(DateTime birthDate) {
    final dayOfYear = _dayOfYear(birthDate);
    final seeds = [
      '今日生まれのあなたは、人を惹きつける魅力の持ち主。',
      'この日生まれの人は、困難を乗り越える力が強い。',
      '今日の誕生日のあなたは、感受性が豊かで芸術の才能に恵まれる。',
      'この日生まれは、周囲を明るくする存在。',
      '今日生まれの人は、論理と直感のバランスが良い。',
      'この日生まれのあなたは、努力が必ず報われる運命線。',
      '今日の誕生日は、人との縁に恵まれる日。',
      'この日生まれは、新しいことに挑戦すると運が開く。',
      '今日生まれのあなたは、穏やかさの中に強い意志を秘めている。',
      'この日生まれの人は、今日という日があなたの転機になり得る。',
    ];
    return seeds[dayOfYear % seeds.length];
  }

  static int _dayOfYear(DateTime d) {
    final start = DateTime(d.year, 1, 1);
    return d.difference(start).inDays + 1;
  }

  /// 今日のバイオリズム風スコア（生年月日と今日の日付から 0〜100 の整数を算出。再現可能）
  static int dailyBiorhythmScore(DateTime birthDate, DateTime today) {
    final base = birthDate.millisecondsSinceEpoch ~/ 86400000;
    final current = today.millisecondsSinceEpoch ~/ 86400000;
    final cycle = (current - base).abs();
    final seed = (cycle * 31 + birthDate.day + today.day) % 101;
    return seed.clamp(0, 100);
  }

  /// 明日のラッキーカラー（日付ベースで再現可能）。名前のみ返す。
  static String tomorrowLuckyColorName(DateTime today) {
    final tomorrow = today.add(const Duration(days: 1));
    final dayOfYear = _dayOfYear(tomorrow);
    const colors = [
      'レッド', 'ゴールド', 'ブルー', 'グリーン', 'パープル', 'ピンク',
      'オレンジ', 'ターコイズ', 'イエロー', 'シルバー', 'コーラル', 'ラベンダー',
    ];
    return colors[dayOfYear % colors.length];
  }

  /// 過去数日分のバイオリズムスコア（折れ線グラフ用）。[今日, 昨日, ...] の順で最大7日分。
  static List<int> biorhythmScoresForChart(DateTime birthDate, DateTime today, {int days = 7}) {
    final list = <int>[];
    for (var i = 0; i < days; i++) {
      final d = today.subtract(Duration(days: i));
      list.add(dailyBiorhythmScore(birthDate, d));
    }
    return list.reversed.toList();
  }
}
