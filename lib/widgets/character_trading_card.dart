import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:poigo/models/character_card.dart';
import 'package:poigo/theme/app_colors.dart';

/// トレーディングカード風キャラクター表示（枠・名前・星・属性・説明文）
/// Lv.1〜2: シンプル / Lv.3+: アニメ縁・キラキラ / Lv.4+: オーラ
class CharacterTradingCard extends StatefulWidget {
  const CharacterTradingCard({
    super.key,
    required this.card,
    this.size = 280,
    this.onTap,
  });

  final CharacterCard card;
  final double size;
  final VoidCallback? onTap;

  @override
  State<CharacterTradingCard> createState() => _CharacterTradingCardState();
}

class _CharacterTradingCardState extends State<CharacterTradingCard>
    with TickerProviderStateMixin {
  late AnimationController _tiltController;
  late AnimationController _shimmerController;
  late AnimationController _particleController;

  @override
  void initState() {
    super.initState();
    _tiltController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    )..repeat(reverse: true);
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    )..repeat();
    _particleController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _tiltController.dispose();
    _shimmerController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final card = widget.card;
    final size = widget.size;
    final isRare = card.isRare;
    final isCustom = card.isCustom;

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: Listenable.merge([_tiltController, _shimmerController, _particleController]),
        builder: (context, child) {
          final tilt = isRare ? 0.02 * math.sin(_tiltController.value * 2 * math.pi) : 0.0;
          return Transform(
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateX(tilt)
              ..rotateY(tilt * 0.5),
            alignment: Alignment.center,
            child: child,
          );
        },
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (isCustom) _buildAuraParticles(size),
            if (isRare) _buildSparkleParticles(size),
            _buildCardContent(card, size, isRare),
            if (isRare) _buildAnimatedBorder(size),
          ],
        ),
      ),
    );
  }

  Widget _buildAuraParticles(double size) {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _particleController,
        builder: (context, _) {
          return CustomPaint(
            size: Size(size, size * 1.4),
            painter: _AuraParticlePainter(
              progress: _particleController.value,
              color: AppColors.primaryOrange.withOpacity(0.3),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSparkleParticles(double size) {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _particleController,
        builder: (context, _) {
          return CustomPaint(
            size: Size(size, size * 1.4),
            painter: _SparkleParticlePainter(progress: _particleController.value),
          );
        },
      ),
    );
  }

  Widget _buildCardContent(CharacterCard card, double size, bool isRare) {
    final w = size;
    final h = size * 1.35;
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: isRare ? AppColors.cardWhite : AppColors.surface,
        border: Border.all(
          color: isRare
              ? AppColors.primaryOrange.withOpacity(0.75)
              : AppColors.primaryYellow.withOpacity(0.8),
          width: 4,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withOpacity(0.12),
            blurRadius: isRare ? 20 : 12,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: (isRare ? AppColors.primaryOrange : AppColors.primaryYellow).withOpacity(0.25),
            blurRadius: 8,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Column(
          children: [
            SizedBox(height: 8),
            Text(
              card.name,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.navy,
              ),
            ),
            _buildStars(card.stars),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isRare
                    ? AppColors.primaryYellow.withOpacity(0.4)
                    : AppColors.textSecondary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                card.attribute,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isRare ? AppColors.navy : AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: w * 0.55,
              height: w * 0.55,
              child: _buildCharacterImage(card),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
              child: Text(
                card.description,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.3,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStars(int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (i) {
        return Icon(
          i < count ? Icons.star_rounded : Icons.star_border_rounded,
          size: 16,
          color: AppColors.primaryYellow,
        );
      }),
    );
  }

  Widget _buildCharacterImage(CharacterCard card) {
    if (card.imageUrl != null && card.imageUrl!.isNotEmpty) {
      return Image.network(
        card.imageUrl!,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => _placeholderIcon(),
      );
    }
    final path = card.imageAssetPath ?? 'assets/images/jelly_lv1.gif';
    return Image.asset(
      path,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) {
        final fallback = 'assets/images/jelly_lv${card.level.clamp(1, 3)}.gif';
        return Image.asset(
          fallback,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => _placeholderIcon(),
        );
      },
    );
  }

  Widget _placeholderIcon() {
    return Center(
      child: Icon(Icons.pets, size: 64, color: AppColors.textSecondary),
    );
  }

  Widget _buildAnimatedBorder(double size) {
    final w = size + 8;
    final h = size * 1.35 + 8;
    return Positioned(
      width: w,
      height: h,
      child: AnimatedBuilder(
        animation: _shimmerController,
        builder: (context, _) {
          return CustomPaint(
            size: Size(w, h),
            painter: _ShimmerBorderPainter(
              progress: _shimmerController.value,
              borderRadius: 18,
            ),
          );
        },
      ),
    );
  }
}

class _ShimmerBorderPainter extends CustomPainter {
  _ShimmerBorderPainter({required this.progress, required this.borderRadius});
  final double progress;
  final double borderRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(borderRadius),
    );
    final colors = [
      AppColors.primaryYellow,
      AppColors.primaryOrange,
      const Color(0xFFFFD700),
      AppColors.primaryYellow,
    ];
    final gradient = SweepGradient(
      startAngle: progress * 2 * math.pi,
      endAngle: progress * 2 * math.pi + 2 * math.pi,
      colors: colors,
    );
    final paint = Paint()
      ..shader = gradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    canvas.drawRRect(rect, paint);
  }

  @override
  bool shouldRepaint(covariant _ShimmerBorderPainter old) => old.progress != progress;
}

class _SparkleParticlePainter extends CustomPainter {
  _SparkleParticlePainter({required this.progress});
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = math.Random(42);
    for (int i = 0; i < 12; i++) {
      final x = (rnd.nextDouble() * size.width * 0.8 + size.width * 0.1);
      final y = (rnd.nextDouble() * size.height * 0.6 + size.height * 0.2);
      final phase = (i / 12 + progress) % 1.0;
      final alpha = (math.sin(phase * 2 * math.pi) * 0.5 + 0.5).clamp(0.0, 1.0);
      final paint = Paint()
        ..color = AppColors.primaryYellow.withOpacity(alpha * 0.6)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(x, y), 2, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SparkleParticlePainter old) => old.progress != progress;
}

class _AuraParticlePainter extends CustomPainter {
  _AuraParticlePainter({required this.progress, required this.color});
  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    for (int i = 0; i < 8; i++) {
      final angle = (i / 8) * 2 * math.pi + progress * 2 * math.pi;
      final r = size.width * 0.35 + math.sin(progress * 4 * math.pi + i) * 10;
      final x = center.dx + math.cos(angle) * r;
      final y = center.dy + math.sin(angle) * r * 0.6;
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(x, y), 8, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _AuraParticlePainter old) =>
      old.progress != progress || old.color != color;
}
