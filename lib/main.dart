import 'dart:async';
import 'dart:math' as math;
import 'package:app_links/app_links.dart';
import 'package:confetti/confetti.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import 'admin/admin_app.dart';
import 'data/life_info_data_source.dart';
import 'widgets/japan_weather_tab.dart';
import 'data/prefecture_list.dart';
import 'constants/point_constants.dart';
import 'firebase_options.dart';
import 'models/news_model.dart';
import 'models/news_settings_model.dart';
import 'models/user_model.dart';
import 'screens/exchange/exchange_menu_screen.dart';
import 'screens/fortune/fortune_flow_screen.dart';
import 'screens/lottery/my_lottery_screen.dart';
import 'screens/ledger/earnings_ledger_screen.dart';
import 'screens/otoku/otoku_mission_list_screen.dart';
import 'screens/referral/referral_input_screen.dart';
import 'screens/slot/slot_screen.dart';
import 'screens/ranking/ranking_screen.dart';
import 'screens/settings/privacy_policy_screen.dart';
import 'screens/settings/tokushoho_screen.dart';
import 'screens/settings/terms_of_service_screen.dart';
import 'screens/skyflag_offerwall_screen.dart';
import 'services/ad_service.dart';
import 'services/poigo_scheme_navigation.dart';
import 'services/lottery_service.dart';
import 'services/device_id_service.dart';
import 'services/economy_settings_service.dart';
import 'services/step_count_service.dart';
import 'services/openai_character_service.dart';
import 'services/user_firestore_service.dart';
import 'theme/app_colors.dart';
import 'widgets/video_reward_dialog.dart';
import 'models/character_card.dart';
import 'services/character_evolution_service.dart';
import 'services/skyflag_service.dart';
import 'widgets/character_trading_card.dart';
import 'widgets/character_evolution_animation.dart';
import 'widgets/app_tutorial_overlay.dart';
import 'services/level_up_ai_offer.dart';
import 'services/tutorial_prefs.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await _ensureFirebaseInitialized();

  try {
    if (Firebase.apps.isNotEmpty) {
      await FirebaseAuth.instance.signInAnonymously();
    }
  } catch (e) {
    // ignore: avoid_print
    print('Firebase Auth signInAnonymously error: $e');
  }

  // Web のときは管理画面、それ以外はアプリ
  if (kIsWeb) {
    runApp(const AdminApp());
    return;
  }

  await AdService.initialize();

  unawaited(_listenPoigoDeepLinks());

  final stepService = StepCountService.instance;
  stepService.start();
  stepService.enableSimulationFallbackAfterDelay();

  runApp(const PoikatsuApp());
}

/// SKYFLAG 等からの `poigo://open/browser?url=` を OS 経由で受けたときに外部ブラウザを開く。
Future<void> _listenPoigoDeepLinks() async {
  try {
    final appLinks = AppLinks();
    final initial = await appLinks.getInitialLink();
    if (initial != null) {
      await PoigoSchemeNavigation.handleIncomingUri(initial);
    }
    appLinks.uriLinkStream.listen((uri) {
      unawaited(PoigoSchemeNavigation.handleIncomingUri(uri));
    });
  } catch (e) {
    if (kDebugMode) {
      // ignore: avoid_print
      print('Poigo deep link init: $e');
    }
  }
}

Future<void> _ensureFirebaseInitialized() async {
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } on FirebaseException catch (e) {
    // iOS の再起動・複数エンジン環境で [DEFAULT] が既にある場合は継続する。
    if (e.code != 'duplicate-app') {
      // ignore: avoid_print
      print('Firebase initialization error: $e');
    }
  } catch (e) {
    // ignore: avoid_print
    print('Firebase initialization error: $e');
  }
}

/// 500歩 = 1単位（タンク1つ分）
const int stepsPerTankUnit = 500;

/// ペット満腹度・清潔度の経過時間による減少（1時間で10%）
const double petDecayPerHour = 0.10;

double _petDecayedValue(double stored, DateTime? lastUpdate) {
  final last = lastUpdate ?? DateTime.now();
  final hours = DateTime.now().difference(last).inMinutes / 60.0;
  final decay = (hours * petDecayPerHour).clamp(0.0, 1.0);
  return (stored - decay).clamp(0.0, 1.0);
}

/// 歩数から3つのタンクの進捗（0.0〜1.0）を計算
List<double> tankLevelsFromSteps(int steps) {
  return [
    (steps / stepsPerTankUnit).clamp(0.0, 1.0),
    ((steps - stepsPerTankUnit) / stepsPerTankUnit).clamp(0.0, 1.0),
    ((steps - stepsPerTankUnit * 2) / stepsPerTankUnit).clamp(0.0, 1.0),
  ];
}

class PoikatsuApp extends StatelessWidget {
  const PoikatsuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ポイ活',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primaryYellow,
          primary: AppColors.primaryYellow,
          secondary: AppColors.navy,
          surface: AppColors.surface,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: AppColors.background,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.background,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          centerTitle: true,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryYellow,
            foregroundColor: AppColors.navy,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
        ),
        tabBarTheme: const TabBarThemeData(
          labelColor: AppColors.navy,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.navy,
          indicatorSize: TabBarIndicatorSize.label,
          labelPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  static const List<_TabItem> _tabs = [
    _TabItem(icon: Icons.stars_rounded, label: 'チップ'),
    _TabItem(icon: Icons.local_offer_rounded, label: 'おトク'),
    _TabItem(icon: Icons.thumb_up_rounded, label: 'イチオシ'),
    _TabItem(icon: Icons.history_rounded, label: 'ログ'),
    _TabItem(icon: Icons.person_rounded, label: 'マイページ'),
  ];

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnap) {
        final uid = authSnap.data?.uid;
        if (uid == null) {
          return Scaffold(
            body: const Center(child: CircularProgressIndicator(color: AppColors.primaryYellow)),
            bottomNavigationBar: _buildNavBar(),
          );
        }
        return StreamBuilder<UserModel?>(
          stream: UserFirestoreService.instance.streamUser(uid),
          builder: (context, userSnap) {
            final user = userSnap.data;
            if (user == null && userSnap.connectionState != ConnectionState.waiting) {
              return Scaffold(
                body: _EnsureUserView(uid: uid),
              );
            }
            if (user != null && user.isBanned) {
              return Scaffold(
                body: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.block, size: 48, color: AppColors.textSecondary),
                        const SizedBox(height: 16),
                        Text(
                          'アカウントは停止されています。',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16, color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }
            final showReferral = user != null &&
                user.referredBy == null &&
                (user.referralPromptSeen != true);
            return Scaffold(
              body: showReferral
                  ? ReferralInputScreen(uid: uid)
                  : _TutorialGate(
                      child: IndexedStack(
                        index: _currentIndex,
                        children: [
                          MileTab(uid: uid),
                          OtokuTab(uid: uid),
                          IchioshiTab(uid: uid),
                          LogTab(uid: uid),
                          MyPageTab(uid: uid),
                        ],
                      ),
                    ),
              bottomNavigationBar: showReferral ? null : _buildNavBar(),
            );
          },
        );
      },
    );
  }

  Widget _buildNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            children: List.generate(_tabs.length, (index) {
              final tab = _tabs[index];
              final isSelected = _currentIndex == index;
              return Expanded(
                child: _NavBarItem(
                  icon: tab.icon,
                  label: tab.label,
                  isSelected: isSelected,
                  onTap: () => setState(() => _currentIndex = index),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

/// 初回だけチュートリアルオーバーレイを重ねる
class _TutorialGate extends StatefulWidget {
  const _TutorialGate({required this.child});

  final Widget child;

  @override
  State<_TutorialGate> createState() => _TutorialGateState();
}

class _TutorialGateState extends State<_TutorialGate> {
  bool? _showOverlay;

  @override
  void initState() {
    super.initState();
    TutorialPrefs.isCompleted().then((done) {
      if (!mounted) return;
      setState(() => _showOverlay = !done);
    });
  }

  @override
  Widget build(BuildContext context) {
    final show = _showOverlay == true;
    return Stack(
      children: [
        widget.child,
        if (show)
          Positioned.fill(
            child: AppTutorialOverlay(
              onFinish: () => setState(() => _showOverlay = false),
            ),
          ),
      ],
    );
  }
}

/// 初回: ユーザードキュメントが無い場合に作成（デバイス1台1アカウントチェック付き）
class _EnsureUserView extends StatefulWidget {
  const _EnsureUserView({required this.uid});

  final String uid;

  @override
  State<_EnsureUserView> createState() => _EnsureUserViewState();
}

class _EnsureUserViewState extends State<_EnsureUserView> {
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _create();
  }

  Future<void> _create() async {
    try {
      await UserFirestoreService.instance.ensureUserExists(widget.uid);
      if (mounted) setState(() => _loading = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e is StateError ? e.message : e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.warning_amber_rounded, size: 48, color: AppColors.primaryOrange),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textPrimary, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }
    return const Center(
      child: CircularProgressIndicator(color: AppColors.primaryOrange),
    );
  }
}

class _TabItem {
  final IconData icon;
  final String label;
  const _TabItem({required this.icon, required this.label});
}

class _NavBarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? AppColors.primaryYellow : AppColors.textSecondary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24, color: color),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: color,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── 円形ポイントタンク（グラデーション・アニメーション） ───

class PointTankGauge extends StatefulWidget {
  final double fillRatio;
  final double size;
  final double strokeWidth;
  final bool showGetButton;
  /// 満タン時: リワード広告で受取（固定30チップ）
  final VoidCallback? onClaimWithVideo;
  /// 満タン時: 広告なしで受取（固定1チップ）
  final VoidCallback? onClaimPlain;

  const PointTankGauge({
    super.key,
    required this.fillRatio,
    this.size = 88,
    this.strokeWidth = 8,
    this.showGetButton = false,
    this.onClaimWithVideo,
    this.onClaimPlain,
  });

  @override
  State<PointTankGauge> createState() => _PointTankGaugeState();
}

class _PointTankGaugeState extends State<PointTankGauge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: widget.fillRatio).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(PointTankGauge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fillRatio != widget.fillRatio) {
      _animation = Tween<double>(begin: _animation.value, end: widget.fillRatio)
          .animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ));
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: widget.size,
          height: widget.size,
          child: AnimatedBuilder(
            animation: _animation,
            builder: (context, _) => CustomPaint(
              painter: _GaugePainter(
                progress: _animation.value,
                strokeWidth: widget.strokeWidth,
              ),
              size: Size(widget.size, widget.size),
            ),
          ),
        ),
        if (widget.showGetButton &&
            widget.onClaimWithVideo != null &&
            widget.onClaimPlain != null) ...[
          const SizedBox(height: 8),
          SizedBox(
            width: widget.size + 24,
            child: _TankClaimButtons(
              onVideo: widget.onClaimWithVideo!,
              onPlain: widget.onClaimPlain!,
            ),
          ),
        ],
      ],
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double progress;
  final double strokeWidth;

  _GaugePainter({required this.progress, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide / 2) - strokeWidth / 2;

    // 背景円
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = AppColors.surface
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );

    if (progress <= 0) return;

    final sweepAngle = 2 * math.pi * progress;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final gradient = SweepGradient(
      startAngle: -math.pi / 2,
      endAngle: 3 * math.pi / 2,
      colors: const [AppColors.gaugeStart, AppColors.gaugeEnd],
    );
    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      rect,
      -math.pi / 2,
      sweepAngle,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _GaugePainter old) =>
      old.progress != progress || old.strokeWidth != strokeWidth;
}

