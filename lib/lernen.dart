import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import 'i18n.dart';
import 'learn/data.dart';
import 'learn/exercise.dart';
import 'learn/html.dart';
import 'learn/progress.dart';
import 'learn/round.dart';
import 'learn/tasks.dart';
import 'learn/trainers.dart';
import 'learn/tts.dart';
import 'learn/widgets.dart';
import 'nav.dart';
import 'store.dart';
import 'theme.dart';
import 'ui.dart';

String _l(AppState s, String de, String ru, String en) => l3(s.lang, de, ru, en);

void startWords(BuildContext context, AppState s, List<Word> pool, String mode) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => RoundScreen(p: s.learn, pool: pool, mode: mode, lang: s.lang),
    ),
  );
}

class LernenScreen extends StatelessWidget {
  final AppState s;
  const LernenScreen({super.key, required this.s});

  @override
  Widget build(BuildContext context) {
    final l = (String de, String ru, String en) => _l(s, de, ru, en);
    final d = LearnData.i;
    final p = s.learn;
    final isCourse = nav.lv == null || (nav.lv == s.courseLv && nav.n == s.courseN);
    final c = d.chapter(nav.lv ?? s.courseLv, nav.n ?? s.courseN) ?? d.book['A1']!.first;
    final ws = p.wordsOf(c.id);
    final fresh = ws.where((w) => p.prog[w.k] == null).length;
    final due = p.dueCount();

    return LPage(
      children: [
        const Header('Lernen'),
        Row(
          children: [
            Expanded(
              child: _Tile(
                icon: Icons.menu_book_outlined,
                label: l('Wörterbuch', 'Словарь', 'Dictionary'),
                color: L.der,
                row: true,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DictScreen(s: s))),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _Tile(
                icon: Icons.rule,
                label: l('Alle Regeln', 'Все правила', 'All rules'),
                color: L.die,
                row: true,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AllRulesScreen(s: s))),
              ),
            ),
          ],
        ),
        SectionTitle(l('Trainer', 'Тренажёры', 'Trainers')),
        Row(
          children: [
            for (final (i, t) in trainers.indexed) ...[
              if (i > 0) const SizedBox(width: 8),
              Expanded(
                child: _Tile(
                  big: t.badge,
                  label: t.name(s.lang),
                  color: t.color,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TrainerScreen(s: s, t: t),
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(width: 8),
            Expanded(
              child: _Tile(big: '+', label: l('bald', 'скоро', 'soon'), color: L.muted, dashed: true),
            ),
          ],
        ),
        Panel(
          accent: L.der,
          glow: 22,
          color: const Color(0xFF141A2C),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${c.lv} · ${l('Kapitel', 'Глава', 'Chapter')} ${c.n}${isCourse ? ' · ${l('im Kurs', 'на курсе', 'in class')}' : ''}'.toUpperCase(),
                          style: L.b(11, isCourse ? L.derSoft : L.muted).copyWith(letterSpacing: .8),
                        ),
                        const SizedBox(height: 2),
                        Text(c.title, style: L.h(23)),
                      ],
                    ),
                  ),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: L.ink2,
                      side: const BorderSide(color: L.line2),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                    ),
                    onPressed: () => pickChapter(context, s),
                    child: Text('${l('wechseln', 'сменить', 'switch')} ▾', style: L.b(12, L.ink2)),
                  ),
                ],
              ),
              if (!isCourse)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    style: TextButton.styleFrom(padding: EdgeInsets.zero, visualDensity: VisualDensity.compact),
                    onPressed: nav.backToCourse,
                    child: Text(
                      '← ${l('zum Kapitel im Kurs', 'к главе курса', 'back to the class chapter')} (${s.courseLv} · ${s.courseN})',
                      style: L.b(12, L.der),
                    ),
                  ),
                ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Pill('${ws.length} ${l('Wörter', 'слов', 'words')}'),
                  if (fresh > 0) Pill('$fresh ${l('neu', 'новых', 'new')}', color: L.der),
                  Pill('${(p.chapterDone(c) * 100).round()} %', color: L.das),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: GlowButton(l('Wörter lernen', 'Учить слова', 'Learn words'), onTap: ws.isEmpty ? null : () => startWords(context, s, ws, 'new')),
                  ),
                  const SizedBox(width: 8),
                  GhostButton(
                    '${l('Wiederholen', 'Повторить', 'Review')} · $due',
                    color: L.sign,
                    onTap: p.seenCount == 0 ? null : () => startWords(context, s, p.allWords, 'rev'),
                  ),
                ],
              ),
            ],
          ),
        ),
        SectionTitle('${l('Regeln', 'Правила', 'Rules')} · ${l('Kapitel', 'Глава', 'Chapter')} ${c.n}'),
        if (c.rules.isEmpty)
          Text(l('In diesem Kapitel gibt es keine Regeln.', 'В этой главе нет правил.', 'No rules in this chapter.'), style: L.t(14, c: L.muted)),
        if (c.rules.isNotEmpty)
          Panel(
            child: Rows([for (final r in c.rules) RuleRow(s: s, r: r)]),
          ),
        const SizedBox(height: 70),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  final IconData? icon;
  final String? big;
  final String label;
  final Color color;
  final VoidCallback? onTap;
  final bool row, dashed;
  const _Tile({this.icon, this.big, required this.label, required this.color, this.onTap, this.row = false, this.dashed = false});
  @override
  Widget build(BuildContext context) {
    final ic = icon != null ? Icon(icon, size: 20, color: color) : Text(big ?? '', style: L.h(18, color));
    final txt = Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: L.b(12, dashed ? L.muted : L.ink));
    return Panel(
      accent: dashed ? null : color,
      glow: dashed ? 0 : 8,
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
      child: row
          ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ic,
                const SizedBox(width: 8),
                Flexible(child: txt),
              ],
            )
          : Column(children: [ic, const SizedBox(height: 4), txt]),
    );
  }
}

