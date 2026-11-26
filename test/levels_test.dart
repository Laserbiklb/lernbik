import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lernbik/learn/data.dart';
import 'package:lernbik/learn/progress.dart';
import 'package:lernbik/learn/tasks.dart';
import 'package:lernbik/learn/trainers.dart';
import 'package:lernbik/learn/gen_rules.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  test('all green = known, no jump above, lapsed green back after one', () async {
    await LearnData.load();
    final p = Progress();
    registerTrainers(p);
    registerRuleGens();
    final rule = LearnData.i.rules.firstWhere((r) => Progress.ruleElements!(r.id).length >= 3);
    void run(bool clean) {
      final ts = tasksForRule(rule, 'ru', got: p.rel[rule.id]);
      p.recordElements(rule.id, [for (var i = 0; i < ts.length; i++) (elementOf(ts[i]), clean || i > 0)]);
      p.applyRuleRun(rule.id, clean, 1);
    }

    var runs = 0;
    while (!p.ruleCovered(rule.id) && runs < 30) {
      expect(p.ruleBox(rule.id), lessThan(ruleLearnedBox));
      run(true);
      runs++;
    }
    expect(p.ruleBox(rule.id), ruleLearnedBox, reason: 'covered → known');
    // More clean runs right away (not due) don't raise the level.
    for (var i = 0; i < 5; i++) {
      run(true);
    }
    expect(p.ruleBox(rule.id), ruleLearnedBox);
    // Due again → one level up.
    p.rdue[rule.id] = 0;
    run(true);
    expect(p.ruleBox(rule.id), ruleLearnedBox + 1);
    // A lapsed green element: red, one right answer → green again.
    final e = p.rel[rule.id]!.keys.first;
    p.recordElements(rule.id, [(e, false)]);
    expect(p.rel[rule.id]![e], -2);
    p.recordElements(rule.id, [(e, true)]);
    expect(p.rel[rule.id]![e], 2);
    // A never-green red element still needs two.
    p.rel[rule.id]![e] = 0;
    p.recordElements(rule.id, [(e, false)]);
    p.recordElements(rule.id, [(e, true)]);
    expect(p.rel[rule.id]![e], 1);
  });
}
