/// 累計獲得チップに基づくレベル算出・還元率（倍々設計・上限50%）
class LevelService {
  LevelService._();
  static final LevelService instance = LevelService._();

  /// 倍々設計: Lv.1(0〜499), Lv.2(500〜999), Lv.3(1000〜1999), Lv.4(2000〜3999) ...
  static int levelFromTotalEarnedChips(int totalEarnedChips) {
    if (totalEarnedChips < 500) return 1;
    int level = 1;
    int threshold = 500;
    while (totalEarnedChips >= threshold) {
      level++;
      threshold *= 2;
    }
    return level;
  }

  /// 表示用レベル（ペナルティで下がる）。最小1。
  static int displayLevel(int totalEarnedChips, int levelPenalty) {
    final fromChips = levelFromTotalEarnedChips(totalEarnedChips);
    return (fromChips - levelPenalty).clamp(1, 999);
  }

  /// レベルに応じたチップ還元率（0.0〜0.5）。高レベルほど還元率アップ、最大50%。
  static double redemptionRateForLevel(int level) {
    // 例: 0.05 + level * 0.04 → Lv.10 で 0.45, Lv.12 で 0.53 → min(0.5, ...)
    final rate = 0.05 + level * 0.04;
    return rate.clamp(0.0, 0.5);
  }
}
