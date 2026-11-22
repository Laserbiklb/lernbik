import '../fx.dart';

import 'dart:async';
import 'dart:math';

import 'package:material_ui/material_ui.dart';

import '../i18n.dart';
import '../theme.dart';
import 'data.dart';
import 'progress.dart';
import 'tts.dart';
import 'widgets.dart';

/// Games of a word round, in the order Wortkreis plays them.
const _games = {
  'rueck': ('Zurück', 'Обратно', 'Back'),
  'artikel': ('Artikel', 'Артикль', 'Article'),
  'wahl': ('Übersetzung', 'Перевод', 'Translation'),
  'paare': ('Paare', 'Пары', 'Pairs'),
  'tippen': ('Tippen', 'Набор', 'Typing'),
  'hoeren': ('Hören', 'На слух', 'Listening'),
  'buchstaben': ('Buchstaben', 'Буквы', 'Letters'),
};
const _gameHint = {
  'rueck': ('das deutsche Wort wählen', 'выбрать немецкое слово', 'pick the German word'),
  'artikel': ('der, die oder das', 'der, die или das', 'der, die or das'),
  'wahl': ('aus vier wählen', 'выбрать из четырёх', 'pick one of four'),
  'paare': ('Wort und Übersetzung verbinden', 'соединить слово и перевод', 'match word and translation'),
  'tippen': ('auf Deutsch schreiben', 'написать по-немецки', 'write it in German'),
  'hoeren': ('hören und Übersetzung wählen', 'услышать и выбрать перевод', 'listen and pick the translation'),
  'buchstaben': ('Wort aus Buchstaben bauen', 'собрать слово из букв', 'build the word from letters'),
};

String fold(String s) =>
    s.toLowerCase().trim().replaceAll(RegExp(r'\s+'), ' ').replaceAll('ä', 'ae').replaceAll('ö', 'oe').replaceAll('ü', 'ue').replaceAll('ß', 'ss');

/// "der Polizist / die Polizistin": one gender form is enough.
List<(String, String)> variants(Word w) {
  final full = (w.a.isNotEmpty ? '${w.a} ' : '') + w.d;
  final parts = full.split(RegExp(r'\s*/\s*')).where((x) => x.isNotEmpty).toList();
  final o = <(String, String)>[];
  for (final p in parts) {
    final m = RegExp(r'^(der|die|das)\s+(.+)$', caseSensitive: false).firstMatch(p);
    o.add(m != null ? (m.group(1)!.toLowerCase(), m.group(2)!) : (w.a.isNotEmpty && parts.length == 1 ? w.a : '', p));
  }
  return o.isEmpty ? [(w.a, w.d)] : o;
}

String bareD(Word w) => variants(w).first.$2;
String say(Word w) => (w.a.isNotEmpty ? '${w.a} ' : '') + w.d;

class RoundScreen extends StatefulWidget {
  final Progress p;
  final List<Word> pool;
  final String mode; // new | rev | mix
  final String lang;
  const RoundScreen({super.key, required this.p, required this.pool, required this.mode, required this.lang});
  @override
  State<RoundScreen> createState() => _RoundScreenState();
}

class _RoundScreenState extends State<RoundScreen> {
  final rnd = Random();
  late List<Word> batch;
  late List<String> stages;
  int si = -1;
  final missed = <String>{}, seen = <String>{}, answered = <String>{};
  Set<String> fresh = {};
  int right = 0, combo = 0, bonus = 0;
  List<Word> queue = [];
  int total = 0, doneN = 0;
  Word? cur;
  bool locked = false, wait = false;
  List<String> opts = [];
  int? picked; // chosen option
  String? fbMsg; // feedback line
  bool? fbOk;
  String phase = 'intro'; // intro | q | pairs | done | empty
  // letters
  List<int> lPool = [], lPick = [];
  List<String> lChars = [];
  // typing
  final typeC = TextEditingController();
  final typeF = FocusNode();
  // listening
  bool revealed = false;
  // pairs
  List<List<Word>> pq = [];
  List<Word> pl = [], pr = [];
  int psel = -1;
  final pdone = <String>{};
  (int, int)? pbad;
  // finish
  List<(Word, int, bool)> results = [];
  int runId = 0;

