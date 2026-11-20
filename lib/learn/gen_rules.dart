// Generators for textbook rules: every call builds a fresh task from word lists and templates,
// so the five clean runs are not just the same sentences again.
import 'dart:math';

import 'data.dart';
import 'exercise.dart';
import 'gen_cases.dart' show cap;
import 'tasks.dart';

T _p<T>(Random r, List<T> a) => a[r.nextInt(a.length)];
String _w(String lang, String de, String ru, String en) => lang == 'ru' ? ru : (lang == 'en' ? en : de);

// ---------------- persons and verbs ----------------

/// (pronoun, form index 0…5, ru, en)
const _pers = [
  ('ich', 0, 'я', 'I'),
  ('du', 1, 'ты', 'you'),
  ('er', 2, 'он', 'he'),
  ('sie', 2, 'она', 'she'),
  ('wir', 3, 'мы', 'we'),
  ('ihr', 4, 'вы (друзья)', 'you all'),
  ('sie', 5, 'они', 'they'),
  ('Sie', 5, 'Вы (вежливо)', 'you (polite)'),
];
const _names = [('Anna', 2), ('Tom', 2), ('Maria', 2), ('Omar', 2), ('Herr Krause', 2), ('Frau Müller', 2), ('Anna und Tom', 5), ('Die Kinder', 5)];

/// Present tense of a regular verb: ich, du, er, wir, ihr, sie.
List<String> conj(String inf) {
  final stem = inf.substring(0, inf.length - 2);
  final e = RegExp(r'(t|d|chn|ffn|tm|gn)$').hasMatch(stem);
  final s = RegExp(r'(s|ß|z|x)$').hasMatch(stem);
  return ['${stem}e', stem + (e ? 'est' : s ? 't' : 'st'), stem + (e ? 'et' : 't'), inf, stem + (e ? 'et' : 't'), inf];
}

/// Regular verbs with a fitting rest of the sentence.
const _regular = [
  ('kommen', 'aus Polen'),
  ('wohnen', 'in Lüneburg'),
  ('lernen', 'jeden Tag Deutsch'),
  ('arbeiten', 'in einer Bäckerei'),
  ('spielen', 'gern Fußball'),
  ('kochen', 'heute Suppe'),
  ('machen', 'die Hausaufgaben'),
  ('hören', 'gern Musik'),
  ('kaufen', 'Brot und Milch'),
  ('trinken', 'morgens Kaffee'),
  ('gehen', 'nach Hause'),
  ('schreiben', 'eine E-Mail'),
  ('tanzen', 'am Samstag'),
  ('reisen', 'nach Italien'),
  ('warten', 'auf den Bus'),
  ('antworten', 'sofort'),
  ('finden', 'den Film gut'),
  ('öffnen', 'das Fenster'),
  ('suchen', 'eine Wohnung'),
  ('brauchen', 'einen Termin'),
  ('fragen', 'die Lehrerin'),
  ('bezahlen', 'mit Karte'),
  ('besuchen', 'die Oma'),
  ('verstehen', 'die Frage'),
];

/// Verbs that change their vowel: inf, du, er, rest.
const _vowel = [
  ('lesen', 'liest', 'liest', 'ein Buch'),
  ('sehen', 'siehst', 'sieht', 'einen Film'),
  ('sprechen', 'sprichst', 'spricht', 'gut Deutsch'),
  ('essen', 'isst', 'isst', 'gern Fisch'),
  ('nehmen', 'nimmst', 'nimmt', 'den Bus'),
  ('geben', 'gibst', 'gibt', 'mir das Buch'),
  ('helfen', 'hilfst', 'hilft', 'der Nachbarin'),
  ('treffen', 'triffst', 'trifft', 'Freunde'),
  ('fahren', 'fährst', 'fährt', 'nach Berlin'),
  ('schlafen', 'schläfst', 'schläft', 'lange'),
  ('laufen', 'läufst', 'läuft', 'jeden Morgen'),
  ('tragen', 'trägst', 'trägt', 'eine Jacke'),
  ('waschen', 'wäschst', 'wäscht', 'das Auto'),
  ('vergessen', 'vergisst', 'vergisst', 'den Schlüssel'),
];

/// Irregular tables: ich, du, er, wir, ihr, sie.
const _tables = {
  'sein': ['bin', 'bist', 'ist', 'sind', 'seid', 'sind'],
  'haben': ['habe', 'hast', 'hat', 'haben', 'habt', 'haben'],
  'können': ['kann', 'kannst', 'kann', 'können', 'könnt', 'können'],
  'müssen': ['muss', 'musst', 'muss', 'müssen', 'müsst', 'müssen'],
  'wollen': ['will', 'willst', 'will', 'wollen', 'wollt', 'wollen'],
  'sollen': ['soll', 'sollst', 'soll', 'sollen', 'sollt', 'sollen'],
  'dürfen': ['darf', 'darfst', 'darf', 'dürfen', 'dürft', 'dürfen'],
  'mögen': ['mag', 'magst', 'mag', 'mögen', 'mögt', 'mögen'],
  'möchten': ['möchte', 'möchtest', 'möchte', 'möchten', 'möchtet', 'möchten'],
  'wissen': ['weiß', 'weißt', 'weiß', 'wissen', 'wisst', 'wissen'],
  'lassen': ['lasse', 'lässt', 'lässt', 'lassen', 'lasst', 'lassen'],
  'war': ['war', 'warst', 'war', 'waren', 'wart', 'waren'],
  'hatte': ['hatte', 'hattest', 'hatte', 'hatten', 'hattet', 'hatten'],
  'sollte': ['sollte', 'solltest', 'sollte', 'sollten', 'solltet', 'sollten'],
  'würde': ['würde', 'würdest', 'würde', 'würden', 'würdet', 'würden'],
  'konnte': ['konnte', 'konntest', 'konnte', 'konnten', 'konntet', 'konnten'],
  'musste': ['musste', 'musstest', 'musste', 'mussten', 'musstet', 'mussten'],
  'wollte': ['wollte', 'wolltest', 'wollte', 'wollten', 'wolltet', 'wollten'],
  'durfte': ['durfte', 'durftest', 'durfte', 'durften', 'durftet', 'durften'],
  'gehen': ['gehe', 'gehst', 'geht', 'gehen', 'geht', 'gehen'],
};

List<String> _others(List<String> forms, String ans, [int n = 2]) {
  final o = forms.where((f) => f != ans).toSet().toList()..shuffle();
  return o.take(n).toList();
}

/// "Ich ___ …" with a person; returns subject text, form index and a cue.
(String, int, String) _subj(Random r, String lang, {bool names = true, bool polite = true}) {
  if (names && r.nextDouble() < .3) {
    final n = _p(r, _names);
    return (n.$1, n.$2, '');
  }
  final ps = _pers.where((p) => polite || p.$1 != 'Sie').toList();
  final p = _p(r, ps);
  final cue = p.$1 == 'sie'
      ? '(${_w(lang, p.$2 == 2 ? 'sie = eine Frau' : 'sie = mehrere Personen', p.$3, p.$4)})'
      : p.$1 == 'Sie'
          ? '(${_w(lang, 'Sie = höflich', p.$3, p.$4)})'
          : '';
  return (p.$1, p.$2, cue);
}

