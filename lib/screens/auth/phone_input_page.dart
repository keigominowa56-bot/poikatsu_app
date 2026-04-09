import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:poigo/screens/auth/otp_input_page.dart';
import 'package:poigo/services/auth_service.dart';
import 'package:poigo/theme/app_colors.dart';

class PhoneInputPage extends StatefulWidget {
  const PhoneInputPage({super.key});

  @override
  State<PhoneInputPage> createState() => _PhoneInputPageState();
}

class _PhoneInputPageState extends State<PhoneInputPage> {
  final TextEditingController _phoneController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    final supported = await AuthService.instance.isPhoneAuthSupportedOnCurrentDevice();
    if (!supported) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('iOSシミュレーターでは電話番号認証を利用できません。実機でお試しください。'),
        ),
      );
      return;
    }

    final input = _phoneController.text.trim();
    if (input.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('電話番号を入力してください')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final verificationId = await AuthService.instance.verifyPhoneNumber(input);
      final normalized = AuthService.instance.normalizeJpPhoneNumber(input);
      if (!mounted) return;
      final ok = await Navigator.of(context).push<bool>(
        MaterialPageRoute<bool>(
          builder: (_) => OtpInputPage(
            verificationId: verificationId,
            phoneNumber: normalized,
          ),
        ),
      );
      if (ok == true && mounted) {
        Navigator.of(context).pop(true);
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'SMS送信に失敗しました')),
      );
    } on FormatException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('SMS送信に失敗しました。時間をおいて再度お試しください。')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('電話番号認証')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryYellow.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '不正防止のため、初回交換時のみ本人確認（SMS認証）が必要です。',
                  style: TextStyle(fontSize: 14, color: AppColors.textPrimary),
                ),
              ),
              const SizedBox(height: 16),
              const Text('電話番号（先頭0から入力）'),
              const SizedBox(height: 8),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  hintText: '09012345678',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _loading ? null : _sendCode,
                child: _loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('認証コードを送信'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