class RuleRow extends StatelessWidget {
  final AppState s;
  final Rule r;
  final bool showChapter;
  const RuleRow({super.key, required this.s, required this.r, this.showChapter = false});
  @override
  Widget build(BuildContext context) {
    final p = s.learn;
    final runs = p.rclean[r.id] ?? 0;
    final done = runs >= runsToLearn;
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RuleScreen(s: s, r: r),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(r.t(s.lang), style: L.b(14)),
                  Text(
                    r.ex.replaceAll(RegExp(r'<[^>]+>'), ''),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: L.t(12, c: L.muted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (done) Pill('✓ ${_l(s, 'gelernt', 'выучено', 'learned')}', color: L.das),
            if (!done && runs > 0) Text('$runs/$runsToLearn', style: L.b(12, L.sign)),
            if (!done) const Icon(Icons.chevron_right, color: L.muted),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet with all chapters; picks the chapter shown in "Lernen".
Future<void> pickChapter(BuildContext context, AppState s) async {
  final l = (String de, String ru, String en) => _l(s, de, ru, en);
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: .8,
      builder: (ctx, sc) => ListView(
        controller: sc,
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        children: [
          Text(l('Kapitel wählen', 'Выбрать главу', 'Pick a chapter'), style: L.h(22)),
          for (final lv in ['A1', 'A2']) ...[
            const SizedBox(height: 12),
            SectionTitle(lv),
            Panel(
              child: Rows([
                for (final c in LearnData.i.book[lv]!)
                  ListTile(
                    dense: true,
                    leading: Text('${c.n}', style: L.h(16, c.lv == s.courseLv && c.n == s.courseN ? L.der : L.muted)),
                    title: Text(c.title, style: L.t(14)),
                    subtitle: c.lv == s.courseLv && c.n == s.courseN
                        ? Text(l('jetzt im Kurs', 'сейчас на курсе', 'current in class'), style: L.t(11, c: L.derSoft))
                        : null,
                    trailing: Text('${(s.learn.chapterDone(c) * 100).round()}%', style: L.t(12, c: L.muted)),
                    onTap: () {
                      nav.openChapter(c.lv, c.n);
                      Navigator.pop(ctx);
                    },
                  ),
              ]),
            ),
          ],
        ],
      ),
    ),
  );
}

// ---------------- a rule ----------------

class RuleScreen extends StatelessWidget {
  final AppState s;
  final Rule r;
  const RuleScreen({super.key, required this.s, required this.r});

  @override
  Widget build(BuildContext context) {
    final l = (String de, String ru, String en) => _l(s, de, ru, en);
    final c = r.chapter;
    final idx = c.rules.indexOf(r);
    return ListenableBuilder(
      listenable: s.learn,
      builder: (context, _) {
        final runs = s.learn.rclean[r.id] ?? 0;
        final done = runs >= runsToLearn;
        final can = hasTasks(r);
        return SubPage(
          title: '${c.lv} · ${l('Kapitel', 'Глава', 'Chapter')} ${c.n}',
          actions: [Text('${idx + 1}/${c.rules.length}', style: L.b(13, L.muted))],
          children: [
            Text(r.t(s.lang), style: L.h(30)),
            Panel(padding: const EdgeInsets.fromLTRB(14, 14, 14, 6), child: RuleHtml(r.b(s.lang))),
            if (r.ex.isNotEmpty)
              Panel(
                color: L.der.withValues(alpha: .08),
                accent: L.der,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    Expanded(child: Text(r.ex.replaceAll(RegExp(r'<[^>]+>'), ''), style: L.b(14))),
                    if (Tts.available)
                      IconButton(
                        tooltip: l('Anhören', 'Послушать', 'Listen'),
                        onPressed: () => Tts.say(r.ex.replaceAll(RegExp(r'<[^>]+>'), '').split(' · ').first),
                        icon: const Icon(Icons.volume_up_outlined, color: L.der, size: 20),
                      ),
                  ],
                ),
              ),
            SectionTitle(l('Üben', 'Упражнения', 'Practice')),
            Panel(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(l('Runden ohne Fehler', 'Заходы без ошибок', 'Runs without mistakes'), style: L.b(13))),
                      Text(done ? '✓ ${l('gelernt', 'выучено', 'learned')}' : '$runs / $runsToLearn', style: L.b(13, done ? L.das : L.sign)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Bar(runs / runsToLearn, width: double.infinity, height: 6),
                  const SizedBox(height: 8),
                  Text(
                    l(
                      'Nach $runsToLearn Runden ohne Fehler gilt die Regel als gelernt. Ein Fehler setzt nichts zurück – die Runde zählt nur nicht.',
                      'После $runsToLearn заходов без ошибок правило считается выученным. Ошибка ничего не обнуляет — просто заход не засчитывается.',
                      'After $runsToLearn runs without mistakes the rule counts as learned. A mistake resets nothing – that run just does not count.',
                    ),
                    style: L.t(12, c: L.muted),
                  ),
                  const SizedBox(height: 12),
                  GlowButton(
                    can ? l('Üben', 'Тренировать', 'Practise') : l('Noch keine Aufgaben', 'Заданий пока нет', 'No tasks yet'),
                    onTap: can ? () => practiseRule(context, s, r) : null,
                  ),
                ],
              ),
            ),
            for (final t in r.trainers)
              if (trainerFor(t[0]) != null)
                GhostButton(
                  '${l('Trainer', 'Тренажёр', 'Trainer')}: ${t.length > 2 ? t[2] : trainerFor(t[0])!.name(s.lang)}',
                  color: L.der,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TrainerScreen(s: s, t: trainerFor(t[0])!, topic: t[1]),
                    ),
                  ),
                ),
            Row(
              children: [
                if (idx > 0)
                  Expanded(
                    child: TextButton(
                      style: TextButton.styleFrom(alignment: Alignment.centerLeft),
                      onPressed: () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RuleScreen(s: s, r: c.rules[idx - 1]),
                        ),
                      ),
                      child: Text('‹ ${c.rules[idx - 1].t(s.lang)}', maxLines: 1, overflow: TextOverflow.ellipsis, style: L.b(13, L.muted)),
                    ),
                  )
                else
                  const Spacer(),
                if (idx < c.rules.length - 1)
                  Expanded(
                    child: TextButton(
                      style: TextButton.styleFrom(alignment: Alignment.centerRight),
                      onPressed: () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RuleScreen(s: s, r: c.rules[idx + 1]),
                        ),
                      ),
                      child: Text('${c.rules[idx + 1].t(s.lang)} ›', maxLines: 1, overflow: TextOverflow.ellipsis, style: L.b(13, L.der)),
                    ),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}

