import 'package:flutter/material.dart';

import 'package:poigo/models/fortune_settings_model.dart';

import '../../services/admin_fortune_settings_service.dart';

/// 占いの運営設定を編集する画面（今日のお告げ・luckyFactor・specialEvent）
class FortuneSettingsScreen extends StatefulWidget {
  const FortuneSettingsScreen({super.key});

  @override
  State<FortuneSettingsScreen> createState() => _FortuneSettingsScreenState();
}

class _FortuneSettingsScreenState extends State<FortuneSettingsScreen> {
  final _globalMessageController = TextEditingController();
  final _luckyFactorController = TextEditingController();
  final _specialEventController = TextEditingController();
  bool _saving = false;
  bool _aiLoading = false;
  List<String> _aiSuggestions = [];
  bool _initialized = false;

  @override
  void dispose() {
    _globalMessageController.dispose();
    _luckyFactorController.dispose();
    _specialEventController.dispose();
    super.dispose();
  }

  void _applySettingsOnce(FortuneSettingsModel s) {
    if (_initialized) return;
    _initialized = true;
    _globalMessageController.text = s.globalMessage;
    _luckyFactorController.text = s.luckyFactor == 1.0 ? '' : s.luckyFactor.toString();
    _specialEventController.text = s.specialEvent;
  }

  Future<void> _publish() async {
    if (_saving) return;
    final factorStr = _luckyFactorController.text.trim();
    double factor = 1.0;
    if (factorStr.isNotEmpty) {
      factor = double.tryParse(factorStr) ?? 1.0;
      factor = factor.clamp(0.1, 3.0);
    }
    setState(() => _saving = true);
    try {
      await AdminFortuneSettingsService.instance.publish(FortuneSettingsModel(
        globalMessage: _globalMessageController.text.trim(),
        luckyFactor: factor,
        specialEvent: _specialEventController.text.trim(),
        updatedAt: DateTime.now(),
      ));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('配信しました')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// AIアシスト: 3パターンのポジティブなお告げを提案（モック。実際のAI APIに差し替え可能）
  Future<void> _generateAiSuggestions() async {
    if (_aiLoading) return;
    setState(() {
      _aiLoading = true;
      _aiSuggestions = [];
    });
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    final now = DateTime.now();
    final day = now.day;
    final patterns = [
      '今日は小さな一歩が大きな運気を呼びます。いつも通りで大丈夫。',
      'あなたの優しさが今日、誰かの支えになります。そのままのあなたで。',
      '今日という日は二度と来ません。大切な人に想いを伝えてみては？',
      '新しいことに手を伸ばすと、思わぬ幸運が舞い込む日です。',
      '焦らなくて大丈夫。あなたのペースで進むと、道が開けます。',
      '今日のあなたの笑顔が、誰かのラッキーになります。',
      '小さな感謝を口にすると、運気がぐんと上がる一日です。',
      'いつも頑張っているあなたへ。今日は自分を褒めてあげて。',
      '人との縁を大切にすると、良い流れが生まれます。',
    ];
    final suggestions = <String>[];
    for (var i = 0; i < 3; i++) {
      suggestions.add(patterns[(day + i * 3) % patterns.length]);
    }
    setState(() {
      _aiSuggestions = suggestions;
      _aiLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return StreamBuilder<FortuneSettingsModel>(
      stream: AdminFortuneSettingsService.instance.streamFortuneSettings(),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data != null) {
          _applySettingsOnce(snapshot.data!);
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '占いコンテンツの配信',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'ここで設定した内容が、アプリの診断結果に反映されます。',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: theme.colorScheme.outlineVariant),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            '今日の一言（運営からのお告げ）',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 12),
                          FilledButton.tonalIcon(
                            onPressed: _aiLoading ? null : _generateAiSuggestions,
                            icon: _aiLoading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.auto_awesome, size: 18),
                            label: Text(_aiLoading ? '生成中...' : '今日のポジティブなお告げをAIで生成'),
                          ),
                        ],
                      ),
                      if (_aiSuggestions.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        ..._aiSuggestions.map((text) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: InkWell(
                            onTap: () {
                              _globalMessageController.text = text;
                              setState(() => _aiSuggestions = []);
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.lightbulb_outline, size: 20, color: theme.colorScheme.primary),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      text,
                                      style: theme.textTheme.bodyMedium,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '採用',
                                    style: theme.textTheme.labelMedium?.copyWith(
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )),
                        const SizedBox(height: 12),
                      ],
                      const SizedBox(height: 8),
                      TextField(
                        controller: _globalMessageController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: '例: 今日は新しい出会いのチャンスが訪れる日です。',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: theme.colorScheme.surfaceContainerLowest,
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        '運勢スコアの倍率（luckyFactor）',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _luckyFactorController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          hintText: '空欄で1.0。例: 1.2 で20%底上げ',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: theme.colorScheme.surfaceContainerLowest,
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        '特別日のラベル（specialEvent）',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _specialEventController,
                        decoration: InputDecoration(
                          hintText: '例: 大安・一粒万倍日・寅の日',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: theme.colorScheme.surfaceContainerLowest,
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _saving ? null : _publish,
                          icon: _saving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.send),
                          label: const Text('配信'),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
