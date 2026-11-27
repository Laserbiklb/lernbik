import 'package:flutter_test/flutter_test.dart';
import 'package:lernbik/learn/data.dart';
import 'package:lernbik/learn/pieces.dart';
import 'package:flutter/widgets.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  test('pieces', () async {
    for (final w in ['Krankenhaus', 'Wie heißen Sie?', 'einkaufen', 'Schrank', 'Entschuldigung', 'Abend', 'Zucker', 'Lehrerin', 'Bahnhof', 'Guten Morgen!', 'E-Mail', 'Kühlschrank', 'Straßenbahnhaltestelle', 'wie']) {
      final p = pieces(w);
      print('$w → ${p.map((x) => x.trim()).join(' · ')}');
      expect(p.join(), w);
    }
    await LearnData.load();
    var long = 0, one = 0;
    for (final w in LearnData.i.words) {
      final p = pieces(w.d.split('/').first.trim());
      expect(p.join(), w.d.split('/').first.trim());
      for (final x in p) {
        if (x.trim().length > 6) long++;
      }
      if (p.length == 1) one++;
    }
    print('pieces >6 letters: $long, one-piece words: $one of ${LearnData.i.words.length}');
  });
}
