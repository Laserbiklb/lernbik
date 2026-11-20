// Verbs trainer: a port of the Wortkreis generators (sich, prepositions, questions, word order …).
import 'dart:math';

import 'data.dart';
import 'exercise.dart';
import 'gen_cases.dart' show cap;
import 'progress.dart' show shuffled;

Map<String, dynamic> get _d => LearnData.i.tr;
T _pick<T>(Random r, List<T> a) => a[r.nextInt(a.length)];
List<List<dynamic>> _lst(String k) => (_d[k] as List).cast<List<dynamic>>();
List<Map<String, dynamic>> get _vp => (_d['VP'] as List).cast<Map<String, dynamic>>();
Map<String, dynamic> _vpm(String id) => _vp.firstWhere((v) => v['id'] == id);

const _refl = ['mich', 'dich', 'sich', 'uns', 'euch', 'sich'];
const _vdef = {
  'akk': {'m': 'den', 'f': 'die', 'n': 'das'},
  'dat': {'m': 'dem', 'f': 'der', 'n': 'dem'},
  'nom': {'m': 'der', 'f': 'die', 'n': 'das'},
};
const _vind = {
  'akk': {'m': 'einen', 'f': 'eine', 'n': 'ein'},
  'dat': {'m': 'einem', 'f': 'einer', 'n': 'einem'},
  'nom': {'m': 'ein', 'f': 'eine', 'n': 'ein'},
};
const _caseRu = {'akk': 'Akkusativ', 'dat': 'Dativ'};
Map<String, String> get _gru => {
  'm': tl('maskulin', 'мужской род', 'masculine'),
  'f': tl('feminin', 'женский род', 'feminine'),
  'n': tl('neutral', 'средний род', 'neuter'),
};

/// " — meaning", left out in German where the meaning is German itself.
String _mean(Object? x) => Word.lang == 'de' || '$x'.isEmpty ? '' : ' — $x';
String get _askMarked => tl('Frag nach dem Markierten', 'Спросите о выделенном', 'Ask about the marked part');
String _qPerson(bool akk, String c) => tl(
  'Person: die Präposition bleibt + <b>${akk ? 'wen' : 'wem'}</b> ($c).',
  'О человеке: предлог остаётся + <b>${akk ? 'wen' : 'wem'}</b> ($c).',
  'Person: the preposition stays + <b>${akk ? 'wen' : 'wem'}</b> ($c).',
);
String _qThing(String p, bool vowel) =>
    tl('Sache: wo + $p = <b>${_wo[p]}</b>', 'О предмете: wo + $p = <b>${_wo[p]}</b>', 'Thing: wo + $p = <b>${_wo[p]}</b>') +
    (vowel ? tl(' (vor Vokal +r)', ' (перед гласной +r)', ' (+r before a vowel)') : '') +
    '.';
String get _pickRight => tl('Welcher Satz ist richtig?', 'Выберите правильное предложение', 'Pick the correct sentence');
String _em(Object? x) => '$x'.isEmpty ? '' : '<em>$x</em>';
String get _nothing => tl('— nichts', '— ничего', '— nothing');
Map<String, String> get _wo => (_d['WO'] as Map).cast<String, String>();
Map<String, String> get _da => (_d['DA'] as Map).cast<String, String>();

class _NP {
  final String art, np, base;
  final bool ind;
  _NP(this.art, this.np, this.base, this.ind);
}

/// Noun phrase after the preposition; never an+dem / von+dem (those contract).
_NP _vNP(Map<String, dynamic> v, Map<String, dynamic> o, bool ind) {
  if (o['u'] == true) ind = false;
  final c = v['c'] as String, g = o['g'] as String;
  if (!ind && c == 'dat' && g != 'f' && (v['p'] == 'an' || v['p'] == 'von')) ind = true;
  final art = (ind ? _vind : _vdef)[c]![g]!;
  return _NP(art, '$art ${o['n']}', '${(ind ? _vind : _vdef)['nom']![g]} ${o['n']}', ind);
}

List<dynamic> get _vsubj => _d['VSUBJ'] as List;
String _cj(Map<String, dynamic> v, int i) => (v['cj'] as List)[i] as String;

String _vSent(Map<String, dynamic> v, int si, String mid) {
  final s = _vsubj[si] as List;
  final i = s[2] as int;
  return '${cap(s[0] as String)} ${_cj(v, i)}${v['r'] == 1 ? ' ${_refl[i]}' : ''} $mid${v['sep'] != null ? ' ${v['sep']}' : ''}.';
}