class _TankClaimButtons extends StatelessWidget {
  const _TankClaimButtons({required this.onVideo, required this.onPlain});

  final VoidCallback onVideo;
  final VoidCallback onPlain;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _PulsingStepTankVideoButton(onPressed: onVideo),
        const SizedBox(height: 8),
        TextButton(
          onPressed: onPlain,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.textSecondary,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            'そのまま受け取る（${PointConstants.formatChips(PointConstants.stepTankPlainChips)}チップ）',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}

/// 歩数タンク専用: グラデーション＋軽いパルス
class _PulsingStepTankVideoButton extends StatefulWidget {
  const _PulsingStepTankVideoButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  State<_PulsingStepTankVideoButton> createState() => _PulsingStepTankVideoButtonState();
}

class _PulsingStepTankVideoButtonState extends State<_PulsingStepTankVideoButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        final t = 0.97 + 0.06 * Curves.easeInOut.transform(_pulse.value);
        return Transform.scale(scale: t, child: child);
      },
      child: Material(
        color: Colors.transparent,
        elevation: 6,
        shadowColor: AppColors.primaryOrange.withOpacity(0.45),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: widget.onPressed,
          borderRadius: BorderRadius.circular(14),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primaryOrange,
                  AppColors.primaryOrange.withOpacity(0.85),
                  AppColors.primaryYellow,
                ],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              child: Row(
                children: [
                  const Icon(Icons.play_circle_filled_rounded, color: Colors.white, size: 26),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '動画を見て${PointConstants.stepTankVideoMultiplierDisplay}倍（${PointConstants.formatChips(PointConstants.stepTankVideoChips)}チップ）GET',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                        height: 1.25,
                      ),
                      maxLines: 3,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 歩数タンク: リワード広告 → 固定30チップ付与
void _onStepTankClaimWithVideo(BuildContext context, String uid) {
  AdService.showRewardAd(
    context: context,
    onComplete: () async {
      await UserFirestoreService.instance.addPointsAndConsumeTank(
        uid,
        fixedAwardChips: PointConstants.stepTankVideoChips,
      );
      if (!context.mounted) return;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => _StepTankBigRewardDialog(chips: PointConstants.stepTankVideoChips),
      );
    },
    onFallback: () {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('広告を準備中です。少し待ってから再度お試しください')),
      );
    },
  );
}

/// 歩数タンク: 広告なしで固定1チップ付与
Future<void> _onStepTankClaimPlain(BuildContext context, String uid) async {
  await UserFirestoreService.instance.addPointsAndConsumeTank(
    uid,
    fixedAwardChips: PointConstants.stepTankPlainChips,
  );
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        '${PointConstants.formatChips(PointConstants.stepTankPlainChips)}チップを受け取りました',
      ),
    ),
  );
}

class _StepTankBigRewardDialog extends StatefulWidget {
  const _StepTankBigRewardDialog({required this.chips});

  final int chips;

  @override
  State<_StepTankBigRewardDialog> createState() => _StepTankBigRewardDialogState();
}