/// A gap for a verb form in a template "{S} ___ {rest}."
Task _verbGap(Random r, String lang, List<String> forms, String rest, {String why = '', bool names = true, bool polite = true, String cue = ''}) {
  final (s, i, sc) = _subj(r, lang, names: names, polite: polite);
  final ans = forms[i];
  final text = '${cap(s)} ___ $rest.';
  return Task.gap(text, ans, _others(forms, ans), why.isNotEmpty ? why : '$s → $ans',
      cue: [sc, cue].where((x) => x.isNotEmpty).join(' '), full: text.replaceFirst('___', ans));
}

// ---------------- nouns ----------------

/// Everyday nouns with gender and plural (for articles, kein, plural, pronouns).
const _nouns = [
  ('Tisch', 'm', 'Tische'), ('Stuhl', 'm', 'Stühle'), ('Schrank', 'm', 'Schränke'), ('Kühlschrank', 'm', 'Kühlschränke'),
  ('Balkon', 'm', 'Balkone'), ('Fernseher', 'm', 'Fernseher'), ('Computer', 'm', 'Computer'), ('Teppich', 'm', 'Teppiche'),
  ('Schlüssel', 'm', 'Schlüssel'), ('Kuli', 'm', 'Kulis'), ('Rucksack', 'm', 'Rucksäcke'), ('Apfel', 'm', 'Äpfel'),
  ('Garten', 'm', 'Gärten'), ('Laptop', 'm', 'Laptops'), ('Spiegel', 'm', 'Spiegel'), ('Herd', 'm', 'Herde'),
  ('Lampe', 'f', 'Lampen'), ('Tasche', 'f', 'Taschen'), ('Küche', 'f', 'Küchen'), ('Wohnung', 'f', 'Wohnungen'),
  ('Uhr', 'f', 'Uhren'), ('Jacke', 'f', 'Jacken'), ('Tasse', 'f', 'Tassen'), ('Flasche', 'f', 'Flaschen'),
  ('Waschmaschine', 'f', 'Waschmaschinen'), ('Dusche', 'f', 'Duschen'), ('Brille', 'f', 'Brillen'), ('Zeitung', 'f', 'Zeitungen'),
  ('Pflanze', 'f', 'Pflanzen'), ('Tür', 'f', 'Türen'), ('Badewanne', 'f', 'Badewannen'), ('Kamera', 'f', 'Kameras'),
  ('Bett', 'n', 'Betten'), ('Sofa', 'n', 'Sofas'), ('Buch', 'n', 'Bücher'), ('Handy', 'n', 'Handys'),
  ('Fahrrad', 'n', 'Fahrräder'), ('Regal', 'n', 'Regale'), ('Bild', 'n', 'Bilder'), ('Fenster', 'n', 'Fenster'),
  ('Auto', 'n', 'Autos'), ('Bad', 'n', 'Bäder'), ('Zimmer', 'n', 'Zimmer'), ('Glas', 'n', 'Gläser'),
  ('Heft', 'n', 'Hefte'), ('Kleid', 'n', 'Kleider'), ('Radio', 'n', 'Radios'), ('Haus', 'n', 'Häuser'),
];
const _family = [
  ('Bruder', 'm'), ('Vater', 'm'), ('Sohn', 'm'), ('Onkel', 'm'), ('Opa', 'm'), ('Mann', 'm'), ('Freund', 'm'), ('Chef', 'm'),
  ('Schwester', 'f'), ('Mutter', 'f'), ('Tochter', 'f'), ('Tante', 'f'), ('Oma', 'f'), ('Frau', 'f'), ('Freundin', 'f'), ('Lehrerin', 'f'),
  ('Kind', 'n'), ('Baby', 'n'),
];
const _art = {'m': 'der', 'f': 'die', 'n': 'das'};

String _artAll(String g) => _art[g]!;

// ---------------- generators per rule ----------------

