import 'dart:async';

import 'package:flutter/material.dart';

/// 解析ボタン押下後、広告の前に約5秒表示する「あなたの運命を計算中...」演出
class CalculatingOverlayScreen extends StatefulWidget {
  const CalculatingOverlayScreen({
    super.key,
    required this.onComplete,
    this.duration = const Duration(seconds: 5),
  });

  final VoidCallback onComplete;
  final Duration duration;

  @override
  State<CalculatingOverlayScreen> createState() => _CalculatingOverlayScreenState();
}

class _CalculatingOverlayScreenState extends State<CalculatingOverlayScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    Future.delayed(widget.duration, () {
      if (!mounted) return;
      widget.onComplete();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF1B365D),
      child: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: 0.85 + 0.15 * _pulseController.value,
                    child: child,
                  );
                },
                child: const SizedBox(
                  width: 72,
                  height: 72,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF6B35)),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'あなたの運命を計算中...',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withOpacity(0.95),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'しばらくお待ちください',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
