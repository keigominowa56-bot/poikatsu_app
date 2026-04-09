import 'package:flutter/material.dart';
import 'package:poigo/admin/services/admin_lottery_service.dart';
import 'package:poigo/models/lottery_draw_model.dart';

/// 宝くじ管理：回号設定・当選番号/等級チップ数の発表
class LotteryManageScreen extends StatefulWidget {
  const LotteryManageScreen({super.key});

  @override
  State<LotteryManageScreen> createState() => _LotteryManageScreenState();
}

class _LotteryManageScreenState extends State<LotteryManageScreen> {
  final _roundController = TextEditingController();
  final _groupController = TextEditingController();
  final _numberController = TextEditingController();
  final _firstController = TextEditingController();
  final _secondController = TextEditingController();
  final _thirdController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _roundController.dispose();
    _groupController.dispose();
    _numberController.dispose();
    _firstController.dispose();
    _secondController.dispose();
    _thirdController.dispose();
    super.dispose();
  }

  Future<void> _publish() async {
    final round = _roundController.text.trim();
    final group = int.tryParse(_groupController.text.trim()) ?? 1;
    final number = _numberController.text.trim();
    if (round.isEmpty || number.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('回号と6桁番号は必須です')));
      return;
    }
    final first = int.tryParse(_firstController.text.trim()) ?? 0;
    final second = int.tryParse(_secondController.text.trim()) ?? 0;
    final third = int.tryParse(_thirdController.text.trim()) ?? 0;
    final roundNum = int.tryParse(round);
    if (roundNum != null) {
      final alreadyPublished = await AdminLotteryService.instance.hasDraw(round);
      if (alreadyPublished && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('この回は既に発表済みです。内容を更新する場合はそのまま保存できます。')),
        );
      }
    }
    setState(() => _saving = true);
    try {
      await AdminLotteryService.instance.publishDraw(
        round: round,
        winningGroup: group.clamp(1, 10),
        winningNumber: number.padLeft(6, '0').substring(0, 6),
        prizeFirst: first,
        prizeSecond: second,
        prizeThird: third,
      );
      if (roundNum != null) {
        await AdminLotteryService.instance.setCurrentRound((roundNum + 1).toString());
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('当選発表を保存しました。新規発行は次の回になります。')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return StreamBuilder<String>(
      stream: AdminLotteryService.instance.streamCurrentRound(),
      builder: (context, roundSnap) {
        if (roundSnap.hasData && _roundController.text.isEmpty) {
          _roundController.text = roundSnap.data!;
        }
        return StreamBuilder<List<LotteryDraw>>(
          stream: AdminLotteryService.instance.streamDraws(),
          builder: (context, drawsSnap) {
            final draws = drawsSnap.data ?? [];
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('宝くじ管理', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('当選番号（組・番号）と等級ごとの当選チップ数を発表します。', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _roundController,
                          decoration: const InputDecoration(labelText: '回号（例: 2026-03）', border: OutlineInputBorder()),
                        ),
                      ),
                      const SizedBox(width: 12),
                      FilledButton(
                        onPressed: _saving ? null : _publish,
                        child: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('発表/更新'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _groupController,
                          decoration: const InputDecoration(labelText: '当選 組（1-10）', border: OutlineInputBorder()),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: _numberController,
                          decoration: const InputDecoration(labelText: '当選 番号（6桁）', border: OutlineInputBorder()),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _firstController,
                          decoration: const InputDecoration(labelText: '1等チップ', border: OutlineInputBorder()),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _secondController,
                          decoration: const InputDecoration(labelText: '2等チップ', border: OutlineInputBorder()),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _thirdController,
                          decoration: const InputDecoration(labelText: '3等チップ', border: OutlineInputBorder()),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  Text('過去の発表', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  if (draws.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Center(child: Text('まだ発表がありません', style: theme.textTheme.bodyMedium)),
                      ),
                    )
                  else
                    ...draws.map((d) => Card(
                          child: ListTile(
                            title: Text('第${d.round}回  ${d.winningGroup}組 ${d.winningNumber}'),
                            subtitle: Text('1等 ${d.prizeFirst} / 2等 ${d.prizeSecond} / 3等 ${d.prizeThird} チップ'),
                          ),
                        )),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

