import 'dart:math' as math;

/// 蓄積ポイント（累計獲得チップ）によるキャラクター進化レベル計算
/// 次のレベルに必要な累計が前レベルの2倍（倍々）
class CharacterEvolutionService {
  CharacterEvolutionService._();
  static final CharacterEvolutionService instance = CharacterEvolutionService._();

  /// 基準ポイント（Lv1→Lv2に5,000pt）。係数変更で調整可能
  static const int basePoints = 5000;

  /// 指定レベルに到達するために必要な累計ポイント
  /// Lv2=5,000 / Lv3=15,000 / Lv4=35,000 / Lv5=75,000 ...
  static int requiredCumulativeForLevel(int level) {
    if (level <= 1) return 0;
    return (basePoints * (math.pow(2, level - 1) - 1)).round();
  }

  /// 次のレベルまでに必要な追加ポイント（現在レベルから）
  static int requiredPointsForNextLevel(int currentLevel) {
    return (basePoints * math.pow(2, currentLevel - 1)).round();
  }

  /// 累計ポイントから現在のレベルを算出（1以上）
  int levelFromTotalPoints(int totalEarnedChips) {
    if (totalEarnedChips < 0) return 1;
    if (totalEarnedChips < basePoints) return 1;
    final t = (totalEarnedChips / basePoints) + 1;
    final raw = (math.log(t) / math.log(2)).floor() + 1;
    return raw.clamp(1, 999);
  }

  /// 表示用レベル（ペナルティを反映）
  int displayLevel(int totalEarnedChips, int levelPenalty) {
    final lvl = levelFromTotalPoints(totalEarnedChips);
    return (lvl - levelPenalty).clamp(1, 999);
  }

  /// 次のレベルまでの進捗（0.0〜1.0）。あと何%で進化か
  double progressToNextLevel(int totalEarnedChips, int levelPenalty) {
    final current = displayLevel(totalEarnedChips, levelPenalty);
    final currentCumulative = requiredCumulativeForLevel(current);
    final nextCumulative = requiredCumulativeForLevel(current + 1);
    final need = nextCumulative - currentCumulative;
    if (need <= 0) return 1.0;
    final have = totalEarnedChips - currentCumulative;
    return (have / need).clamp(0.0, 1.0);
  }

  /// 次のレベルまでにあと何ポイント必要か
  int pointsUntilNextLevel(int totalEarnedChips, int levelPenalty) {
    final current = displayLevel(totalEarnedChips, levelPenalty);
    final currentCumulative = requiredCumulativeForLevel(current);
    final nextCumulative = requiredCumulativeForLevel(current + 1);
    final need = nextCumulative - currentCumulative;
    if (need <= 0) return 0;
    final have = totalEarnedChips - currentCumulative;
    return (need - have).clamp(0, 0x7FFFFFFF);
  }
}
