import 'package:flutter/material.dart';
import 'package:poigo/models/affiliate_mission_model.dart';
import 'package:poigo/services/affiliate_mission_service.dart';
import 'package:poigo/theme/app_colors.dart';

import 'otoku_mission_detail_screen.dart';

/// おトクタブ用：成果報酬型広告（アフィリエイト案件）一覧（トリマ風カード）
class OtokuMissionListScreen extends StatelessWidget {
  const OtokuMissionListScreen({super.key, required this.uid});
  final String uid;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AffiliateMission>>(
      stream: AffiliateMissionService.instance.streamPublishedMissions(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primaryYellow));
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: AppColors.textSecondary),
                  const SizedBox(height: 16),
                  Text(
                    '読み込みに失敗しました',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }
        final missions = snapshot.data ?? [];
        if (missions.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.local_offer_rounded, size: 56, color: AppColors.textSecondary.withOpacity(0.5)),
                  const SizedBox(height: 16),
                  Text(
                    '現在、おトクな案件を準備中です。明日またチェックしてね！',
                    style: TextStyle(fontSize: 15, color: AppColors.textSecondary, height: 1.4),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          itemCount: missions.length,
          itemBuilder: (context, index) {
            final mission = missions[index];
            return _MissionCard(
              mission: mission,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) => OtokuMissionDetailScreen(mission: mission, uid: uid),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// カテゴリ名に応じたアイコン（購入→shopping_bag, 面談→people, アプリ→phone_android）
IconData _categoryIcon(String? category) {
  if (category == null || category.isEmpty) return Icons.local_offer_rounded;
  final c = category.trim().toLowerCase();
  if (c.contains('購入')) return Icons.shopping_bag_rounded;
  if (c.contains('面談')) return Icons.people_rounded;
  if (c.contains('アプリ')) return Icons.phone_android_rounded;
  return Icons.local_offer_rounded;
}

/// カード形式：左に画像、右にタイトルと獲得チップ
class _MissionCard extends StatelessWidget {
  const _MissionCard({required this.mission, required this.onTap});
  final AffiliateMission mission;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
        shadowColor: AppColors.navy.withOpacity(0.08),
        elevation: 0,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.navy.withOpacity(0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: mission.imageUrl != null && mission.imageUrl!.isNotEmpty
                      ? Image.network(
                          mission.imageUrl!,
                          width: 88,
                          height: 88,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _placeholderImage(),
                        )
                      : _placeholderImage(),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (mission.category != null && mission.category!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              Icon(_categoryIcon(mission.category), size: 14, color: AppColors.primaryYellow),
                              const SizedBox(width: 4),
                              Text(
                                mission.category!,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.primaryYellow,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      Text(
                        mission.title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.stars_rounded, size: 18, color: AppColors.primaryYellow),
                          const SizedBox(width: 4),
                          Text(
                            '${mission.pointAmount} チップ',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.navy,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _placeholderImage() {
    return Container(
      width: 88,
      height: 88,
      color: AppColors.surface,
      child: Icon(Icons.image_outlined, color: AppColors.textSecondary.withOpacity(0.5), size: 36),
    );
  }
}