List<Map<String, dynamic>> _things(Map<String, dynamic> v) => (v['o'] as List).cast<Map<String, dynamic>>().where((o) => o['h'] != true).toList();

String _analysis(Map<String, dynamic> v, int si, Map<String, dynamic>? o, _NP? np) {
  final s = _vsubj[si] as List;
  final i = s[2] as int;
  final l = <String>[];
  if (v['r'] == 1) {
    l.add(
      tl(
        '<b>Warum ${_refl[i]}?</b> Verb <i>${v['inf']}</i>, Subjekt <i>${s[0]}</i> → ${_refl[i]}.',
        '<b>Почему ${_refl[i]}?</b> Глагол <i>${v['inf']}</i>, подлежащее <i>${s[0]}</i> → ${_refl[i]}.',
        '<b>Why ${_refl[i]}?</b> Verb <i>${v['inf']}</i>, subject <i>${s[0]}</i> → ${_refl[i]}.',
      ),
    );
  } else {
    l.add(
      tl(
        '<b>Braucht man sich?</b> Nein: <i>${v['inf']}</i> steht ohne sich im Wörterbuch.',
        '<b>Нужно ли sich?</b> Нет: <i>${v['inf']}</i> записан в словаре без sich.',
        '<b>Do you need sich?</b> No: <i>${v['inf']}</i> is listed without sich.',
      ),
    );
  }
  final ce = '<i>${v['inf']} + ${v['c'] == 'akk' ? 'Akk' : 'Dat'}</i>${_mean(v['ru'])}';
  l.add(
    tl(
      '<b>Warum ${v['p']}?</b> Die Verbindung lernt man am Stück: $ce.',
      '<b>Почему ${v['p']}?</b> Сочетание учим целиком: $ce.',
      '<b>Why ${v['p']}?</b> Learn the combination as a whole: $ce.',
    ),
  );
  if (o != null && np != null) {
    l.add(
      tl(
        '<b>Warum ${np.art}?</b> ${np.base} — ${_gru[o['g']]}, nach <i>${v['p']}</i> hier ${_caseRu[v['c']]} → ${np.np}.',
        '<b>Почему ${np.art}?</b> ${np.base} — ${_gru[o['g']]}, после <i>${v['p']}</i> здесь ${_caseRu[v['c']]} → ${np.np}.',
        '<b>Why ${np.art}?</b> ${np.base} — ${_gru[o['g']]}, after <i>${v['p']}</i> here ${_caseRu[v['c']]} → ${np.np}.',
      ),
    );
  }
  if (o != null) {
    final q = o['h'] == true ? '${cap(v['p'] as String)} ${v['c'] == 'akk' ? 'wen' : 'wem'}' : cap(_wo[v['p']]!);
    l.add(
      '<b>${tl('Wie fragt man?', 'Как спросить?', 'How to ask?')}</b> $q ${_cj(v, 1)} du${v['r'] == 1 ? ' dich' : ''}${v['sep'] != null ? ' ${v['sep']}' : ''}?',
    );
    l.add('<b>${tl('Kurze Antwort?', 'Как коротко ответить?', 'Short answer?')}</b> ${cap(v['p'] as String)} ${np?.np ?? ''}.');
  }
  return l.map((x) => '<li>$x</li>').join();
}

List<String> _vOpts(String ans, List<String> pool, [int n = 4]) {
  final o = [ans];
  final seen = {ans.toLowerCase()};
  for (final x in shuffled(pool)) {
    if (o.length < n && seen.add(x.toLowerCase())) o.add(x);
  }
  return o;
}

Task _pickT(String text, String ans, List<String> opts, String cue, String why, String key, String full, {String html = '', String an = ''}) =>
    Task('pick', text: text, html: html, answer: ans, options: opts, cue: cue, why: why, key: key, full: full, an: an);

