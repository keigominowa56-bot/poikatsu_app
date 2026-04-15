import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// 手動でアセットから読んだキー（dotenv より優先して使う）
String _runtimeKey = '';

/// `assets/config/openai.env` を rootBundle で読み、OPENAI_API_KEY を設定する。
/// flutter_dotenv に依存せず、空行・# コメント・クォート付き値にも対応。
Future<void> loadOpenAiEnvFromAssets() async {
  try {
    final raw = await rootBundle.loadString('assets/config/openai.env');
    for (final rawLine in raw.split('\n')) {
      var line = rawLine.trim();
      if (line.isEmpty || line.startsWith('#')) continue;
      final eq = line.indexOf('=');
      if (eq <= 0) continue;
      final key = line.substring(0, eq).trim();
      if (key != 'OPENAI_API_KEY') continue;
      var val = line.substring(eq + 1).trim();
      if (val.length >= 2) {
        final q0 = val[0];
        final q1 = val[val.length - 1];
        if ((q0 == '"' && q1 == '"') || (q0 == "'" && q1 == "'")) {
          val = val.substring(1, val.length - 1);
        }
      }
      if (val.isNotEmpty) {
        _runtimeKey = val;
        if (kDebugMode) {
          // ignore: avoid_print
          print('[OpenAI] openai.env から API キーを読み込みました（${val.length} 文字）');
        }
        return;
      }
    }
    if (kDebugMode) {
      // ignore: avoid_print
      print(
        '[OpenAI] assets/config/openai.env に OPENAI_API_KEY= の値がありません。'
        '「=」の右に sk-... を書いて保存し、アプリを再起動してください。',
      );
    }
  } catch (e, st) {
    if (kDebugMode) {
      // ignore: avoid_print
      print('[OpenAI] openai.env の読み込みエラー: $e\n$st');
    }
  }
}

/// OpenAI API キー（DALL-E キャラ生成用）
///
/// **優先順位**
/// 1. `--dart-define=OPENAI_API_KEY=sk-...`（CI / 本番ビルド向け）
/// 2. [loadOpenAiEnvFromAssets] で読んだ値、または flutter_dotenv
/// 3. `assets/config/openai.env`（dotenv）
///
/// ターミナルの `export OPENAI_API_KEY=...` だけでは反映されません。
String get openAiApiKey {
  const fromDefine = String.fromEnvironment('OPENAI_API_KEY', defaultValue: '');
  if (fromDefine.isNotEmpty) {
    return fromDefine;
  }
  if (_runtimeKey.isNotEmpty) {
    return _runtimeKey;
  }
  try {
    final v = dotenv.env['OPENAI_API_KEY']?.trim() ?? '';
    if (v.isNotEmpty) {
      return v;
    }
  } catch (_) {
    // dotenv 未ロード時は空扱い
  }
  return '';
}