final _gens = <String, List<Gen>>{
  // Alphabet: recognise a spelled word.
  'A1.1.0': [
    (r, lang) {
      final ws = LearnData.i.words.where((w) => w.c == 'A1 · 1' || w.c == 'A1 · 2').map((w) => w.d).where((d) => RegExp(r'^[A-Za-zÄÖÜäöüß]{3,9}$').hasMatch(d)).toList();
      final w = _p(r, ws);
      final sim = (ws.where((x) => x != w && x.length >= w.length - 1 && x.length <= w.length + 1 && x[0].toLowerCase() == w[0].toLowerCase()).toList()..shuffle(r));
      final pool = sim.length >= 2 ? sim : (ws.where((x) => x != w).toList()..shuffle(r));
      final spelled = w.split('').join('-');
      return Task.gap('Wie schreibt man das? — $spelled. Das Wort heißt ___.', w, pool.take(2).toList(), '$spelled = $w');
    },
  ],
  // W-questions.
  'A1.1.2': [(r, lang) => _wq(r, lang)],
  'A1.2.3': [(r, lang) => _wq(r, lang)],
  // Present tense: ich, du, wir, ihr, Sie / er, sie, es, sie.
  'A1.1.3': [
    (r, lang) {
      final v = _p(r, _regular);
      final f = conj(v.$1);
      return _verbGap(r, lang, f, v.$2, names: false);
    },
    (r, lang) => _verbGap(r, lang, _tables['sein']!, _p(r, ['aus der Ukraine', 'in Lüneburg', 'Lehrerin', 'müde', 'zu Hause']), names: false),
  ],
  'A1.2.0': [
    (r, lang) {
      final v = _p(r, _regular);
      final f = conj(v.$1);
      final n = _p(r, _names);
      final ans = f[n.$2];
      final text = '${n.$1} ___ ${v.$2}.';
      return Task.gap(text, ans, _others(f, ans), '${n.$2 == 2 ? 'er/sie' : 'sie (Plural)'} → $ans', full: text.replaceFirst('___', ans));
    },
    (r, lang) {
      final v = _p(r, _vowel);
      final n = _p(r, _names.where((x) => x.$2 == 2).toList());
      final text = '${n.$1} ___ ${v.$4}.';
      return Task.gap(text, v.$3, [v.$1, '${v.$1.substring(0, v.$1.length - 2)}t'], '${v.$1}: er/sie ${v.$3}', cue: '(${v.$1})', full: text.replaceFirst('___', v.$3));
    },
  ],
  // du or Sie.
  'A1.1.4': [
    (r, lang) {
      final formal = r.nextBool();
      final who = formal ? _p(r, ['Frau Müller', 'Herr Klein', 'Frau Doktor Weber', 'Herr Schmidt']) : _p(r, ['Tom', 'Anna', 'Mama', 'Lisa']);
      final v = _p(r, [('kommen', 'woher'), ('wohnen', 'wo'), ('heißen', 'wie'), ('arbeiten', 'wo')]);
      final f = conj(v.$1);
      final verb = formal ? f[5] : f[1];
      final text = '$who, ${v.$2} $verb ___?';
      return Task.gap(text, formal ? 'Sie' : 'du', [formal ? 'du' : 'Sie', 'ihr'],
          formal ? _w(lang, 'Fremde Erwachsene: Sie', 'Незнакомому взрослому — Sie', 'A stranger: Sie') : _w(lang, 'Freunde, Familie: du', 'Друзьям, в семье — du', 'Friends, family: du'),
          full: text.replaceFirst('___', formal ? 'Sie' : 'du'));
    },
    (r, lang) {
      final formal = r.nextBool();
      final who = formal ? _p(r, ['Frau Müller', 'Herr Klein', 'Herr Schmidt']) : _p(r, ['Tom', 'Anna', 'Lisa']);
      final v = _p(r, [('sprechen', 'Englisch', 'sprichst', 'spricht'), ('lernen', 'Deutsch', 'lernst', 'lernt'), ('trinken', 'Kaffee', 'trinkst', 'trinkt'), ('haben', 'Zeit', 'hast', 'hat')]);
      final ans = formal ? v.$1 : v.$3;
      final text = '$who, ___ ${formal ? 'Sie' : 'du'} ${v.$2}?';
      return Task.gap(cap(text), ans, [formal ? v.$3 : v.$1, v.$4],
          formal ? 'Sie → ${v.$1}' : 'du → ${v.$3}', full: text.replaceFirst('___', ans));
    },
  ],
  // Articles: der / ein.
  'A1.2.1': [
    (r, lang) {
      final n = _p(r, _nouns);
      final ind = {'m': 'ein', 'f': 'eine', 'n': 'ein'}[n.$2]!;
      final text = 'Das ist ___ ${n.$1}.';
      return Task.gap(text, ind, [ind == 'ein' ? 'eine' : 'ein', _art[n.$2]!], '${_art[n.$2]} ${n.$1} → $ind ${n.$1}', full: text.replaceFirst('___', ind));
    },
    (r, lang) {
      final n = _p(r, _nouns);
      final ind = {'m': 'ein', 'f': 'eine', 'n': 'ein'}[n.$2]!;
      final text = 'Das ist $ind ${n.$1}. ___ ${n.$1} ist neu.';
      final d = cap(_art[n.$2]!);
      return Task.gap(text, d, ['Der', 'Die', 'Das'].where((x) => x != d).toList(),
          _w(lang, 'Schon bekannt → bestimmter Artikel: ${_art[n.$2]} ${n.$1}', 'Уже известно → der/die/das: ${_art[n.$2]} ${n.$1}', 'Already known → definite article: ${_art[n.$2]} ${n.$1}'),
          full: text.replaceFirst('___', d));
    },
  ],
  // Plural.
  'A1.2.2': [
    (r, lang) {
      final n = _p(r, _nouns.where((x) => x.$3 != x.$1).toList());
      final num = _p(r, ['zwei', 'drei', 'vier', 'viele']);
      final wrong = <String>{'${n.$1}s', '${n.$1}en', '${n.$1}e', '${n.$1}er', '${n.$1}n'}..remove(n.$3);
      final ind = {'m': 'ein', 'f': 'eine', 'n': 'ein'}[n.$2]!;
      return Task.gap('$ind ${n.$1} — $num ___', n.$3, (wrong.toList()..shuffle(r)).take(2).toList(), '${_art[n.$2]} ${n.$1} → die ${n.$3}');
    },
  ],
  // Yes/no questions: verb first.
  'A1.3.0': [
    (r, lang) {
      final v = _p(r, [..._regular.take(12), ('haben', 'einen Balkon')]);
      final f = v.$1 == 'haben' ? _tables['haben']! : conj(v.$1);
      final p = _p(r, [('du', 1), ('ihr', 4), ('Sie', 5)]);
      return Task.order('${cap(f[p.$2])} ${p.$1} ${v.$2}?', _w(lang, 'Ja/Nein-Frage: das Verb steht vorne.', 'Вопрос без W-слова: глагол первым.', 'Yes/no question: the verb comes first.'));
    },
    (r, lang) {
      final n = _p(r, _nouns);
      final adj = _p(r, ['groß', 'neu', 'teuer', 'modern', 'hell', 'klein']);
      final text = '___ ${_art[n.$2]} ${n.$1} $adj?';
      return Task.gap(text, 'Ist', ['Hat', 'Sind'], _w(lang, 'Verb vorne, er/sie/es → ist', 'Глагол первым, он/она/оно → ist', 'Verb first, er/sie/es → ist'), full: text.replaceFirst('___', 'Ist'));
    },
  ],
  // kein.
  'A1.3.2': [
    (r, lang) {
      final n = _p(r, _nouns);
      final k = {'m': 'keinen', 'f': 'keine', 'n': 'kein'}[n.$2]!;
      final text = '${_p(r, ['Ich habe', 'Wir haben', 'Die Wohnung hat', 'Ich brauche'])} ___ ${n.$1}.';
      return Task.gap(text, k, ['kein', 'keine', 'keinen'].where((x) => x != k).toList(), '${_art[n.$2]} ${n.$1}, Akk → $k', full: text.replaceFirst('___', k));
    },
    (r, lang) {
      final a = _p(r, _nouns), b = _p(r, _nouns.where((x) => x.$1 != a.$1).toList());
      final k = {'m': 'kein', 'f': 'keine', 'n': 'kein'}[a.$2]!;
      final ib = {'m': 'ein', 'f': 'eine', 'n': 'ein'}[b.$2]!;
      final text = 'Das ist ___ ${a.$1}, das ist $ib ${b.$1}.';
      return Task.gap(text, k, ['kein', 'keine', 'keinen'].where((x) => x != k).toList(), '${_art[a.$2]} ${a.$1} → $k', full: text.replaceFirst('___', k));
    },
  ],
  // der → er.
  'A1.3.3': [
    (r, lang) {
      final n = _p(r, _nouns);
      final pr = {'m': 'Er', 'f': 'Sie', 'n': 'Es'}[n.$2]!;
      final a = _p(r, ['neu', 'alt', 'klein', 'schön', 'teuer']), b = _p(r, ['praktisch', 'super', 'leider kaputt', 'sehr schön']);
      final text = '${cap(_art[n.$2]!)} ${n.$1} ist $a. ___ ist $b.';
      return Task.gap(text, pr, ['Er', 'Sie', 'Es'].where((x) => x != pr).toList(), '${_art[n.$2]} ${n.$1} → ${pr.toLowerCase()}', full: text.replaceFirst('___', pr));
    },
  ],
  // Possessives.
  'A1.4.0': [
    (r, lang) {
      final p = _p(r, _pers.where((x) => x.$1 != 'Sie').toList());
      final base = {'ich': 'mein', 'du': 'dein', 'er': 'sein', 'sie': p.$2 == 2 ? 'ihr' : 'ihr', 'wir': 'unser', 'ihr': 'euer'}[p.$1]!;
      final n = _p(r, _family.where((x) => x.$2 != 'n').toList());
      final ans = n.$2 == 'f' ? (base == 'euer' ? 'eure' : '${base}e') : base;
      final text = _p(r, ['Das ist ___ ${n.$1}.', 'Wie heißt ___ ${n.$1}?', '___ ${n.$1} wohnt in Berlin.']);
      final a = text.startsWith('___') ? cap(ans) : ans;
      final wrong = [n.$2 == 'f' ? base : (base == 'euer' ? 'eure' : '${base}e'), base == 'mein' ? 'dein' : 'mein'];
      return Task.gap(text, a, wrong.map((x) => text.startsWith('___') ? cap(x) : x).toList(), '${p.$1} → $base; ${_art[n.$2]} ${n.$1} → $ans',
          cue: '(${_w(lang, p.$1, p.$3, p.$4)})', full: text.replaceFirst('___', a));
    },
  ],
  // Vowel change.
  'A1.4.2': [
    (r, lang) {
      final v = _p(r, _vowel);
      final du = r.nextBool();
      final s = du ? 'du' : _p(r, ['er', 'sie', 'Anna', 'Mein Bruder']);
      final ans = du ? v.$2 : v.$3;
      final text = du ? 'Wann ___ du ${v.$4}?' : '$s ___ ${v.$4}.';
      final reg = conj(v.$1);
      return Task.gap(cap(text), ans, [du ? reg[1] : reg[2], du ? v.$3 : v.$2].where((x) => x != ans).toList(), '${v.$1}: du ${v.$2}, er ${v.$3}',
          cue: '(${v.$1})', full: text.replaceFirst('___', ans));
    },
  ],
  // Präteritum war / hatte.
  'A1.4.3': [
    (r, lang) {
      final sein = r.nextBool();
      final rest = sein ? _p(r, ['gestern in Hamburg', 'am Wochenende zu Hause', 'letzte Woche krank', 'früher Lehrerin']) : _p(r, ['gestern keine Zeit', 'letzte Woche Urlaub', 'früher ein Auto', 'am Montag einen Termin']);
      return _verbGap(r, lang, _tables[sein ? 'war' : 'hatte']!, rest, names: false, cue: '(${sein ? 'sein' : 'haben'})',
          why: '${sein ? 'sein' : 'haben'} → ${sein ? 'war' : 'hatte'}');
    },
  ],
  // gehen + infinitive.
  'A1.5.1': [
    (r, lang) {
      final (s, i, _) = _subj(r, lang, names: false, polite: false);
      final time = _p(r, ['heute', 'am Sonntag', 'morgen', 'am Abend']);
      final inf = _p(r, ['einkaufen', 'schwimmen', 'spazieren', 'tanzen', 'essen', 'joggen']);
      return Task.order('${cap(s)} ${_tables['gehen']![i]} $time $inf.',
          _w(lang, 'gehen auf Platz 2, das zweite Verb am Ende.', 'gehen на 2-м месте, второй глагол в конце.', 'gehen in 2nd place, the second verb at the end.'));
    },
  ],
  // möchten / mögen.
  'A1.6.1': [
    (r, lang) {
      final now = r.nextBool();
      final (s, i, sc) = _subj(r, lang, names: false);
      final forms = _tables[now ? 'möchten' : 'mögen']!;
      final ans = forms[i];
      final rest = now ? _p(r, ['einen Kaffee, bitte', 'ein Stück Kuchen', 'jetzt nach Hause', 'eine Pizza bestellen']) : _p(r, ['Schokolade', 'keine Tomaten', 'Hunde', 'Rockmusik']);
      final text = '${cap(s)} ___ $rest.';
      final other = _tables[now ? 'mögen' : 'möchten']![i];
      return Task.gap(text, ans, [other, forms[i == 0 ? 3 : 0]].where((x) => x != ans).toList(),
          now ? _w(lang, 'Jetzt, höflich → möchten', 'Хочу сейчас, вежливо → möchten', 'Want now, politely → möchten') : _w(lang, 'Allgemein gern → mögen', 'Люблю вообще → mögen', 'Like in general → mögen'),
          cue: '$sc ${now ? _w(lang, '(jetzt)', '(сейчас)', '(now)') : _w(lang, '(allgemein)', '(вообще)', '(in general)')}'.trim(), full: text.replaceFirst('___', ans));
    },
  ],
  // gern / nicht gern / lieber.
  'A1.6.2': [
    (r, lang) {
      final k = r.nextInt(3);
      final act = _p(r, [('esse', 'Fisch'), ('trinke', 'Tee'), ('spiele', 'Fußball'), ('lese', 'Bücher'), ('koche', 'am Wochenende'), ('fahre', 'Fahrrad')]);
      final ans = ['gern', 'nicht gern', 'lieber'][k];
      final cue = [_w(lang, '(mag ich)', '(люблю)', '(I like it)'), _w(lang, '(mag ich nicht)', '(не люблю)', '(I don\'t like it)'), _w(lang, '(mehr als Kaffee)', '(больше, чем другое)', '(more than the other)')][k];
      final text = 'Ich ${act.$1} ___ ${act.$2}.';
      return Task.gap(text, ans, ['gern', 'nicht gern', 'lieber', 'gut'].where((x) => x != ans).take(2).toList(),
          '$ans = ${[_w(lang, 'mag ich', 'люблю', 'I like'), _w(lang, 'mag ich nicht', 'не люблю', 'I don\'t like'), _w(lang, 'mag ich mehr', 'больше нравится', 'I prefer')][k]}',
          cue: cue, full: text.replaceFirst('___', ans));
    },
  ],
  // man.
  'A1.6.3': [
    (r, lang) {
      final v = _p(r, [
        ('isst', 'In Deutschland ___ man oft Brot.', ['essen', 'esst']),
        ('sagt', 'Wie ___ man das auf Deutsch?', ['sagen', 'sagst']),
        ('darf', 'Hier ___ man nicht rauchen.', ['dürfen', 'darfst']),
        ('kann', 'Im Park ___ man Fußball spielen.', ['können', 'kannst']),
        ('schreibt', 'Wie ___ man das?', ['schreiben', 'schreibst']),
        ('muss', 'In der Bibliothek ___ man leise sein.', ['müssen', 'musst']),
        ('spricht', 'In Österreich ___ man Deutsch.', ['sprechen', 'sprichst']),
        ('braucht', 'Für das Konto ___ man einen Ausweis.', ['brauchen', 'brauchst']),
        ('fährt', 'Zum Bahnhof ___ man mit dem Bus Nummer 5.', ['fahren', 'fährst']),
        ('bezahlt', 'Hier ___ man an der Kasse.', ['bezahlen', 'bezahlst']),
      ]);
      return Task.gap(v.$2, v.$1, v.$3, 'man → wie er/sie/es: man ${v.$1}', full: v.$2.replaceFirst('___', v.$1));
    },
  ],
  // Modal verbs: word order.
  'A1.7.0': [
    (r, lang) {
      final m = _p(r, ['können', 'müssen', 'wollen']);
      final (s, i, _) = _subj(r, lang, names: false, polite: false);
      final c = _p(r, [('heute', 'arbeiten'), ('gut', 'kochen'), ('Arzt', 'werden'), ('morgen früh', 'aufstehen'), ('Deutsch', 'lernen'), ('am Samstag', 'kommen')]);
      final q = r.nextDouble() < .3;
      final f = _tables[m]![i];
      final sent = q ? '${cap(f)} $s ${c.$1} ${c.$2}?' : '${cap(s)} $f ${c.$1} ${c.$2}.';
      return Task.order(sent, _w(lang, 'Modalverb auf Platz 2 (Frage: vorne), Infinitiv am Ende.', 'Модальный на 2-м месте (в вопросе — первым), инфинитив в конце.',
          'Modal verb in 2nd place (question: first), infinitive at the end.'));
    },
    (r, lang) => _verbGap(r, lang, _tables[_p(r, ['können', 'müssen', 'wollen'])]!, _p(r, ['heute lange arbeiten', 'gut schwimmen', 'nach Hause gehen']), names: false),
  ],
  'A1.8.0': [
    (r, lang) => _verbGap(r, lang, _tables['sollen']!, _p(r, ['viel Wasser trinken', 'im Bett bleiben', 'die Übung machen', 'um acht kommen', 'den Arzt anrufen']),
        names: false, why: _w(lang, 'sollen: jemand anderes sagt es', 'sollen: так сказал кто-то другой', 'sollen: someone else says so')),
  ],
  'A1.9.2': [
    (r, lang) => _verbGap(r, lang, _tables['dürfen']!, _p(r, ['hier nicht parken', 'das Fenster öffnen', 'heute länger bleiben', 'hier fotografieren']),
        names: false, why: _w(lang, 'dürfen = Erlaubnis', 'dürfen = разрешено', 'dürfen = allowed')),
  ],
  // Perfekt: haben or sein.
  'A1.10.0': [(r, lang) => _perfekt(r, lang)],
  'A2.1.0': [(r, lang) => _perfekt(r, lang)],
  'A2.1.1': [
    (r, lang) {
      final v = _p(r, [
        ('studieren', 'studiert'), ('telefonieren', 'telefoniert'), ('reparieren', 'repariert'), ('fotografieren', 'fotografiert'), ('passieren', 'passiert'),
        ('besuchen', 'besucht'), ('bezahlen', 'bezahlt'), ('bekommen', 'bekommen'), ('verstehen', 'verstanden'), ('vergessen', 'vergessen'),
        ('verkaufen', 'verkauft'), ('erzählen', 'erzählt'), ('erklären', 'erklärt'), ('entschuldigen', 'entschuldigt'), ('gehören', 'gehört'), ('beginnen', 'begonnen'),
        ('verlassen', 'verlassen'), ('erleben', 'erlebt'),
      ]);
      return Task.gap('${v.$1} → ___', v.$2, ['ge${v.$2}', v.$1 == v.$2 ? '${v.$1.substring(0, v.$1.length - 2)}t' : v.$1],
          _w(lang, '-ieren, be-, ver-, er-, ent-, ge- → ohne ge-', '-ieren, be-, ver-, er-, ent-, ge- → без ge-', '-ieren, be-, ver-, er-, ent-, ge- → no ge-'));
    },
  ],
  // seit + Dativ.
  'A1.10.2': [
    (r, lang) {
      final t = _p(r, [('einem', 'Jahr', ['ein', 'einen']), ('einer', 'Woche', ['eine', 'einen']), ('einem', 'Monat', ['einen', 'ein']), ('zwei', 'Jahren', ['Jahre', 'Jahr']), ('drei', 'Monaten', ['Monate', 'Monat']), ('vier', 'Wochen', ['Woche', 'Wochens'])]);
      final act = _p(r, ['wohne ich in Lüneburg', 'lerne ich Deutsch', 'arbeite ich hier', 'habe ich ein Auto']);
      final plural = int.tryParse(t.$1) != null || ['zwei', 'drei', 'vier'].contains(t.$1);
      if (plural) {
        final text = 'Seit ${t.$1} ___ $act.';
        return Task.gap(text, t.$2, t.$3, 'seit + Dativ, Plural → -n: ${t.$2}', full: text.replaceFirst('___', t.$2));
      }
      final text = 'Seit ___ ${t.$2} $act.';
      return Task.gap(text, t.$1, t.$3, 'seit + Dativ: ${t.$1} ${t.$2}', full: text.replaceFirst('___', t.$1));
    },
  ],
  // Dates.
  'A1.11.1': [(r, lang) => _date(r, lang)],
  'A2.7.0': [(r, lang) => _date(r, lang)],
  // welch-.
  'A1.12.1': [
    (r, lang) {
      final n = _p(r, _nouns);
      final akk = r.nextBool();
      final ans = akk ? {'m': 'Welchen', 'f': 'Welche', 'n': 'Welches'}[n.$2]! : {'m': 'Welcher', 'f': 'Welche', 'n': 'Welches'}[n.$2]!;
      final text = akk ? '___ ${n.$1} kaufst du?' : '___ ${n.$1} gefällt dir?';
      return Task.gap(text, ans, ['Welcher', 'Welche', 'Welches', 'Welchen'].where((x) => x != ans).take(2).toList(),
          '${_art[n.$2]} ${n.$1}, ${akk ? 'Akk' : 'Nom'} → ${ans.toLowerCase()}', full: text.replaceFirst('___', ans));
    },
  ],
  // Compounds.
  'A1.12.2': [(r, lang) => _komp(r, lang)],
  'A2.13.1': [(r, lang) => _komp(r, lang)],
  // es.
  'A1.13.0': [
    (r, lang) {
      if (r.nextBool()) {
        final w = _p(r, ['regnet heute', 'schneit', 'ist kalt', 'ist schon spät', 'geht mir gut', 'ist zehn Uhr']);
        return Task.gap('___ $w.', 'Es', ['Er', 'Das'], _w(lang, 'Wetter, Zeit, Befinden → es', 'Погода, время, самочувствие → es', 'Weather, time, how you are → es'));
      }
      final n = _p(r, _nouns);
      final ans = {'m': 'einen', 'f': 'eine', 'n': 'ein'}[n.$2]!;
      final text = 'Hier gibt es ___ ${n.$1}.';
      return Task.gap(text, ans, ['einen', 'eine', 'ein', 'einem'].where((x) => x != ans).take(2).toList(), 'es gibt + Akk: ${_art[n.$2]} ${n.$1} → $ans ${n.$1}',
          full: text.replaceFirst('___', ans));
    },
  ],
  // Comparative.
  'A1.13.2': [
    (r, lang) {
      final a = _p(r, [
        ('groß', 'größer', 'Berlin', 'Lüneburg'), ('alt', 'älter', 'Mein Opa', 'mein Vater'), ('jung', 'jünger', 'Meine Schwester', 'ich'),
        ('teuer', 'teurer', 'Das Auto', 'das Fahrrad'), ('schnell', 'schneller', 'Der Zug', 'der Bus'), ('warm', 'wärmer', 'Der Sommer', 'der Winter'),
        ('kalt', 'kälter', 'Der Winter', 'der Herbst'), ('klein', 'kleiner', 'Mein Zimmer', 'dein Zimmer'), ('lang', 'länger', 'Der Rhein', 'die Elbe'),
        ('billig', 'billiger', 'Der Markt', 'der Supermarkt'), ('gut', 'besser', 'Dein Deutsch', 'mein Deutsch'),
      ]);
      if (r.nextDouble() < .35) {
        final text = '${a.$3} ist genauso ${a.$1} ___ ${a.$4}.';
        return Task.gap(text, 'wie', ['als', 'so'], 'genauso … wie', full: text.replaceFirst('___', 'wie'));
      }
      if (r.nextBool()) {
        final text = '${a.$3} ist ${a.$2} ___ ${a.$4}.';
        return Task.gap(text, 'als', ['wie', 'dann'], '-er + als', full: text.replaceFirst('___', 'als'));
      }
      final text = '${a.$3} ist ___ als ${a.$4}.';
      return Task.gap(text, a.$2, ['mehr ${a.$1}', a.$1 == 'gut' ? 'guter' : '${a.$1}er'].where((x) => x != a.$2).toList(), '${a.$1} → ${a.$2}', cue: '(${a.$1})',
          full: text.replaceFirst('___', a.$2));
    },
  ],
  // Possessives with cases.
  'A2.1.2': [
    (r, lang) {
      final base = _p(r, ['mein', 'dein', 'sein', 'ihr', 'unser']);
      final n = _p(r, _family);
      final dat = r.nextDouble() < .6;
      final prep = dat ? _p(r, ['mit', 'bei', 'von']) : 'für';
      final end = dat ? {'m': 'em', 'f': 'er', 'n': 'em'}[n.$2]! : {'m': 'en', 'f': 'e', 'n': ''}[n.$2]!;
      final ans = base + end;
      final verb = {'mit': 'Ich spreche mit', 'bei': 'Ich wohne bei', 'von': 'Das Geschenk ist von', 'für': 'Das Geschenk ist für'}[prep]!;
      final text = '$verb ___ ${n.$1}.';
      final wrong = ['$base${dat ? 'en' : 'em'}', '${base}e', base, '${base}er'].where((x) => x != ans).toList()..shuffle(r);
      return Task.gap(text, ans, wrong.take(2).toList(), '$prep + ${dat ? 'Dat' : 'Akk'}, ${_art[n.$2]} ${n.$1} → $ans', full: text.replaceFirst('___', ans));
    },
  ],
  // ja / nein / doch.
  'A2.3.1': [
    (r, lang) {
      final q = _p(r, [
        ('Hast du Zeit?', 'Hast du keine Zeit?', 'ich habe Zeit', 'ich habe keine Zeit'),
        ('Kommst du mit?', 'Kommst du nicht mit?', 'ich komme mit', 'ich komme nicht mit'),
        ('Hast du Hunger?', 'Hast du keinen Hunger?', 'ich habe Hunger', 'ich habe keinen Hunger'),
        ('Ist das dein Handy?', 'Ist das nicht dein Handy?', 'das ist mein Handy', 'das ist nicht mein Handy'),
        ('Gehst du zum Kurs?', 'Gehst du nicht zum Kurs?', 'ich gehe zum Kurs', 'ich gehe nicht zum Kurs'),
        ('Hast du Geschwister?', 'Hast du keine Geschwister?', 'ich habe Geschwister', 'ich habe keine Geschwister'),
        ('Magst du Kaffee?', 'Magst du keinen Kaffee?', 'ich mag Kaffee', 'ich mag keinen Kaffee'),
      ]);
      final neg = r.nextBool(), yes = r.nextBool();
      final ans = yes ? (neg ? 'Doch' : 'Ja') : 'Nein';
      final text = '${neg ? q.$2 : q.$1} — ___, ${yes ? q.$3 : q.$4}.';
      final why = neg && yes
          ? _w(lang, 'Ja auf eine Frage mit nicht/kein → doch', '«Да» на вопрос с nicht/kein → doch', 'Yes to a question with nicht/kein → doch')
          : yes
              ? _w(lang, 'Normale Frage, Antwort ja → ja', 'Обычный вопрос, ответ «да» → ja', 'Normal question, answer yes → ja')
              : _w(lang, 'Antwort nein → nein', 'Ответ «нет» → nein', 'Answer no → nein');
      return Task.gap(text, ans, ['Ja', 'Nein', 'Doch'].where((x) => x != ans).toList(), why, full: text.replaceFirst('___', ans));
    },
  ],
  // Modals in the past.
  'A2.4.1': [
    (r, lang) {
      final m = _p(r, ['konnte', 'musste', 'wollte', 'durfte']);
      final rest = {
        'konnte': ['als Kind gut singen', 'gestern nicht kommen', 'früher kein Deutsch'],
        'musste': ['früher eine Uniform tragen', 'gestern lange arbeiten', 'zum Arzt gehen'],
        'wollte': ['Lehrerin werden', 'früher in Berlin wohnen', 'Pilot werden'],
        'durfte': ['als Kind nicht lange fernsehen', 'gestern früher gehen', 'nicht rauchen'],
      }[m]!;
      return _verbGap(r, lang, _tables[m]!, _p(r, rest), names: false,
          why: '${{'konnte': 'können', 'musste': 'müssen', 'wollte': 'wollen', 'durfte': 'dürfen'}[m]} → $m (${_w(lang, 'ohne Umlaut', 'без умлаута', 'no umlaut')})');
    },
  ],
  // Indirect questions.
  'A2.5.0': [
    (r, lang) {
      final c = _p(r, _indirect);
      return Task.order('${_p(r, ['Wissen Sie,', 'Können Sie mir sagen,', 'Weißt du,'])} ${c.$1} ${c.$2} ${c.$3}?',
          _w(lang, 'Indirekte Frage: das Verb steht am Ende.', 'Косвенный вопрос: глагол в конце.', 'Indirect question: the verb goes to the end.'));
    },
    (r, lang) {
      final c = _p(r, _indirect);
      final text = 'Wissen Sie, ${c.$1} ${c.$2} ___?';
      return Task.gap(text, c.$3, [c.$4, '${c.$3} es'].where((x) => x != c.$3).take(2).toList(),
          _w(lang, 'Verb am Ende', 'Глагол в конце', 'Verb at the end'), full: text.replaceFirst('___', c.$3));
    },
  ],
  // wissen.
  'A2.5.1': [
    (r, lang) => _verbGap(r, lang, _tables['wissen']!, _p(r, ['die Antwort', 'es nicht', 'das schon', 'nicht, wo Tom wohnt']), names: true),
  ],
  // dies-.
  'A2.5.3': [
    (r, lang) {
      final n = _p(r, _nouns);
      final akk = r.nextBool();
      final ans = akk ? {'m': 'diesen', 'f': 'diese', 'n': 'dieses'}[n.$2]! : {'m': 'Dieser', 'f': 'Diese', 'n': 'Dieses'}[n.$2]!;
      final text = akk ? 'Ich nehme ___ ${n.$1}.' : '___ ${n.$1} ist kaputt.';
      final pool = akk ? ['diesen', 'diese', 'dieses', 'diesem', 'dieser'] : ['Dieser', 'Diese', 'Dieses'];
      return Task.gap(text, ans, pool.where((x) => x != ans).take(2).toList(), '${_art[n.$2]} ${n.$1}, ${akk ? 'Akk' : 'Nom'} → ${ans.toLowerCase()}',
          full: text.replaceFirst('___', ans));
    },
  ],
  // lassen.
  'A2.6.0': [
    (r, lang) => _verbGap(r, lang, _tables['lassen']!, _p(r, ['das Auto reparieren', 'die Wohnung renovieren', 'die Haare schneiden', 'die Wand streichen']),
        names: true, why: _w(lang, 'lassen + Infinitiv = jemand anderes macht es', 'lassen + инфинитив = делает кто-то другой', 'lassen + infinitive = someone else does it')),
  ],
  // sollte.
  'A2.9.0': [
    (r, lang) => _verbGap(r, lang, _tables['sollte']!, _p(r, ['mehr schlafen', 'weniger Zucker essen', 'jeden Tag spazieren gehen', 'mehr Wasser trinken', 'zum Arzt gehen']),
        names: false, why: _w(lang, 'Ratschlag: sollte + Infinitiv', 'Совет: sollte + инфинитив', 'Advice: sollte + infinitive')),
  ],
  // würde gern.
  'A2.10.0': [
    (r, lang) => _verbGap(r, lang, _tables['würde']!, _p(r, ['gern im Büro arbeiten', 'gern eine Ausbildung machen', 'gern ans Meer fahren', 'gern Arzt werden']),
        names: false, why: _w(lang, 'Wunsch: würde gern + Infinitiv', 'Желание: würde gern + инфинитив', 'Wish: würde gern + infinitive')),
  ],
  // ob or W-word.
  'A2.10.1': [
    (r, lang) {
      final c = _p(r, [
        ('ob', 'die Stelle noch frei ist', null), ('ob', 'er heute kommt', null), ('ob', 'der Kurs teuer ist', null), ('ob', 'ich hier parken darf', null),
        ('wann', 'der Kurs beginnt', 'когда'), ('wo', 'der Bahnhof ist', 'где'), ('wie viel', 'das kostet', 'сколько'), ('warum', 'der Zug Verspätung hat', 'почему'),
      ]);
      final text = 'Ich möchte wissen, ___ ${c.$2}.';
      final cue = c.$3 == null ? '' : '(${_w(lang, {'когда': 'wann', 'где': 'wo', 'сколько': 'wie viel', 'почему': 'warum'}[c.$3]!, c.$3!, {'когда': 'when', 'где': 'where', 'сколько': 'how much', 'почему': 'why'}[c.$3]!)})';
      return Task.gap(text, c.$1, [c.$1 == 'ob' ? 'wenn' : 'ob', 'dass'],
          c.$1 == 'ob' ? _w(lang, 'Frage ohne W-Wort → ob', 'Вопрос без W-слова → ob', 'Question without a W-word → ob') : _w(lang, 'Mit W-Wort → das W-Wort', 'Есть W-слово → оно и стоит', 'With a W-word → use it'),
          cue: cue, full: text.replaceFirst('___', c.$1));
    },
  ],
  // Relative clauses.
  'A2.11.0': [(r, lang) => _rel(r, lang, false)],
  'A2.12.0': [(r, lang) => _rel(r, lang, true)],
};

