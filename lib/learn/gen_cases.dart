// Cases trainer: a port of the Wortkreis generators (pronouns, articles, prepositions).
import 'dart:math';

import 'data.dart';
import 'exercise.dart';
import 'progress.dart';

Map<String, dynamic> get _d => LearnData.i.tr;
T _pick<T>(Random r, List<T> a) => a[r.nextInt(a.length)];
String cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
List<List<dynamic>> _lst(String k) => (_d[k] as List).cast<List<dynamic>>();

const gn = {'m': 'der', 'f': 'die', 'n': 'das'};
const _caseN = {'nom': 'Nominativ', 'akk': 'Akkusativ', 'dat': 'Dativ'};

/// A cases task before it becomes a [Task].
class CT {
  final String topic, key, text, ans, cue, why, mode;
  final List<String> fam;
  final String g, noun;
  CT(this.topic, this.key, this.text, this.ans, this.cue, this.fam, this.why, {this.g = '', this.noun = '', this.mode = ''});
}

Map<String, dynamic> get _pr => _d['PR'] as Map<String, dynamic>;
List<String> get _prk => (_d['PRK'] as List).cast<String>();
String _prCue(String k) => k == 'sie'
    ? 'sie — она'
    : k == 'sieP'
    ? 'sie — они'
    : k == 'Sie'
    ? 'Sie — вежливо'
    : k == 'es'
    ? 'es — оно (das Kind)'
    : (_pr[k] as List)[0] as String;

CT genPron(Random r) {
  if (r.nextDouble() < .3) {
    final p = _pick(r, (_d['PP'] as List).cast<Map<String, dynamic>>());
    final no = ((p['no'] as List?) ?? const []).cast<String>();
    final k = _pick(r, _prk.where((x) => !no.contains(x)).toList());
    final ans = (_pr[k] as List)[p['c'] == 'akk' ? 1 : 2] as String;
    return CT('pron', 'p:${p['c']}:$k', (p['t'] as String).replaceFirst('{O}', '___'), ans, _prCue(k), [
      for (final q in _prk) (_pr[q] as List)[1] as String,
      for (final q in _prk) (_pr[q] as List)[2] as String,
    ], '${p['why']}: ${(_pr[k] as List)[0]} → $ans');
  }
  final v = _pick(r, (_d['PV'] as List).cast<Map<String, dynamic>>());
  final s = _pick(r, _lst('SUBJ'));
  final ks = _prk.where((k) => k != s[1] && !(k == 'Sie' && (s[1] == 'du' || s[1] == 'ihr'))).toList();
  final k = _pick(r, ks);
  final c = v['c'] as String;
  final a2 = (_pr[k] as List)[c == 'akk' ? 1 : 2] as String;
  final verb = (v['f'] as List)[s[2] as int] as String;
  return CT(
    'pron',
    'p:$c:$k',
    (v['t'] as String).replaceFirst('{S}', s[0] as String).replaceFirst('{V}', verb).replaceFirst('{O}', '___'),
    a2,
    _prCue(k),
    [
      (_pr[k] as List)[0] as String,
      (_pr[k] as List)[1] as String,
      (_pr[k] as List)[2] as String,
      for (final q in _prk) (_pr[q] as List)[c == 'akk' ? 2 : 1] as String,
    ],
    'Глагол «${v['inf']}» требует ${_caseN[c]}: ${(_pr[k] as List)[0]} → $a2',
  );
}

final _weak = RegExp(
  r'^(Kollege|Name|Herr|Junge|Mensch|Nachbar|Student|Praktikant|Polizist|Kunde|Patient|Tourist|Journalist|Assistent|Präsident|Löwe|Affe|Hase|Bär|Neffe|Gedanke|Glaube|Buchstabe|Friede|Wille|Funke|Same|Fels|Held|Prinz|Elefant|Automat|Architekt|Kandidat|Soldat|Pilot|Biologe|Psychologe|Fotograf|Experte|Zeuge|Bote|Laie|Kamerad|Ökonom|Demokrat)$',
);

/// The learner's own nouns that are safe for the generators (no weak nouns, no plurals).
List<List<dynamic>> myNouns(Progress p) {
  final seen = <String>{};
  final out = <List<dynamic>>[];
  for (final w in p.own) {
    if (!['der', 'die', 'das'].contains(w.a)) continue;
    final d = w.d.trim();
    if (!RegExp(r'^[A-ZÄÖÜ][A-Za-zÄÖÜäöüß-]+$').hasMatch(d) || _weak.hasMatch(d) || seen.contains(d)) continue;
    if (w.a == 'der' && d.endsWith('e') && d != 'Käse') continue;
    if (RegExp(r'\((pl|Pl|мн)').hasMatch(w.r)) continue;
    seen.add(d);
    out.add([
      d,
      {'der': 'm', 'die': 'f', 'das': 'n'}[w.a],
      w.r,
    ]);
  }
  return out;
}