void practiseRule(BuildContext context, AppState s, Rule r) {
  final l = (String de, String ru, String en) => _l(s, de, ru, en);
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => ExerciseScreen(
        title: r.t(s.lang),
        lang: s.lang,
        p: s.learn,
        make: () => tasksForRule(r, s.lang),
        onDone: (clean, right, first, total) => s.learn.applyRuleRun(r.id, clean, right),
        doneExtra: (ctx, clean, first, total) {
          final runs = s.learn.rclean[r.id] ?? 0;
          return Panel(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(l('Runden ohne Fehler', 'Заходы без ошибок', 'Runs without mistakes'), style: L.b(13))),
                    Text(
                      runs >= runsToLearn ? '✓ ${l('gelernt', 'выучено', 'learned')}' : '${runs.clamp(0, runsToLearn)} / $runsToLearn',
                      style: L.b(13, runs >= runsToLearn ? L.das : L.sign),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Bar(runs / runsToLearn, width: double.infinity, height: 6),
              ],
            ),
          );
        },
      ),
    ),
  );
}

// ---------------- all rules ----------------

class AllRulesScreen extends StatefulWidget {
  final AppState s;
  const AllRulesScreen({super.key, required this.s});
  @override
  State<AllRulesScreen> createState() => _AllRulesScreenState();
}