const _indirect = [
  ('wo', 'der Drucker', 'ist', 'sein'),
  ('wann', 'der Kurs', 'beginnt', 'beginnen'),
  ('wie viel', 'das Ticket', 'kostet', 'kosten'),
  ('wo', 'die Toilette', 'ist', 'sein'),
  ('wann', 'der Zug', 'kommt', 'kommen'),
  ('wie lange', 'die Bibliothek', 'geöffnet hat', 'hat geöffnet'),
  ('wer', 'hier', 'arbeitet', 'arbeiten'),
  ('wo', 'Herr Krause', 'wohnt', 'wohnen'),
];

Task _wq(Random r, String lang) {
  final name = _p(r, ['Anna', 'Tom', 'Omar', 'Maria']);
  final city = _p(r, ['Lüneburg', 'Hamburg', 'Kiew', 'Berlin']);
  final q = _p(r, [
    ('Wie', '___ heißen Sie? — Ich heiße $name.', ['Wo', 'Woher']),
    ('Woher', '___ kommen Sie? — Aus der Ukraine.', ['Wo', 'Wer']),
    ('Wo', '___ wohnst du? — In $city.', ['Woher', 'Was']),
    ('Wer', '___ ist das? — Das ist $name.', ['Wie', 'Was']),
    ('Was', '___ machst du heute? — Ich lerne Deutsch.', ['Wie', 'Wer']),
    ('Was', '___ kostet der Laptop? — 300 Euro.', ['Wie', 'Wo']),
    ('Wo', '___ liegt $city? — In Deutschland.', ['Woher', 'Was']),
    ('Wie', '___ geht es dir? — Gut, danke.', ['Was', 'Wo']),
    ('Wann', '___ beginnt der Kurs? — Um neun Uhr.', ['Wie', 'Wo']),
    ('Welche', '___ Sprachen sprichst du? — Russisch und Deutsch.', ['Was', 'Wie']),
    ('Wie alt', '___ bist du? — Ich bin 30.', ['Wie viel', 'Wann']),
    ('Wohin', '___ fährst du? — Nach $city.', ['Wo', 'Woher']),
    ('Was', '___ ist das? — Das ist ein Buch.', ['Wer', 'Wie']),
    ('Wie viel', '___ Uhr ist es? — Es ist zehn.', ['Wie alt', 'Wann']),
  ]);
  return Task.gap(q.$2, q.$1, q.$3, '${q.$1}?', full: q.$2.replaceFirst('___', q.$1));
}

