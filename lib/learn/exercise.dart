import 'dart:async';
import 'dart:math';

import 'package:material_ui/material_ui.dart';

import '../i18n.dart';
import '../theme.dart';
import 'html.dart';
import 'progress.dart';
import 'round.dart' show fold;
import 'tts.dart';
import 'widgets.dart';

/// "Which case?" step before the form (cases trainer). [c]: nom | akk | dat.
class CaseStep {
  final String c, trig, mode; // mode: case (only the case), both (case, then form), form (no step)
  final String hint, explain; // hint before answering, explanation after
  const CaseStep(this.c, this.trig, this.mode, {this.hint = '', this.explain = ''});
}

/// One exercise.
/// kind: pick (choose; a sentence with ___ or an html prompt), type (write it), order (build the sentence), error (tap the wrong word).
class Task {
  final String kind;
  final String text; // sentence with ___, or the prompt for type
  final String html; // rich prompt (mark, em, br) when there is no gap sentence
  final String cue; // small hint under the prompt
  final List<String> options;
  final String answer;
  final List<String> answers; // type: accepted answers; order: accepted sentences
  final List<String> words; // order: tokens
  final String wrong, right; // error
  final String why; // explanation (may contain html)
  final String full; // the whole sentence (read aloud, shown after the answer)
  final String an; // analysis (html <li> items)
  final String exv; // "exception" note
  final CaseStep? step;
  final String key; // statistics key
  const Task(
    this.kind, {
    this.text = '',
    this.html = '',
    this.cue = '',
    this.options = const [],
    this.answer = '',
    this.answers = const [],
    this.words = const [],
    this.wrong = '',
    this.right = '',
    this.why = '',
    this.full = '',
    this.an = '',
    this.exv = '',
    this.step,
    this.key = '',
  });

  factory Task.gap(String text, String answer, List<String> wrong, String why, {String cue = '', String full = ''}) {
    final o = <String>[answer];
    for (final w in wrong) {
      if (w.isNotEmpty && !o.contains(w)) o.add(w);
    }
    return Task('pick', text: text, options: o, answer: answer, why: why, cue: cue, full: full);
  }

  /// Order task from the correct sentence (tokens = words).
  factory Task.order(String sentence, String why, {String cue = '', List<String> alts = const []}) {
    final s = sentence.replaceAll(RegExp(r'[.!?]$'), '');
    return Task('order', words: s.split(RegExp(r'\s+')), answers: [sentence, ...alts], why: why, cue: cue, full: sentence);
  }

  factory Task.orderWords(List<String> words, String why) => Task('order', words: words, answers: [words.join(' ')], why: why, full: words.join(' '));
  factory Task.error(String text, String wrong, String right, String why) => Task('error', text: text, wrong: wrong, right: right, why: why);
  factory Task.write(String task, List<String> answers, String why) => Task('type', text: task, answers: answers, why: why);

  /// Wortkreis quiz line: "g:text|answer|wrong|wrong|why", "o:words|why", "e:text|wrong|right|why".
  factory Task.qz(String s) {
    final k = s[0];
    final p = s.substring(2).split('|');
    String at(int i) => i < p.length ? p[i] : '';
    if (k == 'g') return Task.gap(at(0), at(1), [at(2), at(3)], at(4));
    if (k == 'o') return Task.orderWords(at(0).split(RegExp(r'\s+')), at(1));
    return Task.error(at(0), at(1), at(2), at(3));
  }

  /// A short key so a run does not show the same task twice.
  String get sig => '$kind|$text|$html|${words.join(' ')}|$answer';

  /// The full sentence to read aloud after the answer.
  String get spoken {
    if (full.isNotEmpty) return full;
    return switch (kind) {
      'pick' => text.contains('___') ? text.replaceFirst('___', answer) : answer,
      'order' => answers.isNotEmpty ? answers.first : words.join(' '),
      'error' => text.replaceFirst(RegExp('(?<![\\wäöüß])${RegExp.escape(wrong)}(?![\\wäöüß])'), right),
      _ => answers.isNotEmpty ? answers.first : answer,
    };
  }
}

