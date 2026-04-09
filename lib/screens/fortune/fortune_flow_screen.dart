import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/user_model.dart';
import '../../services/user_firestore_service.dart';
import 'birth_date_input_screen.dart';
import 'calculating_overlay_screen.dart';
import 'fortune_result_screen.dart';
import 'full_screen_ad_placeholder.dart';

/// 占いフロー：生年月日未設定なら入力画面 → 解析ボタン → フルスクリーン広告 → 最終結果
class FortuneFlowScreen extends StatefulWidget {
  const FortuneFlowScreen({super.key});

  @override
  State<FortuneFlowScreen> createState() => _FortuneFlowScreenState();
}

class _FortuneFlowScreenState extends State<FortuneFlowScreen> {
  DateTime? _birthDateForSession;

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return StreamBuilder<UserModel?>(
      stream: UserFirestoreService.instance.streamUser(uid),
      builder: (context, snapshot) {
        final user = snapshot.data;
        final birthDate = _birthDateForSession ?? user?.birthDate;

        if (birthDate == null) {
          return _BuildAnalyzeEntry(
            uid: uid,
            hasStoredBirthDate: user?.birthDate != null,
            onRequestBirthDateInput: () async {
              final picked = await Navigator.of(context).push<DateTime>(
                MaterialPageRoute(
                  builder: (context) => BirthDateInputScreen(uid: uid),
                ),
              );
              if (picked != null && mounted) {
                setState(() => _birthDateForSession = picked);
              }
            },
            onAnalyze: null,
          );
        }

        return _BuildAnalyzeEntry(
          uid: uid,
          hasStoredBirthDate: user?.birthDate != null,
          birthDate: birthDate,
          onRequestBirthDateInput: () async {
            final picked = await Navigator.of(context).push<DateTime>(
              MaterialPageRoute(
                builder: (context) => BirthDateInputScreen(
                  uid: uid,
                  initialDate: birthDate,
                ),
              ),
            );
            if (picked != null && mounted) {
              setState(() => _birthDateForSession = picked);
            }
          },
          onAnalyze: () => _startCalculatingThenAd(context, uid, birthDate),
        );
      },
    );
  }

  void _startCalculatingThenAd(BuildContext flowContext, String uid, DateTime birthDate) {
    Navigator.of(flowContext).push(
      MaterialPageRoute<void>(
        builder: (overlayContext) => CalculatingOverlayScreen(
          duration: const Duration(seconds: 5),
          onComplete: () {
            Navigator.of(overlayContext).pop();
            _showAdDialog(flowContext, uid, birthDate);
          },
        ),
      ),
    );
  }

  void _showAdDialog(BuildContext context, String uid, DateTime birthDate) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black87,
      builder: (dialogContext) => FullScreenAdPlaceholder(
        onClosed: () {
          Navigator.of(dialogContext).pop();
          Navigator.of(context).pushReplacement(
            MaterialPageRoute<void>(
              builder: (context) => FortuneResultScreen(
                uid: uid,
                birthDate: birthDate,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _BuildAnalyzeEntry extends StatelessWidget {
  const _BuildAnalyzeEntry({
    required this.uid,
    required this.hasStoredBirthDate,
    required this.onRequestBirthDateInput,
    this.birthDate,
    this.onAnalyze,
  });

  final String uid;
  final bool hasStoredBirthDate;
  final VoidCallback onRequestBirthDateInput;
  final DateTime? birthDate;
  final VoidCallback? onAnalyze;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('生年月日を軸にした精密診断'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                '生年月日をもとに、星座・数秘術・今日のバイオリズムであなたの運勢を診断します。',
                style: TextStyle(fontSize: 16, height: 1.5),
              ),
              if (birthDate == null) ...[
                const SizedBox(height: 32),
                FilledButton.icon(
                  onPressed: onRequestBirthDateInput,
                  icon: const Icon(Icons.calendar_today),
                  label: const Text('生年月日を入力する'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ] else ...[
                const SizedBox(height: 24),
                Card(
                  margin: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.cake, color: theme.colorScheme.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${birthDate!.year}年${birthDate!.month}月${birthDate!.day}日',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (!hasStoredBirthDate)
                                Text(
                                  'この診断で入力した日付です',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: onRequestBirthDateInput,
                          child: const Text('変更'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                FilledButton.icon(
                  onPressed: onAnalyze,
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text('解析する'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
