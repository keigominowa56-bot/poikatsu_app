import 'package:flutter/material.dart';
import 'package:poigo/models/user_model.dart';
import 'package:poigo/services/user_firestore_service.dart';
import '../../services/admin_firestore_service.dart';

/// isBanned ユーザー一覧・解除/強制停止（BAN）
class BlacklistScreen extends StatelessWidget {
  const BlacklistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<UserModel>>(
      stream: AdminFirestoreService.instance.streamUsers(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final all = snapshot.data ?? [];
        final banned = all.where((u) => u.isBanned).toList();
        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              'ブラックリスト（BANユーザー）',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '解除または強制停止（BAN）ができます。',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            if (banned.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('BANユーザーはいません'),
                ),
              )
            else
              ...banned.map((u) => Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      title: Text(u.id),
                      subtitle: Text('${u.totalPoints} pt · ${u.email ?? ""}'),
                      trailing: FilledButton(
                        onPressed: () async {
                          await UserFirestoreService.instance.setBanned(u.id, false);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('BANを解除しました')),
                            );
                          }
                        },
                        child: const Text('解除'),
                      ),
                    ),
                  )),
          ],
        );
      },
    );
  }
}
