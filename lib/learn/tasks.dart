import 'dart:math';

import 'data.dart';
import 'exercise.dart';

/// A generator makes one fresh random task in the given UI language (for the "why" line).
typedef Gen = Task Function(Random r, String lang);

/// Generators per rule id ("A2.6.1") and per trainer topic ("verbs:refl", "cases:akk").
final ruleGens = <String, List<Gen>>{};
final topicGens = <String, List<Gen>>{};

final _rnd = Random();

List<Gen> gensFor(Rule r) => [...?ruleGens[r.id], for (final t in r.trainers) ...?topicGens['${t[0]}:${t[1]}']];

bool hasTasks(Rule r) => gensFor(r).isNotEmpty || (LearnData.i.quiz[r.id]?.isNotEmpty ?? false);


/// A run for a rule: mostly freshly generated tasks, mixed with the handwritten ones.
/// [got]: what was already mastered in this rule (Progress.rel); not-yet-mastered elements come first.
List<Task> tasksForRule(Rule r, String lang, {int n = 6, Map<String, int>? got}) {
  final gens = gensFor(r);
  // Handwritten tasks explain in Russian; in German/English only the generated ones are used.
  final cyr = RegExp('[а-яА-ЯёЁ]');
  final qz = [
    for (final s in LearnData.i.quiz[r.id] ?? const <String>[])
      if (lang == 'ru' || !cyr.hasMatch(s)) Task.qz(s)
  ]..shuffle(_rnd);
  final out = <Task>[];
  final seen = <String>{};
  final per = <String, int>{};
  void addT(Task t, {bool force = false}) {
    if (out.length >= n || seen.contains(t.sig)) return;
    final ks = focusKeys(t);
    if (!force && !_fits(ks, per)) return;
    seen.add(t.sig);
    for (final k in ks) {
      per[k] = (per[k] ?? 0) + 1;
    }
    out.add(t);
  }

  if (gens.isEmpty) {
    qz.forEach(addT);
    return out;
  }
  // Up to a third handwritten, the rest generated.
  final fromQz = qz.isEmpty ? 0 : max(1, n ~/ 3);
  for (final t in qz.take(fromQz)) {
    addT(t);
  }
  // What hasn't been mastered yet first (missed ones, then new ones); one place stays for the rest.
  final els = elementsOf(r.id);
  if (got != null && els.isNotEmpty) {
    final open = els.keys.where((e) => (got[e] ?? 0) < 2).toSet();
    final room = open.length < els.length ? n - 1 : n;
    for (final wantMissed in [true, false]) {
      final want = wantMissed ? open.where((e) => (got[e] ?? 0) < 0).toSet() : open;
      var t2 = 0;
      while (out.length < room && want.isNotEmpty && t2 < n * 40) {
        t2++;
        try {
          final t = gens[_rnd.nextInt(gens.length)](_rnd, lang);
          if (want.contains(elementOf(t))) addT(t);
        } catch (_) {}
      }
    }
  }
  var tries = 0;
  while (out.length < n && tries < n * 30) {
    tries++;
    try {
      addT(gens[_rnd.nextInt(gens.length)](_rnd, lang));
    } catch (_) {}
  }
  for (final t in qz) {
    addT(t);
  }
  // Too few different tasks for this rule: fill up anyway (spread out below).
  tries = 0;
  while (out.length < n && tries < n * 20) {
    tries++;
    try {
      addT(gens[_rnd.nextInt(gens.length)](_rnd, lang), force: true);
    } catch (_) {}
  }
  out.shuffle(_rnd);
  return _spread(out);
}

/// A run of a trainer topic.
List<Task> tasksForTopic(String topic, String lang, {int n = 8}) {
  final gens = topicGens[topic] ?? const <Gen>[];
  final out = <Task>[];
  final seen = <String>{};
  final per = <String, int>{};
  var tries = 0;
  while (out.length < n && tries < n * 30 && gens.isNotEmpty) {
    tries++;
    try {
      final t = gens[_rnd.nextInt(gens.length)](_rnd, lang);
      final ks = focusKeys(t);
      if (!_fits(ks, per) || !seen.add(t.sig)) continue;
      for (final k in ks) {
        per[k] = (per[k] ?? 0) + 1;
      }
      out.add(t);
    } catch (_) {}
  }
  // A topic about only one or two combinations (freuen auf / über) can't vary more: fill up anyway.
  tries = 0;
  while (out.length < n && tries < n * 20 && gens.isNotEmpty) {
    tries++;
    try {
      final t = gens[_rnd.nextInt(gens.length)](_rnd, lang);
      if (seen.add(t.sig)) out.add(t);
    } catch (_) {}
  }
  return _spread(out);
}

