import 'package:flutter_test/flutter_test.dart';
import 'package:lernbik/learn/progress.dart';

void main() {
  test('rule levels move like words', () {
    final p = Progress();
    expect(p.ruleBox('r'), -1);
    p.applyRuleRun('r', false, 0);
    expect(p.ruleBox('r'), 0);
    expect(p.ruleDue('r'), true);
    p.applyRuleRun('r', true, 3);
    expect(p.ruleBox('r'), 1);
    expect(p.learned('r'), false);
    expect(p.ruleDue('r'), false);
    p.applyRuleRun('r', true, 3);
    expect(p.learned('r'), true);
    expect(levelName(p.ruleBox('r'), 'ru'), 'знаю');
    p.applyRuleRun('r', false, 0);
    expect(p.ruleBox('r'), 2); // a mistake keeps the level
    expect(p.ruleDue('r'), true);
    p.applyRuleReview({'r': true, 'q': false}, 2);
    expect(p.ruleBox('r'), 3);
    expect(p.ruleBox('q'), 0);
    p.rclean['old'] = 7; // old data: clean runs
    expect(p.ruleBox('old'), 5);
    expect(p.learnedRules, 2);
  });
}
