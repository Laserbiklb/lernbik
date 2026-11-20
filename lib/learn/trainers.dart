import 'dart:math';

import 'package:material_ui/material_ui.dart';

import '../i18n.dart';
import '../store.dart';
import '../theme.dart';
import 'data.dart';
import 'exercise.dart';
import 'gen_adj.dart';
import 'gen_cases.dart';
import 'gen_verbs.dart';
import 'html.dart';
import 'progress.dart';
import 'tasks.dart';

typedef T3 = (String, String, String);

class Topic {
  final String id; // "cases:akk"
  final T3 name, desc;
  final int n; // tasks per run
  const Topic(this.id, this.name, this.desc, {this.n = 8});
}

/// A trainer tile in "Lernen" (cases, verbs, adjective endings).
class Trainer {
  final String id;
  final String badge;
  final T3 title, intro;
  final Color color;
  final List<Topic> topics;
  const Trainer(this.id, this.badge, this.title, this.intro, this.color, this.topics);
  String name(String lang) => l3(lang, title.$1, title.$2, title.$3);
}

const trainers = [
  Trainer(
    'cases',
    'D/A',
    ('Fälle', 'Падежи', 'Cases'),
    (
      'Kurze Lektionen, jede mit einer Idee. Zuerst wählst du den Fall, dann die Form.',
      'Короткие уроки, в каждом одна идея. Сначала выбираете падеж, потом форму.',
      'Short lessons, one idea each. First pick the case, then the form.',
    ),
    L.die,
    [
      Topic(
        'cases:role',
        ('Rollen: wer · was · wem', 'Роли: кто · что · кому', 'Roles: who · what · to whom'),
        (
          'Welcher Fall? – nach der Rolle des Wortes im Satz.',
          'Какой падеж нужен — по роли слова в предложении.',
          'Which case – by the role of the word in the sentence.',
        ),
      ),
      Topic(
        'cases:akk',
        ('Akkusativ: der → den', 'Akkusativ: der → den', 'Accusative: der → den'),
        ('Im Akkusativ ändert sich nur das Maskulinum.', 'В Akkusativ меняется только мужской род.', 'In the accusative only the masculine changes.'),
      ),
      Topic(
        'cases:dat',
        ('Dativ: dem · der · dem', 'Dativ: dem · der · dem', 'Dative: dem · der · dem'),
        ('Im Dativ ändern sich alle Artikel.', 'В Dativ меняются все артикли.', 'In the dative every article changes.'),
      ),
      Topic(
        'cases:pron',
        ('Pronomen: mich · mir', 'Местоимения: mich · mir', 'Pronouns: mich · mir'),
        ('Das Verb entscheidet: wen? → mich, wem? → mir.', 'Глагол решает: кого? → mich, кому? → mir.', 'The verb decides: whom? → mich, to whom? → mir.'),
      ),
      Topic(
        'cases:pakk',
        ('für · ohne · durch → Akk', 'für · ohne · durch → Akk', 'für · ohne · durch → Acc'),
        ('Diese Präpositionen wollen immer Akkusativ.', 'Эти предлоги всегда тянут Akkusativ.', 'These prepositions always take the accusative.'),
      ),
      Topic(
        'cases:pdat',
        ('mit · zu · bei · von → Dat', 'mit · zu · bei · von → Dat', 'mit · zu · bei · von → Dat'),
        ('Diese Präpositionen wollen immer Dativ.', 'Эти предлоги всегда тянут Dativ.', 'These prepositions always take the dative.'),
      ),
      Topic(
        'cases:wowo',
        ('Wo oder wohin: im / in den', 'Где или куда: im / in den', 'Where or where to: im / in den'),
        (
          'Wo? (Ort) → Dativ. Wohin? (Bewegung) → Akkusativ.',
          'Wo? (место) → Dativ. Wohin? (движение) → Akkusativ.',
          'Wo? (place) → dative. Wohin? (movement) → accusative.',
        ),
      ),
      Topic(
        'cases:zus',
        ('Verschmelzung: im · ins · zum · zur', 'Слияния: im · ins · zum · zur', 'Contractions: im · ins · zum · zur'),
        ('in + dem = im, zu + der = zur und andere.', 'in + dem = im, zu + der = zur и другие.', 'in + dem = im, zu + der = zur and more.'),
      ),
      Topic(
        'cases:chunk',
        ('Fertige Stücke', 'Готовые кусочки', 'Ready-made chunks'),
        (
          'Häufige Verbindungen als Ganzes: im Park, zum Arzt, mit dem Bus.',
          'Частые сочетания целиком: im Park, zum Arzt, mit dem Bus.',
          'Common phrases as a whole: im Park, zum Arzt, mit dem Bus.',
        ),
        n: 10,
      ),
      Topic(
        'cases:mix',
        ('Alles gemischt', 'Микс всего', 'Everything mixed'),
        ('Alles zusammen: zuerst der Fall, dann die Form.', 'Всё вместе: сначала падеж, потом форма.', 'All together: first the case, then the form.'),
      ),
    ],
  ),
  Trainer(
    'verbs',
    '-te',
    ('Verben', 'Глаголы', 'Verbs'),
    ('Ein Thema auf einmal. Am besten der Reihe nach.', 'Одна тема за раз. Удобнее идти по порядку.', 'One topic at a time. Best in order.'),
    L.das,
    [
      Topic(
        'verbs:refl',
        ('mich / dich / sich', 'mich / dich / sich', 'mich / dich / sich'),
        (
          'Wann man sich braucht und welche Form: ich → mich, wir → uns.',
          'Когда нужен sich и какая форма: ich → mich, wir → uns.',
          'When you need sich and which form: ich → mich, wir → uns.',
        ),
      ),
      Topic(
        'verbs:prep',
        ('Verb + Präposition', 'Глагол + предлог', 'Verb + preposition'),
        (
          'Welche Präposition hat das Verb: warten auf, träumen von.',
          'Какой предлог у глагола: warten auf, träumen von.',
          'Which preposition goes with the verb: warten auf, träumen von.',
        ),
      ),
      Topic(
        'verbs:art',
        ('den · dem · einen · einem', 'den · dem · einen · einem', 'den · dem · einen · einem'),
        (
          'Artikel nach der Präposition: auf den Bus, mit dem Bus.',
          'Артикль после предлога: auf den Bus, mit dem Bus.',
          'Article after the preposition: auf den Bus, mit dem Bus.',
        ),
      ),
      Topic(
        'verbs:fu',
        ('freuen auf / über', 'freuen auf / über', 'freuen auf / über'),
        (
          'auf – was kommt; über – was schon da ist.',
          'freuen auf — то, что впереди; über — то, что уже есть.',
          'auf – what is ahead; über – what is already here.',
        ),
      ),
      Topic(
        'verbs:q',
        ('Fragen: worauf, auf wen', 'Вопросы: worauf, auf wen', 'Questions: worauf, auf wen'),
        (
          'Worauf wartest du? Auf wen wartest du?',
          'Как спросить: Worauf wartest du? Auf wen wartest du?',
          'How to ask: Worauf wartest du? Auf wen wartest du?',
        ),
      ),
      Topic(
        'verbs:da',
        ('darauf · mit ihr', 'darauf · mit ihr', 'darauf · mit ihr'),
        ('Kurz antworten: Ja, ich denke daran / an ihn.', 'Короткий ответ: Ja, ich denke daran / an ihn.', 'Short answer: Ja, ich denke daran / an ihn.'),
      ),
      Topic(
        'verbs:ord',
        ('Wortstellung', 'Порядок слов', 'Word order'),
        ('Verb auf Platz 2, nach weil am Ende.', 'Глагол на 2-м месте, после weil — в конце.', 'Verb in 2nd place, after weil at the end.'),
      ),
      Topic(
        'verbs:zweck',
        ('damit · um … zu', 'damit · um … zu', 'damit · um … zu'),
        (
          'um … zu – dieselbe Person; damit – geht immer.',
          'um … zu — если делает тот же человек, damit — всегда можно.',
          'um … zu – same person; damit – always works.',
        ),
      ),
      Topic(
        'verbs:sep',
        ('Trennbare Verben · Perfekt', 'Отделяемые · Perfekt', 'Separable verbs · Perfekt'),
        (
          'Ich nehme am Kurs teil · ich habe teilgenommen.',
          'Ich nehme am Kurs teil · ich habe teilgenommen.',
          'Ich nehme am Kurs teil · ich habe teilgenommen.',
        ),
      ),
      Topic(
        'verbs:gift',
        ('Geschenke: wem? was?', 'Подарки: кому? что?', 'Gifts: to whom? what?'),
        (
          'Wem? → Dativ, was? → Akkusativ: meinem Sohn einen Ball.',
          'Кому? → Dativ, что? → Akkusativ: meinem Sohn einen Ball.',
          'To whom? → dative, what? → accusative: meinem Sohn einen Ball.',
        ),
      ),
      Topic(
        'verbs:time',
        ('am · im · zum · um · ab', 'am · im · zum · um · ab', 'am · im · zum · um · ab'),
        (
          'am Samstag, im Juni, zum Arzt, um acht / ab acht.',
          'am Samstag, im Juni, zum Arzt, um acht / ab acht.',
          'am Samstag, im Juni, zum Arzt, um acht / ab acht.',
        ),
      ),
      Topic(
        'verbs:pol',
        ('Einladungen und Bitten', 'Приглашения и просьбы', 'Invitations and requests'),
        (
          'Kommt!, Könnte ich …?, Hier spricht …, Auf Wiederhören.',
          'Kommt!, Könnte ich …?, Hier spricht …, Auf Wiederhören.',
          'Kommt!, Könnte ich …?, Hier spricht …, Auf Wiederhören.',
        ),
      ),
    ],
  ),
  Trainer(
    'adj',
    '-en',
    ('Adjektive', 'Прилагательные', 'Adjectives'),
    (
      'Ein Adjektiv vor dem Nomen bekommt eine Endung. Sie hängt von Artikel, Genus und Fall ab.',
      'Прилагательное перед существительным получает окончание. Оно зависит от артикля, рода и падежа.',
      'An adjective before a noun gets an ending. It depends on the article, gender and case.',
    ),
    L.sign,
    [
      Topic(
        'adj:d',
        ('Nach der / die / das', 'После der / die / das', 'After der / die / das'),
        ('der neue Mantel · mit dem neuen Mantel', 'der neue Mantel · mit dem neuen Mantel', 'der neue Mantel · mit dem neuen Mantel'),
        n: 10,
      ),
      Topic(
        'adj:i',
        ('Nach ein / kein / mein', 'После ein / kein / mein', 'After ein / kein / mein'),
        ('ein neuer Mantel · mit meinem neuen Mantel', 'ein neuer Mantel · mit meinem neuen Mantel', 'ein neuer Mantel · mit meinem neuen Mantel'),
        n: 10,
      ),
      Topic('adj:x', ('Alles zusammen', 'Всё вместе', 'All together'), ('der und ein gemischt', 'der и ein вперемешку', 'der and ein mixed'), n: 10),
      Topic(
        'adj:z',
        ('Ohne Artikel', 'Без артикля', 'No article'),
        ('frischer Kaffee · mit frischer Milch', 'frischer Kaffee · mit frischer Milch', 'frischer Kaffee · mit frischer Milch'),
        n: 10,
      ),
    ],
  ),
];

