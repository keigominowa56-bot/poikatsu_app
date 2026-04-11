import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:poigo/constants/digico_showcase.dart';
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

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '貯めたチップをギフトに',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'デジコなら人気の交換先から選べます',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '発行後、デジコのサイトで PayPay・Amazonギフト・各種ポイントなどに振り替え可能です（内容はデジコ側の案内に従ってください）。',
                  style: TextStyle(fontSize: 13, height: 1.45, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final tile = kDigicoShowcaseTiles[index];
                return _ShowcaseSquareCard(
                  tile: tile,
                  onTap: () => _openSheet(context),
                );
              },
              childCount: kDigicoShowcaseTiles.length,
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
          sliver: SliverToBoxAdapter(
            child: FilledButton.icon(
              onPressed: () => _openSheet(context),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryOrange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.redeem_rounded, size: 22),
              label: const Text(
                'デジコで交換する',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// 交換イメージを高める正方形タイル（タップで共通の申込シート）
class _ShowcaseSquareCard extends StatelessWidget {
  const _ShowcaseSquareCard({
    required this.tile,
    required this.onTap,
  });

  final DigicoShowcaseTile tile;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.cardWhite,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.navy.withValues(alpha: 0.08)),
            boxShadow: [
              BoxShadow(
                color: AppColors.navy.withValues(alpha: 0.07),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (tile.gradient != null)
                      DecoratedBox(decoration: BoxDecoration(gradient: tile.gradient))
                    else if (tile.assetPath != null)
                      Image.asset(
                        tile.assetPath!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => ColoredBox(
                          color: AppColors.primaryYellow.withValues(alpha: 0.35),
                          child: Icon(tile.fallbackIcon, size: 48, color: AppColors.navy),
                        ),
                      )
                    else
                      ColoredBox(
                        color: AppColors.primaryYellow.withValues(alpha: 0.35),
                        child: Icon(tile.fallbackIcon, size: 48, color: AppColors.navy),
                      ),
                    if (tile.gradient != null)
                      Center(
                        child: Icon(
                          tile.fallbackIcon,
                          size: 56,
                          color: Colors.white.withValues(alpha: 0.95),
                        ),
                      ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.55),
                            ],
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(10, 20, 10, 10),
                          child: Text(
                            tile.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              shadows: [Shadow(blurRadius: 4, color: Colors.black45)],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Text(
                  tile.caption,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.25,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
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