class _StepTankBigRewardDialogState extends State<_StepTankBigRewardDialog> {
  late ConfettiController _confetti;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 3));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _confetti.play();
    });
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      child: Stack(
        alignment: Alignment.topCenter,
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: -28,
            left: 0,
            right: 0,
            height: 180,
            child: ConfettiWidget(
              confettiController: _confetti,
              blastDirectionality: BlastDirectionality.explosive,
              emissionFrequency: 0.08,
              numberOfParticles: 28,
              maxBlastForce: 25,
              minBlastForce: 12,
              gravity: 0.2,
              colors: const [
                Color(0xFFFF6B35),
                Color(0xFFFFC107),
                Color(0xFFFFE082),
                Colors.white,
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
            decoration: BoxDecoration(
              color: AppColors.cardWhite,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.navy.withOpacity(0.12),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '動画ボーナス！',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [
                      AppColors.primaryOrange,
                      AppColors.primaryYellow,
                      AppColors.navy,
                    ],
                  ).createShader(bounds),
                  child: Text(
                    PointConstants.formatChips(widget.chips),
                    style: const TextStyle(
                      fontSize: 44,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -1,
                    ),
                  ),
                ),
                const Text(
                  'チップ獲得',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.navy,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${PointConstants.stepTankVideoMultiplierDisplay}倍ボーナス（歩数タンク）',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.35),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primaryOrange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('やった！'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 動画くじ: 動画視聴後に抽選アニメ→1〜5pt付与
void _showVideoLottery(BuildContext context, String uid) {
  showVideoRewardDialog(
    context: context,
    title: '動画を見てくじを引く',
    subtitle: '視聴完了でくじが引けます。1〜5チップが当たります。',
    onComplete: () async {
      final pt = await UserFirestoreService.instance.grantLotteryPoints(uid);
      if (!context.mounted) return;
      if (pt == 0) {
        showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('本日の上限に達しました'),
            content: const Text('動画くじは24時間あたりの回数制限があります。明日またお試しください。'),
            actions: [
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } else {
        _showLotteryResultDialog(context, pt);
      }
    },
  );
}

void _showLotteryResultDialog(BuildContext context, int points) {
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => _LotteryResultDialog(points: points),
  );
}

class _LotteryResultDialog extends StatefulWidget {
  const _LotteryResultDialog({required this.points});

  final int points;

  @override
  State<_LotteryResultDialog> createState() => _LotteryResultDialogState();
}

class _LotteryResultDialogState extends State<_LotteryResultDialog> {
  bool _revealed = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) setState(() => _revealed = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: _revealed
                  ? Text('${PointConstants.formatChips(widget.points)} チップ当たり！', textAlign: TextAlign.center)
          : const Text('抽選中...', textAlign: TextAlign.center),
      content: _revealed
          ? Text(
              '${PointConstants.formatChips(widget.points)}チップを獲得しました！',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            )
          : const SizedBox(
              height: 48,
              child: Center(child: CircularProgressIndicator(color: AppColors.primaryOrange)),
            ),
      actions: [
        if (_revealed)
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
      ],
    );
  }
}

// ─── トリマ風 5タブのうち「チップ」内に黄色サブタブ（移動・歩数 / ニュース / 占い / くじ） ───

/// チップ: ヘッダー（チップ＋交換）＋上部黄色 TabBar（移動・歩数＝ホーム / ニュース / 占い / くじ）
class MileTab extends StatefulWidget {
  const MileTab({super.key, required this.uid});
  final String uid;

  @override
  State<MileTab> createState() => _MileTabState();
}

class _MileTabState extends State<MileTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    // 初期表示は「移動・歩数」（index 0）
    _tabController = TabController(length: 4, vsync: this, initialIndex: 0);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          _MileHeader(uid: widget.uid),
          Material(
            color: AppColors.primaryYellow,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: AppColors.navy,
              unselectedLabelColor: AppColors.navy.withOpacity(0.7),
              indicatorColor: AppColors.navy,
              indicatorSize: TabBarIndicatorSize.label,
              labelPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              tabs: [
                Tab(icon: _TabIcon(assetPath: 'assets/icon/number_of_steps.png', iconSize: 40), text: '移動・歩数'),
                Tab(icon: _TabIcon(assetPath: 'assets/icon/news.png'), text: 'ニュース'),
                Tab(icon: _TabIcon(assetPath: 'assets/icon/fortune telling.png'), text: '占い'),
                Tab(icon: _TabIcon(assetPath: 'assets/icon/Lottery.png'), text: 'くじ'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _MileStepsSubTab(uid: widget.uid),
                _MileNewsSubTab(uid: widget.uid),
                _MileFortuneSubTab(),
                _MileLotterySubTab(uid: widget.uid),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// タブ用アイコン（画像をアイコンとして表示）。読み込み失敗時は Material アイコンで代替
class _TabIcon extends StatelessWidget {
  const _TabIcon({required this.assetPath, this.iconSize = 34});
  final String assetPath;
  /// デフォルト34。移動・歩数など見えにくいアイコンのみ大きくする場合に指定
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: iconSize,
      height: iconSize,
      child: Image.asset(
        assetPath,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Icon(Icons.circle_outlined, size: iconSize, color: AppColors.navy.withOpacity(0.7)),
      ),
    );
  }
}

/// 全タブ共通で上部に固定されるヘッダー（ポイント表示＋交換ボタン）
class _MileHeader extends StatelessWidget {
  const _MileHeader({required this.uid});
  final String uid;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<UserModel?>(
      stream: UserFirestoreService.instance.streamUser(uid),
      builder: (context, snapshot) {
        final totalPoints = snapshot.data?.totalPoints ?? 0;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.background,
            border: Border(bottom: BorderSide(color: AppColors.textSecondary.withOpacity(0.1), width: 1)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '現在のチップ',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    PointConstants.formatChips(totalPoints),
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.navy),
                  ),
                ],
              ),
              FilledButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (ctx) => ExchangeMenuScreen(uid: uid)),
                ),
                icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                label: const Text('交換'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryYellow,
                  foregroundColor: AppColors.navy,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// ニュース: 現在のニュース一覧・詳細を移植
class _MileNewsSubTab extends StatelessWidget {
  const _MileNewsSubTab({required this.uid});
  final String uid;

  @override
  Widget build(BuildContext context) {
    return _NewsTabBody(uid: uid);
  }
}

/// NewsTab の中身（9カテゴリ）をそのまま再利用するためのラッパー
class _NewsTabBody extends StatefulWidget {
  const _NewsTabBody({required this.uid});
  final String uid;

  @override
  State<_NewsTabBody> createState() => _NewsTabBodyState();
}

class _NewsTabBodyState extends State<_NewsTabBody> with SingleTickerProviderStateMixin {
  late TabController _newsTabController;

  @override
  void initState() {
    super.initState();
    _newsTabController = TabController(length: 9, vsync: this);
  }

  @override
  void dispose() {
    _newsTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: AppColors.surface,
          child: TabBar(
            controller: _newsTabController,
            isScrollable: true,
            labelColor: AppColors.navy,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primaryYellow,
            indicatorSize: TabBarIndicatorSize.label,
            labelPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            tabs: const [
              Tab(text: '総合'),
              Tab(text: '天気'),
              Tab(text: '政治'),
              Tab(text: '経済'),
              Tab(text: 'エンタメ'),
              Tab(text: 'スポーツ'),
              Tab(text: '国際'),
              Tab(text: '地域'),
              Tab(text: '交通'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _newsTabController,
            children: [
              _NewsListWithRefill(key: const ValueKey('general'), uid: widget.uid, dataSource: NewsCategoryDataSource(NewsSettingsModel.keyGeneral)),
              JapanWeatherTab(uid: widget.uid),
              _NewsListWithRefill(key: const ValueKey('politics'), uid: widget.uid, dataSource: NewsCategoryDataSource(NewsSettingsModel.keyPolitics)),
              _NewsListWithRefill(key: const ValueKey('economy'), uid: widget.uid, dataSource: NewsCategoryDataSource(NewsSettingsModel.keyEconomy)),
              _NewsListWithRefill(key: const ValueKey('entertainment'), uid: widget.uid, dataSource: NewsCategoryDataSource(NewsSettingsModel.keyEntertainment)),
              _NewsListWithRefill(key: const ValueKey('sports'), uid: widget.uid, dataSource: NewsCategoryDataSource(NewsSettingsModel.keySports)),
              _NewsListWithRefill(key: const ValueKey('international'), uid: widget.uid, dataSource: NewsCategoryDataSource(NewsSettingsModel.keyInternational)),
              _RegionNewsTab(uid: widget.uid),
              _NewsListWithRefill(key: const ValueKey('traffic'), uid: widget.uid, dataSource: TrafficDataSource()),
            ],
          ),
        ),
      ],
    );
  }
}

class _MileFortuneSubTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Material(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (context) => const FortuneFlowScreen()),
          ),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryYellow.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.auto_awesome, color: AppColors.navy, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('生年月日を軸にした精密診断', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                      const SizedBox(height: 4),
                      Text('星座・数秘・今日の運勢', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: AppColors.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MileLotterySubTab extends StatelessWidget {
  const _MileLotterySubTab({required this.uid});
  final String uid;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _ActionCard(
            icon: Icons.card_giftcard_rounded,
            title: '動画を見てくじを引く',
            subtitle: '1〜5チップ がランダムで当たる',
            onTap: () => _showVideoLottery(context, uid),
          ),
          const SizedBox(height: 12),
          _ActionCard(
            icon: Icons.confirmation_number_rounded,
            title: '動画を見て宝くじチケットをもらう',
            subtitle: '視聴1回で「組+6桁」を1枚発行',
            onTap: () {
              showVideoRewardDialog(
                context: context,
                title: '動画を見て宝くじチケットGET',
                subtitle: '視聴完了でチケットが発行されます。',
                onComplete: () async {
                  final ticket = await LotteryService.instance.issueRandomTicket(uid);
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('チケット発行: 第${ticket.round}回 ${ticket.group}組 ${ticket.number}')),
                  );
                },
              );
            },
          ),
          const SizedBox(height: 12),
          _ActionCard(
            icon: Icons.paid_rounded,
            title: 'チップで宝くじチケットを1枚購入',
            subtitle: '${PointConstants.formatChips(LotteryService.lotteryTicketChipPrice)}チップで「組+6桁」を1枚発行',
            onTap: () async {
              final ticket = await LotteryService.instance.buyTicketWithChips(uid);
              if (!context.mounted) return;
              if (ticket == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'チップが不足しています（${PointConstants.formatChips(LotteryService.lotteryTicketChipPrice)}チップ必要）',
                    ),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('チケット発行: 第${ticket.round}回 ${ticket.group}組 ${ticket.number}')),
                );
              }
            },
          ),
          const SizedBox(height: 12),
          _ActionCard(
            icon: Icons.receipt_long_rounded,
            title: 'マイくじ',
            subtitle: '自分の番号と当選結果を確認',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (context) => MyLotteryScreen(uid: uid)),
            ),
          ),
          const SizedBox(height: 12),
          _ActionCard(
            icon: Icons.casino_rounded,
            title: '3チップ・スロット',
            subtitle: '3チップでスピン。配当は設定で変動',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (context) => SlotScreen(uid: uid)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.cardWhite,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.navy.withOpacity(0.06),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryYellow.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.navy, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

/// Lv.4+用: キャラ生成/変更ボタン（チップ消費でDALL-E 3生成）
class _ChangeCharacterButton extends StatelessWidget {
  const _ChangeCharacterButton({required this.uid, this.user});
  final String uid;
  final UserModel? user;

  static const int _costChips = 100;
  static const List<String> _promptPresets = [
    'かわいいパンダ風のゲームキャラクター、シンプルな背景',
    'ふわふわしたネコ風のキャラクター、ファンタジー',
    '丸いフォルムの謎の生命体、癒し系',
  ];

  Future<void> _onTap(BuildContext context) async {
    final points = user?.totalPoints ?? 0;
    if (points < _costChips) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${PointConstants.formatChips(_costChips)}チップ必要です（所持: ${PointConstants.formatChips(points)}）',
          ),
        ),
      );
      return;
    }
    final prompt = await showDialog<String>(
      context: context,
      builder: (ctx) => _ChangeCharacterDialog(
        currentPrompt: user?.customCharacterPrompt,
        presets: _promptPresets,
      ),
    );
    if (prompt == null || !context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('キャラを生成中...')));
    final url = await OpenAiCharacterService.instance.generateCharacterImage(prompt);
    if (!context.mounted) return;
    if (url == null || url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('生成に失敗しました。APIキーを確認してください。')));
      return;
    }
    final ok = await UserFirestoreService.instance.tryConsumePoints(uid, _costChips);
    if (!context.mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('チップの消費に失敗しました')));
      return;
    }
    await UserFirestoreService.instance.saveCustomCharacter(uid, url, prompt);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('キャラを設定しました！')));
  }

  @override
  Widget build(BuildContext context) {
    final hasCustom = user?.customCharacterImageUrl != null && user!.customCharacterImageUrl!.isNotEmpty;
    return OutlinedButton.icon(
      onPressed: () => _onTap(context),
      icon: const Icon(Icons.auto_awesome, size: 18),
      label: Text(
        hasCustom
            ? 'キャラを変更（${PointConstants.formatChips(_costChips)}チップ）'
            : 'キャラを生成（${PointConstants.formatChips(_costChips)}チップ）',
      ),
      style: OutlinedButton.styleFrom(foregroundColor: AppColors.navy),
    );
  }
}