Trainer? trainerFor(String id) {
  for (final t in trainers) {
    if (t.id == id) return t;
  }
  return null;
}

/// Explanation sheet for a topic (Wortkreis texts in the app language).
String topicSheet(String topic) {
  final d = LearnData.i.tr;
  final p = topic.split(':');
  if (p[0] == 'cases') return ((d['CEXP'] as Map)[p[1]] ?? '') as String;
  if (p[0] == 'verbs') return ((d['SHEET'] as Map)[p[1]] ?? '') as String;
  final t = d['AJT'] as Map;
  return switch (p[1]) {
    'd' =>
      '${t['d']}<p>${tl('<b>-e</b> nur an 5 Stellen: Nominativ Singular und Akkusativ f, n. Überall sonst — <b>-en</b>.', '<b>-e</b> только в 5 местах: Nominativ ед. ч. и Akkusativ f, n. Везде остальное — <b>-en</b>.', '<b>-e</b> in only 5 places: Nominativ singular and Akkusativ f, n. Everywhere else — <b>-en</b>.')}</p>',
    'i' =>
      '${t['i']}<p>${tl('Wo der Artikel keine Endung hat (<i>ein</i> Mantel, <i>ein</i> Hemd), nimmt das Adjektiv die Endung von der/das: ein neu<b>er</b> Mantel, ein neu<b>es</b> Hemd. Im Dativ und Plural — immer <b>-en</b>.', 'Где у артикля нет окончания (<i>ein</i> Mantel, <i>ein</i> Hemd), прилагательное берёт окончание от der/das: ein neu<b>er</b> Mantel, ein neu<b>es</b> Hemd. В Dativ и мн. ч. — всегда <b>-en</b>.', 'Where the article has no ending (<i>ein</i> Mantel, <i>ein</i> Hemd), the adjective takes the ending of der/das: ein neu<b>er</b> Mantel, ein neu<b>es</b> Hemd. In the Dativ and plural — always <b>-en</b>.')}</p>',
    'z' =>
      '${t['z']}<p>${tl('Es gibt keinen Artikel, also nimmt das Adjektiv seine Endung: d<b>er</b> → frisch<b>er</b> Kaffee, d<b>em</b> → mit frisch<b>em</b> Brot.', 'Артикля нет, поэтому прилагательное берёт его окончание: d<b>er</b> → frisch<b>er</b> Kaffee, d<b>em</b> → mit frisch<b>em</b> Brot.', 'There is no article, so the adjective takes its ending: d<b>er</b> → frisch<b>er</b> Kaffee, d<b>em</b> → mit frisch<b>em</b> Brot.')}</p>',
    _ => '${t['d']}${t['i']}',
  };
}

