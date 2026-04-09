import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:poigo/constants/point_constants.dart';
import 'package:poigo/models/exchange_settings_model.dart';
import 'package:poigo/screens/auth/phone_input_page.dart';
import 'package:poigo/screens/exchange/exchange_history_screen.dart';
import 'package:poigo/services/auth_service.dart';
import 'package:poigo/services/digico_service.dart';
import 'package:poigo/services/exchange_settings_service.dart';
import 'package:poigo/services/user_firestore_service.dart';
import 'package:poigo/theme/app_colors.dart';

/// デジコ連携のギフト交換（交換先は「デジコ」1種類）。
class ExchangeMenuScreen extends StatelessWidget {
  const ExchangeMenuScreen({super.key, required this.uid});

  final String uid;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ExchangeSettingsModel>(
      future: ExchangeSettingsService.instance.getExchangeSettingsOnce(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              title: const Text('交換'),
              backgroundColor: AppColors.background,
              foregroundColor: AppColors.textPrimary,
            ),
            body: const Center(child: CircularProgressIndicator(color: AppColors.primaryOrange)),
          );
        }

        final settings = snapshot.data;
        final digicoEnabled = settings?.externalPointsEnabled ?? true;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('交換'),
            backgroundColor: AppColors.background,
            foregroundColor: AppColors.textPrimary,
            actions: [
              TextButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (ctx) => ExchangeHistoryScreen(uid: uid),
                    ),
                  );
                },
                icon: const Icon(Icons.history_rounded, size: 22, color: AppColors.navy),
                label: const Text('履歴', style: TextStyle(color: AppColors.navy)),
              ),
            ],
          ),
          body: _DigicoMenuTab(uid: uid, enabled: digicoEnabled),
        );
      },
    );
  }
}

class _DigicoMenuTab extends StatelessWidget {
  const _DigicoMenuTab({
    required this.uid,
    required this.enabled,
  });

  final String uid;
  final bool enabled;

  void _openSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: 24 + MediaQuery.paddingOf(ctx).bottom,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'デジコ（ギフトコード）',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  '交換は200円分（20,000チップ）からです。発行されたデジコサイト上で、Amazonギフト、PayPay、Apple Gift Card等に交換できます。',
                ),
                const SizedBox(height: 16),
                _DigicoGiftRequestPanel(
                  uid: uid,
                  categoryId: 'digico',
                  productLabel: 'デジコ（ギフトコード）',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!enabled) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            '現在、デジコ交換は停止しています。',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Material(
          color: AppColors.cardWhite,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: () => _openSheet(context),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.navy.withOpacity(0.06),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.gaugeEnd.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.redeem_rounded, color: AppColors.gaugeStart, size: 28),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'デジコ（ギフトコード）',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Amazonギフト、PayPay、Apple Gift Card等に交換可能',
                          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: AppColors.textSecondary),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DigicoGiftRequestPanel extends StatefulWidget {
  const _DigicoGiftRequestPanel({
    required this.uid,
    required this.categoryId,
    required this.productLabel,
  });

  final String uid;
  final String categoryId;
  final String productLabel;

  @override
  State<_DigicoGiftRequestPanel> createState() => _DigicoGiftRequestPanelState();
}

class _DigicoGiftRequestPanelState extends State<_DigicoGiftRequestPanel> {
  DigicoExchangeTier _selectedTier = PointConstants.digicoExchangeTiers.first;
  bool _loading = false;
  DigicoGiftResult? _result;
  String? _error;

  Future<void> _request() async {
    final user = await UserFirestoreService.instance.getUserOnce(widget.uid);
    final totalPoints = user?.totalPoints ?? 0;
    final need = _selectedTier.chips;
    if (totalPoints < need) {
      if (!mounted) return;
      final msg =
          'チップが不足しています（保有: ${PointConstants.formatChips(totalPoints)} / 必要: ${PointConstants.formatChips(need)}）';
      setState(() => _error = msg);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('交換内容の確認'),
        content: Text(
          '「${widget.productLabel}」${_selectedTier.yen}円分に交換します（${PointConstants.formatChips(_selectedTier.chips)}チップを消費）。よろしいですか？',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('確定'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final currentUser = FirebaseAuth.instance.currentUser;
    if (!AuthService.instance.hasVerifiedPhone(currentUser)) {
      final verified = await Navigator.of(context).push<bool>(
        MaterialPageRoute<bool>(builder: (_) => const PhoneInputPage()),
      );
      if (verified != true || !mounted) return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final chips = _selectedTier.chips;
      final result = await DigicoService.instance.exchange(
        chips: chips,
        categoryId: widget.categoryId,
      );
      if (!mounted) return;
      setState(() => _result = result);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ギフトURLを発行しました')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openGiftUrl() async {
    final url = _result?.giftUrl;
    if (url == null || url.isEmpty) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: PointConstants.digicoExchangeTiers.map((t) {
            return ChoiceChip(
              label: Text('${t.yen}円（${PointConstants.formatChips(t.chips)}チップ）'),
              selected: _selectedTier.yen == t.yen,
              onSelected: (_) => setState(() => _selectedTier = t),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: _loading ? null : _request,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primaryOrange,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: _loading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('交換を確定'),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(
            _error!,
            style: const TextStyle(color: Colors.red, fontSize: 12),
          ),
        ],
        if (_result != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.gaugeEnd.withOpacity(0.18),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('管理番号: ${_result!.managementNo}'),
                const SizedBox(height: 8),
                SelectableText(_result!.giftUrl),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: _openGiftUrl,
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('ギフトを受け取る'),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('閉じる'),
        ),
      ],
    );
  }
}
