import 'package:material_ui/material_ui.dart';

import 'firebase_options.dart';
import 'fx.dart';
import 'i18n.dart';
import 'learn/data.dart';
import 'nav.dart';
import 'store.dart';
import 'theme.dart';
import 'ui.dart';

class HeuteScreen extends StatefulWidget {
  final AppState s;
  final bool update;
  const HeuteScreen({super.key, required this.s, this.update = false});
  @override
  State<HeuteScreen> createState() => _HeuteScreenState();
}

class _HeuteScreenState extends State<HeuteScreen> {
  String? lv; // A1/A2 shown in the chapter list
  bool showDone = false;
  AppState get s => widget.s;
  String l(String de, String ru, String en) => l3(s.lang, de, ru, en);

  @override
  Widget build(BuildContext context) {
    final p = s.learn;
    final live = s.hw.where((h) => !h.deleted).toList()
      ..sort((a, b) {
        final c = (a.due.isEmpty ? '9' : a.due).compareTo(b.due.isEmpty ? '9' : b.due);
        return c != 0 ? c : (a.created ?? DateTime(2100)).compareTo(b.created ?? DateTime(2100));
      });
    final open = live.where((h) => s.done[h.id] != true).toList();
    final done = live.where((h) => s.done[h.id] == true).toList();
    final shownLv = lv ?? s.courseLv;

    return LPage(
      children: [
        Row(
          children: [
            const Logo(),
            const SizedBox(width: 10),
            Text('Lernbik', style: L.h(26)),
            const Spacer(),
            _StreakPill(streak: p.liveStreak, xp: p.xp),
            const SizedBox(width: 8),
            _Avatar(nick: s.nick, onTap: () => nav.go(2)),
          ],
        ),
        if (widget.update)
          Panel(
            accent: L.der,
            color: L.der.withValues(alpha: .1),
            onTap: () => openUrl(apkUrl),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            child: Row(
              children: [
                const Icon(Icons.system_update, size: 18, color: L.der),
                const SizedBox(width: 8),
                Expanded(child: Text(l('Neue Version verfügbar', 'Есть новая версия', 'New version available'), style: L.b(13))),
                Text(l('Installieren', 'Установить', 'Install'), style: L.b(13, L.der)),
              ],
            ),
          ),
        _NewsStrip(s: s),
        SectionTitle(l('Aufgaben', 'Задания', 'Tasks'), trailing: _Link('+ ${l('neu', 'новое', 'new')}', () => editTask(context, s, null))),
        Panel(
          child: Rows([
            for (final h in open) _TaskRow(s: s, h: h),
            if (open.isEmpty)
              Padding(
                padding: const EdgeInsets.all(14),
                child: Text(l('Keine offenen Aufgaben.', 'Открытых заданий нет.', 'No open tasks.'), style: L.t(14, c: L.muted)),
              ),
            if (done.isNotEmpty)
              InkWell(
                onTap: () => setState(() => showDone = !showDone),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 9, 14, 10),
                  child: Text('✓ ${done.length} ${l('erledigt', 'сделано', 'done')} ${showDone ? '▴' : '▾'}', style: L.t(12, c: L.muted)),
                ),
              ),
            if (showDone)
              for (final h in done) _TaskRow(s: s, h: h),
          ]),
        ),
        SectionTitle(
          l('Kapitel', 'Главы', 'Chapters'),
          trailing: Seg<String>(items: const [('A1', 'A1'), ('A2', 'A2')], value: shownLv, onChanged: (v) => setState(() => lv = v)),
        ),
        if (LearnData.loaded)
          Panel(
            child: Rows([for (final c in LearnData.i.book[shownLv]!) _ChapterRow(s: s, c: c)]),
          ),
        const SizedBox(height: 70),
      ],
    );
  }
}

class _Link extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  const _Link(this.text, this.onTap);
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(8),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: Text(text, style: L.b(13, L.der)),
    ),
  );
}

