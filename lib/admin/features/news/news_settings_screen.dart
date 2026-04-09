import 'package:flutter/material.dart';

import 'package:poigo/models/news_settings_model.dart';

import '../../services/admin_news_settings_service.dart';

/// ニュース設定: 各カテゴリ・都道府県のRSS URLを編集
class NewsSettingsScreen extends StatefulWidget {
  const NewsSettingsScreen({super.key});

  @override
  State<NewsSettingsScreen> createState() => _NewsSettingsScreenState();
}

class _NewsSettingsScreenState extends State<NewsSettingsScreen> {
  final _controllers = <String, TextEditingController>{};
  bool _saving = false;
  bool _initialized = false;

  static const List<({String id, String label})> categories = [
    (id: NewsSettingsModel.keyGeneral, label: '総合'),
    (id: NewsSettingsModel.keyPolitics, label: '政治'),
    (id: NewsSettingsModel.keyEconomy, label: '経済'),
    (id: NewsSettingsModel.keyEntertainment, label: 'エンタメ'),
    (id: NewsSettingsModel.keySports, label: 'スポーツ'),
    (id: NewsSettingsModel.keyInternational, label: '国際'),
  ];

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _applyOnce(NewsSettingsModel s) {
    if (_initialized) return;
    _initialized = true;
    for (final cat in categories) {
      _controllers.putIfAbsent(cat.id, () => TextEditingController());
      _controllers[cat.id]!.text = s.categoryUrls[cat.id] ?? '';
    }
    for (var i = 1; i <= 47; i++) {
      final key = i.toString();
      _controllers.putIfAbsent('pref_$key', () => TextEditingController());
      _controllers['pref_$key']!.text = s.prefectureUrls[key] ?? '';
    }
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final categoryUrls = <String, String>{};
      for (final cat in categories) {
        final t = _controllers[cat.id]?.text.trim();
        if (t != null && t.isNotEmpty) categoryUrls[cat.id] = t;
      }
      final prefectureUrls = <String, String>{};
      for (var i = 1; i <= 47; i++) {
        final key = i.toString();
        final t = _controllers['pref_$key']?.text.trim();
        if (t != null && t.isNotEmpty) prefectureUrls[key] = t;
      }
      await AdminNewsSettingsService.instance.save(NewsSettingsModel(
        categoryUrls: categoryUrls,
        prefectureUrls: prefectureUrls,
        updatedAt: DateTime.now(),
      ));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ニュース設定を保存しました')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return StreamBuilder<NewsSettingsModel>(
      stream: AdminNewsSettingsService.instance.streamNewsSettings(),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data != null) {
          _applyOnce(snapshot.data!);
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'ニュース設定',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '各カテゴリ・都道府県のRSS URLを設定できます。空欄の場合はアプリのデフォルトURLを使用します。',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              ...categories.map((cat) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: TextField(
                  controller: _controllers[cat.id],
                  decoration: InputDecoration(
                    labelText: '${cat.label}（RSS URL）',
                    hintText: 'https://...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              )),
              const SizedBox(height: 16),
              ExpansionTile(
                title: const Text('都道府県別RSS URL（任意）'),
                subtitle: const Text('1〜47のコードで都道府県を指定'),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: List.generate(47, (i) {
                        final code = (i + 1).toString();
                        return SizedBox(
                          width: 120,
                          child: TextField(
                            controller: _controllers['pref_$code'],
                            decoration: InputDecoration(
                              labelText: code,
                              isDense: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              filled: true,
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: const Text('保存'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
