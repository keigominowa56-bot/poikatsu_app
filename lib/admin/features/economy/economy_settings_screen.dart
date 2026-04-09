import 'package:flutter/material.dart';

import 'package:poigo/models/economy_settings_model.dart';

import '../../services/admin_economy_settings_service.dart';

/// 経済圏管理パネル: 動画連動・くじのパラメータを編集
class EconomySettingsScreen extends StatefulWidget {
  const EconomySettingsScreen({super.key});

  @override
  State<EconomySettingsScreen> createState() => _EconomySettingsScreenState();
}

class _EconomySettingsScreenState extends State<EconomySettingsScreen> {
  final _maxPerDayController = TextEditingController();
  final _refillCountController = TextEditingController();
  final _basePointsController = TextEditingController();
  final _videoMultiplierController = TextEditingController();
  final _lotteryMinController = TextEditingController();
  final _lotteryMaxController = TextEditingController();
  final _referralInviterController = TextEditingController();
  final _referralInviteeController = TextEditingController();
  final _videoLotteryMaxController = TextEditingController();
  bool _saving = false;
  bool _initialized = false;

  @override
  void dispose() {
    _maxPerDayController.dispose();
    _refillCountController.dispose();
    _basePointsController.dispose();
    _videoMultiplierController.dispose();
    _lotteryMinController.dispose();
    _lotteryMaxController.dispose();
    _referralInviterController.dispose();
    _referralInviteeController.dispose();
    _videoLotteryMaxController.dispose();
    super.dispose();
  }

  void _applyOnce(EconomySettingsModel s) {
    if (_initialized) return;
    _initialized = true;
    _maxPerDayController.text = s.newsReadBonusMaxPerDay.toString();
    _refillCountController.text = s.newsRefillCount.toString();
    _basePointsController.text = s.readBonusBasePoints.toString();
    _videoMultiplierController.text = s.readBonusVideoMultiplier.toString();
    _lotteryMinController.text = s.lotteryMinPt.toString();
    _lotteryMaxController.text = s.lotteryMaxPt.toString();
    _referralInviterController.text = s.referralPointsInviter.toString();
    _referralInviteeController.text = s.referralPointsInvitee.toString();
    _videoLotteryMaxController.text = s.videoLotteryMaxPerDay.toString();
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final s = EconomySettingsModel(
        newsReadBonusMaxPerDay: int.tryParse(_maxPerDayController.text) ?? 5,
        newsRefillCount: int.tryParse(_refillCountController.text) ?? 5,
        readBonusBasePoints: int.tryParse(_basePointsController.text) ?? 1,
        readBonusVideoMultiplier: int.tryParse(_videoMultiplierController.text) ?? 25,
        lotteryMinPt: int.tryParse(_lotteryMinController.text) ?? 1,
        lotteryMaxPt: int.tryParse(_lotteryMaxController.text) ?? 5,
        referralPointsInviter: int.tryParse(_referralInviterController.text) ?? 10,
        referralPointsInvitee: int.tryParse(_referralInviteeController.text) ?? 10,
        videoLotteryMaxPerDay: int.tryParse(_videoLotteryMaxController.text) ?? 5,
        updatedAt: DateTime.now(),
      );
      await AdminEconomySettingsService.instance.save(s);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('経済圏設定を保存しました')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return StreamBuilder<EconomySettingsModel>(
      stream: AdminEconomySettingsService.instance.streamEconomySettings(),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data != null) {
          _applyOnce(snapshot.data!);
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '経済圏管理パネル',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '動画連動・くじのパラメータを調整できます。',
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
                      Text(
                        'ニュース読了ボーナス',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _maxPerDayController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: '1日最大回数',
                          hintText: '5',
                          border: OutlineInputBorder(),
                          filled: true,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _refillCountController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'おかわり: 動画視聴で追加する回数',
                          hintText: '5',
                          border: OutlineInputBorder(),
                          filled: true,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'ポイント倍増（占い・読了後）',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _basePointsController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'そのまま受け取るポイント',
                          hintText: '1',
                          border: OutlineInputBorder(),
                          filled: true,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _videoMultiplierController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: '動画視聴で受け取るポイント',
                          hintText: '3',
                          border: OutlineInputBorder(),
                          filled: true,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        '動画くじ',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _lotteryMinController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: '最小pt',
                                hintText: '1',
                                border: OutlineInputBorder(),
                                filled: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextField(
                              controller: _lotteryMaxController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: '最大pt',
                                hintText: '5',
                                border: OutlineInputBorder(),
                                filled: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text(
                        '友達紹介',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _referralInviterController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: '紹介者に付与するpt',
                                hintText: '10',
                                border: OutlineInputBorder(),
                                filled: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextField(
                              controller: _referralInviteeController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: '被紹介者に付与するpt',
                                hintText: '10',
                                border: OutlineInputBorder(),
                                filled: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text(
                        '動画くじ 24時間あたり最大回数',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _videoLotteryMaxController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: '最大回数',
                          hintText: '5',
                          border: OutlineInputBorder(),
                          filled: true,
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _saving ? null : _save,
                          icon: _saving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.save),
                          label: const Text('保存'),
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
