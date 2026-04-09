import 'package:flutter/material.dart';

import 'package:poigo/models/exchange_request_model.dart';

import '../../services/admin_exchange_requests_service.dart';

/// 交換申請一覧・承認/却下
class ExchangeRequestsScreen extends StatelessWidget {
  const ExchangeRequestsScreen({super.key});

  static String _categoryLabel(String id) {
    switch (id) {
      case 'items':
        return 'アイテム';
      case 'externalPoints':
        return '他社ポイント';
      case 'giftCards':
        return '商品券';
      case 'skins':
        return '着せ替え';
      case 'donation':
        return '寄付';
      default:
        return id;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return StreamBuilder<List<ExchangeRequestModel>>(
      stream: AdminExchangeRequestsService.instance.streamRequests(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text('エラー: ${snapshot.error}', style: TextStyle(color: theme.colorScheme.error)),
          );
        }
        final list = snapshot.data ?? [];
        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              '交換申請管理',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '承認または却下を選択してください。',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            if (list.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    '申請はまだありません',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              )
            else
              ...list.map((r) => Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      title: Text('${_categoryLabel(r.categoryId)} - ${r.userId}'),
                      subtitle: Text(
                        'ステータス: ${r.status}'
                        '${r.createdAt != null ? " · ${r.createdAt!.toIso8601String()}" : ""}',
                      ),
                      trailing: r.status == 'pending'
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TextButton(
                                  onPressed: () async {
                                    await AdminExchangeRequestsService.instance.approve(r.id);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('承認しました')),
                                      );
                                    }
                                  },
                                  child: const Text('承認'),
                                ),
                                TextButton(
                                  onPressed: () async {
                                    await AdminExchangeRequestsService.instance.reject(r.id);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('却下しました')),
                                      );
                                    }
                                  },
                                  child: const Text('却下'),
                                ),
                              ],
                            )
                          : null,
                    ),
                  )),
          ],
        );
      },
    );
  }
}