/// Hook the trainer generators into the task registry (also used by linked rules).
void registerTrainers(Progress p) {
  for (final id in caseLessons) {
    topicGens['cases:$id'] = [(r, lang) => caseLessonTask(id, r, p, <String>{})];
  }
  for (final e in verbGens.entries) {
    topicGens['verbs:${e.key}'] = [(r, lang) => e.value(r)];
  }
  for (final k in ['d', 'i', 'x', 'z']) {
    topicGens['adj:$k'] = [(r, lang) => adjTask(r, k)];
  }
}

void startTopic(BuildContext context, AppState s, Topic t) {
  final name = l3(s.lang, t.name.$1, t.name.$2, t.name.$3);
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => ExerciseScreen(
        title: name,
        lang: s.lang,
        p: s.learn,
        make: () {
          // Cases lessons avoid repeating a noun inside one run.
          if (t.id.startsWith('cases:')) {
            final used = <String>{};
            final r = Random();
            final id = t.id.split(':')[1];
            return [for (var i = 0; i < t.n; i++) caseLessonTask(id, r, s.learn, used)];
          }
          return tasksForTopic(t.id, s.lang, n: t.n);
        },
        onDone: (clean, right, first, total) => s.learn.trainerRun(t.id, first, total, right),
      ),
    ),
  );
}

