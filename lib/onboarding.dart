import 'package:material_ui/material_ui.dart';

import 'i18n.dart';
import 'store.dart';
import 'ui.dart';

/// First start: language → name → group (link, new group, or recovery code).
class Onboarding extends StatefulWidget {
  final AppState s;
  const Onboarding({super.key, required this.s});
  @override
  State<Onboarding> createState() => _OnboardingState();
}

class _OnboardingState extends State<Onboarding> {
  final nickC = TextEditingController();
  final linkC = TextEditingController();
  final nameC = TextEditingController();
  final codeC = TextEditingController();
  String? err;
  bool busy = false;
  int mode = 0; // 0 join, 1 create, 2 restore

  AppState get s => widget.s;
  String t(String k) => tr(s.lang, k);

  @override
  void initState() {
    super.initState();
    if (s.pendingGroup != null) linkC.text = s.pendingGroup!;
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
    final needNick = s.key.isEmpty || s.nick.isEmpty;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: ListView(padding: const EdgeInsets.all(20), children: [
              const SizedBox(height: 12),
              Row(children: [
                const Logo(size: 30),
                const SizedBox(width: 10),
                Text('Lernbik', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
              ]),
              const SizedBox(height: 6),
              Text(t('tagline'), style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 24),
              Text(t('lang'), style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: langs.entries.map((e) => ButtonSegment(value: e.key, label: Text(e.value))).toList(),
                selected: {s.lang},
                showSelectedIcon: false,
                onSelectionChanged: (v) => setState(() => s.setLang(v.first)),
              ),
              const SizedBox(height: 24),
              if (needNick) ..._nickStep() else ..._groupStep(),
              if (err != null) ...[
                const SizedBox(height: 12),
                Text(err!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ],
            ]),
          ),
        ),
      ),
    );
  }

  List<Widget> _nickStep() => [
        TextField(
          controller: nickC,
          textCapitalization: TextCapitalization.words,
          maxLength: 24,
          decoration: InputDecoration(labelText: t('nick'), hintText: t('nickHint'), helperText: t('nickInfo'), helperMaxLines: 2),
          onSubmitted: (_) => _saveNick(),
        ),
        const SizedBox(height: 12),
        FilledButton(onPressed: busy ? null : _saveNick, child: Text(t('next'))),
        const SizedBox(height: 20),
        TextButton(onPressed: () => setState(() => mode = 2), child: Text(t('restore'))),
        if (mode == 2) ..._restore(),
      ];

  void _saveNick() {
    final n = nickC.text.trim();
    if (n.isEmpty) return;
    run(() async {
      if (s.key.isEmpty) {
        await s.createUser(n);
      } else {
        await s.setNick(n);
      }
    });
  }

  List<Widget> _restore() => [
        TextField(controller: codeC, decoration: InputDecoration(hintText: t('codeHint'))),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: busy
              ? null
              : () => run(() async {
                    if (!await s.restore(codeC.text)) err = t('badCode');
                  }),
          child: Text(t('useCode')),
        ),
      ];

  List<Widget> _groupStep() => [
        Text(t('joinTitle'), style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 6),
        Text(t('joinInfo')),
        const SizedBox(height: 12),
        TextField(controller: linkC, decoration: InputDecoration(hintText: t('linkHint'))),
        const SizedBox(height: 8),
        FilledButton(
          onPressed: busy
              ? null
              : () => run(() async {
                    final g = parseGroup(linkC.text);
                    if (g == null || await s.groupExists(g) == null) {
                      err = t('badLink');
                      return;
                    }
                    await s.joinGroup(g);
                  }),
          child: Text(t('join')),
        ),
        const SizedBox(height: 20),
        Row(children: [const Expanded(child: Divider()), Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Text(t('or'))), const Expanded(child: Divider())]),
        const SizedBox(height: 12),
        if (mode != 1)
          OutlinedButton(onPressed: () => setState(() => mode = 1), child: Text(t('createGroup')))
        else ...[
          TextField(controller: nameC, decoration: InputDecoration(labelText: t('groupName'), hintText: t('groupNameHint'))),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: busy
                ? null
                : () {
                    if (nameC.text.trim().isEmpty) return;
                    run(() => s.createGroup(nameC.text));
                  },
            child: Text(t('create')),
          ),
        ],
      ];
}
