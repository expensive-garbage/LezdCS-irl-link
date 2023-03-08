import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
// Import for Android features.
import 'package:webview_flutter_android/webview_flutter_android.dart';
// Import for iOS features.
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

class WebPageView extends StatefulWidget {
  WebPageView(this.title, this.url);

  final String title;
  final String url;

  @override
  _WebPageViewState createState() => _WebPageViewState();
}

class _WebPageViewState extends State<WebPageView>
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
    late final PlatformWebViewControllerCreationParams params;
    
    late WebViewController _controller;
    late AndroidWebViewController _androidController;

  @override
  void initState() {
    super.initState();

    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
      allowsInlineMediaPlayback: true,
    );
    } else {
      params = PlatformWebViewControllerCreationParams();
    }

    if (_controller.platform is AndroidWebViewController) {
    AndroidWebViewController.enableDebugging(true);
    (_controller.platform as AndroidWebViewController)
        .setMediaPlaybackRequiresUserGesture(false);
    }

    _controller = WebViewController.fromPlatformCreationParams(params)
    ..setJavaScriptMode(JavaScriptMode.unrestricted)
    ..loadRequest(Uri.parse(widget.url));
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return WebViewWidget(
      controller: _controller,
      gestureRecognizers: Set()
      ..add(
        Factory<EagerGestureRecognizer>(
            () => EagerGestureRecognizer()),
      ),
    );
  }
}
