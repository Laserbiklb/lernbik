import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lernbik/learn/data.dart';
import 'package:lernbik/learn/progress.dart';
import 'package:lernbik/learn/tasks.dart';
import 'package:lernbik/learn/trainers.dart';
import 'package:lernbik/learn/gen_rules.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  test('coverage', () async {
    await LearnData.load();
    registerTrainers(Progress());
    registerRuleGens();
    final rows = <String>[];
    var worst = 0;
    for (final rule in LearnData.i.rules) {
      final p = Progress();
      var runs = 0;
      while (!p.ruleCovered(rule.id) && runs < 40) {
        final ts = tasksForRule(rule, 'ru', got: p.rel[rule.id]);
        p.recordElements(rule.id, [for (final t in ts) (elementOf(t), true)]);
        runs++;
      }
      if (runs > worst) worst = runs;
      final (m, n) = p.ruleCoverage(rule.id);
      rows.add('${rule.id} elements:$n runs:$runs covered:$m/$n');
    }
    expect(worst, lessThanOrEqualTo(20), reason: rows.join('\n'));
  });
}