final verbGens = <String, Task Function(Random)>{
  'refl': (r) {
    final need = r.nextDouble() < .7;
    final v = _pick(r, _vp.where((x) => need ? x['r'] == 1 : x['r'] != 1).toList());
    final si = r.nextInt(_vsubj.length), s = _vsubj[si] as List, i = s[2] as int;
    final o = _pick(r, (v['o'] as List).cast<Map<String, dynamic>>());
    final np = _vNP(v, o, r.nextDouble() < .3);
    final ans = need ? _refl[i] : _nothing;
    final text = '${cap(s[0] as String)} ${_cj(v, i)} ___ ${v['p']} ${np.np}${v['sep'] != null ? ' ${v['sep']}' : ''}.';
    return _pickT(
      text,
      ans,
      _vOpts(ans, ['mich', 'dich', 'sich', 'uns', 'euch', _nothing]),
      Word.lang == 'de' ? 'wer: ${s[1]}' : '${v['ru']} · ${tl('wer', 'кто', 'who')}: ${s[1]}',
      need
          ? tl(
              'Verb <i>${v['inf']}</i>; Subjekt ${s[0]} → <b>${_refl[i]}</b>.',
              'Глагол <i>${v['inf']}</i>; подлежащее ${s[0]} → <b>${_refl[i]}</b>.',
              'Verb <i>${v['inf']}</i>; subject ${s[0]} → <b>${_refl[i]}</b>.',
            )
          : tl(
              '<i>${v['inf']}</i> — ohne sich, also nichts.',
              '<i>${v['inf']}</i> — без sich, поэтому ничего не нужно.',
              '<i>${v['inf']}</i> — no sich, so nothing is needed.',
            ),
      'v:r:${need ? _refl[i] : 'no'}',
      _vSent(v, si, '${v['p']} ${np.np}'),
      an: _analysis(v, si, o, np),
    );
  },
  'prep': (r) {
    final v = _pick(r, _vp);
    final si = r.nextInt(_vsubj.length);
    final o = _pick(r, (v['o'] as List).cast<Map<String, dynamic>>());
    final np = _vNP(v, o, r.nextDouble() < .4);
    return _pickT(
      _vSent(v, si, '___ ${np.np}'),
      v['p'] as String,
      _vOpts(v['p'] as String, ['auf', 'über', 'an', 'um', 'für', 'mit', 'von']),
      '${v['ru']} (${o['ru']})',
      '<i>${v['inf']} + ${v['c'] == 'akk' ? 'Akk' : 'Dat'}</i>${_mean(v['ru'])}.',
      'v:p:${v['id']}',
      _vSent(v, si, '${v['p']} ${np.np}'),
      an: _analysis(v, si, o, np),
    );
  },
  'fu': (r) {
    final auf = r.nextBool();
    final v = _vpm(auf ? 'fauf' : 'fueb');
    final si = r.nextInt(_vsubj.length);
    final o = r.nextDouble() < .3
        ? {'g': 'n', 'n': 'Geschenk', 'ru': tl('das Geschenk', 'подарок', 'present')}
        : _pick(r, (v['o'] as List).cast<Map<String, dynamic>>());
    final np = _vNP(v, o, r.nextDouble() < .3);
    return _pickT(
      _vSent(v, si, '___ ${np.np}'),
      v['p'] as String,
      shuffled(['auf', 'über']),
      auf
          ? tl('${o['ru']} kommt noch', 'с радостью жду (${o['ru']} ещё впереди)', 'looking forward (${o['ru']} is still to come)')
          : tl('${o['ru']} ist schon da', 'рад (${o['ru']} уже есть)', 'happy (${o['ru']} is already here)'),
      auf
          ? tl(
              '<b>freuen auf</b> — was noch kommt: Ich freue mich auf das Geschenk.',
              '<b>freuen auf</b> — то, что ещё будет: Ich freue mich auf das Geschenk — жду подарка.',
              '<b>freuen auf</b> — something still to come: Ich freue mich auf das Geschenk.',
            )
          : tl(
              '<b>freuen über</b> — was schon da ist: Ich freue mich über das Geschenk.',
              '<b>freuen über</b> — то, что уже есть: Ich freue mich über das Geschenk — рад подарку.',
              '<b>freuen über</b> — something you already have: Ich freue mich über das Geschenk.',
            ),
      'v:fu',
      _vSent(v, si, '${v['p']} ${np.np}'),
      an: _analysis(v, si, o, np),
    );
  },
  'art': (r) {
    final x = r.nextDouble();
    final si = r.nextInt(_vsubj.length);
    if (x < .15) {
      final v0 = _pick(r, _vp.where((v) => v['pl'] == 1).toList());
      final pl = _pick(r, _lst('VPL'));
      return Task(
        'type',
        text: _vSent(v0, si, '${v0['p']} ___'),
        answers: [pl[1] as String],
        cue: '(${pl[0]}${_mean(pl[2])}) · ${tl('schreib Artikel und Wort', 'напишите артикль и слово', 'write the article and the word')}',
        why:
            '<i>${v0['inf']} + Dat</i>. ${tl('Dativ Plural', 'Мн. ч. в Dativ', 'Dativ plural')}: die → <b>den</b>, ${(pl[0] as String).endsWith('n') ? tl('das Wort endet schon auf -n: ', 'слово уже оканчивается на -n: ', 'the word already ends in -n: ') : tl('das Wort bekommt -n: ', 'а слово получает -n: ', 'the word gets -n: ')}${pl[1]}.',
        key: 'v:a:dat:pl',
        full: _vSent(v0, si, '${v0['p']} ${pl[1]}'),
      );
    }
    if (x < .35) {
      final v1 = _pick(r, _vp.where((v) => v['pp'] == 1).toList());
      final pi = r.nextInt(6);
      final ru = Word.lang == 'de'
          ? ['ich', 'du', 'er', 'sie', 'wir', 'ihr']
          : Word.lang == 'en'
          ? ['me', 'you', 'him', 'her', 'us', 'you (pl.)']
          : ['меня', 'тебя', 'его', 'её', 'нас', 'вас'];
      final ruD = Word.lang == 'ru' ? ['мной/мне', 'тобой/тебе', 'ним/нему', 'ней/ней', 'нами/нам', 'вами/вам'] : ru;
      const a = ['mich', 'dich', 'ihn', 'sie', 'uns', 'euch'], d = ['mir', 'dir', 'ihm', 'ihr', 'uns', 'euch'];
      final akk = v1['c'] == 'akk';
      final ans = akk ? a[pi] : d[pi];
      final si1 = pi == 0 ? 1 : 0;
      return _pickT(
        _vSent(v1, si1, '${v1['p']} ___'),
        ans,
        _vOpts(ans, [a[pi], d[pi], ...(akk ? a : d)]),
        '${v1['ru']} · ${tl(akk ? 'wen' : 'wem', 'кого', 'whom')}: ${akk ? ru[pi] : ruD[pi]}',
        '<i>${v1['inf']} + ${akk ? 'Akk' : 'Dat'}</i> → <b>$ans</b>${akk ? ' (auf dich, für mich)' : ' (mit dir, von mir)'}.',
        'v:a:pr:${v1['c']}',
        _vSent(v1, si1, '${v1['p']} $ans'),
      );
    }
    final v = _pick(r, _vp);
    final o = _pick(r, (v['o'] as List).cast<Map<String, dynamic>>());
    final np = _vNP(v, o, r.nextDouble() < .45);
    final pool = np.ind ? ['einen', 'einem', 'einer', 'ein', 'eine'] : ['den', 'dem', 'der', 'das', 'die'];
    return _pickT(
      _vSent(v, si, '${v['p']} ___ ${o['n']}'),
      np.art,
      _vOpts(np.art, pool),
      '(${np.base}${_mean(o['ru'])}) · ${np.ind ? tl('unbestimmter Artikel', 'неопределённый артикль', 'indefinite article') : tl('bestimmter Artikel', 'определённый артикль', 'definite article')}',
      '<i>${v['inf']} + ${v['c'] == 'akk' ? 'Akk' : 'Dat'}</i>; ${np.base} → <b>${np.np}</b>.',
      'v:a:${v['c']}:${o['g']}${np.ind ? 'i' : ''}',
      _vSent(v, si, '${v['p']} ${np.np}'),
      an: _analysis(v, si, o, np),
    );
  },
  'q': (r) {
    final x = r.nextDouble();
    if (x < .12) {
      return _pickT(
        '',
        'Worum bewirbst du dich?',
        ['Worum bewirbst du dich?', 'Warum bewirbst du dich?', 'Um wen bewirbst du dich?', 'Wofür bewirbst du dich?'],
        _askMarked,
        tl(
          '<b>worum</b> = wo + um: um was? <b>warum</b> — aus welchem Grund? Ähnlich, aber verschiedene Fragen.',
          '<b>worum</b> = wo + um: на что? <b>warum</b> — почему? Похоже, но это разные вопросы.',
          '<b>worum</b> = wo + um: about what? <b>warum</b> — why? Similar, but different questions.',
        ),
        'v:q:wr',
        'Worum bewirbst du dich?',
        html: 'Ich bewerbe mich <mark>um die Stelle</mark>.',
      );
    }
    if (x < .22) {
      return _pickT(
        '',
        'Warum bewirbst du dich?',
        ['Warum bewirbst du dich?', 'Worum bewirbst du dich?', 'Wo bewirbst du dich?', 'Woran bewirbst du dich?'],
        _askMarked,
        tl(
          'Grund (weil …) → <b>warum</b>. worum heißt „um was?“.',
          'Причина (weil …) → <b>warum</b>. А worum — «на что?».',
          'A reason (weil …) → <b>warum</b>. worum means "about what?".',
        ),
        'v:q:wr',
        'Warum bewirbst du dich?',
        html: 'Ich bewerbe mich um die Stelle, <mark>weil ich Geld brauche</mark>.',
      );
    }
    final v = _pick(r, _vp.where((v) => _things(v).isNotEmpty || v['pp'] == 1).toList());
    final person = v['pp'] == 1 && (_things(v).isEmpty || r.nextDouble() < .4);
    final p = v['p'] as String, akk = v['c'] == 'akk';
    final tail = ' ${_cj(v, 1)} du${v['r'] == 1 ? ' dich' : ''}${v['sep'] != null ? ' ${v['sep']}' : ''}?';
    final place = v['place'] != null && r.nextDouble() < .25;
    String tgt;
    _NP? np;
    Map<String, dynamic>? o;
    if (person) {
      tgt = '$p ${_pick(r, _lst('VPERS'))[0]}';
    } else {
      o = _pick<Map<String, dynamic>>(r, _things(v));
      np = _vNP(v, o, false);
      tgt = '$p ${np.np}';
    }
    final qT = cap(_wo[p]!) + tail, qP = '${cap(p)} ${akk ? 'wen' : 'wem'}$tail', qW = '${cap(p)} ${akk ? 'wem' : 'wen'}$tail';
    final qWo = 'Wo$tail', qWar = 'Warum$tail';
    final mid = place ? '<mark>${v['place']}</mark> $tgt' : '<mark>$tgt</mark>';
    final html =
        'Ich ${_cj(v, 0)}${v['r'] == 1 ? ' mich' : ''}${place ? '' : (v['place'] != null ? ' ${v['place']}' : '')} $mid${v['sep'] != null ? ' ${v['sep']}' : ''}.';
    final vowel = RegExp(r'^[aeiouäöü]').hasMatch(p);
    if (!place && r.nextDouble() < .35) {
      final qa = person ? '${cap(p)} ${akk ? 'wen' : 'wem'}' : cap(_wo[p]!);
      return Task(
        'type',
        text: '___$tail — ${cap(tgt)}.',
        answers: [qa],
        cue: person
            ? tl('Schreib das Fragewort (Person)', 'Напишите вопросительное слово (о человеке)', 'Write the question word (person)')
            : tl('Schreib das Fragewort (Sache)', 'Напишите вопросительное слово (о предмете)', 'Write the question word (thing)'),
        why: person ? _qPerson(akk, akk ? 'Akk' : 'Dat') : _qThing(p, vowel),
        key: 'v:q:${person ? 'p' : 't'}',
        full: '${person ? qP : qT} — ${cap(tgt)}.',
      );
    }
    final ans = place
        ? qWo
        : person
        ? qP
        : qT;
    final pool = place
        ? [qWo, qT, qWar]
        : person
        ? [qP, qT, qW, qWar]
        : [qT, qP, qWo, qWar];
    return _pickT(
      '',
      ans,
      _vOpts(ans, pool),
      tl('Wie fragt man nach dem Markierten?', 'Как спросить о выделенном?', 'How do you ask about the marked part?'),
      place
          ? tl('Ort → <b>Wo</b>?', 'Место → <b>Wo</b>?', 'Place → <b>Wo</b>?')
          : person
          ? _qPerson(akk, _caseRu[v['c']]!)
          : _qThing(p, vowel),
      'v:q:${place
          ? 'wo'
          : person
          ? 'p'
          : 't'}',
      ans,
      html: html,
      an: o != null ? _analysis(v, 0, o, np) : '',
    );
  },
  'da': (r) {
    final v = _pick(r, _vp.where((v) => _things(v).isNotEmpty || v['pp'] == 1).toList());
    final person = v['pp'] == 1 && (_things(v).isEmpty || r.nextDouble() < .4);
    final p = v['p'] as String, akk = v['c'] == 'akk';
    final head = '${cap(_cj(v, 1))} du${v['r'] == 1 ? ' dich' : ''} $p ';
    String q, ans;
    List<String> pool;
    Map<String, dynamic>? o;
    _NP? np;
    if (person) {
      final pp = _pick(r, _lst('VPERS'));
      final g = pp[1] as String;
      final pr = (akk ? {'m': 'ihn', 'f': 'sie'} : {'m': 'ihm', 'f': 'ihr'})[g]!;
      final wr = (akk ? {'m': 'ihm', 'f': 'ihr'} : {'m': 'ihn', 'f': 'sie'})[g]!;
      q = '$head${pp[0]}${v['sep'] != null ? ' ${v['sep']}' : ''}?';
      ans = '$p $pr';
      pool = [ans, _da[p]!, '$p $wr', '$p ${g == 'm' ? (akk ? 'sie' : 'ihr') : (akk ? 'ihn' : 'ihm')}'];
    } else {
      o = _pick<Map<String, dynamic>>(r, _things(v));
      np = _vNP(v, o, false);
      q = '$head${np.np}${v['sep'] != null ? ' ${v['sep']}' : ''}?';
      ans = _da[p]!;
      final others = _da.keys.where((k) => k != p).map((k) => _da[k]!).toList();
      pool = [
        ans,
        '$p ${{'m': 'ihn', 'f': 'sie', 'n': 'es'}[o['g']]}',
        _pick(r, others),
        _pick(r, others),
      ];
    }
    final a = 'Ja, ich ${_cj(v, 0)}${v['r'] == 1 ? ' mich' : ''} ___${v['sep'] != null ? ' ${v['sep']}' : ''}.';
    final vowel = RegExp(r'^[aeiouäöü]').hasMatch(p);
    return _pickT(
      '',
      ans,
      _vOpts(ans, pool),
      person
          ? tl('Antworte kurz, ohne den Namen zu wiederholen', 'Ответьте коротко, не повторяя имя', 'Answer briefly without repeating the name')
          : tl('Antworte kurz, ohne die Sache zu wiederholen', 'Ответьте коротко, не повторяя предмет', 'Answer briefly without repeating the thing'),
      person
          ? tl(
              'Person: Präposition + Pronomen — <b>$ans</b>.',
              'О человеке: предлог + местоимение — <b>$ans</b>.',
              'Person: preposition + pronoun — <b>$ans</b>.',
            )
          : tl(
                  'Die Sache ist schon genannt → da + $p = <b>$ans</b>',
                  'Предмет уже назван → da + $p = <b>$ans</b>',
                  'The thing is already named → da + $p = <b>$ans</b>',
                ) +
                '${vowel ? tl(' (vor Vokal +r)', ' (перед гласной +r)', ' (+r before a vowel)') : ''}.',
      'v:d:${person ? 'p' : 't'}',
      '$q ${a.replaceFirst('___', ans)}',
      html: '$q<br><em>${a.replaceFirst('___', '____')}</em>',
      an: o != null ? _analysis(v, 0, o, np) : '',
    );
  },
  'ord': (r) {
    final it = _pick(r, _lst('ORD'));
    final ordw = (_d['ORDW'] as Map)[it[4]] as String? ?? '';
    return Task(
      'order',
      words: shuffled((it[0] as List).cast<String>()),
      answers: [it[1] as String, ...(it[2] as List).cast<String>()],
      cue: it[3] as String,
      why: ordw,
      key: 'v:o:${it[4]}',
      full: it[1] as String,
    );
  },
  'sep': (r) {
    final all = [..._lst('SEPI'), ..._lst('PERF')];
    final it = _pick(r, all);
    final perf = _lst('PERF').contains(it);
    return _pickT(
      '',
      it[1] as String,
      [it[1] as String, ...(it[2] as List).cast<String>()],
      _pickRight,
      it[3] as String,
      'v:s:${perf ? 'pf' : 'pr'}',
      it[1] as String,
      html: _em(it[0]),
    );
  },
  'gift': (r) {
    final x = r.nextDouble();
    final rr = _pick(r, _lst('GREC')), gf = _pick(r, _lst('GGIFT'));
    final full = 'Ich schenke ${rr[2]} ${gf[2]}.';
    if (x < .3) {
      final w = _pick(r, _lst('WUN'));
      return _pickT(
        w[0] as String,
        w[2] as String,
        _vOpts(w[2] as String, ['dir', 'dich', 'euch', 'Ihnen', 'Sie', 'ihm', 'ihn', 'ihr']),
        '${tl('wem', 'кому', 'to whom')}: ${w[1]}',
        tl(
          'wünschen <b>wem?</b> → Dativ: du — dir, ihr — euch, Sie — Ihnen, er — ihm, sie — ihr.',
          'wünschen <b>кому?</b> → Dativ: тебе — dir, вам (друзьям) — euch, Вам — Ihnen, ему — ihm, ей — ihr.',
          'wünschen <b>to whom?</b> → Dativ: du — dir, ihr — euch, Sie — Ihnen, er — ihm, sie — ihr.',
        ),
        'v:g:w',
        (w[0] as String).replaceFirst('___', w[2] as String),
      );
    }
    if (x < .55) {
      final rec = r.nextBool();
      final giftDat = tl('wem? → Dativ', 'кому? → Dativ', 'to whom? → Dativ'), giftAkk = tl('was? → Akkusativ', 'что? → Akkusativ', 'what? → Akkusativ');
      return _pickT(
        '',
        rec ? giftDat : giftAkk,
        [giftDat, giftAkk],
        tl('Welche Rolle hat das Markierte?', 'Какая роль у выделенного?', 'What role does the marked part have?'),
        rec
            ? tl('Wem schenke ich? → ${rr[2]} (Dativ).', 'Кому дарю? → ${rr[2]} (Dativ).', 'To whom do I give it? → ${rr[2]} (Dativ).')
            : tl('Was schenke ich? → ${gf[2]} (Akkusativ).', 'Что дарю? → ${gf[2]} (Akkusativ).', 'What do I give? → ${gf[2]} (Akkusativ).'),
        'v:g:role',
        full,
        html: 'Ich schenke ${rec ? '<mark>${rr[2]}</mark> ${gf[2]}' : '${rr[2]} <mark>${gf[2]}</mark>'}.',
      );
    }
    if (x < .8) {
      final parts = (rr[2] as String).split(' ');
      final ra = parts.first;
      return _pickT(
        'Ich schenke ___ ${parts.sublist(1).join(' ')} ${gf[2]}.',
        ra,
        _vOpts(ra, ['meinem', 'meinen', 'meiner', 'mein', 'meine']),
        '${tl('wem', 'кому', 'to whom')}: ${Word.lang == 'de' ? rr[1] : '${rr[3]} (${rr[1]})'}',
        '${tl('Wem', 'Кому', 'To whom')}? → Dativ: ${rr[1]} → <b>${rr[2]}</b>.',
        'v:g:r',
        full,
      );
    }
    final gp = (gf[2] as String).split(' ');
    final ga = gp.first;
    return _pickT(
      'Ich schenke ${rr[2]} ___ ${gp.sublist(1).join(' ')}.',
      ga,
      _vOpts(ga, ['einen', 'einem', 'einer', 'ein', 'eine']),
      '${tl('was', 'что', 'what')}: ${Word.lang == 'de' ? gf[1] : '${gf[3]} (${gf[1]})'}',
      '${tl('Was', 'Что', 'What')}? → Akkusativ: ${gf[1]} → <b>${gf[2]}</b>${gf.length > 4 && '${gf[4]}'.isNotEmpty ? '. ${gf[4]}' : ''}.',
      'v:g:o',
      full,
    );
  },
  'time': (r) {
    final it = _pick(r, _lst('TIMEI'));
    final t0 = it[0] as String;
    final pool = ['am', 'im', 'zum', 'zur', 'vom', 'um', 'ab'].map((x) => t0.startsWith('___') ? cap(x) : x).toList();
    return _pickT(t0, it[1] as String, _vOpts(it[1] as String, pool), it[2] as String, it[3] as String, 'v:t', t0.replaceFirst('___', it[1] as String));
  },
  'pol': (r) {
    final it = _pick(r, _lst('POL'));
    return _pickT(
      '',
      it[1] as String,
      [it[1] as String, ...(it[2] as List).cast<String>()],
      tl('Was sagst du?', 'Как сказать по-немецки?', 'How do you say it in German?'),
      it[3] as String,
      'v:l',
      it[1] as String,
      html: _em(it[0]),
    );
  },
  'zweck': (r) {
    final x = r.nextDouble();
    final zs = _lst('ZS'), zd = _lst('ZD');
    if (x < .35) {
      if (r.nextDouble() < .45) {
        final it = _pick(r, zd);
        final rest = (it[1] as String).split(' ').sublist(1).join(' ');
        return _pickT(
          '${it[0]}, ___ $rest.',
          'damit',
          ['damit', 'um'],
          it[3] as String,
          tl(
            'Verschiedene Personen (${it[4]}) → nur <b>damit</b>; um … zu geht hier nicht.',
            'Разные лица (${it[4]}) → только <b>damit</b>; um … zu здесь нельзя.',
            'Different people (${it[4]}) → only <b>damit</b>; um … zu is not possible here.',
          ),
          'v:z:diff',
          '${it[0]}, ${it[1]}.',
        );
      }
      final s = _pick(r, zs);
      final um = r.nextBool();
      final part = (um ? s[3] : s[2]) as String;
      final tail = part.split(' ').sublist(1).join(' ');
      return _pickT(
        '${s[0]}, ___ $tail.',
        um ? 'um' : 'damit',
        ['damit', 'um'],
        s[4] as String,
        um
            ? tl(
                'Kein Subjekt, am Ende <b>zu</b> + Infinitiv → <b>um … zu</b>.',
                'Нет подлежащего, в конце <b>zu</b> + инфинитив → <b>um … zu</b>.',
                'No subject, <b>zu</b> + infinitive at the end → <b>um … zu</b>.',
              )
            : tl(
                'Mit Subjekt («${s[1]}») und Verb am Ende → <b>damit</b>.',
                'Есть подлежащее («${s[1]}») и глагол в конце → <b>damit</b>.',
                'There is a subject («${s[1]}») and the verb at the end → <b>damit</b>.',
              ),
        'v:z:${um ? 'um' : 'da'}',
        '${s[0]}, $part.',
      );
    }
    if (x < .6) {
      final s2 = _pick(r, zs);
      final ok = '${s2[0]}, ${s2[3]}.';
      final wr = _zWrongUm(s2).map((w) => '${s2[0]}, $w.').toList();
      return _pickT(
        '',
        ok,
        [ok, ...wr],
        tl('Wähle den Satz mit um … zu', 'Выберите вариант с um … zu', 'Pick the sentence with um … zu'),
        tl(
              '<b>um</b> + … + <b>zu</b> + Infinitiv ganz am Ende, ohne Subjekt',
              '<b>um</b> + … + <b>zu</b> + инфинитив в самом конце, без подлежащего',
              '<b>um</b> + … + <b>zu</b> + infinitive at the very end, no subject',
            ) +
            (s2.length > 5 && s2[5] != null
                ? tl(
                    '. Bei trennbaren Verben steht zu in der Mitte: auf<b>zu</b>stehen',
                    '. У отделяемых zu встаёт внутрь: auf<b>zu</b>stehen',
                    '. With separable verbs zu goes inside: auf<b>zu</b>stehen',
                  )
                : '') +
            '.',
        'v:z:umf',
        ok,
        html: _em(s2[4]),
      );
    }
    if (x < .8) {
      final d2 = _pick(r, zd);
      final ok2 = '${d2[0]}, ${d2[1]}.';
      final opts2 = [
        ok2,
        '${d2[0]}, ${d2[2]}.',
        '${d2[0]}, ${_zWrongDamit(d2[1] as String)}.',
        '${d2[0]}, um ${(d2[1] as String).split(' ').sublist(1).join(' ')}.',
      ];
      return _pickT(
        '',
        ok2,
        opts2,
        _pickRight,
        tl(
          'Verschiedene Personen (${d2[4]}) → <b>damit</b>, das Verb geht ans Ende.',
          'Разные лица (${d2[4]}) → <b>damit</b>, а глагол уходит в конец.',
          'Different people (${d2[4]}) → <b>damit</b>, the verb goes to the end.',
        ),
        'v:z:diff',
        ok2,
        html: _em(d2[3]),
      );
    }
    final s3 = _pick(r, zs);
    final useUm = r.nextBool();
    final goal = (useUm ? s3[3] : s3[2]) as String;
    return Task(
      'order',
      words: shuffled([s3[0] as String, ...goal.split(' ')]),
      answers: ['${s3[0]}, $goal.'],
      cue: '${s3[4]}${useUm ? ' (${tl('mit', 'с', 'with')} um … zu)' : ' (${tl('mit', 'с', 'with')} damit)'}'.trim(),
      why: useUm
          ? tl('um … <b>zu + Infinitiv</b> am Ende.', 'um … <b>zu + инфинитив</b> в конце.', 'um … <b>zu + infinitive</b> at the end.')
          : tl('damit + Subjekt … <b>Verb am Ende</b>.', 'damit + подлежащее … <b>глагол в конце</b>.', 'damit + subject … <b>verb at the end</b>.'),
      key: 'v:z:o',
      full: '${s3[0]}, $goal.',
    );
  },
};

List<String> _zWrongUm(List<dynamic> it) {
  if (it.length > 5 && it[5] is List) return (it[5] as List).cast<String>();
  final w = (it[3] as String).split(' ');
  final rest = w.sublist(1).where((x) => x != 'zu').toList();
  return [
    'um zu ${rest.join(' ')}',
    'um ${it[1]} ${w.sublist(1).join(' ')}',
    'um ${rest.sublist(0, rest.length - 1).join(' ')} zu ${rest.last} ${it[1]}',
  ].map((x) => x.replaceAll(RegExp(r'\s+'), ' ').trim()).toList();
}

String _zWrongDamit(String c) {
  final w = c.split(' ');
  final v = w.last;
  return 'damit ${w[1]} $v ${w.sublist(2, w.length - 1).join(' ')}';
}
