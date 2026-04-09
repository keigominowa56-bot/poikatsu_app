import 'package:flutter/material.dart';
import 'package:poigo/models/exchange_settings_model.dart';
import '../../services/admin_exchange_settings_service.dart';

class ExchangeSettingsScreen extends StatefulWidget {
  const ExchangeSettingsScreen({super.key});

  @override
  State<ExchangeSettingsScreen> createState() => _ExchangeSettingsScreenState();
}

class _ExchangeSettingsScreenState extends State<ExchangeSettingsScreen> {
  bool _itemsEnabled = true;
  bool _externalPointsEnabled = true;
  bool _giftCardsEnabled = true;
  bool _skinsEnabled = true;
  bool _donationEnabled = true;
  bool _saving = false;
  bool _initialized = false;

  void _apply(ExchangeSettingsModel s) {
    if (_initialized) return;
    _initialized = true;
    setState(() {
      _itemsEnabled = s.itemsEnabled;
      _externalPointsEnabled = s.externalPointsEnabled;
      _giftCardsEnabled = s.giftCardsEnabled;
      _skinsEnabled = s.skinsEnabled;
      _donationEnabled = s.donationEnabled;
    });
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await AdminExchangeSettingsService.instance.save(ExchangeSettingsModel(
        itemsEnabled: _itemsEnabled,
        externalPointsEnabled: _externalPointsEnabled,
        giftCardsEnabled: _giftCardsEnabled,
        skinsEnabled: _skinsEnabled,
        donationEnabled: _donationEnabled,
        updatedAt: DateTime.now(),
      ));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('交換メニュー設定を保存しました')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return StreamBuilder<ExchangeSettingsModel>(
      stream: AdminExchangeSettingsService.instance.streamExchangeSettings(),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _apply(snapshot.data!);
          });
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('交換メニュー ON/OFF', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _row('アイテム（ガチャチケ等）', _itemsEnabled, (v) => setState(() => _itemsEnabled = v)),
                      _row('他社ポイント（ドットマネー等）', _externalPointsEnabled, (v) => setState(() => _externalPointsEnabled = v)),
                      _row('商品券（Amazonギフト券等）', _giftCardsEnabled, (v) => setState(() => _giftCardsEnabled = v)),
                      _row('着せ替え（アプリ内スキン）', _skinsEnabled, (v) => setState(() => _skinsEnabled = v)),
                      _row('寄付', _donationEnabled, (v) => setState(() => _donationEnabled = v)),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _saving ? null : _save,
                          icon: _saving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save),
                          label: const Text('保存'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _row(String label, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 16))),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}
