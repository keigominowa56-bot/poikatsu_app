import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:poigo/services/auth_service.dart';
import 'package:poigo/theme/app_colors.dart';

class OtpInputPage extends StatefulWidget {
  const OtpInputPage({
    super.key,
    required this.verificationId,
    required this.phoneNumber,
  });

  final String verificationId;
  final String phoneNumber;

  @override
  State<OtpInputPage> createState() => _OtpInputPageState();
}

class _OtpInputPageState extends State<OtpInputPage> {
  final TextEditingController _codeController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final code = _codeController.text.trim();
    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('6桁の認証コードを入力してください')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      await AuthService.instance.signInWithCredential(
        verificationId: widget.verificationId,
        smsCode: code,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? '認証に失敗しました')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('認証に失敗しました。時間をおいて再度お試しください。')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SMS認証コード入力')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '${widget.phoneNumber} 宛に送信された6桁のコードを入力してください。',
                style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _codeController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: const InputDecoration(
                  labelText: '認証コード（6桁）',
                  border: OutlineInputBorder(),
                  counterText: '',
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _loading ? null : _verify,
                child: _loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('認証する'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