String _bare(String s) => s.replaceAll(RegExp(r'^[^A-Za-z0-9äöüÄÖÜß]+|[^A-Za-z0-9äöüÄÖÜß]+$'), '');
String _foldS(String s) => fold(s).replaceAll(RegExp(r'[.!?,;:]+$'), '').replaceAll(RegExp(r'\s*,\s*'), ', ');
String vNorm(String s) => fold(s).replaceAll(RegExp(r'[.,!?…]'), '').replaceAll(RegExp(r'\s+'), ' ').trim();

const caseNames = {'nom': 'Nominativ', 'akk': 'Akkusativ', 'dat': 'Dativ'};
const _baskets = [
  ('nom', ('Wer tut etwas?', 'Кто делает', 'Who does it?'), ('wer? was?', 'кто? что?', 'who? what?')),
  ('akk', ('Worauf zielt die Handlung?', 'Во что попадает действие', 'What the action hits'), ('wen? was?', 'кого? что?', 'whom? what?')),
  ('dat', ('Wem · wo · mit wem', 'Кому · где · с кем', 'To whom · where · with whom'), ('wem? wo? mit wem?', 'кому? где? с кем?', 'to whom? where?')),
];

/// Plays a run of tasks. [onDone] gets (clean, right) when the run is finished.
class ExerciseScreen extends StatefulWidget {
  final String title;
  final List<Task> Function() make;
  final String lang;
  final Progress p;
  final void Function(bool clean, int right, int firstTry, int total)? onDone;
  final Widget Function(BuildContext context, bool clean, int firstTry, int total)? doneExtra;
  const ExerciseScreen({super.key, required this.title, required this.make, required this.lang, required this.p, this.onDone, this.doneExtra});
  @override
  State<ExerciseScreen> createState() => _ExerciseScreenState();
}

class _ExerciseScreenState extends State<ExerciseScreen> {
  final rnd = Random();
  List<Task> queue = [];
  final miss = <Task>[];
  int total = 0, doneN = 0, right = 0;
  Task? cur;
  bool again = false;
  bool locked = false, wait = false, finished = false;
  List<String> opts = [];
  int? picked;
  bool? fbOk;
  String fbCorr = '';
  List<int> oPool = [], oPick = [];
  List<String> toks = [];
  int? tapped;
  // case step
  int stage = 0; // 0 = case question, 1 = form
  String? casePicked;
  bool caseOk = true;
  bool hint = false;
  final typeC = TextEditingController();
  final typeF = FocusNode();
  int runId = 0;
  Timer? timer;

  String l(String de, String ru, String en) => l3(widget.lang, de, ru, en);
  bool get voice => widget.p.voice && Tts.available;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void dispose() {
    timer?.cancel();
    typeC.dispose();
    typeF.dispose();
    super.dispose();
  }

  void _start() {
    runId++;
    queue = widget.make();
    total = queue.length;
    doneN = right = 0;
    miss.clear();
    finished = false;
    _next();
  }

  void _next() {
    timer?.cancel();
    if (queue.isEmpty) {
      cur = null;
      finished = true;
      widget.onDone?.call(miss.isEmpty, right, total - miss.length, total);
      setState(() {});
      return;
    }
    final t = cur = queue.removeAt(0);
    again = miss.contains(t);
    locked = wait = false;
    picked = tapped = casePicked = null;
    fbOk = null;
    caseOk = true;
    hint = false;
    stage = t.step != null && t.step!.mode != 'form' ? 0 : 1;
    if (t.kind == 'pick') opts = shuffled(t.options);
    if (t.kind == 'order') {
      oPool = List.generate(t.words.length, (i) => i);
      var n = 0;
      do {
        oPool.shuffle(rnd);
        n++;
      } while (n < 8 && t.words.length > 1 && oPool.map((i) => t.words[i]).join(' ') == t.words.join(' '));
      oPick = [];
    }
    if (t.kind == 'error') toks = t.text.split(RegExp(r'\s+'));
    if (t.kind == 'type') {
      typeC.clear();
      WidgetsBinding.instance.addPostFrameCallback((_) => typeF.requestFocus());
    }
    setState(() {});
  }

