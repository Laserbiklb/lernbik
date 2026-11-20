import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/services.dart' show MethodChannel;
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import 'i18n.dart';
import 'store.dart';

Future<bool> confirm(BuildContext context, String lang, String title, {String? body, String? yes, bool danger = false}) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      title: Text(title),
      content: body == null ? null : Text(body),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c, false), child: Text(tr(lang, 'cancel'))),
        FilledButton(
          style: danger ? FilledButton.styleFrom(backgroundColor: Theme.of(c).colorScheme.error) : null,
          onPressed: () => Navigator.pop(c, true),
          child: Text(yes ?? tr(lang, 'yes')),
        ),
      ],
    ),
  );
  return r == true;
}

/// Opens Google Translate from German into the phone's language.
/// The Google Translate app ignores the text of a translate.google.com link, so on Android the text
/// is handed to the app directly (in the APK through the "lernbik/translate" channel, in the browser
/// through an intent: link); the web page is the fallback.
Future<void> openTranslate(String text) async {
  final to = WidgetsBinding.instance.platformDispatcher.locale.languageCode;
  final web = Uri.https('translate.google.com', '/', {'sl': 'de', 'tl': to == 'de' ? 'en' : to, 'text': text, 'op': 'translate'});
  if (defaultTargetPlatform == TargetPlatform.android) {
    if (!kIsWeb) {
      try {
        if (await const MethodChannel('lernbik/translate').invokeMethod<bool>('open', {'text': text}) == true) return;
      } catch (_) {}
    } else {
      final e = Uri.encodeComponent;
      final intent =
          'intent:#Intent;action=android.intent.action.SEND;type=text/plain;package=com.google.android.apps.translate;'
          'S.android.intent.extra.TEXT=${e(text)};S.browser_fallback_url=${e(web.toString())};end';
      try {
        if (await launchUrl(Uri.parse(intent))) return;
      } catch (_) {}
    }
  }
  await launchUrl(web, mode: LaunchMode.externalApplication);
}

void openUrl(String url) => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);

/// Section for a due date relative to today: 0 overdue, 1 today, 2 tomorrow, 3 later, 4 no date.
int dueBucket(String due) {
  if (due.isEmpty) return 4;
  final t = ymd(DateTime.now());
  final tm = ymd(DateTime.now().add(const Duration(days: 1)));
  final c = due.compareTo(t);
  if (c < 0) return 0;
  if (c == 0) return 1;
  if (due == tm) return 2;
  return 3;
}

String fmtDate(String lang, String due) {
  if (due.isEmpty) return tr(lang, 'noDue');
  final p = due.split('-');
  if (p.length != 3) return due;
  final b = dueBucket(due);
  if (b == 1) return tr(lang, 'today');
  if (b == 2) return tr(lang, 'tomorrow');
  return '${p[2]}.${p[1]}.${p[0]}';
}

int daysUntil(String date) {
  final p = date.split('-').map(int.tryParse).toList();
  if (p.length != 3 || p.contains(null)) return -1;
  final now = DateTime.now();
  final a = DateTime(now.year, now.month, now.day);
  return DateTime(p[0]!, p[1]!, p[2]!).difference(a).inDays;
}

void toast(BuildContext context, String text, {String? action, VoidCallback? onAction}) {
  final m = ScaffoldMessenger.of(context);
  m.hideCurrentSnackBar();
  m.showSnackBar(
    SnackBar(
      content: Text(text),
      duration: Duration(seconds: action == null ? 2 : 6),
      action: action == null ? null : SnackBarAction(label: action, onPressed: onAction ?? () {}),
    ),
  );
}