class _ChangeCharacterDialog extends StatefulWidget {
  const _ChangeCharacterDialog({this.currentPrompt, required this.presets});
  final String? currentPrompt;
  final List<String> presets;

  @override
  State<_ChangeCharacterDialog> createState() => _ChangeCharacterDialogState();
}

class _ChangeCharacterDialogState extends State<_ChangeCharacterDialog> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentPrompt ?? widget.presets.first);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('キャラの土台（プロンプト）'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('生成したいキャラの説明を入力してください。', style: TextStyle(fontSize: 12)),
            const SizedBox(height: 8),
            TextField(
              controller: _controller,
              maxLines: 2,
              decoration: const InputDecoration(hintText: '例: かわいいパンダ風のキャラ'),
            ),
            const SizedBox(height: 12),
            ...widget.presets.map((p) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: OutlinedButton(
                onPressed: () => _controller.text = p,
                child: Text(p, style: const TextStyle(fontSize: 11), maxLines: 2, overflow: TextOverflow.ellipsis),
              ),
            )),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('キャンセル')),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text.trim().isNotEmpty ? _controller.text.trim() : null),
          child: const Text('生成する'),
        ),
      ],
    );
  }
}

/// 相棒UI: 蓄積ポイントで進化するトレーディングカード（餌やりなし）
class _PetCareSection extends StatefulWidget {
  const _PetCareSection({required this.uid, this.user});
  final String uid;
  final UserModel? user;

  @override
  State<_PetCareSection> createState() => _PetCareSectionState();
}

class _PetCareSectionState extends State<_PetCareSection> {
  int? _lastSeenLevel;
  bool _showingEvolution = false;

  static void _showEvolutionCongratulations(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => _EvolutionDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = widget.uid;
    final user = widget.user;
    final totalEarned = user?.totalEarnedChips ?? 0;
    final levelPenalty = user?.levelPenalty ?? 0;
    final evo = CharacterEvolutionService.instance;
    final level = evo.displayLevel(totalEarned, levelPenalty);
    final progress = evo.progressToNextLevel(totalEarned, levelPenalty);
    final pointsUntil = evo.pointsUntilNextLevel(totalEarned, levelPenalty);
    final customImageUrl = user?.customCharacterImageUrl;
    final card = CharacterCard.forLevel(level, customImageUrl: customImageUrl);
    final isLv4OrHigher = level >= 4;

    if (_lastSeenLevel != null && level > _lastSeenLevel! && !_showingEvolution) {
      _showingEvolution = true;
      final fromLv = _lastSeenLevel!;
      final toLv = level;
      final oldCard = CharacterCard.forLevel(_lastSeenLevel!, customImageUrl: level >= 4 ? customImageUrl : null);
      final nav = Navigator.of(context);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => _EvolutionAutoCloseDialog(
            oldCard: oldCard,
            newCard: card,
            onComplete: () {
              Future.delayed(const Duration(milliseconds: 400), () {
                if (!context.mounted) return;
                nav.pop();
                _showEvolutionCongratulations(context);
                Future.delayed(const Duration(seconds: 3), () {
                  if (!context.mounted) return;
                  unawaited(
                    LevelUpAiOffer.maybeOffer(
                      context: context,
                      uid: uid,
                      fromLevel: fromLv,
                      toLevel: toLv,
                      user: user,
                    ),
                  );
                });
              });
            },
          ),
        ).then((_) {
          if (mounted) setState(() => _showingEvolution = false);
        });
      });
    }
    _lastSeenLevel = level;

    return Stack(
      clipBehavior: Clip.antiAlias,
      children: [
        Positioned.fill(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset(
              'assets/background/background1.png',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => ColoredBox(color: AppColors.surface),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.surface.withOpacity(0.92),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primaryYellow.withOpacity(0.4)),
          ),
          child: Column(
            children: [
              Text('相棒', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
              const SizedBox(height: 4),
              Text('Lv.$level', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.navy)),
              const SizedBox(height: 8),
              Center(
                child: CharacterTradingCard(
                  card: card,
                  size: 270,
                ),
              ),
              if (isLv4OrHigher)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: _ChangeCharacterButton(uid: uid, user: user),
                ),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('次の進化まで', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        Text(
                          '${(progress * 100).round()}%',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.navy),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 8,
                        backgroundColor: AppColors.textSecondary.withOpacity(0.2),
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryYellow),
                      ),
                    ),
                    if (pointsUntil > 0) ...[
                      const SizedBox(height: 4),
                      Text(
                        'あと${pointsUntil}ptで進化',
                        style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// 進化おめでとうダイアログ
class _EvolutionDialog extends StatefulWidget {
  @override
  State<_EvolutionDialog> createState() => _EvolutionDialogState();
}

/// 進化アニメーションが何らかの理由で完了しなくても、数秒で自動クローズする安全用ダイアログ。
class _EvolutionAutoCloseDialog extends StatefulWidget {
  const _EvolutionAutoCloseDialog({
    required this.oldCard,
    required this.newCard,
    required this.onComplete,
  });

  final CharacterCard oldCard;
  final CharacterCard newCard;
  final VoidCallback onComplete;

  @override
  State<_EvolutionAutoCloseDialog> createState() => _EvolutionAutoCloseDialogState();
}

class _EvolutionAutoCloseDialogState extends State<_EvolutionAutoCloseDialog> {
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted || _finished) return;
      _finished = true;
      widget.onComplete();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: CharacterEvolutionAnimation(
        oldCard: widget.oldCard,
        newCard: widget.newCard,
        size: 220,
        onComplete: () {
          if (_finished) return;
          _finished = true;
          widget.onComplete();
        },
      ),
    );
  }
}

class _EvolutionDialogState extends State<_EvolutionDialog> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  bool _closed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller.forward();
    // 念のため自動で閉じる（透明バリア残りを防ぐ）
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted || _closed) return;
      _closed = true;
      Navigator.of(context).pop();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 28),
            decoration: BoxDecoration(
              color: AppColors.cardWhite,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.navy.withOpacity(0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.auto_awesome, size: 48, color: AppColors.primaryOrange),
                const SizedBox(height: 16),
                const Text(
                  '進化おめでとう！',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.navy,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '相棒が成長したよ',
                  style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () {
                    if (_closed) return;
                    _closed = true;
                    Navigator.of(context).pop();
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primaryOrange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('OK'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PetStatBar extends StatelessWidget {
  const _PetStatBar({required this.label, required this.value});
  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            Text('${(value * 100).round()}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.navy)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: value,
            minHeight: 8,
            backgroundColor: AppColors.textSecondary.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(value > 0.5 ? AppColors.gaugeEnd : AppColors.primaryOrange),
          ),
        ),
      ],
    );
  }
}

/// 移動・歩数ホーム: 歩数・タンク表示＋「動画視聴→ポイント獲得」をメイン導線で表示
class _MileStepsSubTab extends StatefulWidget {
  const _MileStepsSubTab({required this.uid});
  final String uid;

  @override
  State<_MileStepsSubTab> createState() => _MileStepsSubTabState();
}

