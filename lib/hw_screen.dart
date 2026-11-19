import 'package:material_ui/material_ui.dart';

import 'i18n.dart';
import 'store.dart';
import 'ui.dart';

class HwScreen extends StatelessWidget {
  final AppState s;
  const HwScreen({super.key, required this.s});
  String t(String k) => tr(s.lang, k);

  @override
  Widget build(BuildContext context) {
    final live = s.hw.where((h) => !h.deleted).toList()
      ..sort((a, b) {
        final c = (a.due.isEmpty ? '9' : a.due).compareTo(b.due.isEmpty ? '9' : b.due);
        return c != 0 ? c : (a.created ?? DateTime(2100)).compareTo(b.created ?? DateTime(2100));
      });
    final open = live.where((h) => s.done[h.id] != true).toList();
    final done = live.where((h) => s.done[h.id] == true).toList();
    final names = [t('overdue'), t('today'), t('tomorrow'), t('later'), t('noDue')];
    final cs = Theme.of(context).colorScheme;

    final items = <Widget>[];
    items.add(_ExamCard(s: s));
    for (final n in s.news) {
      items.add(_NewsCard(s: s, n: n));
    }
    for (var b = 0; b < 5; b++) {
      final g = open.where((h) => dueBucket(h.due) == b).toList();
      if (g.isEmpty) continue;
      items.add(Padding(
        padding: const EdgeInsets.fromLTRB(4, 14, 4, 6),
        child: Text(names[b].toUpperCase(),
            style: TextStyle(fontSize: 12, letterSpacing: 1, fontWeight: FontWeight.w700, color: b == 0 ? cs.error : cs.onSurfaceVariant)),
      ));
      items.addAll(g.map((h) => _HwTile(s: s, h: h)));
    }
    if (open.isEmpty) {
      items.add(Padding(padding: const EdgeInsets.all(32), child: Center(child: Text(t('empty'), style: TextStyle(color: cs.onSurfaceVariant)))));
    }
    if (done.isNotEmpty) {
      items.add(Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 4),
          title: Text('${t('done').toUpperCase()} · ${done.length}',
              style: TextStyle(fontSize: 12, letterSpacing: 1, fontWeight: FontWeight.w700, color: cs.onSurfaceVariant)),
          children: done.map((h) => _HwTile(s: s, h: h)).toList(),
        ),
      ));
    }
    items.add(const SizedBox(height: 90));

    return Scaffold(
      body: ListView(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), children: items),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => editHw(context, s, null),
        icon: const Icon(Icons.add),
        label: Text(t('add')),
      ),
    );
  }
}

class _HwTile extends StatelessWidget {
  final AppState s;
  final Hw h;
  const _HwTile({required this.s, required this.h});
  String t(String k) => tr(s.lang, k);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDone = s.done[h.id] == true;
    final b = dueBucket(h.due);
    final dateColor = b == 0 ? cs.error : (b == 1 ? cDie : cs.onSurfaceVariant);
    final meta = [
      if (h.by.isNotEmpty) '${t('addedBy')} ${h.by}',
      if (h.editedBy.isNotEmpty) '${t('editedBy')} ${h.editedBy}',
    ].join(' · ');
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 6, 0, 6),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Checkbox(
            value: isDone,
            shape: const CircleBorder(),
            onChanged: (v) => s.setDone(h.id, v == true),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(h.text,
                    style: TextStyle(
                        fontSize: 16,
                        decoration: isDone ? TextDecoration.lineThrough : null,
                        color: isDone ? cs.onSurfaceVariant : null)),
                const SizedBox(height: 4),
                Wrap(spacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
                  Text(fmtDate(s.lang, h.due), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: dateColor)),
                  if (meta.isNotEmpty) Text(meta, style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                ]),
              ]),
            ),
          ),
          PopupMenuButton<String>(
            tooltip: '',
            onSelected: (v) async {
              if (v == 'tr') openTranslate(h.text);
              if (v == 'edit') editHw(context, s, h);
              if (v == 'del') {
                if (!await confirm(context, s.lang, t('delAsk'), body: t('delInfo'), yes: t('delYes'), danger: true)) return;
                await s.setDeleted(h.id, true);
                if (context.mounted) toast(context, t('deleted'), action: t('undo'), onAction: () => s.setDeleted(h.id, false));
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(value: 'tr', child: ListTile(leading: const Icon(Icons.translate), title: Text(t('translate')))),
              PopupMenuItem(value: 'edit', child: ListTile(leading: const Icon(Icons.edit_outlined), title: Text(t('edit')))),
              PopupMenuItem(value: 'del', child: ListTile(leading: Icon(Icons.delete_outline, color: cs.error), title: Text(t('delete')))),
            ],
          ),
        ]),
      ),
    );
  }
}

