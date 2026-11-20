import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:material_ui/material_ui.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'firebase_options.dart';
import 'groups.dart';
import 'heute.dart';
import 'i18n.dart';
import 'learn/data.dart';
import 'store.dart';
import 'theme.dart';
import 'ui.dart';

/// Asks for notification permission and stores the device token.
/// Returns 'ok', 'denied' or 'unsupported'.
Future<String> setupPush(AppState s) async {
  try {
    final m = FirebaseMessaging.instance;
    if (!await m.isSupported()) return 'unsupported';
    final p = await m.requestPermission();
    if (p.authorizationStatus == AuthorizationStatus.denied) return 'denied';
    final tok = await m.getToken(vapidKey: kIsWeb && vapidKey.isNotEmpty ? vapidKey : null);
    if (tok != null) await s.saveToken(tok);
    m.onTokenRefresh.listen(s.saveToken);
    return 'ok';
  } catch (_) {
    return 'unsupported';
  }
}

/// Android only: newer APK build on the site?
Future<bool> updateAvailable() async {
  if (kIsWeb) return false;
  try {
    final info = await PackageInfo.fromPlatform();
    final r = await http.get(Uri.parse('$siteUrl/version.json')).timeout(const Duration(seconds: 8));
    final build = (jsonDecode(r.body)['build'] as num).toInt();
    return build > (int.tryParse(info.buildNumber) ?? 0);
  } catch (_) {
    return false;
  }
}

/// Link that opens Lernbik with the group preselected.
String inviteLink(AppState s) => s.gid.isEmpty ? '$siteUrl/' : '$siteUrl/?g=${s.gid}';

Future<void> shareApp(AppState s) async {
  final text = '${tr(s.lang, 'shareText')} ${inviteLink(s)}';
  await Clipboard.setData(ClipboardData(text: inviteLink(s)));
  openUrl('https://wa.me/?text=${Uri.encodeComponent(text)}');
}

enum RankBy { words, rules, streak }

class IchScreen extends StatefulWidget {
  final AppState s;
  const IchScreen({super.key, required this.s});
  @override
  State<IchScreen> createState() => _IchScreenState();
}

class _IchScreenState extends State<IchScreen> {
  String push = '';
  String version = '';
  RankBy by = RankBy.words;
  bool all = false;
  AppState get s => widget.s;
  String l(String de, String ru, String en) => l3(s.lang, de, ru, en);

  @override
  void initState() {
    super.initState();
    setupPush(s).then((v) {
      if (mounted) setState(() => push = v);
    });
    PackageInfo.fromPlatform().then((i) {
      if (mounted) setState(() => version = '${i.version} (${i.buildNumber})');
    });
  }

  int _val(Member m) => switch (by) {
    RankBy.words => m.words,
    RankBy.rules => m.topics,
    RankBy.streak => m.liveStreak,
  };

