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
  void addT(Task t) {
    if (out.length >= n || seen.contains(t.sig)) return;
    final f = focusOf(t);
    if ((per[f] ?? 0) >= maxSameFocus) return;
    seen.add(t.sig);
    per[f] = (per[f] ?? 0) + 1;
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
      final f = focusOf(t);
      if ((per[f] ?? 0) >= maxSameFocus || !seen.add(t.sig)) continue;
      per[f] = (per[f] ?? 0) + 1;
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
    final last = out.isEmpty ? null : focusOf(out.last);
    final i = left.indexWhere((t) => focusOf(t) != last);
    out.add(left.removeAt(i < 0 ? 0 : i));
  }
  return out;
}

/// At most this many tasks about the same thing (e.g. "sich freuen über") in one run.
const maxSameFocus = 2;

List<String>? _vpInf;

/// What a task is about: the verb + preposition it practises (sich freuen über), or else the
/// sentence itself — so a run doesn't keep coming back to the same combination.
String focusOf(Task t) {
  _vpInf ??= [
    for (final v in (LearnData.i.trs['ru']!['VP'] as List? ?? const [])) '${(v as Map)['inf']}',
  ]..sort((a, b) => b.length.compareTo(a.length));
  final txt = '${t.why} ${t.an} ${t.full}';
  for (final inf in _vpInf!) {
    if (txt.contains(inf)) return 'vp:$inf';
  }
  return 'full:${t.full.isNotEmpty ? t.full : t.sig}';
}
