import 'package:material_ui/material_ui.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'ui.dart';

/// Wortkreis page inside the Android app.
class WkView extends StatefulWidget {
  final String url;
  const WkView({super.key, required this.url});
  @override
  State<WkView> createState() => _WkViewState();
}

class _WkViewState extends State<WkView> {
  late final WebViewController c;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    c = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (_) {
          if (mounted) setState(() => loading = false);
        },
        onNavigationRequest: (r) {
          final u = Uri.tryParse(r.url);
          if (u != null && u.host.isNotEmpty && !u.host.endsWith('lernbik.web.app') && !u.host.endsWith('lernbik.firebaseapp.com')) {
            openUrl(r.url);
            return NavigationDecision.prevent;
          }
          return NavigationDecision.navigate;
        },
      ))
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  void didUpdateWidget(WkView old) {
    super.didUpdateWidget(old);
    if (old.url != widget.url) c.loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) async {
          if (await c.canGoBack()) c.goBack();
        },
        child: Stack(children: [
          WebViewWidget(controller: c),
          if (loading) const LinearProgressIndicator(),
        ]),
      );
}
