import 'package:flutter/material.dart';
import 'package:poigo/models/character_card.dart';
import 'package:poigo/widgets/character_trading_card.dart';

/// レベルアップ時: 古いカードが光に包まれて新しいカードに切り替わる進化アニメーション
class CharacterEvolutionAnimation extends StatefulWidget {
  const CharacterEvolutionAnimation({
    super.key,
    required this.oldCard,
    required this.newCard,
    required this.size,
    this.onComplete,
  });

  final CharacterCard oldCard;
  final CharacterCard newCard;
  final double size;
  final VoidCallback? onComplete;

  @override
  State<CharacterEvolutionAnimation> createState() =>
      _CharacterEvolutionAnimationState();
}

class _CharacterEvolutionAnimationState extends State<CharacterEvolutionAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _glowOpacity;
  late Animation<double> _oldScale;
  late Animation<double> _oldFade;
  late Animation<double> _newScale;
  late Animation<double> _newFade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _glowOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: 1), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 1, end: 1), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 1, end: 0), weight: 50),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _oldScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1, end: 1), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1, end: 0.85), weight: 70),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));
    _oldFade = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1, end: 1), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1, end: 0), weight: 70),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));
    _newScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.5, end: 0.5), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 0.5, end: 1.05), weight: 35),
      TweenSequenceItem(tween: Tween(begin: 1.05, end: 1), weight: 15),
    // NOTE:
    // TweenSequence は transform 時の t が 0..1 を前提にしている。
    // Curves.easeOutBack のようなオーバーシュート系カーブを直接かけると
    // 一時的に 1.0 を超えて assert になるため、0..1 に収まるカーブを使う。
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _newFade = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: 0), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 0, end: 1), weight: 50),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward().then((_) => widget.onComplete?.call());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Stack(
          alignment: Alignment.center,
          children: [
            Opacity(
              opacity: _glowOpacity.value,
              child: Container(
                width: size + 40,
                height: size * 1.4 + 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.amber.withOpacity(0.6),
                      blurRadius: 40,
                      spreadRadius: 10,
                    ),
                    BoxShadow(
                      color: Colors.orange.withOpacity(0.4),
                      blurRadius: 60,
                      spreadRadius: 5,
                    ),
                  ],
                ),
              ),
            ),
            Opacity(
              opacity: _oldFade.value,
              child: Transform.scale(
                scale: _oldScale.value,
                child: CharacterTradingCard(
                  card: widget.oldCard,
                  size: size,
                ),
              ),
            ),
            Opacity(
              opacity: _newFade.value,
              child: Transform.scale(
                scale: _newScale.value,
                child: CharacterTradingCard(
                  card: widget.newCard,
                  size: size,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
