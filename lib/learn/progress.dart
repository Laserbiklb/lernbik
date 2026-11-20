import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data.dart';

/// Review intervals by box (0 … 5), as in Wortkreis.
const iv = [Duration.zero, Duration(hours: 4), Duration(days: 1), Duration(days: 3), Duration(days: 7), Duration(days: 21)];

/// Clean runs a rule needs before it counts as learned.
const runsToLearn = 5;

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
  Map<String, int> rclean = {}; // rule id → clean runs
  Map<String, int> rdue = {}; // rule id → when to repeat (ms)
  Map<String, int> best = {}; // trainer records
  Map<String, List<int>> tstat = {}; // trainer topic → [answered, right at first try]
  int rsize = 12;
  bool voice = true;

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
    'best': best,
    'rsize': rsize,
    'voice': voice,
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
    best = ints('best');
    tstat = {
      for (final e in (o['tstat'] as Map? ?? {}).entries)
        if (e.value is List && (e.value as List).length == 2) e.key as String: [((e.value as List)[0] as num).toInt(), ((e.value as List)[1] as num).toInt()],
    };
    rsize = [6, 12, 20].contains(o['rsize']) ? o['rsize'] as int : 12;
    voice = o['voice'] != false;
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
  int get learnedRules => rclean.values.where((v) => v >= runsToLearn).length;
  bool learned(String ruleId) => (rclean[ruleId] ?? 0) >= runsToLearn;

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

    List<Word> byBook(Iterable<Word> a) => a.toList()..sort((x, y) => x.o.compareTo(y.o));
    p.sort((x, y) => rank(x).compareTo(rank(y)));
    if (mode == 'rev') {
      final seen = p.where((w) => prog[w.k] != null).toList()..sort((x, y) => rank(x).compareTo(rank(y)));
      return shuffled(seen.take(n));
    }
    if (mode == 'new') {
      final fresh = byBook(p.where((w) => prog[w.k] == null));
      final learning = p.where((w) => prog[w.k] != null && prog[w.k]!.b < 2).toList()..sort((x, y) => prog[x.k]!.b.compareTo(prog[y.k]!.b));
      var o = fresh.take(n).toList();
      if (o.length < n) o.addAll(learning.take(n - o.length));
      if (o.length < n) o.addAll(p.where((w) => !o.contains(w)).take(n - o.length));
      return shuffled(o);
    }
    final due = p.where((w) => rank(w) == 0).toList();
    final nw = byBook(p.where((w) => rank(w) == 1));
    final rest = p.where((w) => rank(w) > 1).toList();
    final minNew = min(nw.length, (n / 3).ceil());
    final out = due.take(n - minNew).toList();
    out.addAll(nw.take(n - out.length));
    for (final w in due) {
      if (out.length < n && !out.contains(w)) out.add(w);
    }
    if (out.length < n) out.addAll(rest.take(n - out.length));
    return shuffled(out.take(n));
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
  /// One run of a rule's exercises. Only error-free runs count; a mistake never resets the count.
  void applyRuleRun(String ruleId, bool clean, int right) {
    if (clean) rclean[ruleId] = (rclean[ruleId] ?? 0) + 1;
    final c = min(rclean[ruleId] ?? 0, 5);
    rdue[ruleId] = DateTime.now().add(iv[c]).millisecondsSinceEpoch;
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
