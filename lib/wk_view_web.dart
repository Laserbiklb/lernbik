import 'dart:ui_web' as ui_web;

import 'package:material_ui/material_ui.dart';
import 'package:web/web.dart' as web;

final _registered = <String>{};

/// Wortkreis page inside the web version (an iframe).
class WkView extends StatelessWidget {
  final String url;
  const WkView({super.key, required this.url});
  @override
  Widget build(BuildContext context) {
    final type = 'wk-${url.hashCode}';
    if (_registered.add(type)) {
      ui_web.platformViewRegistry.registerViewFactory(type, (int id) {
        final f = web.HTMLIFrameElement()
          ..src = url
          ..style.border = '0'
          ..style.width = '100%'
          ..style.height = '100%'
          ..allow = 'clipboard-write';
        return f;
      });
    }
    return HtmlElementView(viewType: type);
  }
}
