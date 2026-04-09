import 'package:flutter/material.dart';
import 'package:poigo/constants/point_constants.dart';
import 'package:poigo/models/point_history_entry_model.dart';
import 'package:poigo/models/user_model.dart';
import 'package:poigo/services/ad_service.dart';
import 'package:poigo/services/point_history_service.dart';
import 'package:poigo/services/user_firestore_service.dart';
import 'package:poigo/theme/app_colors.dart';

/// 収益通帳: サマリーカード・直近1週間グラフ・履歴一覧
class EarningsLedgerScreen extends StatelessWidget {
  const EarningsLedgerScreen({super.key, required this.uid});
  final String uid;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: StreamBuilder<UserModel?>(
        stream: UserFirestoreService.instance.streamUser(uid),
        builder: (context, userSnap) {
          final user = userSnap.data;
          final totalSteps = user?.totalSteps ?? 0;
          return StreamBuilder<List<PointHistoryEntry>>(
            stream: PointHistoryService.instance.streamPointHistory(uid),
            builder: (context, historySnap) {
              final history = historySnap.data ?? [];
              final todayTotal = _todayTotal(history);
              final weekData = _last7DaysData(history);
              return CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                      child: Row(
                        children: [
                          Icon(Icons.account_balance_wallet_rounded, color: AppColors.navy, size: 28),
                          const SizedBox(width: 10),
                          Text(
                            '収益通帳',
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _SummaryCards(todayChips: todayTotal, totalSteps: totalSteps),
                          const SizedBox(height: 24),
                          _WeekBarChart(data: weekData),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Icon(Icons.list_alt_rounded, size: 20, color: AppColors.navy),
                              const SizedBox(width: 8),
                              Text(
                                '取引明細',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),
                  if (history.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.receipt_long_rounded, size: 56, color: AppColors.textSecondary.withOpacity(0.5)),
                              const SizedBox(height: 16),
                              Text(
                                'まだ取引がありません',
                                style: TextStyle(fontSize: 15, color: AppColors.textSecondary),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'チップを獲得するとここに記録されます',
                                style: TextStyle(fontSize: 13, color: AppColors.textSecondary.withOpacity(0.8)),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => _LedgerRow(entry: history[index]),
                          childCount: history.length,
                        ),
                      ),
                    ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                      child: Center(child: AdService.getBannerWidget()),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  static int _todayTotal(List<PointHistoryEntry> history) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return history
        .where((e) => e.createdAt.isAfter(today) || e.createdAt.isAtSameMomentAs(today))
        .fold<int>(0, (s, e) => s + e.amount);
  }

  static List<int> _last7DaysData(List<PointHistoryEntry> history) {
    final now = DateTime.now();
    final days = List<int>.filled(7, 0);
    for (var i = 0; i < 7; i++) {
      final dayStart = DateTime(now.year, now.month, now.day).subtract(Duration(days: 6 - i));
      final dayEnd = dayStart.add(const Duration(days: 1));
      final sum = history
          .where((e) => !e.createdAt.isBefore(dayStart) && e.createdAt.isBefore(dayEnd))
          .fold<int>(0, (s, e) => s + e.amount);
      days[i] = sum;
    }
    return days;
  }
}

class _SummaryCards extends StatelessWidget {
  const _SummaryCards({required this.todayChips, required this.totalSteps});
  final int todayChips;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            icon: Icons.stars_rounded,
            label: '今日の獲得チップ',
            value: PointConstants.formatChips(todayChips),
            unit: 'チップ',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryCard(
            icon: Icons.directions_walk_rounded,
            label: '累計歩数',
            value: '$totalSteps',
            unit: '歩',
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
  });
  final IconData icon;
  final String label;
  final String value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: AppColors.primaryYellow.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppColors.primaryYellow),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.navy),
              ),
              const SizedBox(width: 4),
              Text(unit, style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }
}

class _WeekBarChart extends StatelessWidget {
  const _WeekBarChart({required this.data});
  final List<int> data;

  @override
  Widget build(BuildContext context) {
    if (data.length != 7) return const SizedBox.shrink();
    final maxVal = data.isEmpty ? 1 : data.reduce((a, b) => a > b ? a : b);
    final maxHeight = maxVal > 0 ? maxVal.toDouble() : 1.0;
    final labels = _last7DayLabels();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryYellow.withOpacity(0.25)),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bar_chart_rounded, size: 18, color: AppColors.navy),
              const SizedBox(width: 6),
              Text(
                '直近7日間の獲得チップ',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 80,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (i) {
                final h = maxHeight > 0 ? (data[i] / maxHeight) * 64 : 0.0;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          PointConstants.formatChips(data[i]),
                          style: TextStyle(fontSize: 9, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          height: h.clamp(4.0, 64.0),
                          decoration: BoxDecoration(
                            color: AppColors.primaryYellow.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          labels[i],
                          style: TextStyle(fontSize: 9, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  static List<String> _last7DayLabels() {
    final now = DateTime.now();
    return List.generate(7, (i) {
      final d = now.subtract(Duration(days: 6 - i));
      return '${d.month}/${d.day}';
    });
  }
}

class _LedgerRow extends StatelessWidget {
  const _LedgerRow({required this.entry});
  final PointHistoryEntry entry;

  static String _reasonLabel(String reason) {
    switch (reason) {
      case '読了':
        return 'ニュース読了';
      case 'くじ':
        return '動画くじ';
      case '歩数':
        return '歩数';
      case '歩数タンク':
        return '歩数';
      case '友達紹介':
        return '友達紹介';
      case 'お世話':
        return 'お世話';
      default:
        return reason.isEmpty ? '獲得' : reason;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = '${entry.createdAt.month}/${entry.createdAt.day}';
    final timeStr = '${entry.createdAt.hour.toString().padLeft(2, '0')}:${entry.createdAt.minute.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.surface),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryYellow.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.monetization_on_rounded, size: 22, color: AppColors.navy),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _reasonLabel(entry.reason),
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  '$dateStr $timeStr',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Text(
            '+${PointConstants.formatChips(entry.amount)}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.navy),
          ),
          const SizedBox(width: 4),
          Text(
            'チップ',
            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
