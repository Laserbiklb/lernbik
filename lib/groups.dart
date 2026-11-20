import 'package:material_ui/material_ui.dart';

import 'i18n.dart';
import 'store.dart';
import 'theme.dart';
import 'ui.dart' show toast;

/// List of existing groups to join, plus "new group". Used on the first start and in Ich.
class GroupPicker extends StatefulWidget {
  final AppState s;

  /// Called after joining or creating (e.g. to close the sheet in Ich).
  final VoidCallback? onDone;
  const GroupPicker({super.key, required this.s, this.onDone});
  @override
  State<GroupPicker> createState() => _GroupPickerState();
}

class _GroupPickerState extends State<GroupPicker> {
  final nameC = TextEditingController();
  late Future<List<GroupInfo>> groups = widget.s.listGroups();
  bool busy = false;
  String? err;

  AppState get s => widget.s;
  String l(String de, String ru, String en) => l3(s.lang, de, ru, en);

  @override
  void dispose() {
    nameC.dispose();
    super.dispose();
  }

  /// The group being joined (shows a spinner on its row).
  String? joining;

  Future<void> _run(Future<void> Function() f, {String? id}) async {
    setState(() {
      busy = true;
      joining = id;
      err = null;
    });
    try {
      await f().timeout(const Duration(seconds: 20));
      widget.onDone?.call();
    } on StateError {
      // The group is gone: say so and reload the list.
      err = l('Diese Gruppe gibt es nicht mehr.', 'Этой группы больше нет.', 'This group no longer exists.');
      groups = s.listGroups();
    } catch (_) {
      err = l(
        'Keine Verbindung. Prüfe das Internet oder öffne lernbik.web.app in Safari / Chrome statt in WhatsApp.',
        'Нет связи. Проверьте интернет или откройте lernbik.web.app в Safari / Chrome, а не внутри WhatsApp.',
        'No connection. Check the internet or open lernbik.web.app in Safari / Chrome instead of WhatsApp.',
      );
    }
    if (!mounted) return;
    setState(() {
      busy = false;
      joining = null;
    });
    // Errors also pop up at the bottom of the screen, where they can't be missed.
    if (err != null) toast(context, err!);
  }

  String _count(int n) {
    final m10 = n % 10, m100 = n % 100;
    final ru = m10 == 1 && m100 != 11
        ? 'участник'
        : (m10 >= 2 && m10 <= 4 && (m100 < 12 || m100 > 14))
        ? 'участника'
        : 'участников';
    return '$n ${l(n == 1 ? 'Mitglied' : 'Mitglieder', ru, n == 1 ? 'member' : 'members')}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle(l('Gruppe wählen', 'Выберите группу', 'Choose a group')),
        FutureBuilder<List<GroupInfo>>(
          future: groups,
          builder: (context, snap) {
            if (snap.hasError) {
              return Padding(
                padding: const EdgeInsets.all(12),
                child: Text(tr(s.lang, 'offline'), style: L.t(14, c: L.die)),
              );
            }
            if (!snap.hasData) {
              return const Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator()));
            }
            final list = [...snap.data!];
            // A group from an invite link comes first.
            final pi = list.indexWhere((g) => g.id == s.pendingGroup);
            if (pi > 0) list.insert(0, list.removeAt(pi));
            if (list.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text(l('Noch keine Gruppen — erstelle die erste.', 'Групп пока нет — создайте первую.', 'No groups yet — create the first one.'), style: L.t(14, c: L.muted)),
              );
            }
            return Panel(
              child: Rows([
                for (final g in list)
                  InkWell(
                    onTap: busy || g.id == s.gid ? null : () => _run(() => s.joinGroup(g.id), id: g.id),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(g.name, style: L.b(16)),
                                Text(_count(g.members), style: L.t(12, c: L.muted)),
                              ],
                            ),
                          ),
                          if (joining == g.id)
                            const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
                          else if (g.id == s.gid)
                            Pill(l('deine', 'ваша', 'yours'), color: L.das)
                          else if (g.id == s.pendingGroup)
                            Pill(l('Einladung', 'приглашение', 'invite'), color: L.sign),
                          const SizedBox(width: 6),
                          if (g.id != s.gid) const Icon(Icons.chevron_right, color: L.muted),
                        ],
                      ),
                    ),
                  ),
              ]),
            );
          },
        ),
        const SizedBox(height: 20),
        SectionTitle(l('Oder neue Gruppe erstellen', 'Или создайте новую группу', 'Or create a new group')),
        TextField(
          controller: nameC,
          maxLength: 40,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(hintText: l('Name, z. B. VHS Hamburg B1', 'Название, напр. VHS Hamburg B1', 'Name, e.g. VHS Hamburg B1')),
          onSubmitted: (_) => _create(),
        ),
        Text(
          l(
            'Wer die Gruppe erstellt, ist ihr Admin: stellt das aktuelle Kapitel ein und wählt Helfer.',
            'Кто создал группу, тот её админ: ставит текущую главу и назначает помощников.',
            'Whoever creates the group is its admin: sets the current chapter and picks helpers.',
          ),
          style: L.t(12, c: L.muted),
        ),
        const SizedBox(height: 10),
        GhostButton(l('Gruppe erstellen', 'Создать группу', 'Create group'), icon: Icons.add, onTap: busy ? null : _create),
        if (err != null) ...[const SizedBox(height: 10), Text(err!, style: L.t(14, c: L.die))],
      ],
    );
  }

  void _create() {
    final n = nameC.text.trim();
    if (n.length < 2) return;
    _run(() => s.createGroup(n));
  }
}
