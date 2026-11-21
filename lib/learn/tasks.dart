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
List<Task> tasksForRule(Rule r, String lang, {int n = 6}) {
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

/// Reorders so that two tasks about the same thing don't come right after each other, where possible.
List<Task> _spread(List<Task> ts) {
  final left = [...ts], out = <Task>[];
  while (left.isNotEmpty) {
    final last = out.isEmpty ? const <String>{} : focusKeys(out.last).where((k) => !k.startsWith('full:')).toSet();
    final i = left.indexWhere((t) => !focusKeys(t).any(last.contains));
    out.add(left.removeAt(i < 0 ? 0 : i));
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
