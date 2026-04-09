import 'package:flutter/material.dart';
import 'package:poigo/models/affiliate_mission_model.dart';
import 'package:poigo/services/affiliate_mission_service.dart';
import 'package:poigo/theme/app_colors.dart';
import 'package:url_launcher/url_launcher.dart';

/// 案件詳細画面（S__61374470.jpg のような構成）。「詳細を見る」「回答する」で外部ブラウザへ＋クリックログ保存
class OtokuMissionDetailScreen extends StatelessWidget {
  const OtokuMissionDetailScreen({super.key, required this.mission, required this.uid});
  final AffiliateMission mission;
  final String uid;

  Future<void> _openAffiliateLink(BuildContext context) async {
    await AffiliateMissionService.instance.logClick(userId: uid, missionId: mission.id);
    final uri = Uri.tryParse(mission.affiliateUrl);
    if (uri == null) return;
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('案件詳細', style: TextStyle(color: AppColors.textPrimary, fontSize: 18)),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (mission.imageUrl != null && mission.imageUrl!.isNotEmpty) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  mission.imageUrl!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _placeholderBanner(),
                ),
              ),
              const SizedBox(height: 20),
            ],
            if (mission.category != null && mission.category!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  mission.category!,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.primaryYellow,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            Text(
              mission.title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.stars_rounded, size: 24, color: AppColors.primaryYellow),
                const SizedBox(width: 6),
                Text(
                  '獲得チップ：${mission.pointAmount}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.navy,
                  ),
                ),
              ],
            ),
            if (mission.description != null && mission.description!.isNotEmpty) ...[
              const SizedBox(height: 20),
              const Text(
                '条件・説明',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  mission.description!,
                  style: TextStyle(fontSize: 14, color: AppColors.textPrimary, height: 1.5),
                ),
              ),
            ],
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () => _openAffiliateLink(context),
              icon: const Icon(Icons.open_in_new_rounded, size: 20),
              label: const Text('詳細を見る'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryYellow,
                foregroundColor: AppColors.navy,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => _openAffiliateLink(context),
              icon: const Icon(Icons.touch_app_rounded, size: 20),
              label: const Text('回答する'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.navy,
                side: const BorderSide(color: AppColors.navy),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _placeholderBanner() {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(Icons.image_outlined, size: 64, color: AppColors.textSecondary.withOpacity(0.5)),
    );
  }
}