  @override
  Widget build(BuildContext context) {
    final p = s.learn;
    final ms = s.members.where((m) => m.nick.isNotEmpty).toList()..sort((a, b) => _val(b).compareTo(_val(a)));
    final myIdx = ms.indexWhere((m) => m.id == s.mid);
    final shown = all ? ms : ms.take(5).toList();

    return LPage(
      children: [
        const Header('Ich'),
        Panel(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: L.die, shape: BoxShape.circle, boxShadow: L.glow(L.die, 14, .6)),
                child: Text(s.nick.isEmpty ? '?' : s.nick.characters.first.toUpperCase(), style: L.h(26, Colors.white)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(s.nick, style: L.h(24)),
                        if (s.isAdmin) Pill(s.isOwner ? 'Admin' : l('Helfer', 'Помощник', 'Helper'), color: L.sign),
                      ],
                    ),
                    InkWell(
                      onTap: _editNick,
                      child: Text('${s.groupName.isEmpty ? courseName : s.groupName} · ${l('Name ändern', 'Сменить имя', 'Change name')}', style: L.t(12, c: L.muted)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Row(
          children: [
            _Stat('${p.knownWords}', l('Wörter', 'Слова', 'Words'), L.der),
            const SizedBox(width: 8),
            _Stat('${p.xp}', 'XP', L.sign),
            const SizedBox(width: 8),
            _Stat('${p.liveStreak}', l('Tage in Folge', 'дней подряд', 'day streak'), L.die),
          ],
        ),
        SectionTitle(
          l('Rangliste', 'Рейтинг', 'Ranking'),
          trailing: Seg<RankBy>(
            color: L.das,
            items: [
              (RankBy.words, l('Wörter', 'Слова', 'Words')),
              (RankBy.rules, l('Regeln', 'Правила', 'Rules')),
              (RankBy.streak, l('Serie', 'Серия', 'Streak')),
            ],
            value: by,
            onChanged: (v) => setState(() => by = v),
          ),
        ),
        Panel(
          child: Rows([
            for (var i = 0; i < shown.length; i++) _RankRow(i + 1, shown[i], _val(shown[i]), shown[i].id == s.mid, s.lang),
            if (!all && myIdx >= 5) _RankRow(myIdx + 1, ms[myIdx], _val(ms[myIdx]), true, s.lang),
            if (ms.length > 5)
              InkWell(
                onTap: () => setState(() => all = !all),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    all ? l('Weniger ▴', 'Свернуть ▴', 'Less ▴') : '${l('Alle', 'Все', 'All')} ${ms.length} ${l('anzeigen', 'показать', 'show')} ▾',
                    style: L.b(13, L.der),
                  ),
                ),
              ),
            if (ms.isEmpty)
              Padding(
                padding: const EdgeInsets.all(14),
                child: Text('…', style: L.t(14, c: L.muted)),
              ),
          ]),
        ),
        Text(
          l(
            'Wörter = sicher gelernt (Stufe 2+). Regeln = 5 Runden ohne Fehler.',
            'Слова = выучены уверенно (уровень 2+). Правила = 5 заходов без ошибок.',
            'Words = learned well (level 2+). Rules = 5 runs without mistakes.',
          ),
          style: L.t(11, c: L.muted),
        ),
        Row(
          children: [
            Expanded(
              child: GlowButton(
                l('Gruppe einladen', 'Пригласить в группу', 'Invite to group'),
                color: L.das,
                textColor: L.bg,
                size: 16,
                onTap: () => shareApp(s),
              ),
            ),
            const SizedBox(width: 8),
            GhostButton(
              l('Link kopieren', 'Копировать ссылку', 'Copy link'),
              color: L.muted,
              onTap: () async {
                await Clipboard.setData(ClipboardData(text: inviteLink(s)));
                if (context.mounted) toast(context, l('Kopiert', 'Скопировано', 'Copied'));
              },
            ),
          ],
        ),
        SectionTitle(l('Sprache', 'Язык', 'Language')),
        Align(
          alignment: Alignment.centerLeft,
          child: Seg<String>(items: [for (final e in langs.entries) (e.key, e.value)], value: s.lang, onChanged: s.setLang),
        ),
        SectionTitle(l('Erinnerungen', 'Напоминания', 'Reminders')),
        Panel(
          padding: const EdgeInsets.fromLTRB(14, 4, 8, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l('Jeden Tag erinnern', 'Напоминать каждый день', 'Remind me every day'), style: L.t(14)),
                        Text(tr(s.lang, 'remindInfo'), style: L.t(12, c: L.muted)),
                      ],
                    ),
                  ),
                  Switch(value: s.remindOn, onChanged: (v) => s.setRemind(v, List.of(s.remind))),
                ],
              ),
              if (s.remindOn)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final r in s.remind) Pill(s.remind.length > 1 ? '$r  ✕' : r, color: L.der, onTap: () => _timeMenu(r)),
                    if (s.remind.length < 4) Pill('+ ${l('Zeit', 'Время', 'Time')}', onTap: () => _pickTime(null)),
                  ],
                ),
              if (push == 'denied')
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(tr(s.lang, 'pushOff'), style: L.t(12, c: L.die)),
                ),
              if (push == 'unsupported' && kIsWeb)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(tr(s.lang, 'pushIos'), style: L.t(12, c: L.muted)),
                ),
            ],
          ),
        ),
        SectionTitle(l('Lernen', 'Учёба', 'Learning')),
        Panel(
          child: Rows([
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  Expanded(child: Text(l('Wörter pro Runde', 'Слов в круге', 'Words per round'), style: L.t(14))),
                  Seg<int>(
                    items: const [(6, '6'), (12, '12'), (20, '20')],
                    value: p.rsize,
                    onChanged: (v) {
                      p.rsize = v;
                      p.save();
                    },
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 4, 8, 4),
              child: Row(
                children: [
                  Expanded(child: Text(l('Wörter vorlesen', 'Озвучивать слова', 'Read words aloud'), style: L.t(14))),
                  Switch(
                    value: p.voice,
                    onChanged: (v) {
                      p.voice = v;
                      p.save();
                    },
                  ),
                ],
              ),
            ),
          ]),
        ),
        if (s.isAdmin) ...[
          SectionTitle(l('Admin · Kurs', 'Админ · Курс', 'Admin · Class'), color: L.sign),
          Panel(
            accent: L.sign,
            child: Rows([
              InkWell(
                onTap: _pickCourse,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l('Aktuelles Kapitel im Kurs', 'Текущая глава на курсе', 'Current chapter in class'), style: L.t(12, c: L.muted)),
                            Text(
                              '${s.courseLv} · ${s.courseN} ${LearnData.loaded ? LearnData.i.chapter(s.courseLv, s.courseN)?.title ?? '' : ''}',
                              style: L.b(14),
                            ),
                          ],
                        ),
                      ),
                      Text('${l('ändern', 'изменить', 'change')} ›', style: L.b(13, L.sign)),
                    ],
                  ),
                ),
              ),
              if (s.isOwner)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l('Helfer (dürfen das Kapitel ändern)', 'Помощники (могут менять главу)', 'Helpers (may change the chapter)'),
                        style: L.t(12, c: L.muted),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final h in s.helpers)
                            Pill('${h['nick']}  ✕', color: L.ink2, onTap: () => s.setHelpers(s.helpers.where((x) => x['mid'] != h['mid']).toList())),
                          Pill('+ ${l('hinzufügen', 'добавить', 'add')}', color: L.sign, onTap: _addHelper),
                        ],
                      ),
                    ],
                  ),
                ),
              if (s.isOwner)
                InkWell(
                  onTap: _manageMembers,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Row(
                      children: [
                        Expanded(child: Text(l('Mitglieder verwalten', 'Управлять участниками', 'Manage members'), style: L.b(14))),
                        Text('${s.members.length} ›', style: L.b(13, L.sign)),
                      ],
                    ),
                  ),
                ),
            ]),
          ),
        ],
        Panel(
          child: Rows([
            _Item(Icons.groups_outlined, l('Gruppe wechseln', 'Сменить группу', 'Change group'), _changeGroup),
            _Item(Icons.flag_outlined, tr(s.lang, 'report'), () => reportDialog(context, s, 'app')),
            _Item(
              Icons.restore_from_trash_outlined,
              l('Papierkorb', 'Корзина', 'Trash'),
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => TrashScreen(s: s))),
            ),
            _Item(Icons.logout, l('Abmelden', 'Выйти', 'Log out'), () async {
              if (await confirm(context, s.lang, tr(s.lang, 'logoutAsk'), danger: true)) s.logout();
            }, color: L.die),
          ]),
        ),
        Center(
          child: Text('Lernbik · ${tr(s.lang, 'version')} $version', style: L.t(12, c: L.muted)),
        ),
        const SizedBox(height: 70),
      ],
    );
  }

  Future<void> _changeGroup() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + MediaQuery.of(ctx).viewInsets.bottom),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l(
                  'Dein Lernfortschritt bleibt. Aufgaben, Hinweise und Rangliste kommen aus der neuen Gruppe.',
                  'Прогресс в учёбе сохранится. Задания, объявления и рейтинг будут из новой группы.',
                  'Your learning progress stays. Tasks, notices and ranking come from the new group.',
                ),
                style: L.t(13, c: L.muted),
              ),
              const SizedBox(height: 12),
              GroupPicker(s: s, onDone: () => Navigator.of(ctx).pop()),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _editNick() async {
    final c = TextEditingController(text: s.nick);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr(s.lang, 'nick')),
        content: TextField(controller: c, autofocus: true, maxLength: 24),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(tr(s.lang, 'cancel'))),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(tr(s.lang, 'save'))),
        ],
      ),
    );
    if (ok == true && c.text.trim().isNotEmpty) {
      final r = await s.setNick(c.text);
      if (!r && mounted) toast(context, tr(s.lang, 'nickTaken'));
    }
  }

  Future<void> _timeMenu(String r) async {
    if (s.remind.length <= 1) return _pickTime(r);
    final v = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.schedule),
            title: Text(l('Zeit ändern', 'Изменить время', 'Change time')),
            onTap: () => Navigator.pop(ctx, 'edit'),
          ),
          ListTile(
            leading: const Icon(Icons.close, color: L.die),
            title: Text(l('Entfernen', 'Убрать', 'Remove')),
            onTap: () => Navigator.pop(ctx, 'del'),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
    if (v == 'edit') _pickTime(r);
    if (v == 'del') s.setRemind(true, List.of(s.remind)..remove(r));
  }

  Future<void> _pickTime(String? old) async {
    var init = const TimeOfDay(hour: 18, minute: 0);
    if (old != null) {
      final p = old.split(':');
      init = TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1]));
    }
    final r = await showTimePicker(context: context, initialTime: init);
    if (r == null) return;
    // Reminders go out on the half hour.
    final m = r.minute < 30 ? 0 : 30;
    final v = '${r.hour.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
    final list = List.of(s.remind)..remove(old);
    if (!list.contains(v)) list.add(v);
    s.setRemind(true, list);
  }

  Future<void> _pickCourse() async {
    if (!LearnData.loaded) return;
    final chosen = await showModalBottomSheet<(String, int)>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: .8,
        builder: (ctx, sc) => ListView(
          controller: sc,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          children: [
            Text(l('Welches Kapitel macht der Kurs gerade?', 'Какую главу сейчас проходит курс?', 'Which chapter is the class on?'), style: L.h(22)),
            const SizedBox(height: 4),
            Text(
              l(
                'Alle sehen es auf „Heute“ und in „Lernen“.',
                'Все увидят это на «Heute» и в «Lernen».',
                'Everyone sees it on “Heute” and in “Lernen”.',
              ),
              style: L.t(12, c: L.muted),
            ),
            for (final lv in ['A1', 'A2']) ...[
              const SizedBox(height: 12),
              SectionTitle(lv),
              Panel(
                child: Rows([
                  for (final c in LearnData.i.book[lv]!)
                    ListTile(
                      dense: true,
                      selected: c.lv == s.courseLv && c.n == s.courseN,
                      selectedColor: L.der,
                      leading: Text('${c.n}', style: L.h(16, L.muted)),
                      title: Text(c.title, style: L.t(14)),
                      trailing: c.lv == s.courseLv && c.n == s.courseN ? const Icon(Icons.check, color: L.der) : null,
                      onTap: () => Navigator.pop(ctx, (c.lv, c.n)),
                    ),
                ]),
              ),
            ],
          ],
        ),
      ),
    );
    if (chosen != null) {
      await s.setCourse(chosen.$1, chosen.$2);
      if (mounted) toast(context, l('Gespeichert', 'Сохранено', 'Saved'));
    }
  }

  /// Owner: list of all members with a remove button (for duplicates and people who left).
  Future<void> _manageMembers() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: .75,
        builder: (ctx, sc) => ListenableBuilder(
          listenable: s,
          builder: (ctx, _) {
            final ms = [...s.members]..sort((a, b) => a.nick.toLowerCase().compareTo(b.nick.toLowerCase()));
            return ListView(
              controller: sc,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              children: [
                Text(l('Mitglieder', 'Участники', 'Members'), style: L.h(22)),
                const SizedBox(height: 4),
                Text(
                  l(
                    'Entfernen nimmt jemanden aus der Gruppe und der Rangliste. Öffnet die Person die App wieder mit diesem Konto, ist sie wieder dabei.',
                    'Удаление убирает человека из группы и рейтинга. Если он снова откроет приложение под этим аккаунтом, то вернётся.',
                    'Removing takes someone out of the group and the ranking. If they open the app again with that account, they are back.',
                  ),
                  style: L.t(12, c: L.muted),
                ),
                const SizedBox(height: 8),
                for (final m in ms)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(m.nick.isEmpty ? '—' : m.nick, style: L.b(15)),
                    subtitle: Text(
                      '${m.words} ${l('Wörter', 'слов', 'words')} · ${m.xp} XP${m.day.isEmpty ? '' : ' · ${l('zuletzt', 'был', 'last')} ${fmtDate(s.lang, m.day)}'}',
                      style: L.t(12, c: L.muted),
                    ),
                    trailing: m.id == s.mid
                        ? Pill(l('du', 'ты', 'you'), color: L.das)
                        : IconButton(
                            tooltip: l('Entfernen', 'Удалить', 'Remove'),
                            icon: const Icon(Icons.person_remove_outlined, color: L.die),
                            onPressed: () async {
                              final ok = await confirm(
                                context,
                                s.lang,
                                l('${m.nick} entfernen?', 'Удалить ${m.nick}?', 'Remove ${m.nick}?'),
                                yes: l('Entfernen', 'Удалить', 'Remove'),
                                danger: true,
                              );
                              if (ok) await s.removeMember(m.id);
                            },
                          ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _addHelper() async {
    final cand = s.members.where((m) => m.nick.isNotEmpty && m.id != s.mid && !s.helpers.any((h) => h['mid'] == m.id)).toList()
      ..sort((a, b) => a.nick.toLowerCase().compareTo(b.nick.toLowerCase()));
    final m = await showModalBottomSheet<Member>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: .6,
        builder: (ctx, sc) => ListView(
          controller: sc,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          children: [
            Text(l('Helfer wählen', 'Выбрать помощника', 'Pick a helper'), style: L.h(22)),
            const SizedBox(height: 10),
            for (final c in cand)
              ListTile(
                title: Text(c.nick, style: L.t(15)),
                onTap: () => Navigator.pop(ctx, c),
              ),
            if (cand.isEmpty) Text(l('Keine weiteren Mitglieder.', 'Больше участников нет.', 'No other members.'), style: L.t(14, c: L.muted)),
          ],
        ),
      ),
    );
    if (m != null)
      await s.setHelpers([
        ...s.helpers,
        {'mid': m.id, 'nick': m.nick},
      ]);
  }
}

class _Stat extends StatelessWidget {
  final String v, label;
  final Color c;
  const _Stat(this.v, this.label, this.c);
  @override
  Widget build(BuildContext context) => Expanded(
    child: Panel(
      accent: c,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(v, style: L.h(22, c)),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: L.t(11, c: L.muted),
          ),
        ],
      ),
    ),
  );
}

