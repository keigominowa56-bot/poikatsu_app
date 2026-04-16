import 'package:url_launcher/url_launcher.dart';

import 'skyflag_service.dart';

/// SKYFLAG 連携のカスタム URL（`poigo://open/browser?url=` 等）。
///
/// WebView 内ナビゲーションと、OS からのディープリンクの両方で利用する。
class PoigoSchemeNavigation {
  PoigoSchemeNavigation._();

  static String get _schemeLower => SkyflagService.defaultAppScheme.toLowerCase();

  static bool isOpenBrowserLink(String url) {
    final lower = url.trim().toLowerCase();
    if (lower.contains('$_schemeLower://open/browser')) return true;
    if (lower.contains(_schemeLower) &&
        (lower.contains('http://') ||
            lower.contains('https://') ||
            lower.contains('http%3a%2f%2f') ||
            lower.contains('https%3a%2f%2f'))) {
      return true;
    }
    final uri = _parseUriRobust(url);
    if (uri == null) return false;
    return _isOpenBrowserHostPath(uri);
  }

  static bool isWebViewCloseLink(String url) {
    final uri = _parseUriRobust(url);
    if (uri == null) return false;
    if (uri.scheme.toLowerCase() != _schemeLower) return false;
    return uri.host.toLowerCase() == 'webview_close';
  }

  /// `poigo://open/browser?url=` を外部ブラウザで開く（該当しない URI は何もしない）。
  static Future<void> handleOpenBrowserLink(String url) async {
    if (!isOpenBrowserLink(url)) return;
    final direct = _extractTargetFromRaw(url);
    if (direct != null) {
      final targetUri = Uri.tryParse(direct);
      if (targetUri != null) {
        await launchUrl(targetUri, mode: LaunchMode.externalApplication);
        return;
      }
    }
    final uri = _parseUriRobust(url);
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
    if (uri.scheme.toLowerCase() != _schemeLower) return false;
    if (uri.host.toLowerCase() != 'open') return false;
    final p = uri.path.toLowerCase();
    return p == '/browser' || p == 'browser' || p.startsWith('/browser/');
  }

  static Future<void> handleOpenBrowserUri(Uri uri) async {
    final target = _extractOpenBrowserTarget(uri);
    if (target == null || target.isEmpty) return;
    final targetUri = Uri.tryParse(target);
    if (targetUri == null) return;
    await launchUrl(targetUri, mode: LaunchMode.externalApplication);
  }

  /// `poigo://open/browser?url=...` の `url` 値を取り出す。
  /// URL 側が未エンコードでも落ちないように、query の生文字列もフォールバックで扱う。
  static String? _extractOpenBrowserTarget(Uri uri) {
    final fromQuery = uri.queryParameters['url'];
    if (fromQuery != null && fromQuery.isNotEmpty) {
      return fromQuery;
    }

    final raw = uri.query;
    if (raw.isEmpty) return null;
    final idx = raw.indexOf('url=');
    if (idx < 0) return null;
    final rawValue = raw.substring(idx + 4);
    if (rawValue.isEmpty) return null;
    return Uri.decodeComponent(rawValue);
  }

  /// WebView の実際の遷移URL（poigo が埋め込まれた形式）から
  /// 外部ブラウザで開くべき http/https URL を抽出する。
  /// 例: .../poigohttps%3A%2F%2Fad.skyflag.jp... -> https://ad.skyflag.jp...
  static String? _extractTargetFromRaw(String rawUrl) {
    final raw = rawUrl.trim();
    if (raw.isEmpty) return null;

    final candidates = <String>[
      raw,
      Uri.decodeFull(raw),
      Uri.decodeFull(Uri.decodeFull(raw)),
    ];

    for (final c in candidates) {
      final lower = c.toLowerCase();
      final poigoIdx = lower.indexOf(_schemeLower);
      if (poigoIdx < 0) continue;
      final tail = c.substring(poigoIdx);
      final tailLower = tail.toLowerCase();

      final plainHttpsIdx = tailLower.indexOf('https://');
      if (plainHttpsIdx >= 0) {
        return tail.substring(plainHttpsIdx).trim();
      }
      final plainHttpIdx = tailLower.indexOf('http://');
      if (plainHttpIdx >= 0) {
        return tail.substring(plainHttpIdx).trim();
      }

      final encHttpsIdx = tailLower.indexOf('https%3a%2f%2f');
      if (encHttpsIdx >= 0) {
        return Uri.decodeFull(tail.substring(encHttpsIdx)).trim();
      }
      final encHttpIdx = tailLower.indexOf('http%3a%2f%2f');
      if (encHttpIdx >= 0) {
        return Uri.decodeFull(tail.substring(encHttpIdx)).trim();
      }
    }

    return null;
  }

  /// about:blank は外部遷移判定の対象外
  static bool isIgnorableNavigation(String url) {
    final u = url.trim().toLowerCase();
    return u == 'about:blank' || u.startsWith('about:blank');
  }

  /// URI のパースを、通常文字列 / 1回デコード / 2回デコードで試す。
  /// WebView 側で URL エンコードされたまま渡るケースの取りこぼしを減らす。
  static Uri? _parseUriRobust(String rawUrl) {
    final original = rawUrl.trim();
    if (original.isEmpty) return null;

    Uri? tryParse(String s) => Uri.tryParse(s);

    final u0 = tryParse(original);
    if (u0 != null) return u0;

    final d1 = Uri.decodeFull(original);
    final u1 = tryParse(d1);
    if (u1 != null) return u1;

    final d2 = Uri.decodeFull(d1);
    return tryParse(d2);
  }
}