  Progress get p => widget.p;
  String l(String de, String ru, String en) => l3(widget.lang, de, ru, en);
  bool get voice => p.voice && Tts.available;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void dispose() {
    typeC.dispose();
    typeF.dispose();
    super.dispose();
  }

  void _start() {
    runId++;
    var b = p.pickBatch(widget.pool, p.rsize, widget.mode);
    final fr = b.where((w) => p.prog[w.k] == null).toList();
    if (fr.length > 5) {
      // At most five new words per round; fill up with words to repeat.
      final keep = fr.take(5).toList();
      final rest = b.where((w) => p.prog[w.k] != null).toList();
      final extra = p.pickBatch(widget.pool, 60, 'rev').where((w) => !keep.contains(w) && !rest.contains(w));
      b = [...keep, ...rest, ...extra].take(b.length).toList();
    }
    batch = b;
    fresh = {
      for (final w in b)
        if (p.prog[w.k] == null) w.k,
    };
    // In German there is no built-in translation: the translation games are skipped and the
    // letter/typing games are prompted by ear.
    stages = noTr ? ['artikel', 'buchstaben', 'tippen'] : ['wahl', 'paare', 'artikel', voice && rnd.nextBool() ? 'hoeren' : 'rueck', 'buchstaben', 'tippen'];
    si = -1;
    missed.clear();
    seen.clear();
    answered.clear();
    right = combo = bonus = 0;
    results = [];
    if (batch.isEmpty) {
      phase = 'empty';
    } else if (fresh.isNotEmpty) {
      phase = 'intro';
    } else {
      _nextStage();
    }
    setState(() {});
  }

  String _level(Word w) {
    if (fresh.contains(w.k)) return 'new';
    final g = p.prog[w.k];
    return g == null || g.b < 2 ? 'learn' : 'known';
  }

  bool get noTr => Word.lang == 'de';

  /// What the letter/typing games show: the translation, or (German UI) nothing because the
  /// word is spoken, or the English one when the device cannot speak.
  String? _cue(Word w) => w.hasTr ? w.r : (Tts.available ? null : (w.en ?? w.ru));

