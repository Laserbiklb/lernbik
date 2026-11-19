import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:material_ui/material_ui.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'firebase_options.dart';
import 'hw_screen.dart';
import 'i18n.dart';
import 'store.dart';
import 'ui.dart';

/// Asks for notification permission and stores the device token.
/// Returns 'ok', 'denied' or 'unsupported'.
Future<String> setupPush(AppState s) async {
  try {
    final m = FirebaseMessaging.instance;
    if (!await m.isSupported()) return 'unsupported';
    final p = await m.requestPermission();
    if (p.authorizationStatus == AuthorizationStatus.denied) return 'denied';
    final tok = await m.getToken(vapidKey: kIsWeb && vapidKey.isNotEmpty ? vapidKey : null);
    if (tok != null) await s.saveToken(tok);
    m.onTokenRefresh.listen(s.saveToken);
    return 'ok';
  } catch (_) {
    return 'unsupported';
  }
}

/// Android only: newer APK build on the site?
Future<bool> updateAvailable() async {
  if (kIsWeb) return false;
  try {
    final info = await PackageInfo.fromPlatform();
    final r = await http.get(Uri.parse('$siteUrl/version.json')).timeout(const Duration(seconds: 8));
    final build = (jsonDecode(r.body)['build'] as num).toInt();
    return build > (int.tryParse(info.buildNumber) ?? 0);
  } catch (_) {
    return false;
  }
}

class MeScreen extends StatefulWidget {
  final AppState s;
  const MeScreen({super.key, required this.s});
  @override
  State<MeScreen> createState() => _MeScreenState();
}

class _MeScreenState extends State<MeScreen> {
  String push = '';
  String version = '';
  AppState get s => widget.s;
  String t(String k) => tr(s.lang, k);

  @override
  void initState() {
    super.initState();
    setupPush(s).then((v) {
      if (mounted) setState(() => push = v);
    });
    PackageInfo.fromPlatform().then((i) {
      if (mounted) setState(() => version = '${i.version} (${i.buildNumber})');
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    Widget head(String k) => Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 6),
          child: Text(t(k).toUpperCase(), style: TextStyle(fontSize: 12, letterSpacing: 1, fontWeight: FontWeight.w700, color: cs.onSurfaceVariant)),
        );
    return ListView(children: [
      ListTile(
        leading: CircleAvatar(child: Text(s.nick.isEmpty ? '?' : s.nick.characters.first.toUpperCase())),
        title: Text(s.nick, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
        subtitle: Text(t('nick')),
        trailing: const Icon(Icons.edit_outlined),
        onTap: _editNick,
      ),
      head('lang'),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: SegmentedButton<String>(
          segments: langs.entries.map((e) => ButtonSegment(value: e.key, label: Text(e.value))).toList(),
          selected: {s.lang},
          showSelectedIcon: false,
          onSelectionChanged: (v) => s.setLang(v.first),
        ),
      ),
      head('reminders'),
      SwitchListTile(
        title: Text(t('remindOn')),
        subtitle: Text(t('remindInfo')),
        value: s.remindOn,
        onChanged: (v) => s.setRemind(v, List.of(s.remind)),
      ),
      if (s.remindOn)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(spacing: 8, runSpacing: 8, children: [
            ...s.remind.map((r) => InputChip(
                  label: Text(r, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  onPressed: () => _pickTime(r),
                  onDeleted: s.remind.length > 1 ? () => s.setRemind(true, List.of(s.remind)..remove(r)) : null,
                )),
            if (s.remind.length < 4) ActionChip(avatar: const Icon(Icons.add, size: 18), label: Text(t('addTime')), onPressed: () => _pickTime(null)),
          ]),
        ),
      if (push == 'denied') Padding(padding: const EdgeInsets.all(16), child: Text(t('pushOff'), style: TextStyle(color: cs.error))),
      if (push == 'unsupported' && kIsWeb) Padding(padding: const EdgeInsets.all(16), child: Text(t('pushIos'), style: TextStyle(color: cs.onSurfaceVariant))),
      const Divider(height: 32),
      ListTile(leading: const Icon(Icons.flag_outlined), title: Text(t('report')), onTap: () => reportDialog(context, s, 'app')),
      ListTile(
        leading: const Icon(Icons.restore_from_trash_outlined),
        title: Text(t('trash')),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TrashScreen(s: s))),
      ),
      ListTile(
        leading: Icon(Icons.logout, color: cs.error),
        title: Text(t('logout'), style: TextStyle(color: cs.error)),
        onTap: () async {
          if (await confirm(context, s.lang, t('logoutAsk'), danger: true)) s.logout();
        },
      ),
      Padding(
        padding: const EdgeInsets.all(16),
        child: Text('Lernbik · ${t('version')} $version', textAlign: TextAlign.center, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
      ),
    ]);
  }

  Future<void> _editNick() async {
    final c = TextEditingController(text: s.nick);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t('nick')),
        content: TextField(controller: c, autofocus: true, maxLength: 24),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(t('cancel'))),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(t('save'))),
        ],
      ),
    );
    if (ok == true && c.text.trim().isNotEmpty) {
      final r = await s.setNick(c.text);
      if (!r && mounted) toast(context, t('nickTaken'));
    }
  }

  Future<void> _pickTime(String? old) async {
    var init = const TimeOfDay(hour: 18, minute: 0);
    if (old != null) {
      final p = old.split(':');
      init = TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1]));
    }
    final r = await showTimePicker(context: context, initialTime: init);
    if (r == null) return;
    // Reminders go out on the half hour.
    final m = r.minute < 30 ? 0 : 30;
    final v = '${r.hour.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
    final l = List.of(s.remind)..remove(old);
    if (!l.contains(v)) l.add(v);
    s.setRemind(true, l);
  }
}

Future<void> reportDialog(BuildContext context, AppState s, String where, {String prefill = ''}) async {
  final t = (String k) => tr(s.lang, k);
  final c = TextEditingController(text: prefill);
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(t('report')),
      content: TextField(controller: c, autofocus: true, minLines: 3, maxLines: 6, decoration: InputDecoration(hintText: t('reportHint'))),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(t('cancel'))),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(t('send'))),
      ],
    ),
  );
  if (ok == true && c.text.trim().isNotEmpty) {
    await s.report(c.text, where);
    if (context.mounted) toast(context, t('reportSent'));
  }
}