class _AllRulesScreenState extends State<AllRulesScreen> {
  late String lv = widget.s.courseLv;
  String q = '';
  AppState get s => widget.s;

  @override
  Widget build(BuildContext context) {
    final l = (String de, String ru, String en) => _l(s, de, ru, en);
    final qq = q.trim().toLowerCase();
    bool hit(Rule r) => qq.isEmpty || r.t(s.lang).toLowerCase().contains(qq) || r.ex.toLowerCase().contains(qq) || r.b(s.lang).toLowerCase().contains(qq);
    final chs = qq.isEmpty ? LearnData.i.book[lv]! : [...LearnData.i.book['A1']!, ...LearnData.i.book['A2']!];
    return ListenableBuilder(
      listenable: s.learn,
      builder: (context, _) => SubPage(
        title: l('Alle Regeln', 'Все правила', 'All rules'),
        actions: [
          Seg<String>(items: const [('A1', 'A1'), ('A2', 'A2')], value: lv, onChanged: (v) => setState(() => lv = v)),
        ],
        children: [
          TextField(
            style: L.t(15),
            onChanged: (v) => setState(() => q = v),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search, color: L.muted),
              hintText: l('Regel suchen, z. B. Dativ', 'Найти правило, напр. Dativ', 'Search a rule, e.g. Dativ'),
            ),
          ),
          for (final c in chs)
            if (c.rules.any(hit)) ...[
              SectionTitle(
                '${qq.isEmpty ? '' : '${c.lv} · '}${c.n} · ${c.title}',
                trailing: c.lv == s.courseLv && c.n == s.courseN ? Text(l('im Kurs', 'на курсе', 'in class'), style: L.b(11, L.derSoft)) : null,
              ),
              Panel(
                accent: c.lv == s.courseLv && c.n == s.courseN ? L.der : null,
                child: Rows([for (final r in c.rules.where(hit)) RuleRow(s: s, r: r)]),
              ),
            ],
        ],
      ),
    );
  }
}

// ---------------- dictionary + own words ----------------

class DictScreen extends StatefulWidget {
  final AppState s;
  const DictScreen({super.key, required this.s});
  @override
  State<DictScreen> createState() => _DictScreenState();
}

class _DictScreenState extends State<DictScreen> {
  String q = '';
  String filter = 'all'; // all | A1 | A2 | course | own
  AppState get s => widget.s;