List<dynamic>? _inList(List<List<dynamic>> l, String d) {
  for (final x in l) {
    if (x[0] == d) return x;
  }
  return null;
}

String _nounCue(List<dynamic> n) => '${gn[n[1]]} ${n[0]}${n.length > 2 && '${n[2]}'.isNotEmpty ? ' — ${n[2]}' : ''}';

CT genArt(Random r, Progress p, Set<String> used) {
  var nn = myNouns(p);
  final builtin = [..._lst('NT'), ..._lst('NP')];
  nn = nn.length >= 6 ? [...nn, ...builtin] : builtin;
  var free = nn.where((n) => !used.contains('n:${n[0]}')).toList();
  if (free.isEmpty) free = nn;
  final n = _pick(r, free);
  final g = n[1] as String;
  final cands = <Map<String, dynamic>>[...(_d['GENT'] as List).cast<Map<String, dynamic>>()];
  for (final t in (_d['AT'] as List).cast<Map<String, dynamic>>()) {
    if (_inList((t['N'] as List).cast<List<dynamic>>(), n[0] as String) != null) cands.add(t);
  }
  final t = _pick(r, cands);
  final thing = [_lst('NT'), _lst('NV'), _lst('NDRINK'), _lst('NTOOL')].any((l) => _inList(l, n[0] as String) != null);
  final tind = t['ind'];
  final ind = tind == 2 && thing
      ? true
      : ((tind != null && tind != 0) || t['t'] == 'Das ist {A} {N}.') && thing
      ? r.nextDouble() < .45
      : false;
  final tab = (ind ? _ind : _def)[t['c']]!;
  final ans = tab[g]!;
  final start = (t['t'] as String).startsWith('{A}');
  final fam = ind ? ['ein', 'eine', 'einen', 'einem', 'einer'] : ['der', 'die', 'das', 'den', 'dem'];
  return CT(
    'art',
    'a:${t['c']}:$g:${ind ? 'i' : 'd'}',
    (t['t'] as String).replaceFirst('{N}', n[0] as String).replaceFirst('{A}', '___'),
    start ? cap(ans) : ans,
    '${_nounCue(n)}${ind ? ' · неопределённый артикль (ein…)' : ' · определённый артикль (der…)'}',
    [for (final x in fam) start ? cap(x) : x],
    '${t['why']}: ${gn[g]} ${n[0]} → $ans ${n[0]}',
    g: g,
    noun: n[0] as String,
  );
}

const _def = {
  'nom': {'m': 'der', 'f': 'die', 'n': 'das'},
  'akk': {'m': 'den', 'f': 'die', 'n': 'das'},
  'dat': {'m': 'dem', 'f': 'der', 'n': 'dem'},
};
const _ind = {
  'nom': {'m': 'ein', 'f': 'eine', 'n': 'ein'},
  'akk': {'m': 'einen', 'f': 'eine', 'n': 'ein'},
  'dat': {'m': 'einem', 'f': 'einer', 'n': 'einem'},
};

