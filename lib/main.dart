import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

import 'firebase_options.dart';
import 'fx.dart';
import 'heute.dart';
import 'i18n.dart';
import 'ich.dart';
import 'learn/data.dart';
import 'learn/gen_rules.dart';
import 'learn/trainers.dart';
import 'learn/tts.dart';
import 'lernen.dart';
import 'nav.dart';
import 'onboarding.dart';
import 'store.dart';
import 'theme.dart';
import 'ui.dart';

final state = AppState();
final messengerKey = GlobalKey<ScaffoldMessengerState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: firebaseOptions);
  if (useEmulator) FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
  await LearnData.load();
  registerTrainers(state.learn);
  registerRuleGens();
  Tts.init();
  runApp(const LernbikApp());
  try {
    await state.init();
  } catch (_) {
    state.ready = true;
    state.notify();
  }
  FirebaseMessaging.onMessage.listen((m) {
    final n = m.notification;
    if (n == null) return;
    messengerKey.currentState?.showSnackBar(SnackBar(content: Text([n.title, n.body].whereType<String>().join('\n'))));
  });
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
      theme: buildTheme(),
      themeMode: ThemeMode.dark,
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
  bool update = false;
  AppState get s => widget.s;

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
    final androidWeb = kIsWeb && defaultTargetPlatform == TargetPlatform.android;
    return ListenableBuilder(
      listenable: Listenable.merge([nav, s.learn]),
      builder: (context, _) => Scaffold(
        body: Column(
          children: [
            if (androidWeb)
              SafeArea(
                bottom: false,
                child: Material(
                  color: L.panel,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                    child: Row(
                      children: [
                        const Icon(Icons.android, size: 18, color: L.das),
                        const SizedBox(width: 6),
                        Expanded(
                          child: TextButton(
                            style: TextButton.styleFrom(alignment: Alignment.centerLeft),
                            onPressed: () => openUrl(apkUrl),
                            child: Text(tr(s.lang, 'android'), style: L.b(13, L.das)),
                          ),
                        ),
                        TextButton(
                          onPressed: () => openUrl('lernbik://join'),
                          child: Text(tr(s.lang, 'openApp'), style: L.b(13, L.der)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            Expanded(
              child: IndexedStack(
                index: nav.tab,
                children: [
                  HeuteScreen(s: s, update: update),
                  LernenScreen(s: s),
                  IchScreen(s: s),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: _NavBar(lang: s.lang),
      ),
    );
  }
}

class _NavBar extends StatelessWidget {
  final String lang;
  const _NavBar({required this.lang});
  @override
  Widget build(BuildContext context) {
    final items = [(Icons.wb_sunny_outlined, 'Heute'), (Icons.school_outlined, 'Lernen'), (Icons.person_outline, 'Ich')];
    return Container(
      decoration: const BoxDecoration(
        color: L.navBg,
        border: Border(top: BorderSide(color: L.line)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (var i = 0; i < items.length; i++)
                Semantics(
                  button: true,
                  selected: nav.tab == i,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => nav.go(i),
                    child: SizedBox(
                      width: 76,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedContainer(
                            duration: Fx.d(260),
                            curve: Curves.easeOutCubic,
                            padding: EdgeInsets.symmetric(horizontal: nav.tab == i ? 18 : 14, vertical: 4),
                            decoration: BoxDecoration(
                              color: nav.tab == i ? L.die.withValues(alpha: .14) : null,
                              borderRadius: BorderRadius.circular(99),
                              boxShadow: nav.tab == i ? L.glow(L.die, 10, .4) : null,
                            ),
                            child: AnimatedScale(
                              scale: nav.tab == i ? 1.12 : 1,
                              duration: Fx.d(260),
                              curve: Curves.easeOutBack,
                              child: Icon(items[i].$1, size: 20, color: nav.tab == i ? L.die : L.muted),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(items[i].$2, style: nav.tab == i ? L.b(12, L.die) : L.t(12, c: L.muted)),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
