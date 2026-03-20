import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class AdjustableWebView extends StatefulWidget {
  final String html;
  const AdjustableWebView({super.key, required this.html});

  @override
  State<AdjustableWebView> createState() => _AdjustableWebViewState();
}

class _AdjustableWebViewState extends State<AdjustableWebView> {
  late final WebViewController _controller;
  double _height = 100;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..loadHtmlString(widget.html)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (url) async {
            final height = await _controller.runJavaScriptReturningResult(
              "document.body.scrollHeight",
            );
            setState(() {
              _height = double.tryParse(height.toString()) ?? 100;
            });
          },
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _height,
      child: WebViewWidget(controller: _controller),
    );
  }
}
