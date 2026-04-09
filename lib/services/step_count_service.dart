import 'dart:async';
import 'package:pedometer/pedometer.dart';

/// 歩数ストリームを提供。実機では Pedometer、シミュレーターではダミー増分。
class StepCountService {
  StepCountService._();
  static final StepCountService _instance = StepCountService._();
  static StepCountService get instance => _instance;

  StreamSubscription<StepCount>? _subscription;
  final _stepController = StreamController<int>.broadcast();
  int _lastSteps = 0;
  int _baseSteps = -1;
  bool _useSimulation = false;
  Timer? _simulationTimer;

  /// 現在の歩数が流れるストリーム。アプリ起動時からの相対歩数（0起点）で発火する。
  Stream<int> get stepStream => _stepController.stream;

  /// サービスを開始する。main で呼ぶ。
  void start() {
    if (_subscription != null) return;

    if (!_stepController.isClosed) _stepController.add(0);

    _subscription = Pedometer.stepCountStream.listen(
      _onStepData,
      onError: _onStepError,
      cancelOnError: false,
    );
  }

  void _onStepData(StepCount event) {
    if (_useSimulation) return;

    final raw = event.steps;
    if (_baseSteps < 0) _baseSteps = raw;
    final relative = raw - _baseSteps;
    _lastSteps = relative;
    if (!_stepController.isClosed) {
      _stepController.add(_lastSteps);
    }
  }

  void _onStepError(Object error) {
    _startSimulation();
  }

  /// シミュレーター用：定期的に歩数を増やしてストリームに流す。
  void _startSimulation() {
    if (_useSimulation) return;
    _useSimulation = true;
    _baseSteps = -1;
    _lastSteps = 0;
    if (!_stepController.isClosed) _stepController.add(0);

    _simulationTimer?.cancel();
    _simulationTimer = Timer.periodic(const Duration(milliseconds: 800), (_) {
      _lastSteps += 15;
      if (!_stepController.isClosed) {
        _stepController.add(_lastSteps);
      }
    });
  }

  /// 実機で歩数が長時間 0 のままならシミュレーションに切り替える（オプション）。
  void enableSimulationFallbackAfterDelay({Duration delay = const Duration(seconds: 3)}) {
    Future.delayed(delay, () {
      if (_baseSteps < 0 && !_useSimulation) {
        _startSimulation();
      }
    });
  }

  /// 現在の歩数（最後に発火した値）。ストリームをまだ受け取っていない場合は 0。
  int get currentSteps => _lastSteps;

  void dispose() {
    _subscription?.cancel();
    _subscription = null;
    _simulationTimer?.cancel();
    _simulationTimer = null;
    _stepController.close();
  }
}
