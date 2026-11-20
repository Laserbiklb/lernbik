import 'package:material_ui/material_ui.dart';

import 'i18n.dart';
import 'store.dart';
import 'theme.dart';
import 'ui.dart';

/// Main admin (Laserbik): all groups; open one to move its people or delete it.
class AllGroupsScreen extends StatefulWidget {
  final AppState s;
  const AllGroupsScreen({super.key, required this.s});
  @override
  State<AllGroupsScreen> createState() => _AllGroupsScreenState();
}

class _AllGroupsScreenState extends State<AllGroupsScreen> {
  late Future<List<GroupInfo>> groups = widget.s.listGroups();
  AppState get s => widget.s;
  String l(String de, String ru, String en) => l3(s.lang, de, ru, en);

  void _reload() => setState(() => groups = s.listGroups());

  @override
  Widget build(BuildContext context) => SubPage(
    title: l('Alle Gruppen', 'Все группы', 'All groups'),
    children: [
      Text(
        l(
          'Nur du siehst das. Öffne eine Gruppe, um Leute zu verschieben oder sie zu löschen.',
          'Это видишь только ты. Откройте группу, чтобы переместить людей или удалить её.',
          'Only you see this. Open a group to move people or delete it.',
        ),
        style: L.t(13, c: L.muted),
      ),
      const SizedBox(height: 12),
      FutureBuilder<List<GroupInfo>>(
        future: groups,
        builder: (context, snap) {
          if (!snap.hasData) {
            return snap.hasError
                ? Text(tr(s.lang, 'offline'), style: L.t(14, c: L.die))
                : const Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator()));
          }
          final all = snap.data!;
          return Panel(
            child: Rows([
              for (final g in all)
                InkWell(
                  onTap: () async {
                    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => GroupAdminScreen(s: s, group: g, all: all)));
                    _reload();
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(g.name, style: L.b(16)),
                              Text('${g.members} ${l('Mitglieder', 'участн.', 'members')}', style: L.t(12, c: L.muted)),
                            ],
                          ),
                        ),
                        if (g.id == s.gid) Pill(l('deine', 'ваша', 'yours'), color: L.das),
                        const Icon(Icons.chevron_right, color: L.muted),
                      ],
                    ),
                  ),
                ),
            ]),
          );
        },
      ),
    ],
  );
}

/// One group for the main admin: its members with "move to …", and "delete group".
class GroupAdminScreen extends StatefulWidget {
  final AppState s;
  final GroupInfo group;
  final List<GroupInfo> all;
  const GroupAdminScreen({super.key, required this.s, required this.group, required this.all});
  @override
  State<GroupAdminScreen> createState() => _GroupAdminScreenState();
}

class _GroupAdminScreenState extends State<GroupAdminScreen> {
  late Future<List<Member>> members = widget.s.membersOf(widget.group.id);
  bool busy = false;
  AppState get s => widget.s;
  String l(String de, String ru, String en) => l3(s.lang, de, ru, en);

  Future<void> _do(Future<void> Function() f, String done) async {
    setState(() => busy = true);
    try {
      await f();
      if (mounted) toast(context, done);
    } catch (_) {
      if (mounted) toast(context, tr(s.lang, 'offline'));
    }
    if (mounted) {
      setState(() {
        busy = false;
        members = s.membersOf(widget.group.id);
      });
    }
  }

  Future<void> _move(Member m) async {
    final others = widget.all.where((g) => g.id != widget.group.id).toList();
    if (others.isEmpty) {
      toast(context, l('Es gibt keine andere Gruppe.', 'Других групп нет.', 'There is no other group.'));
      return;
    }
    final to = await showModalBottomSheet<GroupInfo>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          children: [
            Text(l('${m.nick} verschieben nach …', 'Переместить ${m.nick} в …', 'Move ${m.nick} to …'), style: L.h(20)),
            const SizedBox(height: 8),
            for (final g in others)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(g.name, style: L.b(15)),
                trailing: const Icon(Icons.arrow_forward, color: L.der),
                onTap: () => Navigator.of(ctx).pop(g),
              ),
          ],
        ),
      ),
    );
    if (to == null) return;
    await _do(() => s.moveMember(widget.group.id, to.id, m.id), l('${m.nick} → ${to.name}', '${m.nick} → ${to.name}', '${m.nick} → ${to.name}'));
  }

  Future<void> _delete() async {
    final ok = await confirm(
      context,
      s.lang,
      l('„${widget.group.name}“ löschen?', 'Удалить «${widget.group.name}»?', 'Delete "${widget.group.name}"?'),
      body: l(
        'Aufgaben, Hinweise und Rangliste der Gruppe werden gelöscht. Die Mitglieder wählen beim nächsten Öffnen eine neue Gruppe; ihr Lernfortschritt bleibt.',
        'Задания, объявления и рейтинг группы удалятся. Участники при следующем заходе выберут новую группу, их прогресс в учёбе сохранится.',
        'The group\'s tasks, notices and ranking are deleted. Its members choose a new group next time; their learning progress stays.',
      ),
      yes: l('Löschen', 'Удалить', 'Delete'),
      danger: true,
    );
    if (!ok || !mounted) return;
    setState(() => busy = true);
    try {
      await s.deleteGroup(widget.group.id);
      if (mounted) {
        toast(context, l('Gruppe gelöscht', 'Группа удалена', 'Group deleted'));
        Navigator.of(context).pop();
      }
    } catch (_) {
      if (mounted) {
        setState(() => busy = false);
        toast(context, tr(s.lang, 'offline'));
      }
    }
  }

  @override
  Widget build(BuildContext context) => SubPage(
    title: widget.group.name,
    children: [
      if (busy) const LinearProgressIndicator(),
      SectionTitle(l('Mitglieder', 'Участники', 'Members')),
      FutureBuilder<List<Member>>(
        future: members,
        builder: (context, snap) {
          if (!snap.hasData) return const Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator()));
          final ms = snap.data!;
          if (ms.isEmpty) return Text(l('Niemand.', 'Никого нет.', 'Nobody.'), style: L.t(14, c: L.muted));
          return Panel(
            child: Rows([
              for (final m in ms)
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(m.nick.isEmpty ? '—' : m.nick, style: L.b(15)),
                            Text('${m.words} ${l('Wörter', 'слов', 'words')} · ${m.xp} XP', style: L.t(12, c: L.muted)),
                          ],
                        ),
                      ),
                      TextButton.icon(
                        onPressed: busy ? null : () => _move(m),
                        icon: const Icon(Icons.swap_horiz, size: 18),
                        label: Text(l('Verschieben', 'Переместить', 'Move')),
                      ),
                    ],
                  ),
                ),
            ]),
          );
        },
      ),
      const SizedBox(height: 10),
      Text(
        l(
          'Wer eine alte App-Version hat, folgt erst nach dem Update.',
          'У кого старая версия приложения, перейдёт только после обновления.',
          'People with an old app version follow only after updating.',
        ),
        style: L.t(12, c: L.muted),
      ),
      const SizedBox(height: 24),
      GhostButton(l('Gruppe löschen', 'Удалить группу', 'Delete group'), icon: Icons.delete_outline, color: L.die, onTap: busy ? null : _delete),
    ],
  );
}
