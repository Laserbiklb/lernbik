import 'dart:math';
import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

/// A word card. [k] (article + word) is the progress key, as in Wortkreis.
class Word {
  final String a, d, ru, c, p;
  final String? en;
  final bool own;
  final int o; // order in the textbook
  late final String k = (a.isNotEmpty ? '$a ' : '') + d;
  Word(this.a, this.d, this.ru, this.c, {this.p = '', this.en, this.own = false, this.o = 1000000});

  /// The app language; set by the store. In German there is no built-in translation
  /// (the games that need one are skipped and words get a Google Translate button).
  static String lang = 'ru';

  /// The translation in the app language: Russian, English, or none for German.
  /// Own words keep what the user typed.
  String get r => own ? ru : (lang == 'de' ? '' : (lang == 'en' ? (en ?? ru) : ru));
  bool get hasTr => r.isNotEmpty;

  /// "A2 · 6" → "A2"
  String get level => RegExp(r'^(A[12]) · ').firstMatch(c)?.group(1) ?? '';
  int get chapterNo => int.tryParse(c.split(' · ').last) ?? 0;

  /// How hard a new word is, for the order within a chapter: words that look like their English
  /// translation come first (das Hotel, die Pizza), then shorter before longer.
  late final int ease = (looksEnglish(d, en) ? 0 : 1000) + _letters(d);

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

/// A text in the app language (German, Russian, English), for the trainers' generated tasks.
String tl(String de, String ru, String en) => Word.lang == 'de' ? de : (Word.lang == 'en' ? en : ru);

String _pick(Map<String, String> m, String lang) => m[lang] ?? m['de'] ?? m['ru'] ?? m.values.first;

class LearnData {
  final List<Word> words;
  final Map<String, List<Chapter>> book;
  final Map<String, List<String>> quiz;

  /// Trainer data (cases, verbs, adjectives) from Wortkreis, per language: ru (original), de, en.
  final Map<String, Map<String, dynamic>> trs;
  LearnData(this.words, this.book, this.quiz, this.trs);

  /// Trainer data in the app language.
  Map<String, dynamic> get tr => trs[Word.lang] ?? trs['ru']!;

  static LearnData? _i;
  static LearnData get i => _i!;
  static bool get loaded => _i != null;

  static Future<LearnData> load() async {
    if (_i != null) return _i!;
    final w = jsonDecode(await rootBundle.loadString('assets/learn/words.json')) as List;
    final en = (jsonDecode(await rootBundle.loadString('assets/learn/words_en.json')) as Map).cast<String, String>();
    final words = <Word>[];
    for (var i = 0; i < w.length; i++) {
      final x = (w[i] as List).cast<String>();
      words.add(Word(x[0], x[1], x[2], x[3], p: x.length > 4 ? x[4] : '', en: en['${x[0]} ${x[1]}'.trim()], o: i));
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
    final trs = {
      for (final (l, f) in [('ru', 'trainers'), ('de', 'trainers_de'), ('en', 'trainers_en')])
        l: jsonDecode(await rootBundle.loadString('assets/learn/$f.json')) as Map<String, dynamic>,
    };
    return _i = LearnData(words, book, quiz, trs);
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


String _fold(String s) => s
    .toLowerCase()
    .replaceAll('ä', 'a')
    .replaceAll('ö', 'o')
    .replaceAll('ü', 'u')
    .replaceAll('ß', 'ss')
    .replaceAll(RegExp('[^a-z]'), '');

int _letters(String s) => _fold(s).length;

int _lev(String a, String b) {
  var prev = List<int>.generate(b.length + 1, (i) => i);
  for (var i = 1; i <= a.length; i++) {
    final cur = List<int>.filled(b.length + 1, 0)..[0] = i;
    for (var j = 1; j <= b.length; j++) {
      cur[j] = [prev[j] + 1, cur[j - 1] + 1, prev[j - 1] + (a[i - 1] == b[j - 1] ? 0 : 1)].reduce(min);
    }
    prev = cur;
  }
  return prev[b.length];
}

/// Whether a German word looks like (one of) its English translations: Hotel/hotel, Banane/banana, Tomate/tomato.
bool looksEnglish(String de, String? en) {
  if (en == null || en.isEmpty) return false;
  final g = _fold(de.split(' / ').first);
  if (g.length < 3) return false;
  for (var e in en.split(RegExp(r'[,/;]'))) {
    e = e.replaceAll(RegExp(r'\(.*?\)'), '').trim().replaceFirst(RegExp(r'^(to|the|a|an) '), '');
    final f = _fold(e);
    if (f.length < 3) continue;
    if (f == g) return true;
    final d = _lev(g, f);
    if (g.length >= 4 && d <= (g.length >= 7 ? 2 : 1)) return true;
  }
  return false;
}

String _stem(Word w) => _fold(w.d.split(' / ').first);
String _tr(String s) => s.toLowerCase().replaceAll(RegExp(r'\(.*?\)'), '').replaceAll(RegExp('[^a-zа-яё ]'), '').trim();

/// Words that are easy to mix up and shouldn't meet in one round: the same translation, one inside
/// the other (Lehrer / Lehrerin, Haus / Hausaufgabe), a long common start (Kindergarten / Kinderzimmer)
/// or only a letter or two apart (Tasche / Tasse).
bool similarWords(Word a, Word b) {
  if (a.k == b.k) return true;
  final ra = _tr(a.ru), rb = _tr(b.ru);
  if (ra.isNotEmpty && ra == rb) return true;
  if (a.en != null && b.en != null && _tr(a.en!) == _tr(b.en!)) return true;
  final x = _stem(a), y = _stem(b);
  if (x.length < 3 || y.length < 3) return false;
  final short = x.length <= y.length ? x : y, long = x.length <= y.length ? y : x;
  if (short.length >= 4 && long.contains(short)) return true;
  var p = 0;
  while (p < short.length && x[p] == y[p]) {
    p++;
  }
  if (p >= 6) return true;
  // Compounds with the same last part: Heimwerkerkurs / Schauspielkurs, Kinderzimmer / Wohnzimmer.
  if (a.a.isNotEmpty && b.a.isNotEmpty && _sameTail(x, y)) return true;
  return (long.length - short.length) <= 2 && _lev(x, y) <= (short.length <= 4 ? 1 : 2);
}

const _suffixes = ['schaft', 'ismus', 'heit', 'keit', 'erin', 'erei', 'tion', 'chen', 'lein', 'ling', 'ität', 'ung', 'ion', 'nis', 'tum', 'sal', 'ent', 'ant', 'enz', 'anz', 'ei', 'ur', 'ik', 'in', 'er', 'el', 'en', 'ie', 'e'];

/// Whether two nouns end in the same word part (at least 3 letters besides a plain suffix like -ung, -er).
bool _sameTail(String x, String y) {
  var n = 0;
  while (n < x.length && n < y.length && x[x.length - 1 - n] == y[y.length - 1 - n]) {
    n++;
  }
  if (n < 4) return false;
  var tail = x.substring(x.length - n);
  for (final sfx in _suffixes) {
    if (tail.endsWith(sfx)) {
      tail = tail.substring(0, tail.length - sfx.length);
      break;
    }
  }
  return tail.length >= 3;
}
