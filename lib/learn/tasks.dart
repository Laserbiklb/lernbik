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
  void addT(Task t) {
    if (out.length < n && seen.add(t.sig)) out.add(t);
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
  while (out.length < n && tries < n * 12) {
    tries++;
    try {
      addT(gens[_rnd.nextInt(gens.length)](_rnd, lang));
    } catch (_) {}
  }
  for (final t in qz) {
    addT(t);
  }
  out.shuffle(_rnd);
  return out;
}

/// A run of a trainer topic.
List<Task> tasksForTopic(String topic, String lang, {int n = 8}) {
  final gens = topicGens[topic] ?? const <Gen>[];
  final out = <Task>[];
  final seen = <String>{};
  var tries = 0;
  while (out.length < n && tries < n * 12 && gens.isNotEmpty) {
    tries++;
    try {
      final t = gens[_rnd.nextInt(gens.length)](_rnd, lang);
      if (seen.add(t.sig)) out.add(t);
    } catch (_) {}
  }
  return out;
}
