import 'package:flutter/material.dart';
import 'package:poigo/models/affiliate_mission_model.dart';

import '../../services/affiliate_mission_admin_service.dart';

/// 案件管理：一覧・新規投稿・編集・非公開化
class AffiliateMissionManageScreen extends StatelessWidget {
  const AffiliateMissionManageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return StreamBuilder<List<AffiliateMission>>(
      stream: AffiliateMissionAdminService.instance.streamAllMissions(),
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
                  Text('取得エラー: ${snapshot.error}', style: TextStyle(color: theme.colorScheme.error), textAlign: TextAlign.center),
                ],
              ),
            ),
          );
        }
        final missions = snapshot.data ?? [];
        return Scaffold(
          body: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '案件管理（おトク）',
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '成果報酬型広告（アフィリエイト）案件の追加・編集・非公開',
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 24),
              if (missions.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.local_offer_outlined, size: 48, color: theme.colorScheme.outline),
                          const SizedBox(height: 16),
                          Text('まだ案件がありません', style: theme.textTheme.bodyLarge),
                          const SizedBox(height: 8),
                          Text('右下の「案件を追加」から登録してください', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                        ],
                      ),
                    ),
                  ),
                )
              else
                ...missions.map((m) => _MissionListTile(mission: m)),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _openForm(context, mission: null),
            icon: const Icon(Icons.add),
            label: const Text('案件を追加'),
          ),
        );
      },
    );
  }

  void _openForm(BuildContext context, {AffiliateMission? mission}) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => _MissionFormSheet(
        mission: mission,
        onSaved: () => Navigator.of(ctx).pop(),
        onCancel: () => Navigator.of(ctx).pop(),
      ),
    );
  }
}

class _MissionListTile extends StatelessWidget {
  const _MissionListTile({required this.mission});
  final AffiliateMission mission;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: mission.imageUrl != null && mission.imageUrl!.isNotEmpty
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(mission.imageUrl!, width: 56, height: 56, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_outlined)),
              )
            : const SizedBox(width: 56, height: 56, child: Icon(Icons.image_not_supported_outlined)),
        title: Text(mission.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text('${mission.pointAmount} pt ・ ${mission.isPublished ? "公開" : "非公開"}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => _openForm(context),
            ),
            IconButton(
              icon: const Icon(Icons.visibility_off_outlined),
              tooltip: '非公開にする',
              onPressed: () => _unpublish(context),
            ),
          ],
        ),
      ),
    );
  }

  void _openForm(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => _MissionFormSheet(
        mission: mission,
        onSaved: () => Navigator.of(ctx).pop(),
        onCancel: () => Navigator.of(ctx).pop(),
      ),
    );
  }

  Future<void> _unpublish(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('非公開にしますか？'),
        content: Text('「${mission.title}」を非公開にすると、ユーザーには表示されなくなります。'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('キャンセル')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('非公開にする')),
        ],
      ),
    );
    if (ok == true) {
      await AffiliateMissionAdminService.instance.unpublishMission(mission.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('非公開にしました')));
      }
    }
  }
}

class _MissionFormSheet extends StatefulWidget {
  const _MissionFormSheet({this.mission, required this.onSaved, required this.onCancel});
  final AffiliateMission? mission;
  final VoidCallback onSaved;
  final VoidCallback onCancel;

  @override
  State<_MissionFormSheet> createState() => _MissionFormSheetState();
}

class _MissionFormSheetState extends State<_MissionFormSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _pointController;
  late final TextEditingController _imageUrlController;
  late final TextEditingController _affiliateUrlController;
  late final TextEditingController _categoryController;
  bool _isPublished = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final m = widget.mission;
    _titleController = TextEditingController(text: m?.title ?? '');
    _descriptionController = TextEditingController(text: m?.description ?? '');
    _pointController = TextEditingController(text: m != null ? '${m.pointAmount}' : '');
    _imageUrlController = TextEditingController(text: m?.imageUrl ?? '');
    _affiliateUrlController = TextEditingController(text: m?.affiliateUrl ?? '');
    _categoryController = TextEditingController(text: m?.category ?? '');
    _isPublished = m?.isPublished ?? true;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _pointController.dispose();
    _imageUrlController.dispose();
    _affiliateUrlController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    final affiliateUrl = _affiliateUrlController.text.trim();
    if (title.isEmpty || affiliateUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('タイトルとアフィリエイトURLは必須です')));
      return;
    }
    final pointAmount = int.tryParse(_pointController.text.trim()) ?? 0;
    if (pointAmount < 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('チップは0以上で入力してください')));
      return;
    }
    setState(() => _saving = true);
    try {
      final existing = widget.mission;
      final id = existing?.id ?? AffiliateMissionAdminService.instance.generateId();
      final mission = AffiliateMission(
        id: id,
        title: title,
        description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
        pointAmount: pointAmount,
        imageUrl: _imageUrlController.text.trim().isEmpty ? null : _imageUrlController.text.trim(),
        affiliateUrl: affiliateUrl,
        category: _categoryController.text.trim().isEmpty ? null : _categoryController.text.trim(),
        isPublished: _isPublished,
        createdAt: existing?.createdAt,
        updatedAt: DateTime.now(),
      );
      if (existing != null) {
        await AffiliateMissionAdminService.instance.updateMission(mission);
      } else {
        await AffiliateMissionAdminService.instance.addMission(mission);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(existing != null ? '案件を更新しました' : '案件を追加しました')));
      widget.onSaved();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEdit = widget.mission != null;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              isEdit ? '案件を編集' : '新規案件',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'タイトル *',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: '条件・説明',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _pointController,
              decoration: const InputDecoration(
                labelText: '獲得チップ *',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _imageUrlController,
              decoration: const InputDecoration(
                labelText: '画像URL',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
            if (_imageUrlController.text.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        _imageUrlController.text.trim(),
                        width: 64,
                        height: 64,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 64,
                          height: 64,
                          color: theme.colorScheme.surfaceContainerHighest,
                          child: Icon(Icons.broken_image_outlined, color: theme.colorScheme.outline),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text('プレビュー', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            TextField(
              controller: _affiliateUrlController,
              decoration: const InputDecoration(
                labelText: 'アフィリエイトURL（遷移先） *',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _categoryController,
              decoration: const InputDecoration(
                labelText: 'カテゴリ（購入・面談など）',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('公開する'),
              value: _isPublished,
              onChanged: (v) => setState(() => _isPublished = v),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                TextButton(
                  onPressed: _saving ? null : widget.onCancel,
                  child: const Text('キャンセル'),
                ),
                const SizedBox(width: 16),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: _saving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : Text(isEdit ? '更新' : '追加'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