Task _perfekt(Random r, String lang) {
  final v = _p(r, [
    ('gegessen', false, 'gestern Pizza'), ('gefahren', true, 'nach Hamburg'), ('geschlafen', false, 'lange'), ('gekommen', true, '2022 nach Deutschland'),
    ('gekauft', false, 'ein Fahrrad'), ('gegangen', true, 'zum Arzt'), ('gelernt', false, 'viele Wörter'), ('geflogen', true, 'nach Kiew'),
    ('gearbeitet', false, 'bis acht Uhr'), ('geblieben', true, 'zu Hause'), ('getrunken', false, 'einen Tee'), ('aufgestanden', true, 'um sechs'),
    ('kennengelernt', false, 'viele Menschen'), ('umgezogen', true, 'letztes Jahr'), ('gesehen', false, 'einen Film'), ('passiert', true, 'nichts'),
    ('studiert', false, 'in Kiew'), ('gelaufen', true, 'durch den Park'), ('geschrieben', false, 'eine E-Mail'), ('eingeschlafen', true, 'sofort'),
  ]);
  final forms = v.$2 ? _tables['sein']! : _tables['haben']!;
  final (s, i, sc) = v.$3 == 'nichts' ? ('es', 2, '') : _subj(r, lang, names: true);
  final ans = forms[i];
  final text = '${cap(s)} ___ ${v.$3} ${v.$1}.';
  return Task.gap(text, ans, [(v.$2 ? _tables['haben']! : _tables['sein']!)[i], forms[i == 2 ? 0 : 2]].where((x) => x != ans).toList(),
      v.$2 ? _w(lang, 'Bewegung / Veränderung → sein', 'Движение / изменение → sein', 'Movement / change → sein') : _w(lang, 'Die meisten Verben → haben', 'Большинство глаголов → haben', 'Most verbs → haben'),
      cue: sc, full: text.replaceFirst('___', ans));
}

