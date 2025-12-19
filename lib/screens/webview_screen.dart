import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hebrewbooks/shared/widgets/custom_text.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// A screen that displays a web page in an in-app WebView.
class WebViewScreen extends StatefulWidget {
  const WebViewScreen({
    required this.title,
    required this.url,
    super.key,
  });

  /// The title to display in the AppBar.
  final String title;

  /// The URL to load in the WebView.
  final String url;

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late final WebViewController _controller;
  int _loadingPercentage = 0;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            if (mounted) setState(() => _loadingPercentage = 0);
          },
          onProgress: (int progress) {
            if (mounted) setState(() => _loadingPercentage = progress);
          },
          onPageFinished: (String url) {
            if (mounted) setState(() => _loadingPercentage = 100);
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('''
Page resource error:
  code: ${error.errorCode}
  description: ${error.description}
  errorType: ${error.errorType}
  isForMainFrame: ${error.isForMainFrame}
          ''');
          },
          onNavigationRequest: (NavigationRequest request) async {
            if (request.url.startsWith('mailto:')) {
              final uri = Uri.parse(request.url);
              if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
                await Clipboard.setData(
                  ClipboardData(text: uri.path),
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content:
                          CustomText.left('Email address copied to clipboard'),
                    ),
                  );
                }
              }
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: CustomText(widget.title),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_loadingPercentage < 100)
            LinearProgressIndicator(
              value: _loadingPercentage / 100.0,
            ),
        ],
      ),
    );
  }
}
