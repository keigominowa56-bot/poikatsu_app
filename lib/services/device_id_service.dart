/// デバイス固有ID取得（1デバイス1アカウント用）
/// パッケージ未導入時は空文字を返し、デバイス制限は行わない
class DeviceIdService {
  DeviceIdService._();
  static final DeviceIdService _instance = DeviceIdService._();
  static DeviceIdService get instance => _instance;

  String? _cached;

  Future<String> getDeviceId() async {
    if (_cached != null) return _cached!;
    try {
      // device_info_plus を使う場合は以下を有効化し、pubspec に device_info_plus を追加
      // final deviceInfo = DeviceInfoPlugin();
      // if (Platform.isAndroid) {
      //   final android = await deviceInfo.androidInfo;
      //   _cached = android.id;
      // } else if (Platform.isIOS) {
      //   final ios = await deviceInfo.iosInfo;
      //   _cached = ios.identifierForVendor ?? 'ios-${ios.utsname.machine}';
      // }
      _cached = '';
    } catch (_) {
      _cached = '';
    }
    return _cached!;
  }
}
