import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:poigo/constants/point_constants.dart';
import 'package:poigo/services/user_firestore_service.dart';
import 'package:poigo/theme/app_colors.dart';

class RankingScreen extends StatelessWidget {
  const RankingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('ランキング', style: TextStyle(color: AppColors.textPrimary)),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .orderBy('totalEarnedChips', descending: true)
            .limit(100)
            .snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primaryYellow));
          }
          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) {
            return Center(
              child: Text('ランキングデータがありません', style: TextStyle(color: AppColors.textSecondary)),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final d = docs[index].data();
              final nickname = (d['displayName'] as String?)?.trim();
              final earned = (d['totalEarnedChips'] as num?)?.toInt() ?? 0;
              final rankName = UserFirestoreService.rankNameFromEarned(earned);
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.cardWhite,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primaryYellow.withOpacity(0.2)),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.navy.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    _RankBadge(rank: index + 1),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            nickname != null && nickname.isNotEmpty ? nickname : '匿名ユーザー',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            rankName,
                            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.stars_rounded, size: 18, color: AppColors.primaryYellow),
                    const SizedBox(width: 4),
                    Text(
                      PointConstants.formatChips(earned),
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.navy),
                    ),
                    const SizedBox(width: 4),
                    Text('チップ', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _RankBadge extends StatelessWidget {
  const _RankBadge({required this.rank});
  final int rank;

  @override
  Widget build(BuildContext context) {
    final isTop3 = rank <= 3;
    final bg = isTop3 ? AppColors.primaryYellow.withOpacity(0.35) : AppColors.surface;
    final fg = isTop3 ? AppColors.navy : AppColors.textSecondary;
    return Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$rank',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: fg),
      ),
    );
  }
}