/// Reorders a run: never three tasks of the same format in a row (choose / write / order / find
/// the mistake), where the run has other formats; and two tasks about the same thing not right
/// after each other, where possible.
List<Task> _spread(List<Task> ts) {
  final left = [...ts], out = <Task>[];
  while (left.isNotEmpty) {
    final last = out.isEmpty ? const <String>{} : focusKeys(out.last).where((k) => !k.startsWith('full:')).toSet();
    // The format that would make three in a row.
    final banned = out.length >= 2 && out[out.length - 1].kind == out[out.length - 2].kind ? out.last.kind : null;
    final remaining = <String, int>{};
    for (final t in left) {
      remaining[t.kind] = (remaining[t.kind] ?? 0) + 1;
    }
    int score(Task t) =>
        (t.kind == banned ? -1000 : 0) + // the hard rule
        remaining[t.kind]! * 10 + // use up the most common format first, so it doesn't pile up at the end
        (focusKeys(t).any(last.contains) ? -5 : 0) +
        (out.isNotEmpty && out.last.kind == t.kind ? -3 : 0);
    var best = 0;
    for (var i = 1; i < left.length; i++) {
      if (score(left[i]) > score(left[best])) best = i;
    }
    out.add(left.removeAt(best));
  }
  return out;
}

/// At most this many tasks about the same thing (e.g. "sich freuen über", "Frau Müller") in one run;
/// the very same sentence only once.
const maxSameFocus = 2;

bool _fits(List<String> ks, Map<String, int> per) => ks.every((k) => (per[k] ?? 0) < (k.startsWith('full:') ? 1 : maxSameFocus));

List<String>? _vpInf;

String _plain(String s) => s.replaceAll(RegExp('<[^>]*>'), '').replaceAll(RegExp(r'\s+'), ' ').trim();

const _notNouns = {'Sie', 'Ihnen', 'Ihr', 'Ihre', 'Ihren', 'Ihrem', 'Ihrer', 'Ja', 'Nein', 'Doch'};

/// What a task is about, for variety in a run: the verb + preposition it practises
/// (sich freuen über), the nouns and names in its sentence (Problem, Frau Müller), and the sentence itself.
List<String> focusKeys(Task t) {
  _vpInf ??= [
    for (final v in (LearnData.i.trs['ru']!['VP'] as List? ?? const [])) '${(v as Map)['inf']}',
  ]..sort((a, b) => b.length.compareTo(a.length));
  final keys = <String>[];
  final txt = '${t.why} ${t.an} ${t.full}';
  for (final inf in _vpInf!) {
    if (txt.contains(inf)) {
      keys.add('vp:$inf');
      break;
    }
  }
  final sentence = _plain(t.full.isNotEmpty ? t.full : '${t.text} ${t.html}');
  if (sentence.isNotEmpty) keys.add('full:${sentence.toLowerCase().replaceAll(RegExp(r'[^a-zäöüß ]'), '')}');
  // The sentence pattern with its nouns, names and numbers taken out ("Das ist ein _. Das _ ist neu."),
  // so that one pattern doesn't fill the whole run.
  final words = sentence.split(RegExp(r'\s+'));
  final tpl = [
    for (var i = 0; i < words.length; i++)
      i > 0 && RegExp('^[A-ZÄÖÜ0-9]').hasMatch(words[i]) && !RegExp(r'[.!?:—–]$').hasMatch(words[i - 1]) && words[i - 1] != '—'
          ? '_'
          : words[i].toLowerCase(),
  ].join(' ');
  if (words.length >= 3) keys.add('tpl:$tpl');
  // Capitalised words that don't start a sentence: nouns and names.
  for (var i = 1; i < words.length; i++) {
    if (RegExp(r'[.!?:—–]$').hasMatch(words[i - 1]) || words[i - 1] == '—') continue;
    final w = words[i].replaceAll(RegExp(r'[^A-Za-zÄÖÜäöüß-]'), '');
    if (w.length >= 3 && RegExp('^[A-ZÄÖÜ]').hasMatch(w) && !_notNouns.contains(w)) keys.add('n:$w');
  }
  return keys;
}

/// Kept for the test: the verb + preposition, or else the sentence.
String focusOf(Task t) => focusKeys(t).firstWhere((k) => k.startsWith('vp:'), orElse: () => focusKeys(t).first);

