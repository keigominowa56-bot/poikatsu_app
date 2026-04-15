import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/openai_config.dart';
import '../models/user_model.dart';
import 'openai_character_service.dart';
import 'user_firestore_service.dart';

/// レベル3到達時に1回だけ、無料で AI 画像生成を提案する（OPENAI_API_KEY がある場合のみ）
class LevelUpAiOffer {
  LevelUpAiOffer._();

  static const _prefsKeyPrefix = 'free_ai_mascot_done_v1_';

  static Future<void> maybeOffer({
    required BuildContext context,
    required String uid,
    required int fromLevel,
    required int toLevel,
    UserModel? user,
  }) async {
    if (!context.mounted) return;
    if (openAiApiKey.isEmpty) return;
    if (toLevel < 3 || fromLevel >= 3) return;
    final existing = user?.customCharacterImageUrl;
    if (existing != null && existing.isNotEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('$_prefsKeyPrefix$uid') == true) return;

    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (!context.mounted) return;

    final go = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('レベルアップおめでとう！'),
        content: const Text(
          'AIで相棒のオリジナル画像を、1回だけ無料で生成できます。\n'
          '（あとからでも「相棒」欄のボタンから生成可能です。APIキーがビルドに含まれている場合のみ）',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('あとで'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('生成する'),
          ),
        ],
      ),
    );
    if (go != true || !context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('画像を生成しています…')),
    );
    const prompt =
        '歩いて成長するマスコットキャラクター、明るい色、シンプルなゲーム風イラスト、全身、白背景';
    final gen = await OpenAiCharacterService.instance.generateCharacterImage(prompt);
    if (!context.mounted) return;
    if (!gen.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(gen.errorMessage ?? '生成に失敗しました')),
      );
      return;
    }
    await UserFirestoreService.instance.saveCustomCharacter(uid, gen.imageUrl!, prompt);
    await prefs.setBool('$_prefsKeyPrefix$uid', true);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('相棒の画像を設定しました！')),
      );
    }
  }
}