const _months = ['Januar', 'Februar', 'März', 'April', 'Mai', 'Juni', 'Juli', 'August', 'September', 'Oktober', 'November', 'Dezember'];
const _ordBase = {
  1: 'erst', 2: 'zweit', 3: 'dritt', 4: 'viert', 5: 'fünft', 6: 'sechst', 7: 'siebt', 8: 'acht', 9: 'neunt', 10: 'zehnt',
  11: 'elft', 12: 'zwölft', 13: 'dreizehnt', 14: 'vierzehnt', 15: 'fünfzehnt', 16: 'sechzehnt', 17: 'siebzehnt', 18: 'achtzehnt', 19: 'neunzehnt',
};
const _ones = ['', 'ein', 'zwei', 'drei', 'vier', 'fünf', 'sechs', 'sieben', 'acht', 'neun'];

/// 1 → "erst", 24 → "vierundzwanzigst".
String ordinalStem(int n) {
  if (n < 20) return _ordBase[n]!;
  if (n == 20) return 'zwanzigst';
  if (n == 30) return 'dreißigst';
  final tens = n >= 30 ? 'dreißig' : 'zwanzig';
  return '${_ones[n % 10]}und${tens}st';
}

Task _date(Random r, String lang) {
  final n = r.nextInt(31) + 1;
  final m = _p(r, _months);
  final stem = ordinalStem(n);
  final am = r.nextBool();
  final ans = am ? '${stem}en' : '${stem}e';
  final text = am ? '${_p(r, ['Mein Geburtstag ist', 'Die Party ist', 'Der Kurs beginnt', 'Wir fahren'])} am ___ $m. ($n.)' : 'Heute ist der ___ $m. ($n.)';
  const card = ['', 'ein', 'zwei', 'drei', 'vier', 'fünf', 'sechs', 'sieben', 'acht', 'neun', 'zehn', 'elf', 'zwölf', 'dreizehn', 'vierzehn', 'fünfzehn', 'sechzehn', 'siebzehn', 'achtzehn', 'neunzehn'];
  final bad = n < 20 ? '${card[n]}${am ? 'ten' : 'te'}' : '${stem.substring(0, stem.length - 2)}t${am ? 'en' : 'e'}';
  final wrong = <String>{am ? '${stem}e' : '${stem}en', if (n != 7 && n != 8) bad, '${stem}es'}..remove(ans);
  return Task.gap(text, ans, wrong.take(2).toList(),
      '${am ? 'am + -en' : 'der + -e'}; ${n < 20 ? '1–19: -t-' : _w(lang, 'ab 20: -st-', 'с 20: -st-', 'from 20: -st-')}: $n. → ${am ? 'am' : 'der'} $ans',
      full: text.replaceFirst('___', ans).replaceAll(RegExp(r' \(\d+\.\)$'), ''));
}