class TrainerScreen extends StatelessWidget {
  final AppState s;
  final Trainer t;
  final String? topic; // open this topic directly
  const TrainerScreen({super.key, required this.s, required this.t, this.topic});

  @override
  Widget build(BuildContext context) {
    if (topic != null) {
      final tp = t.topics.where((x) => x.id == '${t.id}:$topic').firstOrNull;
      if (tp != null) return TopicScreen(s: s, t: tp, color: t.color);
    }
    final l = (String de, String ru, String en) => l3(s.lang, de, ru, en);
    return ListenableBuilder(
      listenable: s.learn,
      builder: (context, _) {
        final p = s.learn;
        String? next;
        for (final x in t.topics) {
          final st = p.tstat[x.id] ?? [0, 0];
          if (st[0] < 16 || st[1] / max(1, st[0]) < .8) {
            next = x.id;
            break;
          }
        }
        return SubPage(
          title: t.name(s.lang),
          children: [
            Text(l(t.intro.$1, t.intro.$2, t.intro.$3), style: L.t(14, c: L.ink2)),
            Panel(
              child: Rows([
                for (final (i, x) in t.topics.indexed)
                  InkWell(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TopicScreen(s: s, t: x, color: t.color),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                      child: Row(
                        children: [
                          Container(
                            width: 26,
                            height: 26,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: x.id == next ? t.color : t.color.withValues(alpha: .12),
                              borderRadius: BorderRadius.circular(7),
                              border: Border.all(color: t.color.withValues(alpha: .7)),
                            ),
                            child: Text('${i + 1}', style: L.h(14, x.id == next ? L.bg : t.color)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(l3(s.lang, x.name.$1, x.name.$2, x.name.$3), style: L.b(14)),
                                Text(
                                  (x.id == next ? '${l('Als Nächstes empfohlen', 'Рекомендую дальше', 'Recommended next')} · ' : '') +
                                      _stat(s.lang, p.tstat[x.id]),
                                  style: L.t(12, c: x.id == next ? t.color : L.muted),
                                ),
                              ],
                            ),
                          ),
                          Bar(_score(p.tstat[x.id]), color: t.color),
                        ],
                      ),
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

String _stat(String lang, List<int>? st) {
  if (st == null || st[0] == 0) return l3(lang, 'noch nicht angefangen', 'ещё не начинали', 'not started yet');
  return '${(st[1] * 100 / st[0]).round()} % ${l3(lang, 'richtig von', 'верно из', 'right of')} ${st[0]}';
}

double _score(List<int>? st) => st == null || st[0] == 0 ? 0 : min(1, st[0] / 16) * st[1] / st[0];

class TopicScreen extends StatelessWidget {
  final AppState s;
  final Topic t;
  final Color color;
  const TopicScreen({super.key, required this.s, required this.t, required this.color});
  @override
  Widget build(BuildContext context) {
    final l = (String de, String ru, String en) => l3(s.lang, de, ru, en);
    final sheet = topicSheet(t.id);
    return ListenableBuilder(
      listenable: s.learn,
      builder: (context, _) => SubPage(
        title: l(t.name.$1, t.name.$2, t.name.$3),
        children: [
          Text(l(t.desc.$1, t.desc.$2, t.desc.$3), style: L.t(14, c: L.ink2)),
          Text(_stat(s.lang, s.learn.tstat[t.id]), style: L.b(13, color)),
          GlowButton(
            '${l('Los', 'Начать', 'Start')}: ${t.n} ${l('Aufgaben', 'заданий', 'tasks')}',
            color: color,
            textColor: color == L.sign || color == L.das ? L.bg : Colors.white,
            onTap: () => startTopic(context, s, t),
          ),
          if (sheet.isNotEmpty) ...[
            SectionTitle(l('Spickzettel', 'Шпаргалка', 'Cheat sheet')),
            Panel(padding: const EdgeInsets.fromLTRB(14, 14, 14, 6), child: RuleHtml(sheet)),
          ],
        ],
      ),
    );
  }
}
