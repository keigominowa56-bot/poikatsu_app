import 'package:flutter/material.dart';

import 'package:poigo/theme/app_colors.dart';
import 'package:poigo/services/user_firestore_service.dart';

/// 登録後に一度だけ表示する招待コード入力画面
class ReferralInputScreen extends StatefulWidget {
  const ReferralInputScreen({super.key, required this.uid});

  final String uid;

  @override
  State<ReferralInputScreen> createState() => _ReferralInputScreenState();
}

class _ReferralInputScreenState extends State<ReferralInputScreen> {
  final _controller = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final code = _controller.text.trim();
    if (code.isEmpty) {
      setState(() => _error = '招待コードを入力してください');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final ok = await UserFirestoreService.instance.applyReferralCode(widget.uid, code);
      if (!mounted) return;
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('招待コードを適用しました。チップを付与しました。')),
        );
        Navigator.of(context).pop();
      } else {
        setState(() {
          _error = '無効なコードか、既に紹介済みです';
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'エラー: $e';
          _loading = false;
        });
      }
    }
  }

  Future<void> _skip() async {
    await UserFirestoreService.instance.setReferralPromptSeen(widget.uid);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('招待コード'),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              Text(
                '友達から招待コードをもらいましたか？',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'コードを入力すると、紹介者とあなたの両方にチップが付与されます。',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _controller,
                decoration: InputDecoration(
                  labelText: '招待コード',
                  hintText: '例: ABC12345',
                  errorText: _error,
                  border: const OutlineInputBorder(),
                  filled: true,
                ),
                textCapitalization: TextCapitalization.characters,
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _loading ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryOrange,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _loading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('チップを受け取る'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _loading ? null : _skip,
                child: Text(
                  'スキップする',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
