/// 外部連携（レシート・アンケート等）の将来拡張用プレースホルダ。
///
/// 本番ではここから外部APIへ接続し、ミッション一覧を取得して返す想定。
class ExternalMissionService {
  ExternalMissionService._();
  static final ExternalMissionService _instance = ExternalMissionService._();
  static ExternalMissionService get instance => _instance;

  Future<List<Object>> fetchExternalMissions() async {
    // TODO: レシート/アンケート等の外部API連携を実装
    return const [];
  }
}

