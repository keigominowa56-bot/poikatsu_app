import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:poigo/services/user_firestore_service.dart';

/// 管理画面：ランキング（トップ100）を見やすく一覧表示（定期更新の代替としてリアルタイム表示）
class RankingAdminScreen extends StatelessWidget {
  const RankingAdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .orderBy('totalEarnedChips', descending: true)
          .limit(100)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snap.data?.docs ?? [];
        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text('ランキング（トップ100）', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('累計獲得チップ（totalEarnedChips）を元に並び替えています。', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: 16),
            if (docs.isEmpty)
              const Card(child: Padding(padding: EdgeInsets.all(24), child: Center(child: Text('データがありません'))))
            else
              Card(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('順位'), numeric: true),
                      DataColumn(label: Text('ニックネーム')),
                      DataColumn(label: Text('ランク')),
                      DataColumn(label: Text('累計獲得チップ'), numeric: true),
                      DataColumn(label: Text('UID')),
                    ],
                    rows: List.generate(docs.length, (i) {
                      final d = docs[i].data();
                      final uid = docs[i].id;
                      final name = (d['displayName'] as String?)?.trim();
                      final earned = (d['totalEarnedChips'] as num?)?.toInt() ?? 0;
                      final rank = UserFirestoreService.rankNameFromEarned(earned);
                      return DataRow(cells: [
                        DataCell(Text('${i + 1}')),
                        DataCell(Text(name != null && name.isNotEmpty ? name : '匿名ユーザー')),
                        DataCell(Text(rank)),
                        DataCell(Text('$earned')),
                        DataCell(SelectableText(uid)),
                      ]);
                    }),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

