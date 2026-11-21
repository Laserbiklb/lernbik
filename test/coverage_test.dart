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

  test('never three tasks of one format in a row (when the run has other formats)', () async {
    var bad = 0, total = 0;
    final runs = [
      for (final r in LearnData.i.rules) () => tasksForRule(r, 'ru'),
      for (final t in trainers)
        for (final tp in t.topics) () => tasksForTopic(tp.id, 'ru', n: tp.n),
    ];
    for (final make in runs) {
      for (var i = 0; i < 30; i++) {
        final ts = make();
        final kinds = ts.map((t) => t.kind).toList();
        final counts = <String, int>{};
        for (final k in kinds) {
          counts[k] = (counts[k] ?? 0) + 1;
        }
        // Possible only if the most common format isn't more than twice the others + 2.
        final most = counts.values.fold(0, (a, b) => a > b ? a : b);
        if (most > 2 * (kinds.length - most) + 2) continue;
        total++;
        for (var j = 2; j < kinds.length; j++) {
          if (kinds[j] == kinds[j - 1] && kinds[j] == kinds[j - 2]) {
            bad++;
            break;
          }
        }
      }
    }
    expect(bad, 0, reason: '$bad of $total runs');
  });
}