class _MileStepsSubTabState extends State<_MileStepsSubTab> {
  int? _sessionStepsAtLoad;
  Timer? _saveDebounce;
  static const Duration _saveDebounceDuration = Duration(seconds: 2);

  @override
  void dispose() {
    _saveDebounce?.cancel();
    super.dispose();
  }

  void _scheduleSave(String uid, int firestoreTodaySteps, int sessionSteps, int sessionStepsAtLoad) {
    _saveDebounce?.cancel();
    _saveDebounce = Timer(_saveDebounceDuration, () async {
      final newTodaySteps = firestoreTodaySteps + (sessionSteps - sessionStepsAtLoad);
      await UserFirestoreService.instance.saveUserData(uid, todaySteps: newTodaySteps);
      if (mounted) setState(() => _sessionStepsAtLoad = sessionSteps);
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<UserModel?>(
      stream: UserFirestoreService.instance.streamUser(widget.uid),
      builder: (context, userSnapshot) {
        final user = userSnapshot.data;
        final firestoreTodaySteps = user?.todaySteps ?? 0;
        if (_sessionStepsAtLoad == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted || _sessionStepsAtLoad != null) return;
            setState(() {
              _sessionStepsAtLoad = user != null
                  ? StepCountService.instance.currentSteps
                  : 0;
            });
          });
        }

        return StreamBuilder<int>(
          stream: StepCountService.instance.stepStream,
          initialData: StepCountService.instance.currentSteps,
          builder: (context, stepSnapshot) {
            final sessionSteps = stepSnapshot.data ?? 0;
            final stepsAtLoad = _sessionStepsAtLoad ?? sessionSteps;
            final displayedSteps = firestoreTodaySteps + (sessionSteps - stepsAtLoad);
            final tankLevels = tankLevelsFromSteps(displayedSteps);

            if (_sessionStepsAtLoad != null && sessionSteps != stepsAtLoad) {
              _scheduleSave(widget.uid, firestoreTodaySteps, sessionSteps, stepsAtLoad);
            }

            return LayoutBuilder(
              builder: (context, constraints) {
                final padding = constraints.maxWidth > 400 ? 24.0 : 16.0;
                final gaugeSize = constraints.maxWidth > 360 ? 96.0 : 80.0;
                final strokeWidth = gaugeSize * 0.1;
                return SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: padding),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        // 親しみやすいマイル・歩数エリア（アイコン＋今日の歩数）
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.primaryYellow.withOpacity(0.35),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.directions_walk_rounded, size: 32, color: AppColors.navy),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '今日の歩数',
                                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.baseline,
                                  textBaseline: TextBaseline.alphabetic,
                                  children: [
                                    Text(
                                      '$displayedSteps',
                                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.navy, letterSpacing: -0.5),
                                    ),
                                    const SizedBox(width: 4),
                                    Text('歩', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _PetCareSection(uid: widget.uid, user: user),
                        const SizedBox(height: 24),
                        Text(
                          'チップタンク（500歩で1タンク）',
                          style: TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 12,
                          runSpacing: 20,
                          children: List.generate(3, (i) {
                            return PointTankGauge(
                              fillRatio: tankLevels[i],
                              size: gaugeSize,
                              strokeWidth: strokeWidth,
                              showGetButton: tankLevels[i] >= 1.0,
                              onClaimWithVideo: tankLevels[i] >= 1.0
                                  ? () => _onStepTankClaimWithVideo(context, widget.uid)
                                  : null,
                              onClaimPlain: tankLevels[i] >= 1.0
                                  ? () {
                                      unawaited(_onStepTankClaimPlain(context, widget.uid));
                                    }
                                  : null,
                            );
                          }),
                        ),
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            '歩いてタンクを溜めよう。満タンで動画30倍（30チップ）GET、またはそのまま1チップ',
                            style: TextStyle(fontSize: 12, color: AppColors.textSecondary.withOpacity(0.9)),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 28),
                        // メイン導線: ボタンをタップして動画視聴 → ポイント獲得
                        Material(
                          color: AppColors.cardWhite,
                          borderRadius: BorderRadius.circular(16),
                          child: InkWell(
                            onTap: () => _showVideoLottery(context, widget.uid),
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.navy.withOpacity(0.06),
                                    blurRadius: 16,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryYellow.withOpacity(0.4),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: const Icon(Icons.play_circle_filled_rounded, color: AppColors.navy, size: 32),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          '動画を見てチップをゲット',
                                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'タップして動画を視聴 → くじで1〜5チップが当たる',
                                          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary, size: 28),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // SKYFLAG OW（オファーウォール）でポイントを獲得
                        Material(
                          color: AppColors.cardWhite,
                          borderRadius: BorderRadius.circular(16),
                          child: InkWell(
                            onTap: () async {
                              try {
                                final url = SkyflagService.instance.buildOfferWallUrl(
                                  uid: widget.uid,
                                  spram1: 'mile_steps',
                                  spram2: 'home',
                                );
                                if (kIsWeb) {
                                  await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                                } else {
                                  if (!context.mounted) return;
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => SkyflagOfferwallScreen(offerWallUrl: url),
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('SKYFLAG設定が必要です: ${e.toString()}')),
                                );
                              }
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.navy.withOpacity(0.06),
                                    blurRadius: 16,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryOrange.withOpacity(0.25),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: const Icon(Icons.campaign_rounded, color: AppColors.navy, size: 32),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          '広告（SKYFLAG）でポイントを貯める',
                                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'タップしてオファーウォールを表示',
                                          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary, size: 28),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class OtokuTab extends StatelessWidget {
  const OtokuTab({super.key, required this.uid});
  final String uid;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: OtokuMissionListScreen(uid: uid),
    );
  }
}

/// 下部ナビ「イチオシ」… SKYFLAG オファーウォールをタブ内でそのまま表示（追加タップなし）。
class IchioshiTab extends StatefulWidget {
  const IchioshiTab({super.key, required this.uid});

  final String uid;

  @override
  State<IchioshiTab> createState() => _IchioshiTabState();
}

class _IchioshiTabState extends State<IchioshiTab> with AutomaticKeepAliveClientMixin {
  String? _url;
  String? _configError;
  bool _webAutoLaunchScheduled = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    try {
      _url = SkyflagService.instance.buildOfferWallUrl(
        uid: widget.uid,
        spram1: 'ichioshi_tab',
        spram2: 'bottom_nav',
      );
    } catch (e) {
      _configError = e.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_configError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'SKYFLAG設定が必要です:\n$_configError',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }
    final url = _url!;

    if (kIsWeb) {
      if (!_webAutoLaunchScheduled) {
        _webAutoLaunchScheduled = true;
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!mounted) return;
          await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
        });
      }
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.open_in_new_rounded, size: 48, color: AppColors.textSecondary),
              const SizedBox(height: 16),
              Text(
                'Web版ではブラウザでオファーウォールを開きます。',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
                child: const Text('オファーを開く'),
              ),
            ],
          ),
        ),
      );
    }

    return SafeArea(
      child: SkyflagOfferwallView(offerWallUrl: url),
    );
  }
}

class LogTab extends StatelessWidget {
  const LogTab({super.key, required this.uid});
  final String uid;

  @override
  Widget build(BuildContext context) {
    return EarningsLedgerScreen(uid: uid);
  }
}

/// 歩数からおおよその移動距離（km）を計算（1歩≒0.0008km）
double _stepsToKm(int steps) => steps * 0.0008;

