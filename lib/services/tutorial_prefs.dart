import 'package:shared_preferences/shared_preferences.dart';

/// 初回チュートリアル表示済みか（端末ローカル）
class TutorialPrefs {
  TutorialPrefs._();

  static const _key = 'app_tutorial_completed_v1';

  static Future<bool> isCompleted() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_key) ?? false;
  }

  static Future<void> setCompleted() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_key, true);
  }
}