class _StreakPill extends StatelessWidget {
  final int streak, xp;
  const _StreakPill({required this.streak, required this.xp});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(color: const Color(0xFF2A1A10), borderRadius: BorderRadius.circular(99), boxShadow: L.glow(const Color(0xFFFF8A00), 12, .45)),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.local_fire_department, size: 15, color: Color(0xFFFF8A00)),
        Text(' $streak', style: L.b(13, L.fire)),
        const SizedBox(width: 8),
        Text('$xp XP', style: L.b(13, L.sign)),
      ],
    ),
  );
}

class _Avatar extends StatelessWidget {
  final String nick;
  final VoidCallback? onTap;
  final double size;
  const _Avatar({required this.nick, this.onTap}) : size = 34;
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: const BoxDecoration(color: L.die, shape: BoxShape.circle),
      child: Text(nick.isEmpty ? '?' : nick.characters.first.toUpperCase(), style: L.b(size * .44, Colors.white)),
    ),
  );
}

class _NewsStrip extends StatelessWidget {
  final AppState s;
  const _NewsStrip({required this.s});
  @override
  Widget build(BuildContext context) {
    final l = (String de, String ru, String en) => l3(s.lang, de, ru, en);
    final has = s.news.isNotEmpty;
    return Panel(
      accent: has ? L.die : null,
      glow: has ? 14 : 0,
      color: has ? const Color(0xFF1A1420) : L.panel,
      onTap: () => newsSheet(context, s),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Icon(Icons.campaign_outlined, size: 18, color: has ? L.die : L.muted),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              has ? s.news.first.text : l('Keine Hinweise · antippen zum Hinzufügen', 'Объявлений нет · нажми, чтобы добавить', 'No notices · tap to add'),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: has ? L.b(14) : L.t(13, c: L.muted),
            ),
          ),
          if (s.news.length > 1) Text('+${s.news.length - 1}', style: L.b(13, L.die)),
          const SizedBox(width: 4),
          const Icon(Icons.more_horiz, size: 18, color: L.muted),
        ],
      ),
    );
  }
}