  @override
  Widget build(BuildContext context) {
    final l = (String de, String ru, String en) => _l(s, de, ru, en);
    return ListenableBuilder(
      listenable: s.learn,
      builder: (context, _) {
        final p = s.learn;
        final courseId = '${s.courseLv} · ${s.courseN}';
        Iterable<Word> ws = p.allWords;
        ws = switch (filter) {
          'A1' => ws.where((w) => w.level == 'A1'),
          'A2' => ws.where((w) => w.level == 'A2'),
          'course' => ws.where((w) => w.c == courseId),
          'own' => ws.where((w) => w.own),
          _ => ws,
        };
        final qq = fold(q);
        if (qq.isNotEmpty) ws = ws.where((w) => fold(w.k).contains(qq) || w.r.toLowerCase().contains(q.trim().toLowerCase()));
        final list = ws.take(200).toList();
        final ownChapters = {for (final w in p.own) w.c}.toList();
        Widget chip(String v, String label, [Color c = L.der]) =>
            Pill(label, color: filter == v ? c : L.muted, filled: filter == v, onTap: () => setState(() => filter = v));
        return SubPage(
          title: l('Wörterbuch', 'Словарь', 'Dictionary'),
          actions: [Text('${p.allWords.length}', style: L.b(13, L.muted))],
          children: [
            TextField(
              style: L.t(15),
              onChanged: (v) => setState(() => q = v),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search, color: L.muted),
                hintText: l('Wort suchen (de / ru) …', 'Найти слово (de / ru) …', 'Search a word (de / ru) …'),
              ),
            ),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                chip('all', l('Alle', 'Все', 'All')),
                chip('A1', 'A1'),
                chip('A2', 'A2'),
                chip('course', '${l('Kapitel', 'Глава', 'Chapter')} ${s.courseN}'),
                chip('own', l('Eigene', 'Свои', 'Own'), L.sign),
              ],
            ),
            if (filter == 'own' && ownChapters.isNotEmpty)
              Panel(
                child: Rows([
                  for (final ch in ownChapters)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
                      child: Row(
                        children: [
                          Expanded(child: Text('$ch · ${p.own.where((w) => w.c == ch).length}', style: L.b(14))),
                          TextButton(
                            onPressed: () => startWords(context, s, p.own.where((w) => w.c == ch).toList(), 'new'),
                            child: Text(l('Lernen', 'Учить', 'Learn')),
                          ),
                          IconButton(
                            tooltip: l('Löschen', 'Удалить', 'Delete'),
                            icon: const Icon(Icons.delete_outline, color: L.muted, size: 20),
                            onPressed: () async {
                              if (await confirm(context, s.lang, '${l('Löschen', 'Удалить', 'Delete')}: $ch?', danger: true)) p.deleteOwnChapter(ch);
                            },
                          ),
                        ],
                      ),
                    ),
                ]),
              ),
            Panel(
              child: Rows([
                for (final w in list)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 6, 4, 6),
                    child: Row(
                      children: [
                        Container(
                          width: 4,
                          height: 30,
                          decoration: BoxDecoration(color: L.art(w.a), borderRadius: BorderRadius.circular(2)),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text.rich(
                                TextSpan(
                                  children: [
                                    if (w.a.isNotEmpty) TextSpan(text: '${w.a} ', style: L.b(14, L.art(w.a))),
                                    TextSpan(text: w.d, style: L.b(14)),
                                    if (w.p.isNotEmpty && w.p != '-')
                                      TextSpan(
                                        text: ', ${w.p}',
                                        style: L.t(12, c: L.muted),
                                      ),
                                  ],
                                ),
                              ),
                              Text(w.hasTr ? '${w.r} · ${w.c}' : w.c, style: L.t(12, c: L.muted)),
                            ],
                          ),
                        ),
                        if (p.prog[w.k] != null) LevelDots(p.prog[w.k]!.b),
                        if (Tts.available)
                          IconButton(
                            tooltip: l('Anhören', 'Послушать', 'Listen'),
                            onPressed: () => Tts.say(say(w)),
                            icon: const Icon(Icons.volume_up_outlined, color: L.der, size: 20),
                          ),
                        IconButton(
                          tooltip: l('Übersetzen', 'Перевести', 'Translate'),
                          onPressed: () => openGoogle(say(w)),
                          icon: const Icon(Icons.translate, color: L.muted, size: 18),
                        ),
                      ],
                    ),
                  ),
                if (list.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Text(l('Nichts gefunden.', 'Ничего не найдено.', 'Nothing found.'), style: L.t(14, c: L.muted)),
                  ),
              ]),
            ),
            if (ws.length > list.length)
              Text(
                '… ${ws.length - list.length} ${l('weitere – suche genauer', 'ещё – уточните поиск', 'more – refine the search')}',
                style: L.t(12, c: L.muted),
              ),
            Row(
              children: [
                Expanded(
                  child: GlowButton(
                    '+ ${l('Eigene Wörter', 'Свои слова', 'Own words')}',
                    color: L.sign,
                    textColor: L.bg,
                    size: 16,
                    onTap: () => _addWords(context),
                  ),
                ),
                const SizedBox(width: 8),
                GhostButton(
                  l('KI-Anfrage kopieren', 'Запрос для нейросети', 'Copy AI prompt'),
                  color: L.muted,
                  onTap: () async {
                    await Clipboard.setData(ClipboardData(text: aiPrompt(s.lang)));
                    if (context.mounted)
                      toast(
                        context,
                        l(
                          'Kopiert. In eine KI einfügen und die Antwort unten einfügen.',
                          'Скопировано. Вставьте в нейросеть, а её ответ — сюда.',
                          'Copied. Paste it into an AI, then paste its answer here.',
                        ),
                      );
                  },
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Future<void> _addWords(BuildContext context) async {
    final l = (String de, String ru, String en) => _l(s, de, ru, en);
    final ch = TextEditingController();
    final tx = TextEditingController();
    String note = '';
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => Padding(
          padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l('Eigene Wörter', 'Свои слова', 'Own words'), style: L.h(24)),
                const SizedBox(height: 12),
                TextField(
                  controller: ch,
                  style: L.t(15),
                  decoration: InputDecoration(hintText: l('Name der Liste, z. B. Arbeit', 'Название списка, напр. Работа', 'List name, e.g. Work')),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: tx,
                  minLines: 4,
                  maxLines: 10,
                  style: L.t(15),
                  decoration: const InputDecoration(hintText: 'der Tisch — стол\ndie Reise — путешествие\nabholen — забирать'),
                ),
                const SizedBox(height: 8),
                Text(
                  l(
                    'Ein Wort pro Zeile: Wort — Übersetzung. Nomen mit Artikel.',
                    'По одному в строке: слово — перевод. Существительные с артиклем.',
                    'One per line: word — translation. Nouns with article.',
                  ),
                  style: L.t(12, c: L.muted),
                ),
                if (note.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(note, style: L.b(13, L.sign)),
                  ),
                const SizedBox(height: 14),
                GlowButton(
                  l('Hinzufügen', 'Добавить', 'Add'),
                  color: L.sign,
                  textColor: L.bg,
                  onTap: () {
                    final name = ch.text.trim().isEmpty ? l('Meine Wörter', 'Мои слова', 'My words') : ch.text.trim();
                    final (a, d, b) = s.learn.addWords(name.length > 40 ? name.substring(0, 40) : name, tx.text);
                    if (a > 0 && d == 0 && b == 0) {
                      Navigator.pop(ctx);
                      toast(context, '${l('Hinzugefügt', 'Добавлено', 'Added')}: $a');
                      setState(() => filter = 'own');
                      return;
                    }
                    set(
                      () => note =
                          '${l('Hinzugefügt', 'Добавлено', 'Added')}: $a · ${l('schon da', 'уже были', 'already there')}: $d · ${l('nicht erkannt', 'не разобрано', 'not understood')}: $b',
                    );
                    if (a > 0) tx.clear();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String aiPrompt(String lang) => [
  'Ich lerne Deutsch (A2–B1). Schreib mir eine Wortliste zum Thema: <THEMA>.',
  'Format: eine Zeile pro Wort, „Wort — Übersetzung“. Nomen immer mit Artikel (der/die/das). 15–25 Wörter, nur die Liste, kein anderer Text.',
  'Übersetzung auf ${lang == 'en' ? 'Englisch' : (lang == 'ru' ? 'Russisch' : '<SPRACHE>')}.',
  'Beispiel:',
  lang == 'en' ? 'der Tisch — table' : 'der Tisch — стол',
  lang == 'en' ? 'abholen — to pick up' : 'abholen — забирать',
].join('\n');
