import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:lernbik/learn/data.dart';
import 'package:lernbik/learn/exercise.dart';
import 'package:lernbik/learn/gen_cases.dart';
import 'package:lernbik/learn/gen_rules.dart';
import 'package:lernbik/learn/progress.dart';
import 'package:lernbik/learn/tasks.dart';
import 'package:lernbik/learn/trainers.dart';

void check(Task t, String where) {
  expect(t.kind, isIn(['pick', 'type', 'order', 'error']), reason: where);
  if (t.kind == 'pick' && t.step?.mode != 'case') {
    expect(t.options, contains(t.answer), reason: '$where: ${t.text}${t.html}');
    expect(t.options.toSet().length, t.options.length, reason: '$where dup options ${t.options}');
    expect(t.options.length, greaterThanOrEqualTo(2), reason: where);
  }
  if (t.kind == 'pick' && t.text.isNotEmpty) expect(t.text.contains('___'), isTrue, reason: '$where: ${t.text}');
  if (t.kind == 'order') {
    expect(t.words.length, greaterThanOrEqualTo(2), reason: where);
    expect(t.answers, isNotEmpty, reason: where);
  }
  if (t.kind == 'type') expect(t.answers.isNotEmpty || t.answer.isNotEmpty, isTrue, reason: where);
  if (t.kind == 'error') expect(t.text.split(RegExp(r'\s+')).any((w) => w.replaceAll(RegExp(r'[^\wäöüÄÖÜß]'), '') == t.wrong.replaceAll(RegExp(r'[^\wäöüÄÖÜß]'), '')), isTrue, reason: '$where: ${t.text} / ${t.wrong}');
  expect(t.text.contains('{') || t.html.contains('{'), isFalse, reason: '$where unfilled template: ${t.text}${t.html}');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('all generators make valid tasks', () async {
    await LearnData.load();
    final p = Progress();
    final r = Random(7);
    registerTrainers(p);
    registerRuleGens();
    for (final e in ruleGens.entries) {
      for (final g in e.value) {
        for (var i = 0; i < 300; i++) {
          check(g(r, 'de'), 'rule gen ${e.key}');
        }
      }
    }
    // print a sample of each
    for (final e in ruleGens.entries) {
      final t = e.value.first(r, 'ru');
      // ignore: avoid_print
      print('${e.key}: ${t.text}${t.words.join(' ')} → ${t.answer}${t.answers.join('/')} | ${t.options.join(', ')} | ${t.why}');
    }
    for (final e in topicGens.entries) {
      for (var i = 0; i < 400; i++) {
        final t = e.value.first(r, 'ru');
        check(t, e.key);
      }
    }
    for (final id in caseLessons) {
      final used = <String>{};
      for (var i = 0; i < 300; i++) {
        check(caseLessonTask(id, r, p, used), 'lesson $id');
        if (i % 8 == 0) used.clear();
      }
    }
    var withTasks = 0;
    for (final rule in LearnData.i.rules) {
      if (!hasTasks(rule)) continue;
      withTasks++;
      for (var i = 0; i < 20; i++) {
        expect(tasksForRule(rule, 'de'), isNotEmpty, reason: 'de ${rule.id}');
        for (final t in tasksForRule(rule, 'ru')) {
          check(t, 'rule ${rule.id}');
        }
      }
    }
    // ignore: avoid_print
    print('topics ${topicGens.length}, rules with tasks $withTasks of ${LearnData.i.rules.length}');
  });
}
