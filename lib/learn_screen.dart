import 'package:material_ui/material_ui.dart';

import 'firebase_options.dart';
import 'store.dart';
import 'wk_view.dart';

/// Wortkreis is hosted on the site, so its content updates without a new app version.
class LearnScreen extends StatelessWidget {
  final AppState s;
  const LearnScreen({super.key, required this.s});
  @override
  Widget build(BuildContext context) {
    final q = {'k': s.key, 'm': s.mid, 'g': s.gid, 'n': s.nick, 'l': s.lang, 'app': '1', if (useEmulator) 'emu': '1'};
    final url = '$siteUrl/wortkreis/#${Uri(queryParameters: q).query}';
    return WkView(url: url);
  }
}
