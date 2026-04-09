import 'package:flutter/material.dart';

import '../services/ad_service.dart';
import '../services/economy_settings_service.dart';
import '../services/user_firestore_service.dart';

/// 読了ボーナス用: 動画視聴完了時のみチップ付与。キャンセル時は onDismissed でアラート表示想定。
Future<void> showPointRewardChoiceDialog({
  required BuildContext context,
  required String uid,
  required VoidCallback onComplete,
}) async {
  final settings = await EconomySettingsService.instance.getEconomySettingsOnce();
  if (!context.mounted) return;
  final videoPoints = settings.readBonusVideoMultiplier;
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => _PointRewardChoiceDialog(
      uid: uid,
      videoPoints: videoPoints,
      onComplete: () {
        Navigator.of(ctx).pop();
        onComplete();
      },
    ),
  );
}

class _PointRewardChoiceDialog extends StatelessWidget {
  const _PointRewardChoiceDialog({
    required this.uid,
    required this.videoPoints,
    required this.onComplete,
  });

  final String uid;
  final int videoPoints;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('チップ獲得'),
      content: Text(
        '動画を最後まで視聴すると${videoPoints}チップがもらえます。',
        style: const TextStyle(height: 1.4),
      ),
      actions: [
        FilledButton.icon(
          onPressed: () {
            showVideoRewardDialog(
              context: context,
              title: '動画を見てチップを獲得',
              subtitle: '視聴完了で${videoPoints}チップが付与されます。',
              onComplete: () async {
                await UserFirestoreService.instance.grantReadBonusVideoMultiplier(uid);
                onComplete();
              },
              onDismissed: () {
                if (!context.mounted) return;
                showDialog<void>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('チップを受け取るには'),
                    content: const Text(
                      '動画を最後まで見るとチップがもらえます。',
                      style: TextStyle(height: 1.4),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
              },
            );
          },
          icon: const Icon(Icons.play_circle_filled),
          label: const Text('動画を見てチップを獲得！'),
        ),
      ],
    );
  }
}

/// リワード広告を表示。視聴完了（onUserEarnedReward）で onComplete を呼ぶ。
/// 広告を閉じて報酬未獲得の場合は onDismissed を呼ぶ。
/// 広告が表示できない場合はプレースホルダを表示し、「視聴完了」タップで onComplete、「閉じる」で onDismissed を呼ぶ。
void showVideoRewardDialog({
  required BuildContext context,
  required VoidCallback onComplete,
  String title = '広告（プレースホルダ）',
  String subtitle = '本番ではここに動画広告が表示されます。',
  VoidCallback? onDismissed,
}) {
  AdService.showRewardAd(
    context: context,
    onComplete: () {
      onComplete();
    },
    onDismissed: onDismissed,
    onFallback: () {
      if (!context.mounted) return;
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.black87,
        builder: (ctx) => _VideoRewardDialog(
          title: title,
          subtitle: subtitle,
          onClosed: () {
            Navigator.of(ctx).pop();
            onComplete();
          },
          onDismissed: () {
            Navigator.of(ctx).pop();
            onDismissed?.call();
          },
        ),
      );
    },
  );
}

class _VideoRewardDialog extends StatelessWidget {
  const _VideoRewardDialog({
    required this.title,
    required this.subtitle,
    required this.onClosed,
    VoidCallback? onDismissed,
  }) : _onDismissed = onDismissed;

  final String title;
  final String subtitle;
  final VoidCallback onClosed;
  final VoidCallback? _onDismissed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black87,
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.play_circle_filled_rounded,
              size: 80,
              color: Colors.white.withOpacity(0.9),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white.withOpacity(0.95),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
            ),
            const SizedBox(height: 48),
            FilledButton(
              onPressed: onClosed,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black87,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: const Text('視聴完了'),
            ),
            if (_onDismissed != null) ...[
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => _onDismissed!(),
                child: Text(
                  '閉じる',
                  style: TextStyle(color: Colors.white.withOpacity(0.8)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