class MyPageTab extends StatelessWidget {
  const MyPageTab({super.key, required this.uid});
  final String uid;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: StreamBuilder<UserModel?>(
        stream: UserFirestoreService.instance.streamUser(uid),
        builder: (context, userSnap) {
          final user = userSnap.data;
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('マイページ', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                const SizedBox(height: 24),
                _CollectedCardsSection(user: user),
                const SizedBox(height: 20),
                _StatsCard(user: user),
                const SizedBox(height: 20),
                _NicknameRow(uid: uid, displayName: user?.displayName),
                const SizedBox(height: 20),
                _ReferralCodeCard(uid: uid),
                const SizedBox(height: 16),
                _ReferralPromoCard(),
                const SizedBox(height: 16),
                _RankingEntryCard(),
                const SizedBox(height: 24),
                Text('設定', style: TextStyle(fontSize: 14, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                StreamBuilder<User?>(
                  stream: FirebaseAuth.instance.authStateChanges(),
                  builder: (context, snapshot) {
                    final authUser = snapshot.data ?? FirebaseAuth.instance.currentUser;
                    if (authUser == null) {
                      return Card(
                        margin: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: const Padding(padding: EdgeInsets.all(16), child: Text('未ログイン', style: TextStyle(color: AppColors.textSecondary))),
                      );
                    }
                    return Card(
                      margin: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('ユーザーID', style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
                            const SizedBox(height: 6),
                            SelectableText(authUser.uid, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, fontFamily: 'monospace')),
                            if (authUser.isAnonymous) ...[
                              const SizedBox(height: 12),
                              Text('（匿名ログイン）', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
                Text('法務・規約', style: TextStyle(fontSize: 14, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                const _LegalLinksCard(),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// 法務関連リンク（利用規約・プライバシーポリシー・特商法・消費税法）
class _LegalLinksCard extends StatelessWidget {
  const _LegalLinksCard();

  static const String _baseUrl = 'https://poigo.keygo.jp';

  Future<void> _openUrl(String path) async {
    final uri = Uri.parse('$_baseUrl$path');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          _LegalLinkTile(
            icon: Icons.description_outlined,
            label: '利用規約',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const TermsOfServiceScreen()),
              );
            },
          ),
          const Divider(height: 1, indent: 52),
          _LegalLinkTile(
            icon: Icons.privacy_tip_outlined,
            label: 'プライバシーポリシー',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
              );
            },
          ),
          const Divider(height: 1, indent: 52),
          _LegalLinkTile(
            icon: Icons.storefront_outlined,
            label: '特定商取引法に基づく表示',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const TokushohoScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _LegalLinkTile extends StatelessWidget {
  const _LegalLinkTile({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 22, color: AppColors.textSecondary),
            const SizedBox(width: 14),
            Expanded(child: Text(label, style: const TextStyle(fontSize: 14, color: AppColors.textPrimary))),
            const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

/// 獲得したカード一覧（コレクター向け）
class _CollectedCardsSection extends StatelessWidget {
  const _CollectedCardsSection({this.user});
  final UserModel? user;

  @override
  Widget build(BuildContext context) {
    final totalEarned = user?.totalEarnedChips ?? 0;
    final level = CharacterEvolutionService.instance.levelFromTotalPoints(totalEarned);
    final customImageUrl = user?.customCharacterImageUrl;
    final cards = <CharacterCard>[
      CharacterCard.forLevel(1),
      CharacterCard.forLevel(2),
      CharacterCard.forLevel(3),
    ];
    if (level >= 4) {
      cards.add(CharacterCard.forLevel(4, customImageUrl: customImageUrl));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('獲得したカード', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        const SizedBox(height: 12),
        SizedBox(
          height: 165,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: cards.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final card = cards[index];
              return CharacterTradingCard(card: card, size: 100);
            },
          ),
        ),
      ],
    );
  }
}

/// 累計スタッツ：累計獲得チップ・累計歩数・累計移動距離・利用開始日
class _StatsCard extends StatelessWidget {
  const _StatsCard({this.user});
  final UserModel? user;

  @override
  Widget build(BuildContext context) {
    final totalEarnedChips = user?.totalEarnedChips ?? 0;
    final totalSteps = user?.totalSteps ?? 0;
    final totalKm = _stepsToKm(totalSteps);
    final createdAt = user?.createdAt;
    final startLabel = createdAt != null
        ? '${createdAt.year}/${createdAt.month.toString().padLeft(2, '0')}/${createdAt.day.toString().padLeft(2, '0')} から利用中'
        : '—';

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('累計スタッツ', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            const SizedBox(height: 14),
            _StatRow(label: '累計獲得チップ', value: PointConstants.formatChips(totalEarnedChips)),
            const SizedBox(height: 10),
            _StatRow(label: '累計歩数', value: '$totalSteps 歩'),
            const SizedBox(height: 10),
            _StatRow(label: '累計移動距離', value: totalKm >= 1 ? '${totalKm.toStringAsFixed(1)} km' : '${(totalKm * 1000).round()} m'),
            const SizedBox(height: 10),
            _StatRow(label: '利用開始日', value: startLabel),
          ],
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.navy)),
      ],
    );
  }
}

/// ニックネーム表示＋タップで編集
class _NicknameRow extends StatelessWidget {
  const _NicknameRow({required this.uid, this.displayName});
  final String uid;
  final String? displayName;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showNicknameDialog(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.person_rounded, color: AppColors.primaryYellow, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ニックネーム', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    const SizedBox(height: 2),
                    Text(
                      displayName != null && displayName!.isNotEmpty ? displayName! : 'タップしてニックネームを設定',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: displayName != null && displayName!.isNotEmpty ? AppColors.textPrimary : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.edit_rounded, size: 20, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showNicknameDialog(BuildContext context) async {
    final controller = TextEditingController(text: displayName ?? '');
    final result = await showDialog<String?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ニックネーム編集'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'ニックネームを入力',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
          maxLength: 30,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('キャンセル')),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim().isEmpty ? null : controller.text.trim()),
            child: const Text('保存'),
          ),
        ],
      ),
    );
    if (result != null && context.mounted) {
      await UserFirestoreService.instance.saveDisplayName(uid, result);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ニックネームを保存しました')));
      }
    }
  }
}

/// 友達紹介プロモーション（目を引くカード）
class _ReferralPromoCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryYellow.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryYellow.withOpacity(0.5), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.card_giftcard_rounded, color: AppColors.navy, size: 22),
              const SizedBox(width: 8),
              Text(
                '友達を招待してチップをGET！',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.navy),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'あなたの紹介コードを友達が登録すると、あなたと友達の両方に 5,000チップ をプレゼント！招待人数に制限はありません。どんどん広めて一緒に稼ごう！',
            style: TextStyle(fontSize: 13, height: 1.45, color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }
}

class _RankingEntryCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(Icons.emoji_events_rounded, color: AppColors.primaryYellow),
        title: const Text('ランキング', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        subtitle: Text('トップ100をチェック', style: TextStyle(color: AppColors.textSecondary)),
        trailing: Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (context) => const RankingScreen()),
        ),
      ),
    );
  }
}

class _ReferralCodeCard extends StatefulWidget {
  const _ReferralCodeCard({required this.uid});
  final String uid;

  @override
  State<_ReferralCodeCard> createState() => _ReferralCodeCardState();
}

class _ReferralCodeCardState extends State<_ReferralCodeCard> {
  String? _code;

