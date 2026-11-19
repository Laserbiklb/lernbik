import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

import 'firebase_options.dart';
import 'group_screen.dart';
import 'hw_screen.dart';
import 'i18n.dart';
import 'learn_screen.dart';
import 'me_screen.dart';
import 'onboarding.dart';
import 'store.dart';
import 'ui.dart';

final state = AppState();
final messengerKey = GlobalKey<ScaffoldMessengerState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: firebaseOptions);
  if (useEmulator) FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
  // A group link opened in the browser: lernbik.web.app/?g=XXXX
  if (kIsWeb) {
    final g = parseGroup(Uri.base.toString());
    if (g != null) state.pendingGroup = g;
  }
  runApp(const LernbikApp());
  try {
    await state.init();
  } catch (_) {
    state.ready = true;
    state.notify();
  }
  if (!kIsWeb) _listenLinks();
  FirebaseMessaging.onMessage.listen((m) {
    final n = m.notification;
    if (n == null) return;
    messengerKey.currentState?.showSnackBar(SnackBar(content: Text([n.title, n.body].whereType<String>().join('\n'))));
  });
}

/// lernbik://join?g=XXXX opened from the web page or WhatsApp.
void _listenLinks() {
  final links = AppLinks();
  void handle(Uri u) {
    final g = parseGroup(u.toString());
    if (g == null) return;
    state.pendingGroup = g;
    state.notify();
  }

  links.getInitialLink().then((u) {
    if (u != null) handle(u);
  });
  links.uriLinkStream.listen(handle);
}

class LernbikApp extends StatelessWidget {
  const LernbikApp({super.key});
  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: state,
        builder: (context, _) => MaterialApp(
          title: 'Lernbik',
          debugShowCheckedModeBanner: false,
          scaffoldMessengerKey: messengerKey,
          theme: buildTheme(Brightness.light),
          darkTheme: buildTheme(Brightness.dark),
          home: !state.ready
              ? const Scaffold(body: Center(child: Logo(size: 40)))
              : state.onboarded
                  ? Shell(s: state)
                  : Onboarding(s: state),
        ),
      );
}

class Shell extends StatefulWidget {
  final AppState s;
  const Shell({super.key, required this.s});
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int tab = 0;
  bool update = false;
  bool askingSwitch = false;
  AppState get s => widget.s;
  String t(String k) => tr(s.lang, k);

  @override
  void initState() {
    super.initState();
    updateAvailable().then((v) {
      if (mounted) setState(() => update = v);
    });
    setupPush(s);
  }

  @override
  Widget build(BuildContext context) {
    _maybeSwitchGroup();
    final cs = Theme.of(context).colorScheme;
    final androidWeb = kIsWeb && defaultTargetPlatform == TargetPlatform.android;
    final pages = [HwScreen(s: s), LearnScreen(s: s), GroupScreen(s: s), MeScreen(s: s)];
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(children: [
          const Logo(),
          const SizedBox(width: 10),
          Flexible(
              child: Text(tab == 0 && s.groupName.isNotEmpty ? s.groupName : 'Lernbik',
                  overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800))),
        ]),
        actions: [
          if (tab != 1) IconButton(tooltip: t('share'), icon: const Icon(Icons.share_outlined), onPressed: () => shareApp(context, s)),
        ],
      ),
      body: Column(children: [
        if (update)
          MaterialBanner(
            content: Text(t('update')),
            leading: const Icon(Icons.system_update),
            actions: [
              TextButton(onPressed: () => setState(() => update = false), child: Text(t('cancel'))),
              FilledButton(onPressed: () => openUrl(apkUrl), child: Text(t('install'))),
            ],
          ),
        if (androidWeb)
          Material(
            color: cs.secondaryContainer,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Wrap(spacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
                TextButton.icon(onPressed: () => openUrl(apkUrl), icon: const Icon(Icons.android), label: Text(t('android'))),
                TextButton(onPressed: () => openUrl('lernbik://join?g=${s.gid}'), child: Text(t('openApp'))),
              ]),
            ),
          ),
        Expanded(child: IndexedStack(index: tab, children: pages)),
      ]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (i) => setState(() => tab = i),
        destinations: [
          NavigationDestination(icon: const Icon(Icons.checklist_outlined), selectedIcon: const Icon(Icons.checklist), label: t('tabHw')),
          NavigationDestination(icon: const Icon(Icons.school_outlined), selectedIcon: const Icon(Icons.school), label: t('tabLearn')),
          NavigationDestination(icon: const Icon(Icons.groups_outlined), selectedIcon: const Icon(Icons.groups), label: t('tabGroup')),
          NavigationDestination(icon: const Icon(Icons.person_outline), selectedIcon: const Icon(Icons.person), label: t('tabMe')),
        ],
      ),
    );
  }

  /// A link to another group was opened while already in a group.
  void _maybeSwitchGroup() {
    final g = s.pendingGroup;
    if (g == null || askingSwitch) return;
    if (g == s.gid) {
      s.pendingGroup = null;
      return;
    }
    askingSwitch = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final name = await s.groupExists(g);
      if (!mounted) return;
      if (name != null && await confirm(context, s.lang, '${t('join')}: $name?')) {
        await s.joinGroup(g);
      }
      s.pendingGroup = null;
      askingSwitch = false;
    });
  }
}
