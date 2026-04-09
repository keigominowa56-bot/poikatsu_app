import 'package:flutter/material.dart';
import 'package:poigo/admin/services/admin_slot_settings_service.dart';
import 'package:poigo/models/slot_settings_model.dart';

class SlotSettingsScreen extends StatefulWidget {
  const SlotSettingsScreen({super.key});

  @override
  State<SlotSettingsScreen> createState() => _SlotSettingsScreenState();
}

class _SlotSettingsScreenState extends State<SlotSettingsScreen> {
  final _probController = TextEditingController();
  final _multController = TextEditingController();
  bool _saving = false;
  bool _initialized = false;

  @override
  void dispose() {
    _probController.dispose();
    _multController.dispose();
    super.dispose();
  }

  void _applyOnce(SlotSettings s) {
    if (_initialized) return;
    _initialized = true;
    _probController.text = s.winProbabilityPercent.toString();
    _multController.text = s.payoutMultiplier.toString();
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final p = double.tryParse(_probController.text.trim()) ?? 10.0;
      final m = double.tryParse(_multController.text.trim()) ?? 2.0;
      await AdminSlotSettingsService.instance.save(
        SlotSettings(winProbabilityPercent: p, payoutMultiplier: m),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('スロット設定を保存しました')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return StreamBuilder<SlotSettings>(
      stream: AdminSlotSettingsService.instance.stream(),
      builder: (context, snap) {
        if (snap.hasData) _applyOnce(snap.data!);
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('スロット設定', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('当たり確率（%）と配当倍率を調整します。', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              const SizedBox(height: 24),
              TextField(
                controller: _probController,
                decoration: const InputDecoration(
                  labelText: '当たり確率（%）',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _multController,
                decoration: const InputDecoration(
                  labelText: '配当倍率（例: 2.0）',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('保存'),
              ),
            ],
          ),
        );
      },
    );
  }
}

