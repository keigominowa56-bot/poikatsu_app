import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:poigo/models/slot_settings_model.dart';
import 'package:poigo/services/slot_settings_service.dart';
import 'package:poigo/services/user_firestore_service.dart';
import 'package:poigo/theme/app_colors.dart';
import 'package:poigo/widgets/video_reward_dialog.dart';

class SlotScreen extends StatefulWidget {
  const SlotScreen({super.key, required this.uid});
  final String uid;

  @override
  State<SlotScreen> createState() => _SlotScreenState();
}

class _SlotScreenState extends State<SlotScreen> {
  static const int _cost = 3;
  final _symbols = const ['💎', '🪙', '⭐️', '🍀', '🦔', '🎁'];
  final _rng = math.Random();

  bool _spinning = false;
  String _s1 = '⭐️';
  String _s2 = '⭐️';
  String _s3 = '⭐️';

  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// 絵柄から配当を計算。3揃い > 2揃い > はずれ
  int _payoutFromSymbols(String s1, String s2, String s3, double multiplier) {
    final three = s1 == s2 && s2 == s3;
    final two = s1 == s2 || s2 == s3 || s1 == s3;
    if (three) return (3 * multiplier).round().clamp(1, 1 << 30);
    if (two) return (2 * multiplier).round().clamp(1, 1 << 30);
    return 0;
  }

  /// チップ消費してスピン
  Future<void> _spinWithChips() async {
    if (_spinning) return;
    final ok = await UserFirestoreService.instance.tryConsumePoints(widget.uid, _cost);
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('チップが足りません（3チップ必要）')));
      return;
    }
    await _doSpin();
  }

  /// 動画視聴後にスピン（チップ消費なし）
  Future<void> _spinWithVideo() async {
    if (_spinning) return;
    showVideoRewardDialog(
      context: context,
      title: '動画を見てスロットを回す',
      subtitle: '視聴完了で1回スピンできます。',
      onComplete: () async {
        if (!mounted) return;
        await _doSpin();
      },
    );
  }

  /// リール回転と結果判定・配当（共通）
  Future<void> _doSpin() async {
    if (_spinning) return;
    setState(() => _spinning = true);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 80), (_) {
      if (!mounted) return;
      setState(() {
        _s1 = _symbols[_rng.nextInt(_symbols.length)];
        _s2 = _symbols[_rng.nextInt(_symbols.length)];
        _s3 = _symbols[_rng.nextInt(_symbols.length)];
      });
    });

    await Future<void>.delayed(const Duration(milliseconds: 1200));
    _timer?.cancel();
    if (!mounted) return;

    final settings = await SlotSettingsService.instance.getOnce();
    final payout = _payoutFromSymbols(_s1, _s2, _s3, settings.payoutMultiplier);

    if (payout > 0) {
      await UserFirestoreService.instance.grantPoints(widget.uid, payout);
      await UserFirestoreService.instance.logEarning(widget.uid, 'スロット', payout);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('当たり！ +$payout チップ')),
      );
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('はずれ… また挑戦してね')));
      }
    }

    if (mounted) setState(() => _spinning = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('3チップ・スロット', style: TextStyle(color: AppColors.textPrimary)),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.cardWhite,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primaryYellow.withOpacity(0.25)),
                  boxShadow: [
                    BoxShadow(color: AppColors.navy.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2)),
                  ],
                ),
                child: Column(
                  children: [
                    Text('3チップで1回、または動画視聴で1回', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _Reel(symbol: _s1),
                        const SizedBox(width: 10),
                        _Reel(symbol: _s2),
                        const SizedBox(width: 10),
                        _Reel(symbol: _s3),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _spinning ? null : _spinWithChips,
                icon: const Icon(Icons.casino_rounded),
                label: Text(_spinning ? '回転中…' : 'スピンする（$_cost チップ）'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryYellow,
                  foregroundColor: AppColors.navy,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _spinning ? null : _spinWithVideo,
                icon: const Icon(Icons.play_circle_filled),
                label: const Text('動画を見て回す'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.navy,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: BorderSide(color: AppColors.primaryYellow),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 24),
              FutureBuilder<SlotSettings>(
                future: SlotSettingsService.instance.getOnce(),
                builder: (context, snap) {
                  if (!snap.hasData) return const SizedBox.shrink();
                  final s = snap.data!;
                  final threePayout = (3 * s.payoutMultiplier).round().clamp(1, 1 << 30);
                  final twoPayout = (2 * s.payoutMultiplier).round().clamp(1, 1 << 30);
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.cardWhite,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.textSecondary.withOpacity(0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('当たり表', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                        const SizedBox(height: 12),
                        _payRow('同じ絵柄が3つ揃う', '$threePayout チップ'),
                        const SizedBox(height: 6),
                        _payRow('同じ絵柄が2つ揃う', '$twoPayout チップ'),
                        const SizedBox(height: 6),
                        _payRow('それ以外', 'はずれ'),
                        const SizedBox(height: 8),
                        Text('絵柄: 💎 🪙 ⭐️ 🍀 🦔 🎁', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _payRow(String condition, String payout) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(condition, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary)),
        Text(payout, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.navy)),
      ],
    );
  }
}

class _Reel extends StatelessWidget {
  const _Reel({required this.symbol});
  final String symbol;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 90,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.textSecondary.withOpacity(0.2)),
      ),
      child: Text(symbol, style: const TextStyle(fontSize: 40)),
    );
  }
}

