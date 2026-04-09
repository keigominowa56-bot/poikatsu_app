import 'package:url_launcher/url_launcher.dart';

import 'skyflag_service.dart';

/// SKYFLAG 連携のカスタム URL（`poigo://open/browser?url=` 等）。
///
/// WebView 内ナビゲーションと、OS からのディープリンクの両方で利用する。
class PoigoSchemeNavigation {
  PoigoSchemeNavigation._();

  static String get _schemeLower => SkyflagService.defaultAppScheme.toLowerCase();

  static bool isOpenBrowserLink(String url) {
    final u = url.trim().toLowerCase();
    return u.startsWith('$_schemeLower://open/browser');
  }

  static bool isWebViewCloseLink(String url) {
    final u = url.trim().toLowerCase();
    return u.startsWith('$_schemeLower://webview_close');
  }

  /// `poigo://open/browser?url=` を外部ブラウザで開く（該当しない URI は何もしない）。
  static Future<void> handleOpenBrowserLink(String url) async {
    if (!isOpenBrowserLink(url)) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await handleOpenBrowserUri(uri);
  }

  /// OS のディープリンク起動（`Uri` 単体でも解釈可能なように）。
  static Future<void> handleIncomingUri(Uri uri) async {
    if (uri.scheme.toLowerCase() != _schemeLower) return;

    if (_isOpenBrowserHostPath(uri)) {
      await handleOpenBrowserUri(uri);
    }
  }

  static bool _isOpenBrowserHostPath(Uri uri) {
    if (uri.host.toLowerCase() != 'open') return false;
    final p = uri.path.toLowerCase();
    return p == '/browser' || p == 'browser' || p.startsWith('/browser/');
  }

  static Future<void> handleOpenBrowserUri(Uri uri) async {
    final target = uri.queryParameters['url'];
    if (target == null || target.isEmpty) return;
    final targetUri = Uri.tryParse(target);
    if (targetUri == null) return;
    await launchUrl(targetUri, mode: LaunchMode.externalApplication);
  }
}
