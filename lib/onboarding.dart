import 'package:material_ui/material_ui.dart';

import 'groups.dart';
import 'i18n.dart';
import 'store.dart';
import 'theme.dart';

/// First start: language → name → group (pick an existing one or create a new one).
class Onboarding extends StatefulWidget {
  final AppState s;
  const Onboarding({super.key, required this.s});
  @override
  State<Onboarding> createState() => _OnboardingState();
}

class _OnboardingState extends State<Onboarding> {
  final nickC = TextEditingController();
  String? err;
  bool busy = false;

  AppState get s => widget.s;
  String t(String k) => tr(s.lang, k);

  @override
  void initState() {
    super.initState();
    nickC.text = s.nick;
  }

  Future<void> run(Future<void> Function() f) async {
    setState(() {
      busy = true;
      err = null;
    });
    try {
      await f();
    } catch (e) {
      err = t('offline');
    }
    if (mounted) setState(() => busy = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Logo(size: 30),
                    const SizedBox(width: 10),
                    Text('Lernbik', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(t('tagline'), style: Theme.of(context).textTheme.bodyLarge),
                const SizedBox(height: 24),
                if (s.key.isNotEmpty && s.nick.isNotEmpty) ...[
                  Text(l3(s.lang, 'Hallo, ${s.nick}!', 'Привет, ${s.nick}!', 'Hi, ${s.nick}!'), style: L.h(26)),
                  const SizedBox(height: 14),
                  GroupPicker(s: s),
                  const SizedBox(height: 18),
                  TextButton(
                    onPressed: s.logout,
                    child: Text(l3(s.lang, 'Anderer Name', 'Другое имя', 'Another name')),
                  ),
                ] else ...[
                Text(t('lang'), style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                SegmentedButton<String>(
                  segments: langs.entries.map((e) => ButtonSegment(value: e.key, label: Text(e.value))).toList(),
                  selected: {s.lang},
                  showSelectedIcon: false,
                  onSelectionChanged: (v) => setState(() => s.setLang(v.first)),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: nickC,
                  textCapitalization: TextCapitalization.words,
                  maxLength: 24,
                  decoration: InputDecoration(labelText: t('nick'), hintText: t('nickHint'), helperText: t('nickInfo'), helperMaxLines: 3),
                  onSubmitted: (_) => _go(),
                ),
                const SizedBox(height: 12),
                FilledButton(onPressed: busy ? null : _go, child: Text(t('next'))),
                if (err != null) ...[const SizedBox(height: 12), Text(err!, style: TextStyle(color: Theme.of(context).colorScheme.error))],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _go() {
    final n = nickC.text.trim();
    if (n.isEmpty) return;
    run(() => s.login(n));
  }
}
