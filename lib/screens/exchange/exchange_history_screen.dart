import 'package:flutter/material.dart';
import 'package:poigo/constants/point_constants.dart';
import 'package:poigo/models/exchange_history_entry.dart';
import 'package:poigo/services/exchange_history_service.dart';
import 'package:poigo/theme/app_colors.dart';
import 'package:url_launcher/url_launcher.dart';

/// 過去のギフト交換を確認（URL紛失時の再表示用）
class ExchangeHistoryScreen extends StatelessWidget {
  const ExchangeHistoryScreen({super.key, required this.uid});

  final String uid;

  static String _formatDate(DateTime d) {
    final y = d.year;
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    final h = d.hour.toString().padLeft(2, '0');
    final min = d.minute.toString().padLeft(2, '0');
    return '$y/$m/$day $h:$min';
  }

  Future<void> _openGiftUrl(String url) async {
    if (url.isEmpty) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('交換履歴'),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
      ),
      backgroundColor: AppColors.background,
      body: StreamBuilder<List<ExchangeHistoryEntry>>(
        stream: ExchangeHistoryService.instance.streamExchangeHistory(uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primaryOrange));
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  '読み込みに失敗しました\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ),
            );
          }
          final list = snapshot.data ?? [];
          if (list.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'まだ交換履歴がありません。',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final e = list[i];
              final dateStr =
                  e.createdAt != null ? _formatDate(e.createdAt!.toLocal()) : '—';
              return Material(
                color: AppColors.cardWhite,
                borderRadius: BorderRadius.circular(14),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dateStr,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (e.yen != null)
                        Text(
                          '${e.yen}円相当',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                        ),
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            PointConstants.formatChips(e.amount),
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppColors.navy,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'チップ消費',
                            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                      if (e.managementNo.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          '管理番号: ${e.managementNo}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: e.giftUrl.isEmpty ? null : () => _openGiftUrl(e.giftUrl),
                          icon: const Icon(Icons.card_giftcard_rounded, size: 20),
                          label: const Text('ギフトを受け取る'),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primaryOrange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
