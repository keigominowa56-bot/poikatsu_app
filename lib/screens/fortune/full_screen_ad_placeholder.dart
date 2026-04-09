import 'package:flutter/material.dart';

/// 解析ボタン押下直後に表示するフルスクリーン広告のプレースホルダ。
/// 広告終了後に [onClosed] で最終結果画面へ遷移する。
class FullScreenAdPlaceholder extends StatelessWidget {
  const FullScreenAdPlaceholder({
    super.key,
    required this.onClosed,
  });

  final VoidCallback onClosed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black87,
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.campaign_rounded,
              size: 80,
              color: Colors.white.withOpacity(0.9),
            ),
            const SizedBox(height: 24),
            Text(
              '広告（プレースホルダ）',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white.withOpacity(0.95),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                '本番ではここにフルスクリーン広告が表示されます。',
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
              child: const Text('閉じる'),
            ),
          ],
        ),
      ),
    );
  }
}
