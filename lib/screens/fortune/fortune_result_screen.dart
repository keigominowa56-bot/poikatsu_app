import 'dart:math' as math;
import 'dart:ui';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';

import '../../models/fortune_settings_model.dart';
import '../../services/fortune_logic.dart';
import '../../services/fortune_settings_service.dart';
import '../../widgets/video_reward_dialog.dart';

/// 生年月日を軸にした精密診断の「最も豪華な最終結果画面」
class FortuneResultScreen extends StatefulWidget {
  const FortuneResultScreen({
    super.key,
    required this.uid,
    required this.birthDate,
  });

  final String uid;
  final DateTime birthDate;

  @override
  State<FortuneResultScreen> createState() => _FortuneResultScreenState();
}

class _FortuneResultScreenState extends State<FortuneResultScreen> {
  late ConfettiController _confettiController;
  bool _choiceShown = false;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _choiceShown) return;
      _choiceShown = true;
      showPointRewardChoiceDialog(
        context: context,
        uid: widget.uid,
        onComplete: () {
          Future.delayed(const Duration(milliseconds: 400), () {
            if (mounted) _confettiController.play();
          });
        },
      );
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final zodiac = FortuneLogic.zodiacSign(widget.birthDate);
    final lifePath = FortuneLogic.lifePathNumber(widget.birthDate);
    final numerologyMsg = FortuneLogic.numerologyMessage(lifePath);
    final dayMsg = FortuneLogic.dayOfYearMessage(widget.birthDate);
    final today = DateTime.now();
    final rawScore = FortuneLogic.dailyBiorhythmScore(widget.birthDate, today);
    final chartScores = FortuneLogic.biorhythmScoresForChart(widget.birthDate, today);
    final luckyColor = FortuneLogic.tomorrowLuckyColorName(today);

    return StreamBuilder<FortuneSettingsModel>(
      stream: FortuneSettingsService.instance.streamFortuneSettings(),
      builder: (context, settingsSnapshot) {
        final settings = settingsSnapshot.data ?? const FortuneSettingsModel();
        final score = (rawScore * settings.luckyFactor).round().clamp(0, 100);
        final hasGlobalMessage = settings.globalMessage.trim().isNotEmpty;
        final hasSpecialEvent = settings.specialEvent.trim().isNotEmpty;

        return Scaffold(
          body: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: const [
                      Color(0xFF1B365D),
                      Color(0xFF2C4A6F),
                      Color(0xFF243B55),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                    slivers: [
                      SliverAppBar(
                        expandedHeight: 100,
                        pinned: true,
                        backgroundColor: Colors.transparent,
                        flexibleSpace: FlexibleSpaceBar(
                          title: Text(
                            '精密診断リザルト',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.95),
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          background: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Colors.black26, Colors.transparent],
                              ),
                            ),
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate([
                            if (hasGlobalMessage || hasSpecialEvent) ...[
                              _glassCard(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _sectionLabel('運営からのメッセージ'),
                                    if (hasSpecialEvent) ...[
                                      const SizedBox(height: 6),
                                      Text(
                                        settings.specialEvent.trim(),
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.amber.shade200,
                                        ),
                                      ),
                                    ],
                                    if (hasGlobalMessage) ...[
                                      if (hasSpecialEvent) const SizedBox(height: 10),
                                      Text(
                                        settings.globalMessage.trim(),
                                        style: TextStyle(
                                          fontSize: 15,
                                          height: 1.5,
                                          color: Colors.white.withOpacity(0.95),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                            _glassCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _sectionLabel('あなたの星座'),
                              const SizedBox(height: 8),
                              Text(
                                zodiac,
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 1,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${widget.birthDate.year}年${widget.birthDate.month}月${widget.birthDate.day}日生まれ',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white.withOpacity(0.85),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        _glassCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _sectionLabel('今日のバイオリズム'),
                              const SizedBox(height: 16),
                              _BiorhythmGauge(score: score),
                              const SizedBox(height: 16),
                              _BiorhythmChart(scores: chartScores),
                              const SizedBox(height: 8),
                              Text(
                                '$score / 100',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        _glassCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _sectionLabel('数秘術（ライフパスナンバー $lifePath）'),
                              const SizedBox(height: 8),
                              Text(
                                numerologyMsg,
                                style: TextStyle(
                                  fontSize: 15,
                                  height: 1.5,
                                  color: Colors.white.withOpacity(0.95),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        _glassCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _sectionLabel('その日生まれのあなたへ'),
                              const SizedBox(height: 8),
                              Text(
                                dayMsg,
                                style: TextStyle(
                                  fontSize: 15,
                                  height: 1.5,
                                  color: Colors.white.withOpacity(0.95),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        _glassCard(
                          child: Column(
                            children: [
                              Icon(Icons.star_rounded, size: 48, color: Colors.amber.shade300),
                              const SizedBox(height: 12),
                              Text(
                                '1pt獲得しました！',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.amber.shade200,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '診断を見たご褒美です',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white.withOpacity(0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        _glassCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _sectionLabel('明日もまた来たくなる一言'),
                              const SizedBox(height: 12),
                              Text(
                                '明日のあなたのラッキーカラーは$luckyColorです。明日また確認に来てね！',
                                style: TextStyle(
                                  fontSize: 16,
                                  height: 1.5,
                                  color: Colors.white.withOpacity(0.95),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        Center(
                          child: Text(
                            '今日も良い一日を',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.7),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                        const SizedBox(height: 48),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: math.pi / 2,
              maxBlastForce: 25,
              minBlastForce: 8,
              numberOfParticles: 30,
              gravity: 0.15,
              colors: const [
                Color(0xFFFF6B35),
                Color(0xFF9CCC65),
                Colors.amber,
                Colors.orange,
                Colors.white,
              ],
              shouldLoop: false,
            ),
          ),
        ],
      ),
    );
      },
    );
  }

  Widget _glassCard({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.12),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Colors.white.withOpacity(0.7),
        letterSpacing: 0.5,
      ),
    );
  }
}

/// 円形ゲージでバイオリズムスコアを表示
class _BiorhythmGauge extends StatelessWidget {
  const _BiorhythmGauge({required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    const size = 100.0;
    const strokeWidth = 10.0;
    final ratio = (score / 100).clamp(0.0, 1.0);
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _GaugePainter(
          progress: ratio,
          strokeWidth: strokeWidth,
          backgroundColor: Colors.white24,
          progressColor: const Color(0xFFFF6B35),
        ),
        size: const Size(size, size),
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  _GaugePainter({
    required this.progress,
    required this.strokeWidth,
    required this.backgroundColor,
    required this.progressColor,
  });

  final double progress;
  final double strokeWidth;
  final Color backgroundColor;
  final Color progressColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide / 2) - strokeWidth / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = backgroundColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );

    if (progress > 0) {
      final sweepAngle = 2 * math.pi * progress;
      canvas.drawArc(
        rect,
        -math.pi / 2,
        sweepAngle,
        false,
        Paint()
          ..color = progressColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GaugePainter old) =>
      old.progress != progress || old.strokeWidth != strokeWidth;
}

/// 過去7日分のバイオリズムをシンプルな折れ線グラフで表示
class _BiorhythmChart extends StatelessWidget {
  const _BiorhythmChart({required this.scores});

  final List<int> scores;

  @override
  Widget build(BuildContext context) {
    if (scores.isEmpty) return const SizedBox.shrink();
    const height = 60.0;
    const padding = 8.0;
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        return SizedBox(
          width: w,
          height: height + padding * 2,
          child: CustomPaint(
            painter: _LineChartPainter(
              values: scores.map((e) => e / 100.0).toList(),
              lineColor: const Color(0xFFFF6B35),
              gridColor: Colors.white24,
            ),
            size: Size(w, height + padding * 2),
          ),
        );
      },
    );
  }
}

class _LineChartPainter extends CustomPainter {
  _LineChartPainter({
    required this.values,
    required this.lineColor,
    required this.gridColor,
  });

  final List<double> values;
  final Color lineColor;
  final Color gridColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    const padding = 8.0;
    final w = size.width - padding * 2;
    final h = size.height - padding * 2;
    final minY = 0.0;
    final maxY = 1.0;
    final stepX = w / (values.length - 1);

    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final x = padding + i * stepX;
      final y = padding + h - (values[i].clamp(0.0, 1.0) - minY) / (maxY - minY) * h;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = lineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter old) =>
      old.values != values;
}
