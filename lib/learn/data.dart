import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

/// A word card. [k] (article + word) is the progress key, as in Wortkreis.
class Word {
  final String a, d, r, c, p;
  final bool own;
  final int o; // order in the textbook
  late final String k = (a.isNotEmpty ? '$a ' : '') + d;
  Word(this.a, this.d, this.r, this.c, {this.p = '', this.own = false, this.o = 1000000});

  /// "A2 · 6" → "A2"
  String get level => RegExp(r'^(A[12]) · ').firstMatch(c)?.group(1) ?? '';
  int get chapterNo => int.tryParse(c.split(' · ').last) ?? 0;
}

class Chapter {
  final String lv;
  final int n;
  final String title;
  final List<Rule> rules;
  Chapter(this.lv, this.n, this.title, this.rules);
  String get id => '$lv · $n';
}

/// A grammar rule of a textbook chapter. Texts are keyed by language (de/ru/en).
class Rule {
  final String id; // "A2.6.1"
  final Map<String, String> title;
  final String ex;
  final Map<String, String> body; // small HTML
  final List<List<String>> trainers; // [["verbs","refl"], …]
  late Chapter chapter;
  Rule(this.id, this.title, this.ex, this.body, this.trainers);

  String t(String lang) => _pick(title, lang).replaceAll(RegExp(r'<[^>]+>'), '');
  String b(String lang) => _pick(body, lang);
}

String _pick(Map<String, String> m, String lang) => m[lang] ?? m['de'] ?? m['ru'] ?? m.values.first;

class LearnData {
  final List<Word> words;
  final Map<String, List<Chapter>> book;
  final Map<String, List<String>> quiz;
  final Map<String, dynamic> tr; // trainer data (cases, verbs, adjectives) from Wortkreis
  LearnData(this.words, this.book, this.quiz, this.tr);

  static LearnData? _i;
  static LearnData get i => _i!;
  static bool get loaded => _i != null;

  static Future<LearnData> load() async {
    if (_i != null) return _i!;
    final w = jsonDecode(await rootBundle.loadString('assets/learn/words.json')) as List;
    final words = <Word>[];
    for (var i = 0; i < w.length; i++) {
      final x = (w[i] as List).cast<String>();
      words.add(Word(x[0], x[1], x[2], x[3], p: x.length > 4 ? x[4] : '', o: i));
    }
    final b = jsonDecode(await rootBundle.loadString('assets/learn/book.json')) as Map<String, dynamic>;
    final book = <String, List<Chapter>>{};
    for (final lv in ['A1', 'A2']) {
      book[lv] = [
        for (final c in (b[lv] as List).cast<Map<String, dynamic>>())
          () {
            final rules = [
              for (final r in (c['r'] as List).cast<Map<String, dynamic>>())
                Rule(r['id'] as String, Map<String, String>.from(r['t'] as Map), r['ex'] as String, Map<String, String>.from(r['b'] as Map), [
                  for (final t in (r['tr'] as List)) (t as List).cast<String>(),
                ]),
            ];
            final ch = Chapter(lv, c['n'] as int, c['t'] as String, rules);
            for (final r in rules) {
              r.chapter = ch;
            }
            return ch;
          }(),
      ];
    }
    final q = jsonDecode(await rootBundle.loadString('assets/learn/quiz.json')) as Map<String, dynamic>;
    final quiz = {for (final e in q.entries) e.key: (e.value as List).cast<String>()};
    final tr = jsonDecode(await rootBundle.loadString('assets/learn/trainers.json')) as Map<String, dynamic>;
    return _i = LearnData(words, book, quiz, tr);
  }

  Chapter? chapter(String lv, int n) {
    for (final c in book[lv] ?? const <Chapter>[]) {
      if (c.n == n) return c;
    }
    return null;
  }

  Iterable<Rule> get rules sync* {
    for (final lv in ['A1', 'A2']) {
      for (final c in book[lv]!) {
        yield* c.rules;
      }
    }
  }

  Rule? rule(String id) {
    for (final r in rules) {
      if (r.id == id) return r;
    }
    return null;
  }
}
