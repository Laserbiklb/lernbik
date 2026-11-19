import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import 'firebase_options.dart';
import 'i18n.dart';
import 'store.dart';
import 'ui.dart';

String groupLink(AppState s) => '$siteUrl/?g=${s.gid}';

Future<void> shareApp(BuildContext context, AppState s) async {
  final text = '${tr(s.lang, 'shareText')} ${groupLink(s)}';
  await Clipboard.setData(ClipboardData(text: groupLink(s)));
  openUrl('https://wa.me/?text=${Uri.encodeComponent(text)}');
}

class GroupScreen extends StatelessWidget {
  final AppState s;
  const GroupScreen({super.key, required this.s});
  String t(String k) => tr(s.lang, k);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return ListView(padding: const EdgeInsets.all(12), children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(4, 4, 4, 10),
        child: Text(s.groupName.isEmpty ? t('group') : s.groupName, style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
      ),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            SelectableText(groupLink(s), style: TextStyle(color: cs.primary)),
            const SizedBox(height: 10),
            Wrap(spacing: 8, runSpacing: 8, children: [
              FilledButton.icon(onPressed: () => shareApp(context, s), icon: const Icon(Icons.share), label: Text(t('share'))),
              OutlinedButton.icon(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: groupLink(s)));
                  if (context.mounted) toast(context, t('copied'));
                },
                icon: const Icon(Icons.copy),
                label: Text(t('copy')),
              ),
            ]),
          ]),
        ),
      ),
      const SizedBox(height: 8),
      Row(children: [
        Expanded(
          child: OutlinedButton.icon(onPressed: () => _addNews(context), icon: const Icon(Icons.campaign_outlined), label: Text(t('newsAdd'))),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(onPressed: () => _setExam(context), icon: const Icon(Icons.event), label: Text(t('examSet'))),
        ),
      ]),
      const SizedBox(height: 18),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Text('${t('members').toUpperCase()} · ${s.members.length}',
            style: TextStyle(fontSize: 12, letterSpacing: 1, fontWeight: FontWeight.w700, color: cs.onSurfaceVariant)),
      ),
      const SizedBox(height: 6),
      Card(
        child: Column(children: [
          ListTile(
            dense: true,
            title: const SizedBox.shrink(),
            trailing: SizedBox(
              width: 140,
              child: Row(children: [
                Expanded(child: Text(t('words'), textAlign: TextAlign.end, style: tt.labelSmall)),
                Expanded(child: Text(t('topics'), textAlign: TextAlign.end, style: tt.labelSmall)),
              ]),
            ),
          ),
          ...s.members.map((m) {
            final me = m.id == s.mid;
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: me ? cs.primary : cs.surfaceContainerHighest,
                foregroundColor: me ? cs.onPrimary : cs.onSurface,
                child: Text(m.nick.isEmpty ? '?' : m.nick.characters.first.toUpperCase()),
              ),
              title: Text(me ? '${m.nick} (${t('you')})' : m.nick, style: TextStyle(fontWeight: me ? FontWeight.w700 : null)),
              subtitle: m.streak > 0 ? Text('🔥 ${m.streak}') : null,
              trailing: SizedBox(
                width: 140,
                child: Row(children: [
                  Expanded(child: Text('${m.words}', textAlign: TextAlign.end, style: tt.titleMedium)),
                  Expanded(child: Text('${m.topics}', textAlign: TextAlign.end, style: tt.titleMedium)),
                ]),
              ),
            );
          }),
        ]),
      ),
      Padding(padding: const EdgeInsets.all(8), child: Text(t('statsInfo'), style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13))),
    ]);
  }

  Future<void> _addNews(BuildContext context) async {
    final c = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t('newsAdd')),
        content: TextField(controller: c, autofocus: true, maxLines: 3, minLines: 1, decoration: InputDecoration(hintText: t('newsHint'))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(t('cancel'))),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(t('save'))),
        ],
      ),
    );
    if (ok == true && c.text.trim().isNotEmpty) {
      await s.addNews(c.text);
      if (context.mounted) toast(context, t('saved'));
    }
  }

  Future<void> _setExam(BuildContext context) async {
    final name = TextEditingController(text: s.examName);
    var date = s.examDate;
    final r = await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => AlertDialog(
          title: Text(t('examSet')),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: name, decoration: InputDecoration(hintText: t('examName'))),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.calendar_month),
              label: Text(date.isEmpty ? t('pickDate') : fmtDate(s.lang, date)),
              onPressed: () async {
                final now = DateTime.now();
                final d = await showDatePicker(context: ctx, firstDate: now, lastDate: now.add(const Duration(days: 730)), initialDate: now);
                if (d != null) set(() => date = ymd(d));
              },
            ),
          ]),
          actions: [
            if (s.examDate.isNotEmpty) TextButton(onPressed: () => Navigator.pop(ctx, 'clear'), child: Text(t('examRemove'))),
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(t('cancel'))),
            FilledButton(onPressed: date.isEmpty ? null : () => Navigator.pop(ctx, 'save'), child: Text(t('save'))),
          ],
        ),
      ),
    );
    if (r == null || !context.mounted) return;
    if (!await confirm(context, s.lang, t('examAsk'))) return;
    if (r == 'clear') {
      await s.setExam('', '');
    } else {
      await s.setExam(date, name.text);
    }
    if (context.mounted) toast(context, t('saved'));
  }
}