class _TaskRow extends StatelessWidget {
  final AppState s;
  final Hw h;
  const _TaskRow({required this.s, required this.h});
  @override
  Widget build(BuildContext context) {
    final isDone = s.done[h.id] == true;
    final b = dueBucket(h.due);
    final dc = b <= 1 ? L.die : (b == 2 ? L.ink : L.muted);
    return InkWell(
      onTap: () => taskSheet(context, s, h),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 2, 14, 2),
        child: Row(
          children: [
            Semantics(
              checked: isDone,
              label: l3(s.lang, 'Erledigt', 'Сделано', 'Done'),
              child: IconButton(
                onPressed: () => s.setDone(h.id, !isDone),
                icon: Pop(
                  active: isDone,
                  scale: 1.35,
                  child: AnimatedSwitcher(
                    duration: Fx.d(220),
                    transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
                    child: Icon(isDone ? Icons.check_circle : Icons.radio_button_unchecked, key: ValueKey(isDone), color: isDone ? L.das : L.muted, size: 22),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Text(
                h.text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: L.t(15, c: isDone ? L.muted : L.ink).copyWith(decoration: isDone ? TextDecoration.lineThrough : null),
              ),
            ),
            const SizedBox(width: 10),
            if (h.due.isNotEmpty) Text(shortDate(s.lang, h.due), style: L.b(13, isDone ? L.muted : dc)),
          ],
        ),
      ),
    );
  }
}

class _ChapterRow extends StatelessWidget {
  final AppState s;
  final Chapter c;
  const _ChapterRow({required this.s, required this.c});
  @override
  Widget build(BuildContext context) {
    final now = c.lv == s.courseLv && c.n == s.courseN;
    final past = c.lv.compareTo(s.courseLv) < 0 || (c.lv == s.courseLv && c.n < s.courseN);
    final done = s.learn.chapterDone(c);
    final col = now ? L.der : (done >= .999 ? L.das : (past ? L.das : L.muted));
    return Material(
      color: now ? L.der.withValues(alpha: .1) : Colors.transparent,
      child: InkWell(
        onTap: () => nav.openChapter(c.lv, c.n),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 14, vertical: now ? 12 : 9),
          child: Row(
            children: [
              _maybeBreathe(
                now,
                Container(
                  width: 26,
                  height: 26,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: now ? L.der : col.withValues(alpha: done >= .999 || past ? .2 : .08),
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(color: now ? L.der : col.withValues(alpha: .7)),
                    boxShadow: now ? L.glow(L.der, 10, .7) : null,
                  ),
                  child: Text(done >= .999 ? '✓' : '${c.n}', style: L.h(14, now ? Colors.white : col)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c.title, style: now ? L.b(14) : L.t(14, c: past || done > 0 ? L.ink : L.ink2)),
                    if (now)
                      Text(
                        l3(s.lang, 'jetzt im Kurs', 'сейчас на курсе', 'current in class') +
                            (s.courseSince.isNotEmpty ? ' · ${l3(s.lang, 'seit', 'с', 'since')} ${_dm(s.courseSince)}' : ''),
                        style: L.t(11, c: L.derSoft),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Bar(done, color: now ? L.der : L.das),
              SizedBox(
                width: 38,
                child: Text(
                  '${(done * 100).round()}%',
                  textAlign: TextAlign.right,
                  style: L.t(11, c: L.muted),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _dm(String ymd) {
    final p = ymd.split('-');
    return p.length == 3 ? '${p[2]}.${p[1]}.' : ymd;
  }
}

// ---------------- sheets ----------------

Future<T?> _sheet<T>(BuildContext context, Widget Function(BuildContext, StateSetter) b) => showModalBottomSheet<T>(
  context: context,
  isScrollControlled: true,
  builder: (ctx) => StatefulBuilder(
    builder: (ctx, set) => Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
      child: SingleChildScrollView(child: b(ctx, set)),
    ),
  ),
);

/// New task or edit: text + date (today, tomorrow, any day).
Future<void> editTask(BuildContext context, AppState s, Hw? h) async {
  final l = (String de, String ru, String en) => l3(s.lang, de, ru, en);
  final c = TextEditingController(text: h?.text ?? '');
  var due = h?.due ?? ymd(DateTime.now().add(const Duration(days: 1)));
  final openN = s.hw.where((x) => !x.deleted && s.done[x.id] != true && x.id != h?.id).length;
  await _sheet(context, (ctx, set) {
    final today = ymd(DateTime.now()), tom = ymd(DateTime.now().add(const Duration(days: 1)));
    final custom = due != today && due != tom;
    Widget chip(String label, bool on, VoidCallback f) => Pill(label, color: on ? L.der : L.muted, filled: on, onTap: f);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(h == null ? l('Neue Aufgabe', 'Новое задание', 'New task') : l('Aufgabe bearbeiten', 'Изменить задание', 'Edit task'), style: L.h(24)),
        const SizedBox(height: 14),
        TextField(
          controller: c,
          autofocus: true,
          minLines: 1,
          maxLines: 4,
          textCapitalization: TextCapitalization.sentences,
          style: L.t(15),
          decoration: InputDecoration(hintText: l('z. B. Kursbuch S. 54, Übung 3', 'напр. Kursbuch S. 54, Übung 3', 'e.g. Kursbuch p. 54, ex. 3')),
        ),
        const SizedBox(height: 14),
        SectionTitle(l('Bis wann?', 'К какому дню?', 'Due when?')),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            chip(l('Heute', 'Сегодня', 'Today'), due == today, () => set(() => due = today)),
            chip(l('Morgen', 'Завтра', 'Tomorrow'), due == tom, () => set(() => due = tom)),
            chip(custom ? shortDate(s.lang, due) : l('Datum wählen …', 'Выбрать дату …', 'Pick a date …'), custom, () async {
              final now = DateTime.now();
              final d = await showDatePicker(
                context: ctx,
                firstDate: now.subtract(const Duration(days: 30)),
                lastDate: now.add(const Duration(days: 400)),
                initialDate: now,
              );
              if (d != null) set(() => due = ymd(d));
            }),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          (openN > 0 ? '${l('Offen', 'Открыто', 'Open')}: $openN. ' : '') +
              l(
                'Alle in der Gruppe sehen die Aufgabe. Auch Prüfungen trägst du hier mit Datum ein.',
                'Задание увидят все в группе. Экзамен тоже вносится сюда, с датой.',
                'Everyone in the group sees it. Exams go here too, with their date.',
              ),
          style: L.t(12, c: L.muted),
        ),
        const SizedBox(height: 16),
        GlowButton(
          l('Speichern', 'Сохранить', 'Save'),
          onTap: () async {
            if (c.text.trim().isEmpty) return;
            Navigator.pop(ctx);
            if (h == null) {
              await s.addHw(c.text, due);
            } else {
              await s.editHw(h.id, c.text, due);
            }
          },
        ),
      ],
    );
  });
}

/// An opened task: who added it, done, edit, delete, translate.
Future<void> taskSheet(BuildContext context, AppState s, Hw h) async {
  final l = (String de, String ru, String en) => l3(s.lang, de, ru, en);
  await _sheet(context, (ctx, set) {
    final isDone = s.done[h.id] == true;
    final meta = [
      if (h.by.isNotEmpty) '${l('eingetragen von', 'добавил(а)', 'added by')} ${h.by}',
      if (h.editedBy.isNotEmpty) '${l('geändert von', 'изменил(а)', 'edited by')} ${h.editedBy}',
    ].join(' · ');
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (h.due.isNotEmpty)
          Align(
            alignment: Alignment.centerLeft,
            child: Pill('${l('bis', 'до', 'due')} ${shortDate(s.lang, h.due)}', color: L.die, filled: true),
          ),
        const SizedBox(height: 10),
        SelectableText(h.text, style: L.h(24)),
        if (meta.isNotEmpty) ...[const SizedBox(height: 6), Text(meta, style: L.t(12, c: L.muted))],
        const SizedBox(height: 16),
        GlowButton(
          isDone ? l('Doch nicht erledigt', 'Ещё не сделано', 'Not done yet') : '✓  ${l('Erledigt', 'Сделано', 'Done')}',
          color: isDone ? L.line2 : L.das,
          textColor: isDone ? L.ink : L.bg,
          onTap: () {
            s.setDone(h.id, !isDone);
            Navigator.pop(ctx);
          },
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: GhostButton(
                l('Bearbeiten', 'Изменить', 'Edit'),
                icon: Icons.edit_outlined,
                onTap: () {
                  Navigator.pop(ctx);
                  editTask(context, s, h);
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: GhostButton(
                l('Löschen', 'Удалить', 'Delete'),
                color: L.die,
                icon: Icons.delete_outline,
                onTap: () async {
                  Navigator.pop(ctx);
                  await s.setDeleted(h.id, true);
                  if (context.mounted) {
                    toast(context, l('Gelöscht', 'Удалено', 'Deleted'), action: l('Rückgängig', 'Отменить', 'Undo'), onAction: () => s.setDeleted(h.id, false));
                  }
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        GhostButton(l('Übersetzen', 'Перевести', 'Translate'), color: L.muted, icon: Icons.translate, onTap: () => openTranslate(h.text)),
        const SizedBox(height: 10),
        Text(
          l(
            'Gelöschte Aufgaben kannst du unter Ich → Papierkorb zurückholen.',
            'Удалённое задание можно вернуть: Ich → Корзина.',
            'Deleted tasks can be restored under Ich → Trash.',
          ),
          style: L.t(12, c: L.muted),
        ),
      ],
    );
  });
}

/// Notices for the whole group: list, delete, add.
Future<void> newsSheet(BuildContext context, AppState s) async {
  final l = (String de, String ru, String en) => l3(s.lang, de, ru, en);
  final c = TextEditingController();
  await _sheet(context, (ctx, set) {
    return ListenableBuilder(
      listenable: s,
      builder: (ctx, _) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l('Hinweise', 'Объявления', 'Notices'), style: L.h(24)),
          const SizedBox(height: 12),
          if (s.news.isNotEmpty)
            Panel(
              child: Rows([
                for (final n in s.news)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 8, 4, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(n.text, style: L.b(14)),
                              if (n.by.isNotEmpty) Text('${l('von', 'от', 'by')} ${n.by}', style: L.t(12, c: L.muted)),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: l('Löschen', 'Удалить', 'Delete'),
                          icon: const Icon(Icons.close, color: L.muted, size: 18),
                          onPressed: () async {
                            await s.setNewsDeleted(n.id, true);
                            if (context.mounted) {
                              toast(
                                context,
                                l('Gelöscht', 'Удалено', 'Deleted'),
                                action: l('Rückgängig', 'Отменить', 'Undo'),
                                onAction: () => s.setNewsDeleted(n.id, false),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
              ]),
            ),
          const SizedBox(height: 12),
          TextField(
            controller: c,
            maxLines: 3,
            minLines: 1,
            style: L.t(15),
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(hintText: l('z. B. Morgen kein Kurs', 'напр. Завтра нет курса', 'e.g. No class tomorrow')),
          ),
          const SizedBox(height: 10),
          GhostButton(
            '+ ${l('Hinweis hinzufügen', 'Добавить объявление', 'Add notice')}',
            color: L.die,
            onTap: () async {
              if (c.text.trim().isEmpty) return;
              await s.addNews(c.text);
              c.clear();
            },
          ),
          const SizedBox(height: 8),
          Text(
            l(
              'Alle in der Gruppe sehen den Hinweis oben auf „Heute“.',
              'Объявление увидят все в группе вверху «Heute».',
              'Everyone in the group sees it at the top of “Heute”.',
            ),
            style: L.t(12, c: L.muted),
          ),
        ],
      ),
    );
  });
}

/// Deleted tasks with a restore button.
class TrashScreen extends StatelessWidget {
  final AppState s;
  const TrashScreen({super.key, required this.s});
  @override
  Widget build(BuildContext context) {
    final l = (String de, String ru, String en) => l3(s.lang, de, ru, en);
    return ListenableBuilder(
      listenable: s,
      builder: (context, _) {
        final del = s.hw.where((h) => h.deleted).toList()..sort((a, b) => (b.deletedAt ?? DateTime(0)).compareTo(a.deletedAt ?? DateTime(0)));
        return SubPage(
          title: l('Papierkorb', 'Корзина', 'Trash'),
          children: [
            if (del.isEmpty) Text(l('Nichts gelöscht.', 'Ничего не удалено.', 'Nothing deleted.'), style: L.t(14, c: L.muted)),
            if (del.isNotEmpty)
              Panel(
                child: Rows([
                  for (final h in del)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(h.text, style: L.t(14)),
                                if (h.due.isNotEmpty) Text(shortDate(s.lang, h.due), style: L.t(12, c: L.muted)),
                              ],
                            ),
                          ),
                          TextButton(onPressed: () => s.setDeleted(h.id, false), child: Text(l('Zurückholen', 'Вернуть', 'Restore'))),
                        ],
                      ),
                    ),
                ]),
              ),
          ],
        );
      },
    );
  }
}

/// The current course chapter glows softly.
Widget _maybeBreathe(bool on, Widget child) => on ? Breathe(color: L.der, radius: 7, child: child) : child;