// ---------- what a rule consists of ----------

/// The element of a rule a task practises: the verb + preposition, else the kind of task
/// (e.g. "a:akk:m" = article, Akkusativ, masculine), else its answer.
String elementOf(Task t) {
  for (final k in focusKeys(t)) {
    if (k.startsWith('vp:')) return k;
  }
  if (t.key.isNotEmpty) return 'k:${t.key.split(':').take(3).join(':')}';
  final a = t.answer.isNotEmpty ? t.answer : t.answers.join(' / ');
  return 'a:${a.toLowerCase()}';
}

final _elCache = <String, Map<String, String>>{};

/// The elements of a rule with a short label each, found by trying its generators (always the same
/// for a rule): the common ones, at most 16.
Map<String, String> elementsOf(String ruleId) {
  final hit = _elCache[ruleId];
  if (hit != null) return hit;
  final rule = LearnData.i.rule(ruleId);
  final gens = rule == null ? const <Gen>[] : gensFor(rule);
  final count = <String, int>{};
  final answers = <String, Map<String, int>>{};
  if (gens.isNotEmpty) {
    var seed = 7;
    for (final c in ruleId.codeUnits) {
      seed = (seed * 31 + c) & 0x3fffffff;
    }
    final r = Random(seed);
    for (var i = 0; i < 400; i++) {
      try {
        final t = gens[r.nextInt(gens.length)](r, 'de');
        final e = elementOf(t);
        count[e] = (count[e] ?? 0) + 1;
        final a = t.answer.isNotEmpty ? t.answer : t.answers.join(' / ');
        (answers[e] ??= {})[a] = (answers[e]![a] ?? 0) + 1;
      } catch (_) {}
    }
  }
  // Tasks that only differ by their (very varied) answer — dates, spelled words, whole sentences —
  // have no useful parts to cover: such a rule goes by its level alone.
  if (count.keys.where((k) => k.startsWith('a:')).length > 50) return _elCache[ruleId] = const {};
  final keys = count.keys.where((k) => count[k]! >= 6).toList()..sort((a, b) => count[b]!.compareTo(count[a]!));
  // Only what the rule itself shows (its text and example), so it can be coloured right there.
  final text = rule == null ? '' : '${rule.b('de')} ${rule.b('ru')} ${rule.ex}'.replaceAll(RegExp('<[^>]*>'), ' ');
  final out = <String, String>{};
  for (final k in keys) {
    final label = _label(k, answers[k] ?? const {});
    final word = elementWord(label);
    // Whole sentences aren't parts of a rule; words and short phrases (sich freuen über) are.
    if (word.length >= 2 && word.split(' ').length <= 3 && wordIn(word, text)) out[k] = label;
    if (out.length >= 16) break;
  }
  return _elCache[ruleId] = out.length >= 2 ? out : const {};
}

/// The word(s) of an element as they stand in the rule text ("dem · Dat m" → "dem", "um … zu" → "um").
String elementWord(String label) => label.split(' · ').first.trim();

RegExp wordRe(String w) => RegExp('(?<![A-Za-zÄÖÜäöüß])${RegExp.escape(w)}(?![A-Za-zÄÖÜäöüß])', caseSensitive: false);

bool wordIn(String w, String text) => wordRe(w).hasMatch(text);

const _caseShort = {'nom': 'Nom', 'akk': 'Akk', 'dat': 'Dat', 'gen': 'Gen'};
const _orderNames = {
  'v2': 'Verb auf Platz 2',
  'wq': 'W-Frage',
  'yn': 'Ja/Nein-Frage',
  'mod': 'Modalverb',
  'sub': 'weil / dass',
  'ind': 'indirekte Frage',
  'sep': 'trennbares Verb',
  'pf': 'Perfekt',
};

String _label(String k, Map<String, int> answers) {
  if (k.startsWith('vp:')) return k.substring(3);
  final top = answers.isEmpty ? '' : (answers.entries.toList()..sort((a, b) => b.value.compareTo(a.value))).first.key;
  if (k.startsWith('a:')) return k.substring(2);
  final p = k.substring(2).split(':');
  if (p.length >= 3 && p[0] == 'v' && p[1] == 'o') return _orderNames[p[2]] ?? top;
  final cs = p.map((x) => _caseShort[x]).whereType<String>().toList();
  final g = p.where((x) => const {'m', 'f', 'n', 'pl'}.contains(x)).toList();
  return cs.isEmpty ? top : '$top · ${cs.first}${g.isEmpty ? '' : ' ${g.first}'}';
}
