import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:poigo/services/poigo_scheme_navigation.dart';
import 'package:poigo/services/skyflag_service.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// SKYFLAG OW の WebView 本体（タブ埋め込み・モーダル画面の両方で利用）。
///
/// - `{app_name}://open/browser?url=...` : OS標準ブラウザで開く
/// - `{app_name}://webview_close` : [onWebViewClose] があれば実行、なければ
///   Navigator で pop。pop 不可（タブ内など）の場合は WebView 自体を閉じる
class SkyflagOfferwallView extends StatefulWidget {
  const SkyflagOfferwallView({
    super.key,
    required this.offerWallUrl,
    this.onWebViewClose,
  });

  final String offerWallUrl;

  /// モーダル表示時は `Navigator.pop` などを渡す。タブ内では null。
  final VoidCallback? onWebViewClose;

  @override
  State<SkyflagOfferwallView> createState() => _SkyflagOfferwallViewState();
}

class _SkyflagOfferwallViewState extends State<SkyflagOfferwallView> {
  late final WebViewController _controller;
  bool _closedByScheme = false;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (NavigationRequest request) async {
            final url = request.url;
            if (kDebugMode) {
              // ignore: avoid_print
              print('[WebView] Navigation to: $url');
            }

            if (PoigoSchemeNavigation.isIgnorableNavigation(url)) {
              if (kDebugMode) {
                // ignore: avoid_print
                print('[WebView] Ignore navigation: $url');
              }
              return NavigationDecision.navigate;
            }

            if (PoigoSchemeNavigation.isOpenBrowserLink(url)) {
              if (kDebugMode) {
                // ignore: avoid_print
                print('[WebView] Detected open/browser scheme -> external browser');
              }
              await PoigoSchemeNavigation.handleOpenBrowserLink(url);
              return NavigationDecision.prevent;
            }

            if (PoigoSchemeNavigation.isWebViewCloseLink(url)) {
              if (kDebugMode) {
                // ignore: avoid_print
                print('[WebView] Detected webview_close scheme -> close webview');
              }
              if (widget.onWebViewClose != null) {
                widget.onWebViewClose!();
              } else if (context.mounted) {
                final nav = Navigator.of(context);
                if (nav.canPop()) {
                  nav.pop();
                } else {
                  setState(() => _closedByScheme = true);
                }
              }
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
        ),
      );

    _loadOfferWall();
  }

  Future<void> _loadOfferWall() async {
    final ua = SkyflagService.webviewUserAgent.trim();
    if (ua.isNotEmpty) {
      await _controller.setUserAgent(ua);
    }
    if (!mounted) return;
    await _controller.loadRequest(Uri.parse(widget.offerWallUrl));
  }

  @override
  Widget build(BuildContext context) {
    if (_closedByScheme) {
      return const SizedBox.shrink();
    }
    return WebViewWidget(controller: _controller);
  }
}

/// SKYFLAG OW をモーダルで表示する画面（マイルタブ等から push 用）。
class SkyflagOfferwallScreen extends StatelessWidget {
  const SkyflagOfferwallScreen({super.key, required this.offerWallUrl});

  final String offerWallUrl;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('広告（SKYFLAG）'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SkyflagOfferwallView(
          offerWallUrl: offerWallUrl,
          onWebViewClose: () {
            if (context.mounted) Navigator.of(context).pop();
          },
        ),
      ),
    );
  }
}