class _RankRow extends StatelessWidget {
  final int place, value;
  final Member m;
  final bool me;
  final String lang;
  const _RankRow(this.place, this.m, this.value, this.me, this.lang);
  @override
  Widget build(BuildContext context) {
    final pc = place == 1 ? L.sign : (place == 2 ? L.ink2 : (place == 3 ? L.fire : L.muted));
    return Container(
      color: me ? L.me : null,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            child: Text('$place', textAlign: TextAlign.center, style: L.h(16, pc)),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(me ? '${m.nick} (${l3(lang, 'du', 'ты', 'you')})' : m.nick, style: me ? L.b(14) : L.t(14))),
          Text('$value', style: L.b(14, L.das)),
        ],
      ),
    );
  }
}

class _Item extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback onTap;
  final Color color;
  const _Item(this.icon, this.text, this.onTap, {this.color = L.ink});
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color == L.ink ? L.muted : color),
          const SizedBox(width: 12),
          Text(text, style: L.t(14, c: color)),
        ],
      ),
    ),
  );
}

Future<void> reportDialog(BuildContext context, AppState s, String where, {String prefill = ''}) async {
  final t = (String k) => tr(s.lang, k);
  final c = TextEditingController(text: prefill);
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(t('report')),
      content: TextField(
        controller: c,
        autofocus: true,
        minLines: 3,
        maxLines: 6,
        decoration: InputDecoration(hintText: t('reportHint')),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(t('cancel'))),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(t('send'))),
      ],
    ),
  );
  if (ok == true && c.text.trim().isNotEmpty) {
    await s.report(c.text, where);
    if (context.mounted) toast(context, t('reportSent'));
  }
}