  Widget _ask(Word w, String sub, {Color? subColor}) {
    final cue = _cue(w);
    if (cue != null) return Ask(cue, sub, subColor: subColor);
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l('Hör zu', 'Послушайте', 'Listen'), style: L.h(30)),
          const SizedBox(height: 4),
          Text(sub, style: L.b(13, subColor ?? L.muted)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              GhostButton(l('▶ Noch einmal', '▶ Ещё раз', '▶ Again'), onTap: () => Tts.say(say(w))),
              GhostButton(l('Übersetzen', 'Перевести', 'Translate'), color: L.muted, onTap: () => openGoogle(say(w))),
            ],
          ),
        ],
      ),
    );
  }

  bool _elig(String g, Word w) {
    final lv = _level(w);
    if (noTr && g == 'buchstaben') return lv != 'known';
    return switch (g) {
      'wahl' || 'paare' => lv != 'known',
      'artikel' => true,
      'rueck' || 'hoeren' => lv != 'new',
      'buchstaben' => lv == 'learn',
      'tippen' => lv == 'known',
      _ => true,
    };
  }

  void _bump() {
    combo++;
    if (combo >= 3) bonus++;
  }

  void _nextStage() {
    si++;
    if (si >= stages.length) return _finish();
    final g = stages[si];
    var items = shuffled(batch).where((w) => _elig(g, w)).toList();
    if (g == 'artikel') items = items.where((w) => w.a.isNotEmpty).toList();
    if (g == 'buchstaben') items = items.where((w) => bareD(w).length > 1 && bareD(w).length <= 18).toList();
    if (g == 'paare') {
      if (items.length < 2) return _nextStage();
      seen.addAll(items.map((w) => w.k));
      pq = [for (var i = 0; i < items.length; i += 6) items.sublist(i, min(i + 6, items.length))];
      if (pq.length > 1 && pq.last.length < 2) {
        final last = pq.removeLast();
        pq.last = [...pq.last, ...last];
      }
      total = items.length;
      doneN = 0;
      _pairsChunk();
      phase = 'pairs';
      return;
    }
    if (items.isEmpty) return _nextStage();
    queue = items;
    total = items.length;
    doneN = 0;
    phase = 'q';
    _nextQ();
  }

  void _pairsChunk() {
    final c = pq.removeAt(0);
    pl = c;
    pr = shuffled(c);
    psel = -1;
    pdone.clear();
    pbad = null;
  }

  void _nextQ() {
    if (queue.isEmpty) {
      cur = null;
      return _nextStage();
    }
    final w = cur = queue.removeAt(0);
    seen.add(w.k);
    locked = false;
    wait = false;
    picked = null;
    fbMsg = null;
    fbOk = null;
    revealed = false;
    final g = stages[si];
    final all = p.allWords;
    if (g == 'rueck') {
      final oth = shuffled(all.where((x) => x.k != w.k && x.r != w.r));
      final op = <String>[w.k];
      for (final x in oth) {
        if (op.length < 4 && !op.contains(x.k) && (w.a.isEmpty == x.a.isEmpty)) op.add(x.k);
      }
      for (final x in oth) {
        if (op.length < 4 && !op.contains(x.k)) op.add(x.k);
      }
      opts = shuffled(op);
    } else if (g == 'wahl' || g == 'hoeren') {
      final op = <String>[w.r];
      for (final x in shuffled(all.where((x) => x.r != w.r))) {
        if (op.length < 4 && !op.contains(x.r)) op.add(x.r);
      }
      opts = shuffled(op);
      if (g == 'hoeren') Tts.say(say(w));
      if (g == 'wahl' && voice) Tts.say(say(w));
    } else if (g == 'artikel') {
      if (voice) Tts.say(w.d);
    } else if (g == 'buchstaben') {
      if (_cue(w) == null) Tts.say(say(w));
      final bd = bareD(w);
      lChars = bd.split('');
      lPool = List.generate(lChars.length, (i) => i);
      var n = 0;
      do {
        lPool.shuffle(rnd);
        n++;
      } while (n < 8 && lPool.map((i) => lChars[i]).join() == bd);
      lPick = [];
    } else if (g == 'tippen') {
      if (_cue(w) == null) Tts.say(say(w));
      typeC.clear();
      WidgetsBinding.instance.addPostFrameCallback((_) => typeF.requestFocus());
    }
  }

  void _answer(bool ok, [String msg = '']) {
    final w = cur!;
    answered.add(w.k);
    locked = true;
    final g = stages[si];
    if (voice && !(g == 'hoeren' && !ok)) Tts.say(say(w));
    if (ok) {
      right++;
      doneN++;
      _bump();
      fbOk = true;
      fbMsg = null;
      // No auto-skip: the learner always taps "Next".
      wait = true;
    } else {
      missed.add(w.k);
      queue.add(w);
      wait = true;
      combo = 0;
      fbOk = false;
      fbMsg = msg;
    }
    setState(() {});
  }

  void _pairTap(bool left, int i) {
    if (pbad != null) return;
    if (left) {
      if (pdone.contains(pl[i].k)) return;
      setState(() => psel = i);
      if (voice) Tts.say(say(pl[i]));
      return;
    }
    if (psel < 0) return;
    final lw = pl[psel], rw = pr[i];
    answered.add(lw.k);
    if (lw.k == rw.k) {
      pdone.add(lw.k);
      psel = -1;
      right++;
      doneN++;
      _bump();
      setState(() {});
      // A finished set waits for "Next" (see _pairs).
    } else {
      missed.add(lw.k);
      combo = 0;
      pbad = (psel, i);
      psel = -1;
      setState(() {});
      Timer(const Duration(milliseconds: 650), () {
        if (mounted) setState(() => pbad = null);
      });
    }
  }

  void _checkTyped() {
    final v = typeC.text;
    if (v.trim().isEmpty) return;
    final w = cur!;
    final vs = variants(w);
    final fv = fold(v);
    final ok = fv == fold(w.k) || vs.any((x) => fv == fold((x.$1.isNotEmpty ? '${x.$1} ' : '') + x.$2));
    var msg = '';
    if (!ok && w.a.isNotEmpty) {
      final m = RegExp(r'^(der|die|das) (.+)$').firstMatch(fv);
      if (m != null && vs.any((x) => m.group(2) == fold(x.$2))) {
        msg = l('Wort richtig, Artikel falsch. ', 'Слово верное, артикль другой. ', 'Right word, wrong article. ');
      } else if (vs.any((x) => fv == fold(x.$2))) {
        msg = l('Der Artikel fehlt. ', 'Не хватает артикля. ', 'The article is missing. ');
      }
    }
    _answer(ok, msg);
  }

  void _hint() {
    if (locked) return;
    final v0 = variants(cur!).first;
    final full = (v0.$1.isNotEmpty ? '${v0.$1} ' : '') + v0.$2;
    final c = typeC.text;
    var k = 0;
    while (k < c.length && k < full.length && c[k].toLowerCase() == full[k].toLowerCase()) {
      k++;
    }
    typeC.text = full.substring(0, min(full.length, k + 1));
    typeC.selection = TextSelection.collapsed(offset: typeC.text.length);
    typeF.requestFocus();
  }

  /// Leaving early keeps what was already answered.
  void _quit() {
    if (phase != 'done' && phase != 'empty' && answered.isNotEmpty) {
      p.applyRound(batch.where((w) => answered.contains(w.k)), missed, right, bonus);
    }
    Navigator.pop(context);
  }

  void _finish() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final done = batch.where((w) => seen.contains(w.k)).toList();
    p.applyRound(done, missed, right, bonus);
    results = [for (final w in done) (w, p.prog[w.k]?.b ?? 0, missed.contains(w.k))];
    phase = 'done';
    cur = null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && results.isNotEmpty) confetti(context, count: missed.isEmpty ? 110 : 60);
    });
    if (now < 0) return;
  }

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (did, _) {
        if (!did) _quit();
      },
      child: Scaffold(
        body: SafeArea(
          child: switch (phase) {
            'intro' => _intro(),
            'pairs' => _gameFrame(_pairs()),
            'q' => _gameFrame(_question()),
            'done' => _done(),
            _ => _empty(),
          },
        ),
      ),
    );
  }

  Widget _topBar() => Padding(
    padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
    child: Row(
      children: [
        IconButton(
          tooltip: l('Beenden', 'Выйти', 'Quit'),
          onPressed: _quit,
          icon: const Icon(Icons.close, color: L.muted),
        ),
        Expanded(
          child: Row(
            children: [
              for (var i = 0; i < stages.length; i++)
                Expanded(
                  child: Container(
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: i < si ? L.das : (i == si ? L.das.withValues(alpha: .5) : L.line),
                      borderRadius: BorderRadius.circular(99),
                      boxShadow: i <= si ? L.glow(L.das, 6, .6) : null,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        AnimatedSwitcher(
          duration: Fx.d(260),
          transitionBuilder: (c, a) => ScaleTransition(
            scale: CurvedAnimation(parent: a, curve: Curves.easeOutBack),
            child: c,
          ),
          child: combo >= 2
              ? Padding(
                  key: ValueKey(combo),
                  padding: const EdgeInsets.only(right: 8),
                  child: Text('×$combo', style: L.h(16 + min(combo, 8).toDouble(), L.sign).copyWith(shadows: L.glow(L.sign, 10, .8))),
                )
              : const SizedBox.shrink(key: ValueKey(0)),
        ),
        Text('$doneN/$total', style: L.b(14, L.muted)),
      ],
    ),
  );

  Widget _gameFrame(Widget body) {
    final g = stages[si];
    final n = _games[g]!, h = _gameHint[g]!;
    return Column(
      children: [
        _topBar(),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
            children: [
              Text('${l(n.$1, n.$2, n.$3)} · ${l(h.$1, h.$2, h.$3)}'.toUpperCase(), style: L.h(14, L.muted).copyWith(letterSpacing: 1.6)),
              const SizedBox(height: 18),
              body,
            ],
          ),
        ),
      ],
    );
  }

  Widget _sign(Word w, {bool article = true, String? sub}) => Center(
    child: Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
      constraints: const BoxConstraints(minWidth: 200),
      decoration: BoxDecoration(color: L.sign, borderRadius: BorderRadius.circular(10), boxShadow: L.glow(L.sign, 30, .45)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text.rich(
            TextSpan(
              children: [
                if (article && w.a.isNotEmpty) TextSpan(text: '${w.a} ', style: L.h(_fs(w), _artDark(w.a))),
                TextSpan(text: w.d, style: L.h(_fs(w), L.bg)),
              ],
            ),
            textAlign: TextAlign.center,
          ),
          if (sub != null) ...[
            const SizedBox(height: 4),
            Text(
              sub,
              textAlign: TextAlign.center,
              style: L.t(15, c: const Color(0xFF3A3410)),
            ),
          ],
        ],
      ),
    ),
  );

  static double _fs(Word w) {
    final n = w.d.length + w.a.length;
    return n > 22
        ? 24
        : n > 14
        ? 30
        : 36;
  }

  static Color _artDark(String a) => a == 'der'
      ? const Color(0xFF1D4FA8)
      : a == 'die'
      ? const Color(0xFFB0102C)
      : const Color(0xFF0E7A45);

  Widget _question() {
    final w = cur!;
    final g = stages[si];
    final kids = <Widget>[];
    if (g == 'artikel') {
      kids.add(_sign(w, article: false, sub: w.hasTr ? w.r : null));
      for (final a in ['der', 'die', 'das']) {
        final good = locked && a == w.a, bad = locked && picked == ['der', 'die', 'das'].indexOf(a) && a != w.a;
        kids.add(
          OptionTile(
            label: a,
            color: L.art(a),
            big: true,
            state: good
                ? OptState.good
                : bad
                ? OptState.bad
                : (locked ? OptState.dim : OptState.idle),
            onTap: locked
                ? null
                : () {
                    picked = ['der', 'die', 'das'].indexOf(a);
                    _answer(a == w.a);
                  },
          ),
        );
      }
    } else if (g == 'wahl' || g == 'rueck' || g == 'hoeren') {
      if (g == 'wahl') kids.add(_sign(w, sub: w.c));
      if (g == 'rueck') kids.add(Ask(w.r, l('das deutsche Wort wählen', 'выберите немецкое слово', 'pick the German word')));
      if (g == 'hoeren') {
        kids.add(
          Center(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                GhostButton(l('▶ Noch einmal', '▶ Ещё раз', '▶ Again'), onTap: () => Tts.say(say(w))),
                GhostButton(l('Wort zeigen', 'Показать слово', 'Show word'), color: L.muted, onTap: () => setState(() => revealed = true)),
              ],
            ),
          ),
        );
        if (revealed)
          kids.add(
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Center(child: Text(say(w), style: L.h(26))),
            ),
          );
        kids.add(const SizedBox(height: 14));
      }
      final target = g == 'rueck' ? w.k : w.r;
      for (var i = 0; i < opts.length; i++) {
        final good = locked && opts[i] == target, bad = locked && picked == i && opts[i] != target;
        kids.add(
          OptionTile(
            label: opts[i],
            num: i + 1,
            color: L.der,
            state: good
                ? OptState.good
                : bad
                ? OptState.bad
                : (locked ? OptState.dim : OptState.idle),
            onTap: locked
                ? null
                : () {
                    picked = i;
                    _answer(opts[i] == target);
                  },
          ),
        );
      }
    } else if (g == 'buchstaben') {
      final v0 = variants(w).first;
      kids.add(
        _ask(
          w,
          v0.$1.isNotEmpty ? '${l('Artikel', 'артикль', 'article')}: ${v0.$1}' : l('Wort aus Buchstaben bauen', 'соберите слово из букв', 'build the word'),
          subColor: v0.$1.isNotEmpty ? L.art(v0.$1) : null,
        ),
      );
      kids.add(
        TokenLine(
          tokens: [for (final i in lPick) lChars[i]],
          placeholder: true,
          letters: true,
          onTap: locked ? null : (j) => setState(() => lPool.add(lPick.removeAt(j))),
        ),
      );
      kids.add(const SizedBox(height: 12));
      kids.add(
        TokenLine(
          tokens: [for (final i in lPool) lChars[i]],
          letters: true,
          onTap: locked
              ? null
              : (j) {
                  setState(() => lPick.add(lPool.removeAt(j)));
                  if (lPool.isEmpty) _answer(lPick.map((i) => lChars[i]).join() == bareD(w));
                },
        ),
      );
    } else {
      kids.add(
        _ask(
          w,
          w.a.isNotEmpty
              ? l('Nomen: mit Artikel schreiben', 'существительное, пишите с артиклем', 'noun: write it with the article') +
                    (variants(w).length > 1 ? ' · ${l('eine Form reicht', 'достаточно одной формы', 'one form is enough')}' : '')
              : l('ohne Artikel', 'без артикля', 'no article'),
        ),
      );
      kids.add(
        TypeBox(
          controller: typeC,
          focus: typeF,
          locked: locked,
          onSubmit: () {
            if (wait) return setState(_nextQ);
            if (!locked) _checkTyped();
          },
        ),
      );
      kids.add(const SizedBox(height: 10));
      kids.add(
        Row(
          children: [
            Expanded(child: GlowButton(l('Prüfen', 'Проверить', 'Check'), onTap: locked ? null : _checkTyped)),
            const SizedBox(width: 8),
            GhostButton(l('Buchstabe', 'Буква', 'Letter'), color: L.sign, onTap: locked ? null : _hint),
          ],
        ),
      );
    }
    kids.add(_feedback(w));
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: kids);
  }

  Widget _feedback(Word w) {
    if (fbOk == null) return const SizedBox(height: 70);
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Verdict(
        ok: fbOk!,
        lang: widget.lang,
        text: TextSpan(
          children: [
            if (!fbOk!) TextSpan(text: fbMsg ?? ''),
            if (!fbOk!) TextSpan(text: '${l('Richtig', 'Правильно', 'Correct')}: '),
            if (w.a.isNotEmpty)
              TextSpan(
                text: '${w.a} ',
                style: TextStyle(color: L.art(w.a)),
              ),
            TextSpan(
              text: w.d,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            if (w.hasTr) TextSpan(text: ' — ${w.r}'),
          ],
        ),
        onNext: wait ? () => setState(_nextQ) : null,
        onSay: voice ? () => Tts.say(say(w)) : null,
        onTranslate: say(w),
      ),
    );
  }

  Widget _pairs() {
    Widget cell(String text, bool left, int i, Word w) {
      final done = pdone.contains(w.k);
      final sel = left && psel == i;
      final bad = pbad != null && (left ? pbad!.$1 == i : pbad!.$2 == i);
      return PairCell(
        child: left
            ? Text.rich(
                TextSpan(
                  children: [
                    if (w.a.isNotEmpty)
                      TextSpan(
                        text: '${w.a} ',
                        style: TextStyle(color: L.art(w.a)),
                      ),
                    TextSpan(text: w.d),
                  ],
                ),
                textAlign: TextAlign.center,
                style: L.b(14),
              )
            : Text(text, textAlign: TextAlign.center, style: L.b(14)),
        state: done
            ? OptState.good
            : bad
            ? OptState.bad
            : sel
            ? OptState.sel
            : OptState.idle,
        onTap: done ? null : () => _pairTap(left, i),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < pl.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Expanded(child: cell(pl[i].d, true, i, pl[i])),
                const SizedBox(width: 10),
                Expanded(child: cell(pr[i].r, false, i, pr[i])),
              ],
            ),
          ),
        const SizedBox(height: 6),
        if (pdone.length >= pl.length)
          Appear(
            child: GlowButton(
              l('Weiter', 'Дальше', 'Next'),
              color: L.das,
              textColor: L.bg,
              onTap: () => setState(doneN >= total || pq.isEmpty ? _nextStage : _pairsChunk),
            ),
          )
        else
          Text(
            l('Tippe ein deutsches Wort, dann seine Übersetzung.', 'Нажмите немецкое слово, затем его перевод.', 'Tap a German word, then its translation.'),
            style: L.t(13, c: L.muted),
          ),
      ],
    );
  }

  Widget _intro() {
    final ws = batch.where((w) => fresh.contains(w.k)).toList();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
          child: Row(
            children: [
              IconButton(
                onPressed: _quit,
                icon: const Icon(Icons.close, color: L.muted),
              ),
              const Spacer(),
              Text('${l('neue Wörter', 'новые слова', 'new words')}: ${ws.length}', style: L.b(14, L.muted)),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
            children: [
              Text(
                l('KENNENLERNEN · NUR ANSCHAUEN', 'ЗНАКОМСТВО · ПРОСТО ПОСМОТРИТЕ', 'MEET THE WORDS · JUST LOOK'),
                style: L.h(14, L.muted).copyWith(letterSpacing: 1.6),
              ),
              const SizedBox(height: 12),
              Panel(
                child: Rows([
                  for (final w in ws)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text.rich(
                                  TextSpan(
                                    children: [
                                      if (w.a.isNotEmpty) TextSpan(text: '${w.a} ', style: L.b(16, L.art(w.a))),
                                      TextSpan(text: w.d, style: L.b(16)),
                                      if (w.p.isNotEmpty && w.p != '-')
                                        TextSpan(
                                          text: ', ${w.p}',
                                          style: L.t(13, c: L.muted),
                                        ),
                                    ],
                                  ),
                                ),
                                if (w.hasTr) Text(w.r, style: L.t(13, c: L.ink2)),
                              ],
                            ),
                          ),
                          if (voice)
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
                ]),
              ),
              const SizedBox(height: 10),
              Text(
                l(
                  'Lies jedes Wort laut, mit Artikel. Zuerst kommen Aufgaben zum Erkennen, schreiben musst du erst später.',
                  'Прочитайте каждое слово вслух вместе с артиклем. Сначала задания на узнавание, писать придётся позже.',
                  'Read each word aloud with its article. First you recognise them, writing comes later.',
                ),
                style: L.t(13, c: L.muted),
              ),
              const SizedBox(height: 16),
              GlowButton(l('Verstanden, los', 'Понятно, к заданиям', 'Got it, start'), onTap: () => setState(_nextStage)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _done() {
    final clean = results.where((r) => !r.$3).length;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      children: [
        Text(l('RUNDE GESCHAFFT', 'КРУГ ПРОЙДЕН', 'ROUND DONE'), style: L.h(14, L.muted).copyWith(letterSpacing: 1.6)),
        const SizedBox(height: 8),
        if (results.isNotEmpty) Text('$clean ${l('von', 'из', 'of')} ${results.length} ${l('ohne Fehler', 'без ошибок', 'without mistakes')}', style: L.h(30)),
        if (results.isEmpty)
          Text(l('In dieser Auswahl gab es keine Nomen.', 'В этой подборке нет существительных.', 'There were no nouns in this set.'), style: L.t(15)),
        const SizedBox(height: 6),
        Row(
          children: [
            CountUp(
              right + bonus,
              prefix: '+',
              suffix: ' XP',
              style: L.h(24, L.sign).copyWith(shadows: L.glow(L.sign, 12, .7)),
            ),
            if (bonus > 0) Text('  (${l('Bonus für Serien', 'бонус за серии', 'streak bonus')}: +$bonus)', style: L.t(13, c: L.muted)),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          l(
            'Wörter ohne Fehler steigen eine Stufe und kommen später wieder. Wörter mit Fehler kommen in der nächsten Runde.',
            'Слова без ошибок поднялись на уровень и вернутся позже. Слова с ошибкой придут в следующем круге.',
            'Words without mistakes move up a level and come back later. Missed words come in the next round.',
          ),
          style: L.t(13, c: L.muted),
        ),
        const SizedBox(height: 14),
        Panel(
          child: Rows([
            for (final (w, b, miss) in results)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                child: Row(
                  children: [
                    Text(miss ? '✕' : '✓', style: L.b(15, miss ? L.die : L.das)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          children: [
                            if (w.a.isNotEmpty) TextSpan(text: '${w.a} ', style: L.b(14, L.art(w.a))),
                            TextSpan(text: w.d, style: L.b(14)),
                            TextSpan(
                              text: '  ${w.r}',
                              style: L.t(12, c: L.muted),
                            ),
                          ],
                        ),
                      ),
                    ),
                    LevelDots(b),
                  ],
                ),
              ),
          ]),
        ),
        const SizedBox(height: 16),
        GlowButton(l('Nächste Runde', 'Следующий круг', 'Next round'), onTap: _start),
        const SizedBox(height: 10),
        GhostButton(l('Fertig', 'Готово', 'Done'), color: L.muted, onTap: () => Navigator.pop(context)),
      ],
    );
  }

  Widget _empty() => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      Align(
        alignment: Alignment.centerLeft,
        child: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close, color: L.muted),
        ),
      ),
      const SizedBox(height: 20),
      Text(l('Hier gibt es gerade nichts zu üben.', 'Сейчас здесь нечего тренировать.', 'Nothing to practise here right now.'), style: L.h(24)),
      const SizedBox(height: 8),
      Text(
        l(
          'Wähle ein anderes Kapitel oder lerne zuerst neue Wörter.',
          'Выберите другую главу или сначала выучите новые слова.',
          'Pick another chapter or learn new words first.',
        ),
        style: L.t(14, c: L.muted),
      ),
    ],
  );
}
