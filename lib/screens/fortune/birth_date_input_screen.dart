import 'package:flutter/material.dart';

import '../../services/user_firestore_service.dart';

/// プロフィールに生年月日がない場合、占いフロー内で表示する生年月日入力画面（DatePicker）
class BirthDateInputScreen extends StatefulWidget {
  const BirthDateInputScreen({
    super.key,
    required this.uid,
    this.initialDate,
  });

  final String uid;
  final DateTime? initialDate;

  @override
  State<BirthDateInputScreen> createState() => _BirthDateInputScreenState();
}

class _BirthDateInputScreenState extends State<BirthDateInputScreen> {
  late DateTime _selectedDate;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate ??
        DateTime(DateTime.now().year - 30, DateTime.now().month, DateTime.now().day);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      locale: const Locale('ja'),
    );
    if (picked != null && mounted) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _confirm() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await UserFirestoreService.instance.saveBirthDate(widget.uid, _selectedDate);
      if (!mounted) return;
      Navigator.of(context).pop(_selectedDate);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('生年月日を入力'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                '精密診断のために生年月日を教えてください。',
                style: TextStyle(fontSize: 16, height: 1.4),
              ),
              const SizedBox(height: 24),
              ListTile(
                title: const Text('生年月日'),
                subtitle: Text(
                  '${_selectedDate.year}年${_selectedDate.month}月${_selectedDate.day}日',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: _pickDate,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                tileColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: _saving ? null : _confirm,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _saving
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('この日付で確定'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