Future<void> editHw(BuildContext context, AppState s, Hw? h) async {
  final t = (String k) => tr(s.lang, k);
  final c = TextEditingController(text: h?.text ?? '');
  var due = h?.due ?? ymd(DateTime.now().add(const Duration(days: 1)));
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => StatefulBuilder(builder: (ctx, set) {
      Widget chip(String label, String v) => ChoiceChip(label: Text(label), selected: due == v, onSelected: (_) => set(() => due = v));
      final today = ymd(DateTime.now()), tom = ymd(DateTime.now().add(const Duration(days: 1)));
      final custom = due.isNotEmpty && due != today && due != tom;
      return Padding(
        padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(h == null ? t('add') : t('edit'), style: Theme.of(ctx).textTheme.titleLarge),
          const SizedBox(height: 12),
          TextField(
            controller: c,
            autofocus: true,
            minLines: 2,
            maxLines: 6,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(labelText: t('task'), hintText: t('taskHint')),
          ),
          const SizedBox(height: 12),
          Text(t('due'), style: Theme.of(ctx).textTheme.titleSmall),
          const SizedBox(height: 6),
          Wrap(spacing: 8, runSpacing: 6, children: [
            chip(t('today'), today),
            chip(t('tomorrow'), tom),
            ChoiceChip(
              avatar: const Icon(Icons.calendar_month, size: 18),
              label: Text(custom ? fmtDate(s.lang, due) : t('pickDate')),
              selected: custom,
              onSelected: (_) async {
                final now = DateTime.now();
                final d = await showDatePicker(
                    context: ctx, firstDate: now.subtract(const Duration(days: 30)), lastDate: now.add(const Duration(days: 365)), initialDate: now);
                if (d != null) set(() => due = ymd(d));
              },
            ),
            chip(t('noDue'), ''),
          ]),
          const SizedBox(height: 10),
          Text(t('forAll'), style: TextStyle(color: Theme.of(ctx).colorScheme.onSurfaceVariant)),
          const SizedBox(height: 14),
          FilledButton(
            onPressed: () async {
              if (c.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              if (h == null) {
                await s.addHw(c.text, due);
              } else {
                await s.editHw(h.id, c.text, due);
              }
              if (context.mounted) toast(context, t('saved'));
            },
            child: Text(t('save')),
          ),
        ]),
      );
    }),
  );
}

class _NewsCard extends StatelessWidget {
  final AppState s;
  final News n;
  const _NewsCard({required this.s, required this.n});
  @override
  Widget build(BuildContext context) {
    final t = (String k) => tr(s.lang, k);
    final cs = Theme.of(context).colorScheme;
    return Card(
      color: cs.tertiaryContainer,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(Icons.campaign_outlined, color: cs.onTertiaryContainer),
        title: Text(n.text, style: TextStyle(color: cs.onTertiaryContainer, fontWeight: FontWeight.w600)),
        subtitle: n.by.isEmpty ? null : Text('${t('addedBy')} ${n.by}', style: TextStyle(color: cs.onTertiaryContainer)),
        trailing: IconButton(
          icon: Icon(Icons.close, color: cs.onTertiaryContainer),
          tooltip: t('delete'),
          onPressed: () async {
            if (!await confirm(context, s.lang, t('newsDelAsk'), yes: t('delYes'), danger: true)) return;
            await s.setNewsDeleted(n.id, true);
            if (context.mounted) toast(context, t('deleted'), action: t('undo'), onAction: () => s.setNewsDeleted(n.id, false));
          },
        ),
      ),
    );
  }
}

class _ExamCard extends StatelessWidget {
  final AppState s;
  const _ExamCard({required this.s});
  @override
  Widget build(BuildContext context) {
    if (s.examDate.isEmpty) return const SizedBox.shrink();
    final t = (String k) => tr(s.lang, k);
    final d = daysUntil(s.examDate);
    if (d < 0) return const SizedBox.shrink();
    final cs = Theme.of(context).colorScheme;
    final name = s.examName.isEmpty ? t('exam') : s.examName;
    return Card(
      color: cs.primaryContainer,
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(children: [
          Text(d == 0 ? '🍀' : '$d', style: TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: cs.onPrimaryContainer)),
          const SizedBox(width: 14),
          Expanded(
            child: Text(d == 0 ? t('examToday') : '${d == 1 ? t('day1') : t('days')} · ${t('examIn')}: $name (${fmtDate(s.lang, s.examDate)})',
                style: TextStyle(color: cs.onPrimaryContainer, fontWeight: FontWeight.w600)),
          ),
        ]),
      ),
    );
  }
}

/// List of deleted tasks with a restore button.
class TrashScreen extends StatelessWidget {
  final AppState s;
  const TrashScreen({super.key, required this.s});
  @override
  Widget build(BuildContext context) {
    final t = (String k) => tr(s.lang, k);
    return ListenableBuilder(
      listenable: s,
      builder: (context, _) {
        final del = s.hw.where((h) => h.deleted).toList()..sort((a, b) => (b.deletedAt ?? DateTime(0)).compareTo(a.deletedAt ?? DateTime(0)));
        return Scaffold(
          appBar: AppBar(title: Text(t('trash'))),
          body: del.isEmpty
              ? Center(child: Text(t('trashEmpty')))
              : ListView(
                  children: del
                      .map((h) => ListTile(
                            title: Text(h.text),
                            subtitle: Text(fmtDate(s.lang, h.due)),
                            trailing: TextButton(onPressed: () => s.setDeleted(h.id, false), child: Text(t('restoreBtn'))),
                          ))
                      .toList()),
        );
      },
    );
  }
}
