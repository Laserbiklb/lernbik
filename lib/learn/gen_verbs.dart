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
const _gru = {'m': 'мужской', 'f': 'женский', 'n': 'средний'};
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
    l.add('<b>Почему ${_refl[i]}?</b> Глагол <i>${v['inf']}</i>, подлежащее <i>${s[0]}</i> → ${_refl[i]}.');
  } else {
    l.add('<b>Нужно ли sich?</b> Нет: <i>${v['inf']}</i> записан в словаре без sich.');
  }
  l.add('<b>Почему ${v['p']}?</b> Сочетание учим целиком: <i>${v['inf']} + ${v['c'] == 'akk' ? 'Akk' : 'Dat'}</i> — ${v['ru']}.');
  if (o != null && np != null) {
    l.add('<b>Почему ${np.art}?</b> ${np.base} — ${_gru[o['g']]} род, после <i>${v['p']}</i> здесь ${_caseRu[v['c']]} → ${np.np}.');
  }
  if (o != null) {
    final q = o['h'] == true ? '${cap(v['p'] as String)} ${v['c'] == 'akk' ? 'wen' : 'wem'}' : cap(_wo[v['p']]!);
    l.add('<b>Как спросить?</b> $q ${_cj(v, 1)} du${v['r'] == 1 ? ' dich' : ''}${v['sep'] != null ? ' ${v['sep']}' : ''}?');
    l.add('<b>Как коротко ответить?</b> ${cap(v['p'] as String)} ${np?.np ?? ''}.');
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
    final ans = need ? _refl[i] : '— ничего';
    final text = '${cap(s[0] as String)} ${_cj(v, i)} ___ ${v['p']} ${np.np}${v['sep'] != null ? ' ${v['sep']}' : ''}.';
    return _pickT(
      text,
      ans,
      _vOpts(ans, ['mich', 'dich', 'sich', 'uns', 'euch', '— ничего']),
      '${v['ru']} · кто: ${s[1]}',
      need ? 'Глагол <i>${v['inf']}</i>; подлежащее ${s[0]} → <b>${_refl[i]}</b>.' : '<i>${v['inf']}</i> — без sich, поэтому ничего не нужно.',
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
      '<i>${v['inf']} + ${v['c'] == 'akk' ? 'Akk' : 'Dat'}</i> — ${v['ru']}.',
      'v:p:${v['id']}',
      _vSent(v, si, '${v['p']} ${np.np}'),
      an: _analysis(v, si, o, np),
    );
  },
  'fu': (r) {
    final auf = r.nextBool();
    final v = _vpm(auf ? 'fauf' : 'fueb');
    final si = r.nextInt(_vsubj.length);
    final o = r.nextDouble() < .3 ? {'g': 'n', 'n': 'Geschenk', 'ru': 'подарок'} : _pick(r, (v['o'] as List).cast<Map<String, dynamic>>());
    final np = _vNP(v, o, r.nextDouble() < .3);
    return _pickT(
      _vSent(v, si, '___ ${np.np}'),
      v['p'] as String,
      shuffled(['auf', 'über']),
      auf ? 'с радостью жду (${o['ru']} ещё впереди)' : 'рад (${o['ru']} уже есть)',
      auf
          ? '<b>freuen auf</b> — то, что ещё будет: Ich freue mich auf das Geschenk — жду подарка.'
          : '<b>freuen über</b> — то, что уже есть: Ich freue mich über das Geschenk — рад подарку.',
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
        cue: '(${pl[0]} — ${pl[2]}) · напишите артикль и слово',
        why:
            '<i>${v0['inf']} + Dat</i>. Мн. ч. в Dativ: die → <b>den</b>, ${(pl[0] as String).endsWith('n') ? 'слово уже оканчивается на -n: ' : 'а слово получает -n: '}${pl[1]}.',
        key: 'v:a:dat:pl',
        full: _vSent(v0, si, '${v0['p']} ${pl[1]}'),
      );
    }
    if (x < .35) {
      final v1 = _pick(r, _vp.where((v) => v['pp'] == 1).toList());
      final pi = r.nextInt(6);
      const ru = ['меня', 'тебя', 'его', 'её', 'нас', 'вас'], ruD = ['мной/мне', 'тобой/тебе', 'ним/нему', 'ней/ней', 'нами/нам', 'вами/вам'];
      const a = ['mich', 'dich', 'ihn', 'sie', 'uns', 'euch'], d = ['mir', 'dir', 'ihm', 'ihr', 'uns', 'euch'];
      final akk = v1['c'] == 'akk';
      final ans = akk ? a[pi] : d[pi];
      final si1 = pi == 0 ? 1 : 0;
      return _pickT(
        _vSent(v1, si1, '${v1['p']} ___'),
        ans,
        _vOpts(ans, [a[pi], d[pi], ...(akk ? a : d)]),
        '${v1['ru']} · кого: ${akk ? ru[pi] : ruD[pi]}',
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
      '(${np.base} — ${o['ru']}) · ${np.ind ? 'неопределённый' : 'определённый'} артикль',
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
        'Спросите о выделенном',
        '<b>worum</b> = wo + um: на что? <b>warum</b> — почему? Похоже, но это разные вопросы.',
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
        'Спросите о выделенном',
        'Причина (weil …) → <b>warum</b>. А worum — «на что?».',
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
        cue: 'Напишите вопросительное слово (${person ? 'о человеке' : 'о предмете'})',
        why: person
            ? 'О человеке: предлог остаётся + <b>${akk ? 'wen' : 'wem'}</b> (${akk ? 'Akk' : 'Dat'}).'
            : 'О предмете: wo + $p = <b>${_wo[p]}</b>${vowel ? ' (перед гласной +r)' : ''}.',
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
      'Как спросить о выделенном?',
      place
          ? 'Место → <b>Wo</b>?'
          : person
          ? 'О человеке: предлог остаётся + <b>${akk ? 'wen' : 'wem'}</b> (${_caseRu[v['c']]}).'
          : 'О предмете: wo + $p = <b>${_wo[p]}</b>${vowel ? ' (перед гласной +r)' : ''}.',
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
      person ? 'Ответьте коротко, не повторяя имя' : 'Ответьте коротко, не повторяя предмет',
      person
          ? 'О человеке: предлог + местоимение — <b>$ans</b>.'
          : 'Предмет уже назван → da + $p = <b>$ans</b>${vowel ? ' (перед гласной +r)' : ''}.',
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
      'Выберите правильное предложение',
      it[3] as String,
      'v:s:${perf ? 'pf' : 'pr'}',
      it[1] as String,
      html: '<em>${it[0]}</em>',
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
        'кому: ${w[1]}',
        'wünschen <b>кому?</b> → Dativ: тебе — dir, вам (друзьям) — euch, Вам — Ihnen, ему — ihm, ей — ihr.',
        'v:g:w',
        (w[0] as String).replaceFirst('___', w[2] as String),
      );
    }
    if (x < .55) {
      final rec = r.nextBool();
      return _pickT(
        '',
        rec ? 'кому? → Dativ' : 'что? → Akkusativ',
        ['кому? → Dativ', 'что? → Akkusativ'],
        'Какая роль у выделенного?',
        rec ? 'Кому дарю? → ${rr[2]} (Dativ).' : 'Что дарю? → ${gf[2]} (Akkusativ).',
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
        'кому: ${rr[3]} (${rr[1]})',
        'Кому? → Dativ: ${rr[1]} → <b>${rr[2]}</b>.',
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
      'что: ${gf[3]} (${gf[1]})',
      'Что? → Akkusativ: ${gf[1]} → <b>${gf[2]}</b>${gf.length > 4 && '${gf[4]}'.isNotEmpty ? '. ${gf[4]}' : ''}.',
      'v:g:o',
      full,
    );
  },
  'time': (r) {
    final it = _pick(r, _lst('TIMEI'));
    final t0 = it[0] as String;
    final pool = ['am', 'im', 'zum', 'zur', 'vom', 'um', 'ab'].map((x) => t0.startsWith('___') ? cap(x) : x).toList();
    return _pickT(
      t0,
      it[1] as String,
      _vOpts(it[1] as String, pool),
      it[2] as String,
      it[3] as String,
      'v:t',
      t0.replaceFirst('___', it[1] as String),
    );
  },
  'pol': (r) {
    final it = _pick(r, _lst('POL'));
    return _pickT(
      '',
      it[1] as String,
      [it[1] as String, ...(it[2] as List).cast<String>()],
      'Как сказать по-немецки?',
      it[3] as String,
      'v:l',
      it[1] as String,
      html: '<em>${it[0]}</em>',
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
          'Разные лица (${it[4]}) → только <b>damit</b>; um … zu здесь нельзя.',
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
        um ? 'Нет подлежащего, в конце <b>zu</b> + инфинитив → <b>um … zu</b>.' : 'Есть подлежащее («${s[1]}») и глагол в конце → <b>damit</b>.',
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
        'Выберите вариант с um … zu',
        '<b>um</b> + … + <b>zu</b> + инфинитив в самом конце, без подлежащего${s2.length > 5 && s2[5] != null ? '. У отделяемых zu встаёт внутрь: auf<b>zu</b>stehen' : ''}.',
        'v:z:umf',
        ok,
        html: '<em>${s2[4]}</em>',
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
        'Выберите правильное предложение',
        'Разные лица (${d2[4]}) → <b>damit</b>, а глагол уходит в конец.',
        'v:z:diff',
        ok2,
        html: '<em>${d2[3]}</em>',
      );
    }
    final s3 = _pick(r, zs);
    final useUm = r.nextBool();
    final goal = (useUm ? s3[3] : s3[2]) as String;
    return Task(
      'order',
      words: shuffled([s3[0] as String, ...goal.split(' ')]),
      answers: ['${s3[0]}, $goal.'],
      cue: '${s3[4]}${useUm ? ' (с um … zu)' : ' (с damit)'}',
      why: useUm ? 'um … <b>zu + инфинитив</b> в конце.' : 'damit + подлежащее … <b>глагол в конце</b>.',
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
