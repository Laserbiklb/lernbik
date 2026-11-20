// Adjective endings trainer (der neue / ein neuer / frischer Kaffee), ported from Wortkreis.
import 'dart:math';

import 'data.dart';
import 'exercise.dart';
import 'gen_cases.dart' show cap;
import 'progress.dart' show shuffled;

Map<String, dynamic> get _aj => LearnData.i.tr['AJ'] as Map<String, dynamic>;
T _pick<T>(Random r, List<T> a) => a[r.nextInt(a.length)];
Map<String, String> get _ajg => {'m': 'm', 'f': 'f', 'n': 'n', 'p': tl('Pl.', 'мн.', 'pl.')};
const _ajc = {'nom': 'Nominativ', 'akk': 'Akkusativ', 'dat': 'Dativ'};

String _poss(Random r, String art, String kind) {
  if (kind != 'i') return art;
  final x = r.nextDouble();
  if (x < .4) return art;
  final base = art.replaceFirst(RegExp(r'^k?ein'), '');
  return '${x < .7 ? 'mein' : 'kein'}$base';
}

/// kind: d (after der), i (after ein/kein/mein), z (no article), x (d or i).
Task adjTask(Random r, String kind) {
  if (kind == 'x') kind = r.nextBool() ? 'd' : 'i';
  final g = _pick(r, ['m', 'f', 'n', 'p']);
  final cs = _pick(r, ['nom', 'akk', 'dat']);
  final food = kind == 'z';
  final end = ((_aj['end'] as Map)[kind] as Map)[cs][g] as String;
  String adj, noun, art = '';
  if (food) {
    adj = _pick(r, (_aj['fa'] as List).cast<String>());
    noun = _pick(r, ((_aj['food'] as Map)[g] as List).cast<String>());
    if (cs == 'dat' && g == 'p' && !noun.endsWith('n')) noun += 'n';
  } else {
    adj = _pick(r, (_aj['a'] as List).cast<String>());
    final nn = _pick(r, ((_aj['n'] as Map)[g] as List).cast<List<dynamic>>());
    noun = (g == 'p' && cs == 'dat' ? nn[1] : nn[0]) as String;
    art = ((_aj['art'] as Map)[kind] as Map)[cs][g] as String;
    art = _poss(r, art, kind);
    if (kind == 'i' && g == 'p' && !RegExp(r'^(kein|mein)').hasMatch(art)) art = cs == 'dat' ? 'meinen' : 'meine';
  }
  var form = adj + end;
  final pl = g == 'p';
  final frame = food
      ? {
          'nom': ['___ ${pl ? 'sind' : 'ist'} lecker.', '___ ${pl ? 'schmecken' : 'schmeckt'} gut.'],
          'akk': ['Ich möchte ___.', 'Wir kaufen ___.'],
          'dat': ['Das Frühstück mit ___ ist toll.', 'Ich koche mit ___.'],
        }[cs]!
      : {
          'nom': ['___ ${pl ? 'sind' : 'ist'} hier.', 'Hier ${pl ? 'sind' : 'ist'} ___.'],
          'akk': ['Ich kaufe ___.', 'Siehst du ___?', 'Wir brauchen ___.'],
          'dat': ['Was machst du mit ___?', 'Ich spreche von ___.'],
        }[cs]!;
  final ph = '${art.isNotEmpty ? '$art ' : ''}___ $noun';
  var t = _pick(r, frame).replaceFirst('___', ph);
  if (t.startsWith('___')) {
    // gap first: nothing to capitalise
  } else if (t[0] == t[0].toLowerCase()) {
    t = cap(t);
  }
  var opts = [
    ...['e', 'en'].where((x) => x != end),
    ...shuffled(['er', 'es', 'em'].where((x) => x != end)),
  ].take(3).map((x) => adj + x).toList();
  if (t.startsWith('___')) {
    form = cap(form);
    opts = opts.map(cap).toList();
  }
  final why =
      '${_ajc[cs]}, ${_ajg[g]}${art.isNotEmpty ? ', ${tl('nach', 'после', 'after')} «$art»' : ', ${tl('ohne Artikel', 'без артикля', 'no article')}'} → -$end';
  return Task.gap('$t ($adj)', form, opts, why, full: t.replaceFirst('___', form));
}