  void _answer(bool ok, String corr) {
    final t = cur!;
    ok = ok && caseOk;
    locked = true;
    fbOk = ok;
    fbCorr = corr;
    if (voice) Tts.say(t.spoken);
    if (ok) {
      right++;
      doneN++;
      final id = runId, at = cur;
      if (t.an.isEmpty) {
        timer = Timer(Duration(milliseconds: t.why.isNotEmpty ? 2000 : 900), () {
          if (mounted && id == runId && cur == at) _next();
        });
      }
      wait = true;
    } else {
      if (!miss.contains(t)) miss.add(t);
      queue.add(t);
      wait = true;
    }
    setState(() {});
  }

  void _pickCase(String c) {
    final t = cur!, st = t.step!;
    casePicked = c;
    final ok = c == st.c;
    if (!ok) caseOk = false;
    if (st.mode == 'case') {
      _answer(ok, caseNames[st.c]!);
      return;
    }
    stage = 1;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    tooltip: l('Beenden', 'Выйти', 'Quit'),
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: L.muted),
                  ),
                  Expanded(
                    child: Text(widget.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: L.b(14, L.ink2)),
                  ),
                  const SizedBox(width: 10),
                  Bar(total == 0 ? 0 : doneN / total, width: 60),
                  const SizedBox(width: 10),
                  Text('$doneN/$total', style: L.b(14, L.muted)),
                ],
              ),
            ),
            Expanded(
              child: ListView(padding: const EdgeInsets.fromLTRB(20, 16, 20, 24), children: finished ? _done() : (cur == null ? [] : _task(cur!))),
            ),
          ],
        ),
      ),
    );
  }

  Widget _head(String de, String ru, String en) => Text(
    (l(de, ru, en) + (again ? ' · ${l('noch einmal', 'ещё раз', 'once more')}' : '')).toUpperCase(),
    style: L.h(14, L.muted).copyWith(letterSpacing: 1.6),
  );

  List<Widget> _task(Task t) {
    final out = <Widget>[];
    switch (t.kind) {
      case 'pick':
        out.add(
          t.step != null && stage == 0
              ? _head('Welcher Fall?', 'Какой падеж?', 'Which case?')
              : t.text.contains('___')
              ? _head('Wähle das Wort für die Lücke', 'Выберите слово в пропуск', 'Pick the word for the gap')
              : _head('Wähle die richtige Antwort', 'Выберите правильный ответ', 'Pick the right answer'),
        );
        out.add(const SizedBox(height: 14));
        out.add(_prompt(t));
        if (t.step != null && stage == 0) {
          out.addAll(_caseButtons(t));
        } else {
          if (t.step != null) out.add(_caseNote(t));
          out.add(const SizedBox(height: 12));
          for (var i = 0; i < opts.length; i++) {
            final good = locked && opts[i] == t.answer, bad = locked && picked == i && opts[i] != t.answer;
            out.add(
              OptionTile(
                label: opts[i],
                num: i + 1,
                state: good
                    ? OptState.good
                    : bad
                    ? OptState.bad
                    : (locked ? OptState.dim : OptState.idle),
                onTap: locked
                    ? null
                    : () {
                        picked = i;
                        _answer(opts[i] == t.answer, t.answer);
                      },
              ),
            );
          }
        }
      case 'order':
        out.add(_head('Bau den Satz', 'Соберите предложение', 'Build the sentence'));
        out.add(const SizedBox(height: 14));
        if (t.cue.isNotEmpty || t.html.isNotEmpty) out.add(_prompt(t));
        out.add(const SizedBox(height: 10));
        out.add(
          TokenLine(
            tokens: [for (final i in oPick) t.words[i]],
            placeholder: true,
            onTap: locked ? null : (j) => setState(() => oPool.add(oPick.removeAt(j))),
          ),
        );
        out.add(const SizedBox(height: 12));
        out.add(
          TokenLine(
            tokens: [for (final i in oPool) t.words[i]],
            onTap: locked
                ? null
                : (j) {
                    setState(() => oPick.add(oPool.removeAt(j)));
                    if (oPool.isEmpty) {
                      final got = vNorm(oPick.map((i) => t.words[i]).join(' '));
                      _answer(t.answers.any((a) => vNorm(a) == got), t.answers.first);
                    }
                  },
          ),
        );
      case 'error':
        out.add(_head('Tippe auf das falsche Wort', 'Нажмите на слово с ошибкой', 'Tap the wrong word'));
        out.add(const SizedBox(height: 14));
        out.add(
          TokenLine(
            tokens: toks,
            states: locked
                ? [
                    for (var i = 0; i < toks.length; i++)
                      _bare(toks[i]) == _bare(t.wrong) ? OptState.bad : (i == tapped ? OptState.sel : OptState.idle),
                  ]
                : null,
            onTap: locked
                ? null
                : (i) {
                    tapped = i;
                    _answer(_bare(toks[i]) == _bare(t.wrong), '${t.wrong} → ${t.right}');
                  },
          ),
        );
      default:
        out.add(_head('Schreib auf Deutsch', 'Напишите по-немецки', 'Write it in German'));
        out.add(const SizedBox(height: 14));
        out.add(_prompt(t));
        out.add(const SizedBox(height: 14));
        out.add(
          TypeBox(
            controller: typeC,
            focus: typeF,
            locked: locked,
            onSubmit: () {
              if (wait) return _next();
              if (!locked) _checkWrite(t);
            },
          ),
        );
        out.add(const SizedBox(height: 10));
        out.add(GlowButton(l('Prüfen', 'Проверить', 'Check'), onTap: locked ? null : () => _checkWrite(t)));
    }
    if (fbOk != null) out.add(_verdict(t));
    return out;
  }

  Widget _prompt(Task t) {
    final kids = <Widget>[];
    if (t.html.isNotEmpty) {
      kids.add(Text.rich(htmlSpan(t.html, size: 25, head: true), style: L.h(25).copyWith(height: 1.3)));
    } else if (t.text.isNotEmpty) {
      final parts = t.text.split('___');
      final filled = locked && t.kind == 'pick' && (t.step == null || stage == 1);
      kids.add(
        Text.rich(
          TextSpan(
            children: [
              for (var i = 0; i < parts.length; i++) ...[
                TextSpan(text: parts[i]),
                if (i < parts.length - 1)
                  TextSpan(
                    text: filled ? ' ${t.answer} ' : (t.step?.mode == 'case' ? ' ${t.answer} ' : ' ____ '),
                    style: TextStyle(
                      color: filled ? L.das : L.sign,
                      fontWeight: FontWeight.w700,
                      decoration: t.step?.mode == 'case' ? TextDecoration.underline : null,
                      decorationColor: L.sign,
                    ),
                  ),
              ],
            ],
          ),
          style: L.h(26).copyWith(height: 1.3),
        ),
      );
    }
    if (t.cue.isNotEmpty) {
      kids.add(
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(t.cue, style: L.b(13, L.muted)),
        ),
      );
    }
    if (t.exv.isNotEmpty) {
      kids.add(
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: L.sign.withValues(alpha: .1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: L.sign.withValues(alpha: .5)),
            ),
            child: Text.rich(htmlSpan('⚠ ${t.exv}', size: 13)),
          ),
        ),
      );
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: kids);
  }

  List<Widget> _caseButtons(Task t) {
    final st = t.step!;
    return [
      const SizedBox(height: 14),
      Text(
        st.mode == 'case'
            ? l('Welche Rolle hat das markierte Wort?', 'Какая роль у выделенного слова?', 'What role does the marked word have?')
            : l('Welcher Fall gehört in die Lücke?', 'Какой падеж нужен в пропуске?', 'Which case goes into the gap?'),
        style: L.b(14, L.ink2),
      ),
      const SizedBox(height: 10),
      for (final (c, name, q) in _baskets)
        OptionTile(
          label: '${caseNames[c]} — ${l(name.$1, name.$2, name.$3)} (${l(q.$1, q.$2, q.$3)})',
          color: c == 'nom'
              ? L.der
              : c == 'akk'
              ? L.die
              : L.das,
          state: casePicked == null ? OptState.idle : (c == st.c ? OptState.good : (c == casePicked ? OptState.bad : OptState.dim)),
          onTap: casePicked != null ? null : () => _pickCase(c),
        ),
      if (st.hint.isNotEmpty && casePicked == null)
        hint
            ? Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text.rich(htmlSpan('💡 ${st.hint}', size: 13, color: L.ink2)),
              )
            : Align(
                alignment: Alignment.centerLeft,
                child: TextButton(onPressed: () => setState(() => hint = true), child: Text('💡 ${l('Tipp', 'Подсказка', 'Hint')}')),
              ),
    ];
  }

  Widget _caseNote(Task t) {
    final st = t.step!;
    if (st.mode == 'form') {
      return Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Text.rich(htmlSpan(st.explain, size: 13, color: L.ink2)),
      );
    }
    final ok = casePicked == st.c;
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: (ok ? L.das : L.die).withValues(alpha: .1), borderRadius: BorderRadius.circular(10)),
        child: Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: ok ? '${l('Richtig', 'Верно', 'Right')}: ' : '${l('Gebraucht wird', 'Нужен', 'Needed')}: ',
                style: L.b(13, ok ? L.das : L.die),
              ),
              TextSpan(text: '${caseNames[st.c]}. ', style: L.b(13)),
              htmlSpan(st.explain, size: 13, color: L.ink2),
            ],
          ),
        ),
      ),
    );
  }

  Widget _verdict(Task t) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: (fbOk! ? L.das : L.die).withValues(alpha: .1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: (fbOk! ? L.das : L.die).withValues(alpha: .5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: fbOk! ? '${l('Richtig!', 'Верно!', 'Correct!')} ' : '${l('Leider nicht.', 'Мимо.', 'Not quite.')} ',
                    style: L.b(15, fbOk! ? L.das : L.die),
                  ),
                  if (!fbOk!) TextSpan(text: '${l('Richtig', 'Правильно', 'Correct')}: ', style: L.t(15)),
                  if (!fbOk! || t.kind == 'error') TextSpan(text: fbCorr, style: L.b(15)),
                ],
              ),
            ),
            if (t.why.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text.rich(htmlSpan(t.why, size: 13.5, color: L.ink2)),
              ),
            if (t.full.isNotEmpty && t.full != fbCorr)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(t.full, style: L.t(13, c: L.muted)),
              ),
            if (t.an.isNotEmpty)
              Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  title: Text(l('Satz erklärt', 'Разбор фразы', 'Sentence explained'), style: L.b(13, L.der)),
                  children: [
                    for (final li in RegExp(r'<li>(.*?)</li>').allMatches(t.an))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text.rich(htmlSpan(li.group(1)!, size: 13, color: L.ink2)),
                      ),
                  ],
                ),
              ),
            if (wait && (!fbOk! || t.an.isNotEmpty || t.kind == 'type')) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: GlowButton(l('Weiter', 'Дальше', 'Next'), size: 16, onTap: _next)),
                  if (voice)
                    IconButton(
                      tooltip: l('Anhören', 'Послушать', 'Listen'),
                      onPressed: () => Tts.say(t.spoken),
                      icon: const Icon(Icons.volume_up_outlined, color: L.der),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _checkWrite(Task t) {
    final v = typeC.text;
    if (v.trim().isEmpty) return;
    final acc = t.answers.isNotEmpty ? t.answers : [t.answer];
    _answer(acc.any((a) => _foldS(a) == _foldS(v)), acc.first);
  }

  List<Widget> _done() {
    final first = total - miss.length;
    final clean = miss.isEmpty;
    return [
      Text(l('RUNDE GESCHAFFT', 'ЗАХОД ПРОЙДЕН', 'RUN DONE'), style: L.h(14, L.muted).copyWith(letterSpacing: 1.6)),
      const SizedBox(height: 8),
      Text('$first ${l('von', 'из', 'of')} $total ${l('beim ersten Versuch', 'с первой попытки', 'at first try')}', style: L.h(30)),
      const SizedBox(height: 6),
      Text('+$right XP', style: L.b(15, L.sign)),
      if (widget.doneExtra != null) ...[const SizedBox(height: 14), widget.doneExtra!(context, clean, first, total)],
      if (miss.isNotEmpty) ...[
        const SizedBox(height: 14),
        Panel(
          child: Rows([
            for (final t in miss)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('✕  ${t.spoken}', style: L.b(14)),
                    if (t.why.isNotEmpty) Text.rich(htmlSpan(t.why, size: 12.5, color: L.muted)),
                  ],
                ),
              ),
          ]),
        ),
      ],
      const SizedBox(height: 16),
      GlowButton(l('Noch eine Runde', 'Ещё заход', 'Another run'), onTap: () => setState(_start)),
      const SizedBox(height: 10),
      GhostButton(l('Zurück', 'Назад', 'Back'), color: L.muted, onTap: () => Navigator.pop(context)),
    ];
  }
}
