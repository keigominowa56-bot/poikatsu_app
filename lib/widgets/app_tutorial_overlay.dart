import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../services/tutorial_prefs.dart';

/// 初回起動時の簡易チュートリアル（全画面オーバーレイ）
class AppTutorialOverlay extends StatefulWidget {
  const AppTutorialOverlay({super.key, required this.onFinish});

  final VoidCallback onFinish;

  @override
  State<AppTutorialOverlay> createState() => _AppTutorialOverlayState();
}

class _AppTutorialOverlayState extends State<AppTutorialOverlay> {
  final PageController _pageController = PageController();
  int _index = 0;

  static const _pages = <_TutorialPage>[
    _TutorialPage(
      title: '歩いてチップを貯める',
      body: '歩数でタンクが溜まり、チップに交換できます。まずはホームで今日の歩数を確認しましょう。',
      icon: Icons.directions_walk_rounded,
    ),
    _TutorialPage(
      title: 'タンクと動画ボーナス',
      body: 'タンクが満タンになったら動画を見て多めのチップをゲット。くじやスロットも試せます。',
      icon: Icons.play_circle_fill_rounded,
    ),
    _TutorialPage(
      title: '交換とお得タブ',
      body: '貯めたチップは「交換」からデジコ経由でギフトに。お得タブやイチオシも要チェックです。',
      icon: Icons.card_giftcard_rounded,
    ),
    _TutorialPage(
      title: 'はじめましょう',
      body: '相棒キャラは歩いて成長します。レベルが上がると見た目も変化。楽しんでポイ活してください！',
      icon: Icons.pets_rounded,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _done() async {
    await TutorialPrefs.setCompleted();
    widget.onFinish();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black54,
      child: SafeArea(
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.cardWhite,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.navy.withValues(alpha: 0.15),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 220,
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _pages.length,
                    onPageChanged: (i) => setState(() => _index = i),
                    itemBuilder: (context, i) {
                      final p = _pages[i];
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(p.icon, size: 56, color: AppColors.navy),
                          const SizedBox(height: 16),
                          Text(
                            p.title,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            p.body,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.45,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _pages.length,
                    (i) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i == _index
                            ? AppColors.primaryOrange
                            : AppColors.textSecondary.withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    if (_index > 0)
                      TextButton(
                        onPressed: () {
                          _pageController.previousPage(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeOut,
                          );
                        },
                        child: const Text('戻る'),
                      )
                    else
                      const SizedBox(width: 64),
                    const Spacer(),
                    if (_index < _pages.length - 1)
                      FilledButton(
                        onPressed: () {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeOut,
                          );
                        },
                        child: const Text('次へ'),
                      )
                    else
                      FilledButton(
                        onPressed: _done,
                        child: const Text('はじめる'),
                      ),
                  ],
                ),
                TextButton(
                  onPressed: _done,
                  child: Text(
                    'スキップ',
                    style: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.9)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TutorialPage {
  const _TutorialPage({
    required this.title,
    required this.body,
    required this.icon,
  });
  final String title;
  final String body;
  final IconData icon;
}
