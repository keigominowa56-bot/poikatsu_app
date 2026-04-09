import 'package:flutter/material.dart';
import 'package:poigo/models/user_model.dart';
import 'package:poigo/services/user_firestore_service.dart';

import '../features/affiliate/affiliate_mission_manage_screen.dart';
import '../features/blacklist/blacklist_screen.dart';
import '../features/economy/economy_settings_screen.dart';
import '../features/exchange/exchange_requests_screen.dart';
import '../features/exchange/exchange_settings_screen.dart';
import '../features/fortune/fortune_prompt.dart';
import '../features/fortune/fortune_settings_screen.dart';
import '../features/lottery/lottery_manage_screen.dart';
import '../features/news/news_settings_screen.dart';
import '../features/ranking/ranking_admin_screen.dart';
import '../features/slot/slot_settings_screen.dart';
import '../services/admin_firestore_service.dart';

/// 管理者用ダッシュボード：サイドメニュー・統計カード・ユーザー一覧（検索・ソート）・ポイント操作
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int _selectedIndex = 0;
  bool _sortPointsDesc = true;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<UserModel> _filterAndSort(List<UserModel> users) {
    var list = users;
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      list = list.where((u) => u.id.toLowerCase().contains(q)).toList();
    }
    list = List.from(list)
      ..sort((a, b) => _sortPointsDesc
          ? b.totalPoints.compareTo(a.totalPoints)
          : a.totalPoints.compareTo(b.totalPoints));
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('ポイ活 管理画面'),
        backgroundColor: theme.colorScheme.inversePrimary,
        elevation: 0,
      ),
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (v) => setState(() => _selectedIndex = v),
            labelType: NavigationRailLabelType.all,
            leading: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Icon(Icons.admin_panel_settings, color: theme.colorScheme.primary),
            ),
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard),
                label: Text('ダッシュボード'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.people_outlined),
                selectedIcon: Icon(Icons.people),
                label: Text('ユーザー'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.auto_awesome_outlined),
                selectedIcon: Icon(Icons.auto_awesome),
                label: Text('占い'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.article_outlined),
                selectedIcon: Icon(Icons.article),
                label: Text('ニュース'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.savings_outlined),
                selectedIcon: Icon(Icons.savings),
                label: Text('経済圏'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.swap_horiz_outlined),
                selectedIcon: Icon(Icons.swap_horiz),
                label: Text('交換'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.list_alt_outlined),
                selectedIcon: Icon(Icons.list_alt),
                label: Text('交換申請'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.block_outlined),
                selectedIcon: Icon(Icons.block),
                label: Text('ブラックリスト'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.local_offer_outlined),
                selectedIcon: Icon(Icons.local_offer),
                label: Text('案件管理'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.confirmation_number_outlined),
                selectedIcon: Icon(Icons.confirmation_number),
                label: Text('宝くじ'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.casino_outlined),
                selectedIcon: Icon(Icons.casino),
                label: Text('スロット'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.emoji_events_outlined),
                selectedIcon: Icon(Icons.emoji_events),
                label: Text('ランキング'),
              ),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: _selectedIndex == 2
                ? const FortuneSettingsScreen()
                : _selectedIndex == 3
                    ? const NewsSettingsScreen()
                    : _selectedIndex == 4
                        ? const EconomySettingsScreen()
                        : _selectedIndex == 5
                            ? const ExchangeSettingsScreen()
                            : _selectedIndex == 6
                                ? const ExchangeRequestsScreen()
                                : _selectedIndex == 7
                                    ? const BlacklistScreen()
                                    : _selectedIndex == 8
                                        ? const AffiliateMissionManageScreen()
                : _selectedIndex == 9
                    ? const LotteryManageScreen()
                : _selectedIndex == 10
                    ? const SlotSettingsScreen()
                : _selectedIndex == 11
                    ? const RankingAdminScreen()
                                        : StreamBuilder<List<UserModel>>(
              stream: AdminFirestoreService.instance.streamUsers(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
                          const SizedBox(height: 16),
                          Text(
                            '取得エラー: ${snapshot.error}',
                            style: TextStyle(color: theme.colorScheme.error),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }
                final allUsers = snapshot.data ?? [];
                final filtered = _filterAndSort(allUsers);
                final totalPoints = allUsers.fold<int>(0, (s, u) => s + u.totalPoints);

                return ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    Text(
                      '概要',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _SummaryCard(
                            label: '総ユーザー数',
                            value: '${allUsers.length}',
                            unit: '人',
                            icon: Icons.people,
                            theme: theme,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _SummaryCard(
                            label: '発行済み総ポイント',
                            value: '$totalPoints',
                            unit: 'P',
                            icon: Icons.stars,
                            theme: theme,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'AI生成プロンプト（占い）',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: theme.colorScheme.outlineVariant,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '占いコンテンツをAIで生成する際は、以下の指示をプロンプトに含めてください。',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: SelectableText(
                                FortunePrompt.aiGenerationInstruction,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'ユーザー一覧',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: theme.colorScheme.outlineVariant,
                          width: 1,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: TextField(
                                    controller: _searchController,
                                    decoration: InputDecoration(
                                      hintText: 'ユーザーIDで検索',
                                      prefixIcon: const Icon(Icons.search),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 10,
                                      ),
                                      filled: true,
                                      fillColor: theme.colorScheme.surfaceContainerLowest,
                                    ),
                                    onChanged: (v) => setState(() => _searchQuery = v),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                SegmentedButton<bool>(
                                  segments: const [
                                    ButtonSegment(
                                      value: true,
                                      label: Text('ポイント多い順'),
                                      icon: Icon(Icons.arrow_downward),
                                    ),
                                    ButtonSegment(
                                      value: false,
                                      label: Text('ポイント少ない順'),
                                      icon: Icon(Icons.arrow_upward),
                                    ),
                                  ],
                                  selected: {_sortPointsDesc},
                                  onSelectionChanged: (s) =>
                                      setState(() => _sortPointsDesc = s.first),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            if (filtered.isEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 32, horizontal: 16),
                                child: Center(
                                  child: Text(
                                    allUsers.isEmpty
                                        ? 'ユーザーがまだいません（アプリでログインすると表示されます）'
                                        : '検索に一致するユーザーがいません',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              )
                            else
                              Container(
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: theme.colorScheme.outlineVariant,
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: DataTable(
                                      headingRowColor: WidgetStateProperty.all(
                                        theme.colorScheme.surfaceContainerHigh,
                                      ),
                                      columns: const [
                                        DataColumn(label: Text('ユーザーID')),
                                        DataColumn(
                                            label: Text('ポイント'), numeric: true),
                                        DataColumn(
                                            label: Text('今日の歩数'),
                                            numeric: true),
                                        DataColumn(label: Text('BAN')),
                                        DataColumn(label: Text('操作')),
                                      ],
                                      rows: filtered
                                          .map((user) =>
                                              _userDataRow(context, user))
                                          .toList(),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  DataRow _userDataRow(BuildContext context, UserModel user) {
    return DataRow(
      cells: [
        DataCell(
          SelectableText(
            user.id,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
        ),
        DataCell(Text('${user.totalPoints} P')),
        DataCell(Text('${user.todaySteps} 歩')),
        DataCell(
          Builder(
            builder: (ctx) {
              return TextButton(
                onPressed: () async {
                  final ban = !user.isBanned;
                  await UserFirestoreService.instance.setBanned(user.id, ban);
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(content: Text(ban ? 'BANにしました' : 'BANを解除しました')),
                    );
                  }
                },
                child: Text(user.isBanned ? '解除' : 'BAN'),
              );
            },
          ),
        ),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              FilledButton.tonalIcon(
                onPressed: () async {
                  await AdminFirestoreService.instance.addPoints(user.id, 10);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('+10P 付与しました')),
                    );
                  }
                },
                icon: const Icon(Icons.add, size: 18),
                label: const Text('+10'),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () async {
                  await AdminFirestoreService.instance.subtractPoints(user.id, 10);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('-10P 減算しました')),
                    );
                  }
                },
                child: const Text('-10'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    required this.theme,
  });

  final String label;
  final String value;
  final String unit;
  final IconData icon;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: theme.colorScheme.onPrimaryContainer, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        value,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(unit, style: theme.textTheme.bodySmall),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