const _compounds = [
  ('Kühlschrank', 'kühl', 'der Schrank', 'der'), ('Handtasche', 'die Hand', 'die Tasche', 'die'), ('Kinderzimmer', 'das Kind', 'das Zimmer', 'das'),
  ('Schreibtisch', 'schreiben', 'der Tisch', 'der'), ('Haustür', 'das Haus', 'die Tür', 'die'), ('Wohnzimmer', 'wohnen', 'das Zimmer', 'das'),
  ('Kontogebühr', 'das Konto', 'die Gebühr', 'die'), ('Geldautomat', 'das Geld', 'der Automat', 'der'), ('Krankenversicherung', 'krank', 'die Versicherung', 'die'),
  ('Bahnhof', 'die Bahn', 'der Hof', 'der'), ('Fahrkarte', 'fahren', 'die Karte', 'die'), ('Kleiderschrank', 'das Kleid', 'der Schrank', 'der'),
  ('Badezimmer', 'baden', 'das Zimmer', 'das'), ('Hausaufgabe', 'das Haus', 'die Aufgabe', 'die'), ('Apfelsaft', 'der Apfel', 'der Saft', 'der'),
  ('Tomatensuppe', 'die Tomate', 'die Suppe', 'die'), ('Kaffeetasse', 'der Kaffee', 'die Tasse', 'die'), ('Fußball', 'der Fuß', 'der Ball', 'der'),
  ('Sprachkurs', 'die Sprache', 'der Kurs', 'der'), ('Stadtplan', 'die Stadt', 'der Plan', 'der'), ('Telefonnummer', 'das Telefon', 'die Nummer', 'die'),
  ('Arbeitsplatz', 'die Arbeit', 'der Platz', 'der'), ('Kindergarten', 'das Kind', 'der Garten', 'der'), ('Mietvertrag', 'die Miete', 'der Vertrag', 'der'),
  ('Haustier', 'das Haus', 'das Tier', 'das'), ('Weinglas', 'der Wein', 'das Glas', 'das'), ('Motorrad', 'der Motor', 'das Rad', 'das'),
  ('Lebensmittel', 'das Leben', 'das Mittel', 'das'), ('Arbeitsamt', 'die Arbeit', 'das Amt', 'das'), ('Gesundheitskarte', 'die Gesundheit', 'die Karte', 'die'),
];