  @override
  void initState() {
    super.initState();
    UserFirestoreService.instance.ensureReferralCode(widget.uid).then((code) {
      if (mounted) setState(() => _code = code);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.card_giftcard_rounded, color: AppColors.primaryYellow, size: 22),
                const SizedBox(width: 8),
                Text('友達紹介コード', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: SelectableText(
                    _code ?? '読み込み中…',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.navy, letterSpacing: 2),
                  ),
                ),
                if (_code != null && _code!.isNotEmpty)
                  IconButton(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: _code!));
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('紹介コードをコピーしました')));
                    },
                    icon: const Icon(Icons.copy_rounded),
                    tooltip: 'コピー',
                    style: IconButton.styleFrom(foregroundColor: AppColors.navy),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text('このコードを友達に教えると、双方にチップが付与されます。', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

// ─── 旧ホームタブ（参照用に残す：歩数・タンク・くじは MileTab に移行済み） ───

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  int? _sessionStepsAtLoad;
  Timer? _saveDebounce;
  static const Duration _saveDebounceDuration = Duration(seconds: 2);

  @override
  void dispose() {
    _saveDebounce?.cancel();
    super.dispose();
  }

  void _scheduleSave(String uid, int firestoreTodaySteps, int sessionSteps, int sessionStepsAtLoad) {
    _saveDebounce?.cancel();
    _saveDebounce = Timer(_saveDebounceDuration, () async {
      final newTodaySteps = firestoreTodaySteps + (sessionSteps - sessionStepsAtLoad);
      await UserFirestoreService.instance.saveUserData(uid, todaySteps: newTodaySteps);
      if (mounted) setState(() => _sessionStepsAtLoad = sessionSteps);
    });
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppColors.primaryOrange),
              SizedBox(height: 16),
              Text('読み込み中…', style: TextStyle(color: AppColors.textSecondary)),
            ],
          ),
        ),
      );
    }

    return SafeArea(
      child: StreamBuilder<UserModel?>(
        stream: UserFirestoreService.instance.streamUser(uid),
        builder: (context, userSnapshot) {
          final user = userSnapshot.data;
          final firestoreTodaySteps = user?.todaySteps ?? 0;
          if (_sessionStepsAtLoad == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted || _sessionStepsAtLoad != null) return;
              setState(() {
                _sessionStepsAtLoad = user != null
                    ? StepCountService.instance.currentSteps
                    : 0;
              });
            });
          }

          return StreamBuilder<int>(
            stream: StepCountService.instance.stepStream,
            initialData: StepCountService.instance.currentSteps,
            builder: (context, stepSnapshot) {
              final sessionSteps = stepSnapshot.data ?? 0;
              final stepsAtLoad = _sessionStepsAtLoad ?? sessionSteps;
              final displayedSteps = firestoreTodaySteps + (sessionSteps - stepsAtLoad);
              final tankLevels = tankLevelsFromSteps(displayedSteps);
              final totalPoints = user?.totalPoints ?? 0;

              if (_sessionStepsAtLoad != null && sessionSteps != stepsAtLoad) {
                _scheduleSave(uid, firestoreTodaySteps, sessionSteps, stepsAtLoad);
              }

              return LayoutBuilder(
                builder: (context, constraints) {
                  final padding = constraints.maxWidth > 400 ? 24.0 : 16.0;
                  final gaugeSize = constraints.maxWidth > 360 ? 96.0 : 80.0;
                  final strokeWidth = gaugeSize * 0.1;
                  return SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: padding),
                      child: Column(
                        children: [
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '合計チップ',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${PointConstants.formatChips(totalPoints)} チップ',
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primaryOrange,
                                    ),
                                  ),
                                ],
                              ),
                              FilledButton.icon(
                                onPressed: () => Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (ctx) => ExchangeMenuScreen(uid: uid),
                                  ),
                                ),
                                icon: const Icon(Icons.swap_horiz_rounded, size: 20),
                                label: const Text('交換'),
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.primaryOrange,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Text(
                            '今日の歩数',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            constraints: BoxConstraints(maxWidth: constraints.maxWidth),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: AppColors.cardWhite,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.navy.withOpacity(0.06),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    '$displayedSteps',
                                    style: const TextStyle(
                                      fontSize: 42,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.navy,
                                      letterSpacing: -1,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '歩',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'チップタンク（500歩で1タンク）',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 12,
                            runSpacing: 20,
                            children: List.generate(3, (i) {
                              return PointTankGauge(
                                fillRatio: tankLevels[i],
                                size: gaugeSize,
                                strokeWidth: strokeWidth,
                                showGetButton: tankLevels[i] >= 1.0,
                                onClaimWithVideo: tankLevels[i] >= 1.0
                                    ? () => _onStepTankClaimWithVideo(context, uid)
                                    : null,
                                onClaimPlain: tankLevels[i] >= 1.0
                                    ? () {
                                        unawaited(_onStepTankClaimPlain(context, uid));
                                      }
                                    : null,
                              );
                            }),
                          ),
                          const SizedBox(height: 20),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              '歩いてタンクを溜めよう。満タンで動画30倍（30チップ）GET、またはそのまま1チップ',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary.withOpacity(0.9),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 28),
                          Material(
                            color: AppColors.cardWhite,
                            borderRadius: BorderRadius.circular(16),
                            child: InkWell(
                              onTap: () => _showVideoLottery(context, uid),
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 20, horizontal: 20),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.navy.withOpacity(0.06),
                                      blurRadius: 16,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: AppColors.gaugeEnd.withOpacity(0.3),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.card_giftcard_rounded,
                                        color: AppColors.gaugeStart,
                                        size: 28,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '動画を見てくじを引く',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '1〜5チップ がランダムで当たる',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      Icons.chevron_right,
                                      color: AppColors.textSecondary,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Material(
                            color: AppColors.cardWhite,
                            borderRadius: BorderRadius.circular(16),
                            child: InkWell(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (context) =>
                                        const FortuneFlowScreen(),
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 20, horizontal: 20),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.navy.withOpacity(0.06),
                                      blurRadius: 16,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryOrange
                                            .withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.auto_awesome,
                                        color: AppColors.primaryOrange,
                                        size: 28,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '生年月日を軸にした精密診断',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '星座・数秘・今日の運勢',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      Icons.chevron_right,
                                      color: AppColors.textSecondary,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

// ─── ニュースタブ（総合/政治/経済/エンタメ/スポーツ/国際/地域/天気/交通情報） ───

class NewsTab extends StatefulWidget {
  const NewsTab({super.key});

  @override
  State<NewsTab> createState() => _NewsTabState();
}

class _NewsTabState extends State<NewsTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 9, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('ニュース', style: TextStyle(color: AppColors.textPrimary)),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorSize: TabBarIndicatorSize.label,
          labelPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          tabs: const [
            Tab(text: '総合'),
            Tab(text: '天気'),
            Tab(text: '政治'),
            Tab(text: '経済'),
            Tab(text: 'エンタメ'),
            Tab(text: 'スポーツ'),
            Tab(text: '国際'),
            Tab(text: '地域'),
            Tab(text: '交通情報'),
          ],
        ),
      ),
      body: uid == null
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryOrange))
          : TabBarView(
              controller: _tabController,
              children: [
                _NewsListWithRefill(key: const ValueKey('general'), uid: uid!, dataSource: NewsCategoryDataSource(NewsSettingsModel.keyGeneral)),
                JapanWeatherTab(uid: uid),
                _NewsListWithRefill(key: const ValueKey('politics'), uid: uid!, dataSource: NewsCategoryDataSource(NewsSettingsModel.keyPolitics)),
                _NewsListWithRefill(key: const ValueKey('economy'), uid: uid!, dataSource: NewsCategoryDataSource(NewsSettingsModel.keyEconomy)),
                _NewsListWithRefill(key: const ValueKey('entertainment'), uid: uid!, dataSource: NewsCategoryDataSource(NewsSettingsModel.keyEntertainment)),
                _NewsListWithRefill(key: const ValueKey('sports'), uid: uid!, dataSource: NewsCategoryDataSource(NewsSettingsModel.keySports)),
                _NewsListWithRefill(key: const ValueKey('international'), uid: uid!, dataSource: NewsCategoryDataSource(NewsSettingsModel.keyInternational)),
                _RegionNewsTab(uid: uid!),
                _NewsListWithRefill(key: const ValueKey('traffic'), uid: uid!, dataSource: TrafficDataSource()),
              ],
            ),
    );
  }
}

/// ニュースリスト＋おかわりバナー（5回使い切った時に表示）
class _NewsListWithRefill extends StatelessWidget {
  const _NewsListWithRefill({
    super.key,
    required this.uid,
    required this.dataSource,
  });

  final String uid;
  final LifeInfoDataSource dataSource;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<UserModel?>(
      stream: UserFirestoreService.instance.streamUser(uid),
      builder: (context, userSnapshot) {
        return StreamBuilder(
          stream: EconomySettingsService.instance.streamEconomySettings(),
          builder: (context, economySnapshot) {
            final user = userSnapshot.data;
            final economy = economySnapshot.data;
            final maxPerDay = economy?.newsReadBonusMaxPerDay ?? 5;
            final refillCount = economy?.newsRefillCount ?? 5;
            final showRefill = user != null &&
                economy != null &&
                user.todayReadBonusCount >= maxPerDay &&
                !user.usedReadBonusRefillToday;

            final list = _NewsList(
              key: ValueKey(dataSource.hashCode),
              dataSource: dataSource,
              uid: uid,
            );

            if (!showRefill) return list;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Material(
                    color: AppColors.primaryOrange.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: () {
                        showVideoRewardDialog(
                          context: context,
                          title: '動画を見てあと${refillCount}回分追加',
                          subtitle: '視聴完了で読了ボーナスが${refillCount}回分使えるようになります。',
                          onComplete: () async {
                            await UserFirestoreService.instance.resetReadBonusForRefill(uid);
                          },
                        );
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        child: Row(
                          children: [
                            Icon(Icons.play_circle_filled, color: AppColors.primaryOrange, size: 32),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                '動画を見てあと${refillCount}回分追加',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            Icon(Icons.chevron_right, color: AppColors.textSecondary),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(child: list),
              ],
            );
          },
        );
      },
    );
  }
}

/// 地域タブ: 未設定なら都道府県選択、設定済みなら地域ニュースリスト
class _RegionNewsTab extends StatelessWidget {
  const _RegionNewsTab({required this.uid});

  final String uid;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<UserModel?>(
      stream: UserFirestoreService.instance.streamUser(uid),
      builder: (context, snapshot) {
        final user = snapshot.data;
        final prefecture = user?.prefecture;
        if (prefecture == null || prefecture.isEmpty) {
          return _PrefectureSelectView(uid: uid);
        }
        return _NewsListWithRefill(
          key: const ValueKey('region'),
          uid: uid,
          dataSource: NewsRegionDataSource(prefecture),
        );
      },
    );
  }
}

/// お住まいの地域（都道府県）選択
class _PrefectureSelectView extends StatefulWidget {
  const _PrefectureSelectView({required this.uid});

  final String uid;

  @override
  State<_PrefectureSelectView> createState() => _PrefectureSelectViewState();
}

class _PrefectureSelectViewState extends State<_PrefectureSelectView> {
  String? _selectedCode;
  bool _saving = false;

