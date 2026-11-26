import '../fx.dart';

import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data.dart';

/// Review intervals by box (0 … 5), as in Wortkreis.
const iv = [Duration.zero, Duration(hours: 4), Duration(days: 1), Duration(days: 3), Duration(days: 7), Duration(days: 21)];

/// A rule counts as learned from this level on (as words: box 2+ = known).
const ruleLearnedBox = 2;

/// Level name of a box (words and rules): 0–1 learning, 2–3 know, 4–5 solid.
String levelName(int b, String lang) {
  final i = b >= 4 ? 2 : (b >= 2 ? 1 : 0);
  const names = {
    'de': ['lerne', 'kann', 'sicher'],
    'ru': ['учу', 'знаю', 'закреплено'],
    'en': ['learning', 'know', 'solid'],
  };
  return (names[lang] ?? names['de']!)[i];
}

class Box {
  int b;
  int due; // ms since epoch
  Box(this.b, this.due);
  Map<String, dynamic> toJson() => {'b': b, 'due': due};
}

String dayStr(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

final _rnd = Random();
List<T> shuffled<T>(Iterable<T> it) => it.toList()..shuffle(_rnd);

/// Everything a learner has done. Kept on the phone and mirrored to Firestore (wk/{key}).
class Progress extends ChangeNotifier {
  Map<String, Box> prog = {};
  int xp = 0, streak = 0, dn = 0, ts = 0;
  String day = '';
  List<Word> own = [];

  /// Words starred in the dictionary (by key).
  Set<String> fav = {};
  Map<String, int> rclean = {}; // rule id → level 0 … 5 (old data: clean runs, capped at 5)
  Map<String, int> rdue = {}; // rule id → when to repeat (ms); set once a rule was practised

  /// Per rule, what was practised in it (e.g. "vp:sich freuen über", "a:akk:m"): -1 = last answer
  /// wrong, 1 = right once, 2 = right twice (mastered). A rule counts as learned only when every
  /// element of it is mastered ([ruleElements] says which elements a rule has).
  Map<String, Map<String, int>> rel = {};

  /// The elements of a rule (set by tasks.dart).
  static List<String> Function(String ruleId)? ruleElements;
  Map<String, int> best = {}; // trainer records
  Map<String, List<int>> tstat = {}; // trainer topic → [answered, right at first try]
  int rsize = 12;
  bool voice = true;

  /// Neon animations on/off (mirrored into [Fx.on]).
  bool get anim => Fx.on;
  set anim(bool v) => Fx.on = v;

  String _key = '';
  DocumentReference<Map<String, dynamic>>? _cloud;
  DocumentReference<Map<String, dynamic>>? _member;
  String _nick = '';
  SharedPreferences? _prefs;
  Timer? _push, _stats;

  LearnData get data => LearnData.i;
  List<Word> get allWords => [...data.words, ...own];

  // ---------- persistence ----------
  Map<String, dynamic> toJson() => {
    'v': 2,
    'prog': prog.map((k, v) => MapEntry(k, v.toJson())),
    'xp': xp,
    'streak': streak,
    'dn': dn,
    'day': day,
    'ts': ts,
    'own': [
      for (final w in own) [w.a, w.d, w.ru, w.c],
    ],
    'rclean': rclean,
    'rdue': rdue,
    'rel': rel,
    'best': best,
    'rsize': rsize,
    'voice': voice,
    'anim': anim,
    'rv': 3,
    'fav': fav.toList(),
  };

  void _fromJson(Map<String, dynamic> o) {
    prog = {};
    (o['prog'] as Map? ?? {}).forEach((k, v) {
      if (v is Map && v['b'] is num) prog[k as String] = Box((v['b'] as num).toInt(), (v['due'] as num? ?? 0).toInt());
    });
    int n(String k) => (o[k] as num? ?? 0).toInt();
    xp = n('xp');
    streak = n('streak');
    dn = n('dn');
    ts = n('ts');
    day = (o['day'] ?? '') as String;
    own = [
      for (final w in (o['own'] as List? ?? []))
        if (w is List && w.length >= 4) Word('${w[0]}', '${w[1]}', '${w[2]}', '${w[3]}', own: true),
    ];
    Map<String, int> ints(String k) => {
      for (final e in (o[k] as Map? ?? {}).entries)
        if (e.value is num) e.key as String: (e.value as num).toInt(),
    };
    rclean = ints('rclean');
    rdue = ints('rdue');
    // Before v3 clean runs piled up without spacing: those levels start again from "known".
    if (o['rv'] != 3) {
      for (final k in rclean.keys.toList()) {
        if (rclean[k]! > ruleLearnedBox) rclean[k] = ruleLearnedBox;
      }
    }
    rel = {
      for (final e in (o['rel'] as Map? ?? {}).entries)
        if (e.value is Map)
          e.key as String: {
            for (final x in (e.value as Map).entries)
              if (x.value is num) x.key as String: (x.value as num).toInt(),
          },
    };
    best = ints('best');
    tstat = {
      for (final e in (o['tstat'] as Map? ?? {}).entries)
        if (e.value is List && (e.value as List).length == 2) e.key as String: [((e.value as List)[0] as num).toInt(), ((e.value as List)[1] as num).toInt()],
    };
    rsize = [6, 12, 20].contains(o['rsize']) ? o['rsize'] as int : 12;
    voice = o['voice'] != false;
    anim = o['anim'] != false;
    fav = {for (final k in (o['fav'] as List? ?? [])) '$k'};
  }

  /// The member document of the current group (stats for the ranking); null when in no group.
  void setMember(DocumentReference<Map<String, dynamic>>? member) {
    _member = member;
    _statsSoon();
  }

  /// Load local progress for this account and start syncing.
  Future<void> attach(String key, String nick, DocumentReference<Map<String, dynamic>>? member) async {
    _prefs ??= await SharedPreferences.getInstance();
    _key = key;
    _nick = nick;
    _member = member;
    _fromJson({});
    final raw = _prefs!.getString('learn:$key');
    if (raw != null) {
      try {
        _fromJson(jsonDecode(raw) as Map<String, dynamic>);
      } catch (_) {}
    }
    notifyListeners();
    if (key.isEmpty) return;
    _cloud = FirebaseFirestore.instance.collection('wk').doc(key);
    try {
      final s = await _cloud!.get();
      final d = s.data();
      if (d != null && d['v'] == 2 && d['json'] is String && ((d['ts'] as num?) ?? 0) > ts) {
        _fromJson(jsonDecode(d['json'] as String) as Map<String, dynamic>);
        _prefs!.setString('learn:$key', jsonEncode(toJson()));
        notifyListeners();
      } else if (ts > 0) {
        _pushNow();
      }
    } catch (_) {}
    _statsSoon();
  }

  void setNick(String n) {
    _nick = n;
    _statsSoon();
  }

  void save() {
    ts = DateTime.now().millisecondsSinceEpoch;
    _prefs?.setString('learn:$_key', jsonEncode(toJson()));
    notifyListeners();
    _push?.cancel();
    _push = Timer(const Duration(seconds: 2), _pushNow);
    _statsSoon();
  }

  void _pushNow() {
    _cloud?.set({'v': 2, 'ts': ts, 'json': jsonEncode(toJson())}).catchError((_) {});
  }

  void _statsSoon() {
    _stats?.cancel();
    _stats = Timer(const Duration(milliseconds: 1500), () {
      _member
          ?.set({
            'nick': _nick,
            'words': knownWords,
            'topics': learnedRules,
            'streak': liveStreak,
            'xp': xp,
            'day': day,
            'updated': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true))
          .catchError((_) {});
    });
  }

  // ---------- numbers ----------
  int box(Word w) => prog[w.k]?.b ?? -1;
  int get knownWords => allWords.where((w) => box(w) >= 2).length;
  int get learnedRules => rclean.keys.where(learned).length;

  /// Level of a rule (0 … 5), -1 when it was never practised.
  int ruleBox(String ruleId) {
    final b = _rawBox(ruleId);
    // Not every element mastered yet: at most "learning", however many clean runs.
    return b >= ruleLearnedBox && !ruleCovered(ruleId) ? ruleLearnedBox - 1 : b;
  }

  int _rawBox(String ruleId) => rdue.containsKey(ruleId) || rclean.containsKey(ruleId) ? min(5, rclean[ruleId] ?? 0) : -1;

  /// (mastered, all) elements of a rule.
  (int, int) ruleCoverage(String ruleId) {
    final els = ruleElements?.call(ruleId) ?? const <String>[];
    final got = rel[ruleId] ?? const {};
    return (els.where((e) => (got[e] ?? 0) >= 2).length, els.length);
  }

  bool ruleCovered(String ruleId) {
    final (m, n) = ruleCoverage(ruleId);
    return m >= n;
  }

  /// Records the answers of a run: a right answer counts once per run and element. A wrong one
  /// turns the element red: a never-green element then needs two right answers again, a green one
  /// that slipped (-2) is green again after one.
  void recordElements(String ruleId, Iterable<(String, bool)> answers) {
    final got = rel[ruleId] ??= {};
    final wrong = {for (final (e, ok) in answers) if (!ok) e};
    final right = {for (final (e, ok) in answers) if (ok) e}..removeAll(wrong);
    for (final e in wrong) {
      final g = got[e] ?? 0;
      got[e] = g >= 2 || g == -2 ? -2 : -1;
    }
    for (final e in right) {
      got[e] = got[e] == -2 ? 2 : min(2, max(0, got[e] ?? 0) + 1);
    }
  }
  bool learned(String ruleId) => ruleBox(ruleId) >= ruleLearnedBox;
  bool ruleDue(String ruleId) => rdue.containsKey(ruleId) && rdue[ruleId]! <= DateTime.now().millisecondsSinceEpoch;

  /// The streak only counts if the last learning day was today or yesterday.
  int get liveStreak {
    final now = DateTime.now();
    final y = now.subtract(const Duration(days: 1));
    return day == dayStr(now) || day == dayStr(y) ? streak : 0;
  }

  int dueCount([Iterable<Word>? ws]) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return (ws ?? allWords).where((w) => prog[w.k] != null && prog[w.k]!.due <= now).length;
  }

  int get seenCount => allWords.where((w) => prog[w.k] != null).length;

  List<Word> wordsOf(String chapterId) => allWords.where((w) => w.c == chapterId).toList();

  /// Share of a chapter done: words known (box ≥ 2) and rules learned, half and half.
  double chapterDone(Chapter c) {
    final ws = wordsOf(c.id);
    final wPart = ws.isEmpty ? 1.0 : ws.where((w) => box(w) >= 2).length / ws.length;
    if (c.rules.isEmpty) return wPart;
    final rPart = c.rules.where((r) => learned(r.id)).length / c.rules.length;
    return (wPart + rPart) / 2;
  }

  void touchDay() {
    final now = DateTime.now();
    final today = dayStr(now);
    final y = dayStr(now.subtract(const Duration(days: 1)));
    if (day != today) {
      streak = day == y ? streak + 1 : 1;
      day = today;
      dn = 0;
    }
    dn++;
  }

  // ---------- word rounds ----------
  /// Picks the words for a round (Wortkreis pickBatch).
  /// mode "new": new words first, then weak ones. "rev": only seen words, due first. Otherwise mixed.
  List<Word> pickBatch(List<Word> pool, int n, String mode) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final p = shuffled(pool);
    int rank(Word w) {
      final g = prog[w.k];
      if (g == null) return 1;
      if (g.due <= now) return 0;
      return 2 + g.b;
    }

    // New words: chapter by chapter as in the book, inside a chapter the easy ones first.
    final chapterStart = <String, int>{};
    for (final w in pool) {
      chapterStart[w.c] = min(chapterStart[w.c] ?? w.o, w.o);
    }
    List<Word> byBook(Iterable<Word> a) => a.toList()
      ..sort((x, y) {
        final c = chapterStart[x.c]!.compareTo(chapterStart[y.c]!);
        if (c != 0) return c;
        final e = x.ease.compareTo(y.ease);
        return e != 0 ? e : x.o.compareTo(y.o);
      });
    p.sort((x, y) => rank(x).compareTo(rank(y)));

    // Fill up in order of priority, but never two easily confused words in one round.
    final out = <Word>[];
    void take(Iterable<Word> ws, int upTo) {
      for (final w in ws) {
        if (out.length >= upTo) return;
        if (!out.any((o) => similarWords(o, w))) out.add(w);
      }
    }

    // No other words left: fill the round up to its full size with similar ones rather than
    // starting a shorter round.
    List<Word> done(Iterable<Word> rest) {
      for (final w in rest) {
        if (out.length >= n) break;
        if (!out.contains(w)) out.add(w);
      }
      return shuffled(out);
    }

    if (mode == 'rev') {
      final seen = p.where((w) => prog[w.k] != null).toList()..sort((x, y) => rank(x).compareTo(rank(y)));
      take(seen, n);
      return done(seen);
    }
    if (mode == 'new') {
      final fresh = byBook(p.where((w) => prog[w.k] == null));
      final learning = p.where((w) => prog[w.k] != null && prog[w.k]!.b < 2).toList()..sort((x, y) => prog[x.k]!.b.compareTo(prog[y.k]!.b));
      take(fresh, n);
      take(learning, n);
      take(p, n);
      return done([...fresh, ...learning, ...p]);
    }
    final due = p.where((w) => rank(w) == 0).toList();
    final nw = byBook(p.where((w) => rank(w) == 1));
    final rest = p.where((w) => rank(w) > 1).toList();
    final minNew = min(nw.length, (n / 3).ceil());
    take(due, n - minNew);
    take(nw, n);
    take(due, n);
    take(rest, n);
    return done([...due, ...nw, ...rest]);
  }

  /// After a round: words answered without a miss go up a box, missed ones go down.
  void applyRound(Iterable<Word> answered, Set<String> missed, int right, int bonus) {
    final now = DateTime.now().millisecondsSinceEpoch;
    var n = 0;
    for (final w in answered) {
      final g = prog[w.k] ?? Box(0, 0);
      final miss = missed.contains(w.k);
      final b = miss ? max(0, g.b - 1) : min(5, g.b + 1);
      prog[w.k] = Box(b, miss ? now : now + iv[b].inMilliseconds);
      n++;
    }
    xp += right + bonus;
    if (n > 0 || right > 0) {
      touchDay();
      save();
    }
  }

  // ---------- rules ----------
  /// One run of a rule's exercises, as words: a run without mistakes moves the rule up a level and
  /// it comes back later (iv); a run with a mistake keeps the level and the rule is due again at once.
  void _ruleRun(String ruleId, bool clean) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final b0 = max(0, _rawBox(ruleId));
    final hasEls = (ruleElements?.call(ruleId) ?? const <String>[]).isNotEmpty;
    final wasDue = !rdue.containsKey(ruleId) || rdue[ruleId]! <= now;
    int b;
    if (b0 < ruleLearnedBox) {
      // Before "known": with elements, clean runs don't pile up — "known" comes exactly when
      // every element is green. Rules without elements still need clean runs.
      if (hasEls) {
        b = ruleCovered(ruleId) ? ruleLearnedBox : min(ruleLearnedBox - 1, clean ? b0 + 1 : b0);
      } else {
        b = clean ? b0 + 1 : b0;
      }
    } else {
      // Above "known" only through clean reviews once the rule is due again (spaced).
      b = clean && wasDue ? min(5, b0 + 1) : b0;
    }
    rclean[ruleId] = b;
    if (!clean) {
      rdue[ruleId] = now;
    } else if (b != b0 || wasDue) {
      rdue[ruleId] = now + iv[b].inMilliseconds;
    }
  }

  void applyRuleRun(String ruleId, bool clean, int right) {
    _ruleRun(ruleId, clean);
    xp += right;
    touchDay();
    save();
  }

  /// A review run over several rules: each rule moves on its own (clean = none of its tasks missed).
  void applyRuleReview(Map<String, bool> cleanByRule, int right) {
    cleanByRule.forEach(_ruleRun);
    xp += right;
    touchDay();
    save();
  }

  void trainerRun(String topic, int first, int total, int right) {
    final s = tstat[topic] ?? [0, 0];
    tstat[topic] = [s[0] + total, s[1] + first];
    addXp(right);
  }

  void addXp(int n) {
    xp += n;
    touchDay();
    save();
  }

  void toggleFav(String key) {
    if (!fav.remove(key)) fav.add(key);
    save();
  }

  // ---------- own words ----------
  /// "der Tisch — стол" per line. Returns (added, duplicates, unreadable).
  (int, int, int) addWords(String chapter, String text) {
    final have = {for (final w in allWords) w.k.toLowerCase()};
    var added = 0, dup = 0, bad = 0;
    for (var line in text.split('\n')) {
      line = line.trim();
      if (line.isEmpty) continue;
      final m = line.split(RegExp(r'\s*(?:—|–|=|;|\t)\s*|\s+-\s+'));
      if (m.length < 2 || m[0].isEmpty || m[1].isEmpty) {
        bad++;
        continue;
      }
      var de = m[0].trim();
      if (de.length > 60) de = de.substring(0, 60);
      var ru = m.sublist(1).join(', ').trim();
      if (ru.length > 80) ru = ru.substring(0, 80);
      var a = '';
      final am = RegExp(r'^(der|die|das)\s+(.+)$', caseSensitive: false).firstMatch(de);
      if (am != null) {
        a = am.group(1)!.toLowerCase();
        de = am.group(2)!.trim();
      }
      final k = ((a.isNotEmpty ? '$a ' : '') + de).toLowerCase();
      if (have.contains(k)) {
        dup++;
        continue;
      }
      have.add(k);
      own.add(Word(a, de, ru, chapter, own: true));
      added++;
    }
    if (added > 0) save();
    return (added, dup, bad);
  }

  void deleteOwnChapter(String chapter) {
    own.removeWhere((w) => w.c == chapter);
    save();
  }
}