Task _komp(Random r, String lang) {
  final c = _p(r, _compounds);
  return Task.gap('___ ${c.$1} (${c.$2} + ${c.$3})', c.$4, ['der', 'die', 'das'].where((x) => x != c.$4).toList(),
      _w(lang, 'Der Artikel kommt vom letzten Wort: ${c.$3}', 'Артикль — от последнего слова: ${c.$3}', 'The article comes from the last word: ${c.$3}'),
      full: '${c.$4} ${c.$1}');
}

/// Relative pronouns. dat = Dativ and prepositions too.
Task _rel(Random r, String lang, bool dat) {
  final n = _p(r, [
    ('der Zug', 'm'), ('der Nachbar', 'm'), ('der Kollege', 'm'), ('der Film', 'm'), ('die Frau', 'f'), ('die Wohnung', 'f'), ('die Lehrerin', 'f'),
    ('das Buch', 'n'), ('das Kind', 'n'), ('das Restaurant', 'n'), ('die Kinder', 'p'), ('die Freunde', 'p'),
  ]);
  const nom = {'m': 'der', 'f': 'die', 'n': 'das', 'p': 'die'}, akk = {'m': 'den', 'f': 'die', 'n': 'das', 'p': 'die'}, dt = {'m': 'dem', 'f': 'der', 'n': 'dem', 'p': 'denen'};
  final pl = n.$2 == 'p';
  final head = 'Das ${pl ? 'sind' : 'ist'} ${n.$1},';
  String role, rest, ans;
  if (!dat) {
    if (r.nextBool()) {
      role = 'Nom';
      ans = nom[n.$2]!;
      rest = _p(r, pl ? ['___ hier wohnen', '___ immer helfen'] : ['___ hier ${n.$2 == 'm' && n.$1 == 'der Zug' ? 'hält' : 'ist'}', '___ mir gefällt', '___ neu ist']);
    } else {
      role = 'Akk';
      ans = akk[n.$2]!;
      rest = _p(r, ['___ ich kenne', '___ ich jeden Tag sehe', '___ wir gut finden']);
    }
  } else {
    if (r.nextBool()) {
      role = 'Dat';
      ans = dt[n.$2]!;
      rest = _p(r, ['___ ich oft helfe', '___ ich danke', '___ ich ein Geschenk gebe']);
    } else {
      final pr = _p(r, ['mit', 'von', 'bei']);
      role = '$pr + Dat';
      ans = dt[n.$2]!;
      rest = {'mit': 'mit ___ ich spreche', 'von': 'von ___ ich dir erzählt habe', 'bei': 'bei ___ ich wohne'}[pr]!;
    }
  }
  final text = '$head $rest.';
  final pool = <String>{nom[n.$2]!, akk[n.$2]!, dt[n.$2]!, 'den', 'die', 'dem', 'der', 'denen'}..remove(ans);
  final wrong = pool.toList()..shuffle(r);
  return Task.gap(text, ans, wrong.take(2).toList(), '${n.$1}, $role → $ans', full: text.replaceFirst('___', ans));
}

void registerRuleGens() {
  ruleGens.addAll(_gens);
}