  Future<void> _save() async {
    if (_selectedCode == null || _saving) return;
    setState(() => _saving = true);
    try {
      await UserFirestoreService.instance.savePrefecture(widget.uid, _selectedCode!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('地域を保存しました')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'お住まいの地域（都道府県）を選択してください。',
            style: TextStyle(fontSize: 16, height: 1.4),
          ),
          const SizedBox(height: 24),
          DropdownButtonFormField<String>(
            value: _selectedCode,
            decoration: InputDecoration(
              labelText: '都道府県',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
            ),
            items: PrefectureList.codes.map((code) {
              return DropdownMenuItem(
                value: code,
                child: Text(PrefectureList.name(code)),
              );
            }).toList(),
            onChanged: (v) => setState(() => _selectedCode = v),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _selectedCode == null || _saving ? null : _save,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _saving
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('保存して地域ニュースを表示'),
          ),
        ],
      ),
    );
  }
}

/// ニュース詳細画面（3秒滞在で読了→ポイント受け取りボタン表示）
class NewsDetailScreen extends StatefulWidget {
  final NewsItem item;
  final double initialReadRatio;
  final String? uid;
  final VoidCallback? onReadComplete;

  const NewsDetailScreen({
    super.key,
    required this.item,
    this.initialReadRatio = 0.0,
    this.uid,
    this.onReadComplete,
  });

  @override
  State<NewsDetailScreen> createState() => _NewsDetailScreenState();
}

class _NewsDetailScreenState extends State<NewsDetailScreen> {
  static const Duration readDwellDuration = Duration(seconds: 3);

  double _readRatio = 0.0;
  bool _canReceivePoints = false;
  bool _hasReceived = false;

  @override
  void initState() {
    super.initState();
    _readRatio = widget.initialReadRatio.clamp(0.0, 1.0);
    if (_readRatio >= 1.0) {
      _canReceivePoints = true;
      return;
    }
    Future.delayed(readDwellDuration, () {
      if (!mounted) return;
      setState(() {
        _readRatio = 1.0;
        _canReceivePoints = true;
      });
    });
  }

  void _receivePoints() {
    if (_hasReceived) return;
    _hasReceived = true;
    final uid = widget.uid;
    if (uid != null) {
      showPointRewardChoiceDialog(
        context: context,
        uid: uid,
        onComplete: () {
          widget.onReadComplete?.call();
          if (mounted) Navigator.of(context).pop();
        },
      );
    } else {
      widget.onReadComplete?.call();
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          widget.item.title,
          style: const TextStyle(
            fontSize: 16,
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.item.bodyOrPlaceholder(),
              style: const TextStyle(
                fontSize: 15,
                height: 1.6,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                _SmallReadGauge(ratio: _readRatio),
                const SizedBox(width: 16),
                if (_readRatio < 1.0)
                  Text(
                    '3秒間読むと読了になります',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  )
                else
                  const Text(
                    '読了！',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryOrange,
                    ),
                  ),
              ],
            ),
            if (widget.item.link != null && widget.item.link!.isNotEmpty) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () => _openOriginalLink(widget.item.link!),
                icon: const Icon(Icons.open_in_browser, size: 20),
                label: const Text('元の記事を開く'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.navy,
                  side: const BorderSide(color: AppColors.navy),
                ),
              ),
            ],
            if (_canReceivePoints) ...[
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _receivePoints,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: AppColors.primaryOrange,
                    foregroundColor: Colors.white,
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: const Text('動画を見て報酬を確定させる'),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'そのまま受け取る or 動画で増やせます（1日上限あり）',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 24),
            Center(child: AdService.getBannerWidget()),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _openOriginalLink(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
      }
    } catch (_) {}
  }
}

/// 3記事ごとに挿入する広告枠（プレースホルダ）
class _NewsAdPlaceholder extends StatelessWidget {
  const _NewsAdPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      height: 80,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.textSecondary.withOpacity(0.3)),
      ),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.campaign_rounded, size: 28, color: AppColors.textSecondary.withOpacity(0.7)),
            const SizedBox(width: 12),
            Text(
              '広告',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NewsList extends StatefulWidget {
  final LifeInfoDataSource dataSource;
  final String uid;

  const _NewsList({super.key, required this.dataSource, required this.uid});

  @override
  State<_NewsList> createState() => _NewsListState();
}

class _NewsListState extends State<_NewsList> {
  List<NewsItem> _items = [];
  final Map<String, double> _readRatios = {};
  bool _loading = true;
  String? _error;

  /// 3記事ごとに広告を挟んだ場合の総アイテム数
  int get _totalCount {
    final n = _items.length;
    return n + (n ~/ 3);
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await widget.dataSource.getItems();
      if (!mounted) return;
      setState(() {
        _items = items;
        for (final item in items) {
          _readRatios.putIfAbsent(item.id, () => 0.0);
        }
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = _loadingErrorMessage(e);
        _loading = false;
      });
    }
  }

  /// 例外をユーザー向けの「読み込み失敗」理由に変換
  static String _loadingErrorMessage(Object e) {
    final msg = e.toString();
    if (e is TimeoutException) return '読み込みに失敗しました（タイムアウト）';
    if (msg.contains('SocketException') || msg.contains('Connection')) {
      return '読み込みに失敗しました（ネットワークに接続できません）';
    }
    if (msg.contains('XML') || msg.contains('parse')) {
      return '読み込みに失敗しました（データの解析エラー）';
    }
    if (e is Exception && e.toString() != 'Exception: null') {
      final s = e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
      if (s.isNotEmpty) return '読み込みに失敗しました（$s）';
    }
    return '読み込みに失敗しました';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.primaryOrange),
            SizedBox(height: 16),
            Text('読み込み中…', style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      );
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_error!, style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh),
                label: const Text('再読み込み'),
              ),
            ],
          ),
        ),
      );
    }
    if (_items.isEmpty) {
      return const Center(
        child: Text('記事がありません', style: TextStyle(color: AppColors.textSecondary)),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.primaryOrange,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        itemCount: _totalCount,
        itemBuilder: (context, i) {
          final adIndex = (i + 1) % 4 == 0;
          if (adIndex) {
            return const _NewsAdPlaceholder();
          }
          final itemIndex = i - (i ~/ 4);
          final item = _items[itemIndex];
          final readRatio = _readRatios[item.id] ?? 0.0;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _NewsListItem(
              item: item,
              readRatio: readRatio,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (context) => NewsDetailScreen(
                      item: item,
                      initialReadRatio: readRatio,
                      uid: widget.uid,
                      onReadComplete: () {
                        setState(() => _readRatios[item.id] = 1.0);
                      },
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _NewsListItem extends StatelessWidget {
  final NewsItem item;
  final double readRatio;
  final VoidCallback? onTap;

  const _NewsListItem({
    required this.item,
    required this.readRatio,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.cardWhite,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              if (readRatio >= 1.0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primaryOrange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('済', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryOrange)),
                ),
              const SizedBox(width: 8),
              _SmallReadGauge(ratio: readRatio),
            ],
          ),
        ),
      ),
    );
  }
}

class _SmallReadGauge extends StatelessWidget {
  final double ratio;

  const _SmallReadGauge({required this.ratio});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      height: 36,
      child: CustomPaint(
        painter: _SmallGaugePainter(progress: ratio),
        size: const Size(36, 36),
      ),
    );
  }
}

class _SmallGaugePainter extends CustomPainter {
  final double progress;

  _SmallGaugePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 4.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide / 2) - strokeWidth / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = AppColors.surface
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );

    if (progress <= 0) return;

    final sweepAngle = 2 * math.pi * progress;
    final gradient = SweepGradient(
      startAngle: -math.pi / 2,
      endAngle: 3 * math.pi / 2,
      colors: const [AppColors.gaugeStart, AppColors.gaugeEnd],
    );
    canvas.drawArc(
      rect,
      -math.pi / 2,
      sweepAngle,
      false,
      Paint()
        ..shader = gradient.createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _SmallGaugePainter old) => old.progress != progress;
}

// ─── 履歴・設定タブ ───

class HistoryTab extends StatelessWidget {
  const HistoryTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history_rounded,
            size: 64,
            color: AppColors.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            '履歴',
            style: TextStyle(
              fontSize: 18,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'ここにチップ履歴が表示されます',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }
}

class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '設定',
              style: TextStyle(
                fontSize: 20,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'マイページ',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            StreamBuilder<User?>(
              stream: FirebaseAuth.instance.authStateChanges(),
              builder: (context, snapshot) {
                final user = snapshot.data ?? FirebaseAuth.instance.currentUser;
                if (user == null) {
                  return Card(
                    margin: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        '未ログイン',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  );
                }
                return Card(
                  margin: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ユーザーID',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 6),
                        SelectableText(
                          user.uid,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textPrimary,
                            fontFamily: 'monospace',
                          ),
                        ),
                        if (user.isAnonymous) ...[
                          const SizedBox(height: 12),
                          Text(
                            '（匿名ログイン）',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 32),
            Text(
              'アプリの設定はここから',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