CT genPrep(Random r, Progress p, Set<String> used) {
  final nn = myNouns(p);
  final own = nn.length >= 6;
  final xp = _d['XP'] as Map<String, dynamic>, xf = _d['XF'] as Map<String, dynamic>;
  final opts = <(String, List<dynamic>, String, bool)>[];
  for (final pr in ['in', 'an', 'auf', 'zu', 'bei', 'von']) {
    final xn = ((xp[pr] as Map)['N'] as List).cast<List<dynamic>>();
    for (final n in own ? [...nn, ...xn] : xn) {
      final m = _inList(xn, n[0] as String);
      if (m != null && !used.contains('n:${n[0]}')) opts.add((pr, m, n.length > 2 && n[2] is String ? n[2] as String : '', true));
    }
  }
  if (own) {
    for (final pr in ['zu', 'bei', 'von']) {
      for (final n in nn) {
        if (!used.contains('n:${n[0]}')) opts.add((pr, n, n[2] as String, false));
      }
    }
  }
  final places = opts.where((o) => o.$4).toList();
  final pick = places.isNotEmpty && r.nextDouble() < .65
      ? _pick(r, places)
      : opts.isNotEmpty
      ? _pick(r, opts)
      : ('in', ((xp['in'] as Map)['N'] as List).first as List<dynamic>, '', true);
  final pr = pick.$1, n = pick.$2, ru = pick.$3;
  final g = n[1] as String;
  final x = xp[pr] as Map<String, dynamic>, f = xf[pr] as Map<String, dynamic>;
  String tpl, ans, mode = '', why;
  List<String> tplFrom(dynamic tl) {
    final l = tl as List;
    if (l.isNotEmpty && l.first is List) return ((l[(n[2] is int) ? n[2] as int : 0]) as List).cast<String>();
    return l.cast<String>();
  }

  if (f['x'] != null) {
    tpl = pick.$4 ? _pick(r, tplFrom(x['T'])) : _pick(r, ((_d['GENX'] as Map)[pr] as List).cast<String>());
    ans = (f['x'] as Map)[g] as String;
    why = '$pr всегда + Dativ: ${gn[g]} ${n[0]} → $ans ${n[0]}${!ans.contains(' ') ? ' ($pr + ${g == 'f' ? 'der' : 'dem'} = $ans)' : ''}';
  } else {
    mode = r.nextBool() ? 'wo' : 'wohin';
    tpl = _pick(r, tplFrom((x['T'] as Map)[mode]));
    ans = (f[mode] as Map)[g] as String;
    final base = mode == 'wo'
        ? (g == 'f' ? 'der' : 'dem')
        : (g == 'm'
              ? 'den'
              : g == 'f'
              ? 'die'
              : 'das');
    why =
        '${mode == 'wo' ? 'Wo? — где? → Dativ' : 'Wohin? — куда? → Akkusativ'}: ${gn[g]} ${n[0]} → $ans ${n[0]}${!ans.contains(' ') ? ' ($pr + $base = $ans)' : ''}';
  }
  return CT(
    'prep',
    'x:$pr:${mode.isEmpty ? 'x' : mode}:$g',
    tpl.replaceFirst('{N}', n[0] as String).replaceFirst('{X}', '___'),
    ans,
    '$pr + ${gn[g]} ${n[0]}${ru.isNotEmpty ? ' — $ru' : ''}',
    (f['all'] as List).cast<String>(),
    why,
    g: g,
    noun: n[0] as String,
    mode: mode,
  );
}

String trigOf(CT t) {
  if (t.topic == 'prep') return t.mode.isNotEmpty ? t.mode : 'prep:dat';
  final c = t.key.split(':')[1];
  if (t.why.contains('Nominativ') && c == 'nom') return 'subj';
  if (RegExp('всегда|über|warten auf|denken an|für').hasMatch(t.why)) return 'prep:$c';
  return 'verb:$c';
}

String caseOf(CT t) => t.topic == 'prep' ? (t.mode == 'wohin' ? 'akk' : 'dat') : t.key.split(':')[1];

List<String> opts4(Random r, CT t) {
  final seen = {t.ans.toLowerCase()};
  final o = [t.ans];
  for (final x in shuffled(t.fam)) {
    if (o.length < 4 && seen.add(x.toLowerCase())) o.add(x);
  }
  return o;
}

String _lHint(CT t) {
  final tr = trigOf(t);
  if (t.topic == 'prep' && t.mode.isEmpty) return 'Предлог здесь «${t.key.split(':')[1]}». Какой падеж он требует?';
  if (tr.startsWith('prep')) {
    final m = RegExp(r'(\S+)\s+___').firstMatch(t.text);
    return 'Посмотрите на предлог перед пропуском${m != null ? ': «${m.group(1)}»' : ''}. Какой падеж он требует?';
  }
  if (tr == 'wo' || tr == 'wohin') return 'Здесь есть движение куда-то (Wohin?) или это место (Wo?)?';
  if (tr == 'subj') return 'Кто здесь делает действие?';
  return 'Задайте вопрос от глагола: кого? что? — или кому?';
}

String? _exv(CT t) {
  for (final x in _lst('EXV')) {
    if (t.why.contains('«${x[0]}»') || t.why.startsWith('${x[0]} +'))
      return 'Исключение: <b>${x[0]} + ${x[1]}</b> — ${x[2]}. Это нужно просто запомнить.';
  }
  return null;
}

String _sortSent(CT t) {
  final ph = t.noun.isNotEmpty ? '___ ${t.noun}' : '___';
  final mark = '<mark>${t.ans}${t.noun.isNotEmpty ? ' ${t.noun}' : ''}</mark>';
  if (t.text.contains(ph)) return t.text.replaceFirst(ph, mark);
  return t.text.replaceFirst('___', '<mark>${t.ans}</mark>');
}

/// Lessons of the cases trainer, in order: id → (filter, mode).
const caseLessons = ['role', 'akk', 'dat', 'pron', 'pakk', 'pdat', 'wowo', 'zus', 'chunk', 'mix'];

CT? _lPick(CT Function() make, bool Function(CT) ok) {
  CT? t;
  for (var i = 0; i < 70; i++) {
    t = make();
    if (ok(t)) return t;
  }
  return t;
}

/// One task of a cases lesson.
Task caseLessonTask(String id, Random r, Progress p, Set<String> used) {
  if (id == 'chunk') return chunkTask(r);
  final cl = (_d['CL'] as List).cast<Map<String, dynamic>>().firstWhere((l) => l['id'] == id);
  final mode = cl['mode'] as String;
  CT make() {
    final x = r.nextDouble();
    return switch (id) {
      'role' => x < .65 ? genArt(r, p, used) : genPron(r),
      'akk' || 'dat' || 'zus' => id == 'zus' ? genPrep(r, p, used) : genArt(r, p, used),
      'pron' => genPron(r),
      'pakk' => x < .6 ? genArt(r, p, used) : genPron(r),
      'pdat' =>
        x < .4
            ? genArt(r, p, used)
            : x < .65
            ? genPron(r)
            : genPrep(r, p, used),
      'wowo' => genPrep(r, p, used),
      _ =>
        x < .45
            ? genArt(r, p, used)
            : x < .7
            ? genPron(r)
            : genPrep(r, p, used),
    };
  }

  bool ok(CT t) => switch (id) {
    'role' => ['subj', 'verb:akk', 'verb:dat'].contains(trigOf(t)),
    'akk' => caseOf(t) == 'akk',
    'dat' => caseOf(t) == 'dat',
    'pron' => caseOf(t) != 'nom',
    'pakk' => trigOf(t) == 'prep:akk',
    'pdat' => trigOf(t) == 'prep:dat',
    'wowo' => t.mode == 'wo' || t.mode == 'wohin',
    'zus' => !t.ans.contains(' '),
    _ => true,
  };
  final t = _lPick(make, ok)!;
  if (t.noun.isNotEmpty) used.add('n:${t.noun}');
  final c = caseOf(t), trig = trigOf(t);
  final qopt = (_d['QOPT'] as Map)[trig] as List?;
  final caseHint = ((_d['CASEHINT'] as Map)[c] ?? '') as String;
  final formNote = t.topic == 'pron' ? 'ich → mich / mir · du → dich / dir · er → ihn / ihm · sie → sie / ihr' : caseHint;
  final full = t.text.replaceFirst('___', t.ans);
  final cue = mode == 'case' ? t.cue.replaceAll(RegExp(r' · (не)?определённый артикль.*$'), '') : t.cue;
  return Task(
    'pick',
    text: mode == 'case' ? '' : t.text,
    html: mode == 'case' ? _sortSent(t) : '',
    cue: cue,
    options: opts4(r, t),
    answer: t.ans,
    why: t.why,
    full: full,
    exv: _exv(t) ?? '',
    key: t.key,
    step: CaseStep(
      c,
      trig,
      mode,
      hint: _lHint(t),
      explain: mode == 'form' ? (t.topic == 'pron' ? '<b>${_caseN[c]}</b>: $formNote' : formNote) : '${qopt != null ? qopt[2] : ''} $formNote',
    ),
  );
}

/// Ready-made pieces: im Park, zum Arzt, mit dem Bus.
Task chunkTask(Random r) {
  final c = _pick(r, _lst('CHUNK'));
  final typ = r.nextDouble() >= .7;
  if (typ)
    return Task(
      'type',
      text: c[1] as String,
      cue: 'готовый кусочек · напишите по-немецки',
      answers: [c[0] as String],
      why: c[3] as String,
      full: c[0] as String,
    );
  return Task(
    'pick',
    html: '<mark>${c[1]}</mark>',
    cue: 'готовый кусочек · выберите по-немецки',
    options: [c[0] as String, ...(c[2] as List).cast<String>()],
    answer: c[0] as String,
    why: c[3] as String,
    full: c[0] as String,
  );
}
