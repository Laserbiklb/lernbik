import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_options.dart';

/// The course group. Everyone who opens Lernbik lands here.
const courseGid = 'vhs-lueneburg';
const courseName = 'VHS Lüneburg';

/// "  Anna  Maria " → "anna maria". Same name → same account.
String nickId(String n) => n.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ').replaceAll('/', '_');

const _alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
String randomId(int n) {
  final r = Random.secure();
  return List.generate(n, (_) => _alphabet[r.nextInt(_alphabet.length)]).join();
}

/// "ABCDEFGHJKLMNPQR" → "LB-ABCD-EFGH-JKLM-NPQR"
String prettyCode(String key) {
  final p = <String>[];
  for (var i = 0; i < key.length; i += 4) {
    p.add(key.substring(i, min(i + 4, key.length)));
  }
  return 'LB-${p.join('-')}';
}

String? parseCode(String s) {
  var c = s.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
  if (c.startsWith('LB')) c = c.substring(2);
  if (c.length != 16) return null;
  return c;
}

/// Accepts a full link (…?g=XXXX or lernbik://join?g=XXXX) or a bare group id.
String? parseGroup(String s) {
  s = s.trim();
  final m = RegExp(r'[?&#]g=([A-Za-z0-9]{6,20})').firstMatch(s);
  if (m != null) return m.group(1);
  if (RegExp(r'^[A-Za-z0-9]{6,20}$').hasMatch(s)) return s;
  return null;
}

String ymd(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

class Hw {
  final String id, text, due, by, editedBy;
  final bool deleted;
  final DateTime? created, deletedAt;
  Hw(this.id, Map<String, dynamic> d)
      : text = (d['text'] ?? '') as String,
        due = (d['due'] ?? '') as String,
        by = (d['by'] ?? '') as String,
        editedBy = (d['editedBy'] ?? '') as String,
        deleted = d['deleted'] == true,
        created = (d['created'] as Timestamp?)?.toDate(),
        deletedAt = (d['deletedAt'] as Timestamp?)?.toDate();
}

class News {
  final String id, text, by;
  final DateTime? created;
  News(this.id, Map<String, dynamic> d)
      : text = (d['text'] ?? '') as String,
        by = (d['by'] ?? '') as String,
        created = (d['created'] as Timestamp?)?.toDate();
}

class Member {
  final String id, nick;
  final int words, topics, streak;
  Member(this.id, Map<String, dynamic> d)
      : nick = (d['nick'] ?? '') as String,
        words = (d['words'] ?? 0) as int,
        topics = (d['topics'] ?? 0) as int,
        streak = (d['streak'] ?? 0) as int;
}

class AppState extends ChangeNotifier {
  late SharedPreferences prefs;
  final db = FirebaseFirestore.instance;

  String lang = 'de';
  String key = '';
  String mid = '';
  String nick = '';
  String gid = '';
  String groupName = '';
  String examDate = '', examName = '';
  bool remindOn = true;
  List<String> remind = ['10:00', '22:00'];
  Map<String, bool> done = {};
  List<Hw> hw = [];
  List<News> news = [];
  List<Member> members = [];
  bool ready = false;
  String? pendingGroup; // group id from an opened link

  final _subs = <StreamSubscription>[];

  void notify() => notifyListeners();

  DocumentReference<Map<String, dynamic>> get userDoc => db.collection('users').doc(key);
  DocumentReference<Map<String, dynamic>> get groupDoc => db.collection('groups').doc(gid);

  Future<void> init() async {
    prefs = await SharedPreferences.getInstance();
    lang = prefs.getString('lang') ?? _deviceLang();
    key = prefs.getString('key') ?? '';
    if (!useEmulator && FirebaseAuth.instance.currentUser == null) {
      await FirebaseAuth.instance.signInAnonymously();
    }
    if (key.isNotEmpty) {
      // Show cached values at once; the snapshot below refreshes them.
      nick = prefs.getString('nick') ?? '';
      gid = prefs.getString('gid') ?? '';
      mid = prefs.getString('mid') ?? '';
      _listenUser();
      if (gid != courseGid) joinGroup(courseGid);
    }
    ready = true;
    notifyListeners();
  }

  String _deviceLang() {
    final l = PlatformDispatcher.instance.locale.languageCode;
    return l == 'ru' || l == 'uk' ? 'ru' : (l == 'en' ? 'en' : 'de');
  }

  bool get onboarded => key.isNotEmpty && nick.isNotEmpty && gid.isNotEmpty;

  void setLang(String l) {
    lang = l;
    prefs.setString('lang', l);
    if (key.isNotEmpty) userDoc.set({'lang': l}, SetOptions(merge: true));
    notifyListeners();
  }

  /// Log in by name: the same name always opens the same account.
  Future<void> login(String nickName) async {
    final n = nickName.trim();
    final ref = db.collection('nicks').doc(nickId(n));
    final snap = await ref.get();
    _cancel();
    if (snap.exists) {
      key = (snap.data()!['key'] ?? '') as String;
      final u = await userDoc.get();
      final d = u.data() ?? {};
      nick = (d['nick'] ?? n) as String;
      mid = (d['mid'] ?? randomId(10)) as String;
    } else {
      key = randomId(16);
      mid = randomId(10);
      nick = n;
      await userDoc.set({
        'nick': nick,
        'mid': mid,
        'lang': lang,
        'remind': remind,
        'remindOn': true,
        'tz': DateTime.now().timeZoneOffset.inMinutes,
        'created': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      await ref.set({'key': key, 'nick': nick});
    }
    await prefs.setString('key', key);
    await prefs.setString('nick', nick);
    await prefs.setString('mid', mid);
    _listenUser();
    await joinGroup(courseGid);
  }

  /// Log out on this phone (the account stays and opens again with the same name).
  Future<void> logout() async {
    _cancel();
    key = '';
    nick = '';
    gid = '';
    for (final k in ['key', 'nick', 'mid', 'gid']) {
      await prefs.remove(k);
    }
    notifyListeners();
  }

  /// Returns false if another account already uses this name.
  Future<bool> setNick(String n) async {
    n = n.trim();
    final ref = db.collection('nicks').doc(nickId(n));
    final snap = await ref.get();
    if (snap.exists && snap.data()!['key'] != key) return false;
    if (!snap.exists) await ref.set({'key': key, 'nick': n});
    nick = n;
    await prefs.setString('nick', nick);
    userDoc.set({'nick': nick}, SetOptions(merge: true));
    if (gid.isNotEmpty) _memberDoc().set({'nick': nick}, SetOptions(merge: true));
    notifyListeners();
    return true;
  }

  Future<String?> groupExists(String id) async {
    final s = await db.collection('groups').doc(id).get();
    return s.exists ? (s.data()?['name'] ?? '') as String : null;
  }

  Future<void> joinGroup(String id) async {
    if (id == courseGid && await groupExists(id) == null) {
      await db.collection('groups').doc(id).set({
        'name': courseName,
        'created': FieldValue.serverTimestamp(),
        'examDate': '',
        'examName': '',
      });
    }
    gid = id;
    pendingGroup = null;
    await prefs.setString('gid', gid);
    await userDoc.set({'gid': gid}, SetOptions(merge: true));
    await _memberDoc().set({'nick': nick, 'joined': FieldValue.serverTimestamp()}, SetOptions(merge: true));
    _listenGroup();
    notifyListeners();
  }

  Future<void> createGroup(String name) async {
    final id = randomId(10);
    await db.collection('groups').doc(id).set({
      'name': name.trim(),
      'created': FieldValue.serverTimestamp(),
      'examDate': '',
      'examName': '',
    });
    await joinGroup(id);
  }

  Future<void> leaveGroup() async {
    if (gid.isNotEmpty) await _memberDoc().delete().catchError((_) {});
    gid = '';
    await prefs.remove('gid');
    await userDoc.set({'gid': ''}, SetOptions(merge: true));
    _cancelGroup();
    notifyListeners();
  }

  DocumentReference<Map<String, dynamic>> _memberDoc() => groupDoc.collection('members').doc(mid);

  StreamSubscription? _userSub;
  void _listenUser() {
    _userSub?.cancel();
    _userSub = userDoc.snapshots().listen((s) {
      final d = s.data() ?? {};
      nick = (d['nick'] ?? nick) as String;
      final g = courseGid;
      if (d['mid'] is String && (d['mid'] as String).isNotEmpty) mid = d['mid'] as String;
      done = Map<String, bool>.from((d['done'] ?? {}) as Map);
      remindOn = d['remindOn'] != false;
      if (d['remind'] is List) remind = List<String>.from(d['remind'] as List);
      if (g != gid || _subs.isEmpty) {
        gid = g;
        prefs.setString('gid', gid);
        if (gid.isNotEmpty) _listenGroup();
      }
      notifyListeners();
    });
    if (gid.isNotEmpty) _listenGroup();
    userDoc.set({'tz': DateTime.now().timeZoneOffset.inMinutes, 'seen': FieldValue.serverTimestamp()},
        SetOptions(merge: true));
  }

  void _listenGroup() {
    _cancelGroup();
    if (gid.isEmpty) return;
    _subs.add(groupDoc.snapshots().listen((s) {
      final d = s.data() ?? {};
      groupName = (d['name'] ?? '') as String;
      examDate = (d['examDate'] ?? '') as String;
      examName = (d['examName'] ?? '') as String;
      notifyListeners();
    }));
    _subs.add(groupDoc.collection('hw').snapshots().listen((s) {
      hw = s.docs.map((d) => Hw(d.id, d.data())).toList();
      notifyListeners();
    }));
    _subs.add(groupDoc.collection('news').where('deleted', isEqualTo: false).snapshots().listen((s) {
      news = s.docs.map((d) => News(d.id, d.data())).toList()
        ..sort((a, b) => (b.created ?? DateTime(2100)).compareTo(a.created ?? DateTime(2100)));
      notifyListeners();
    }));
    _subs.add(groupDoc.collection('members').snapshots().listen((s) {
      members = s.docs.map((d) => Member(d.id, d.data())).toList()
        ..sort((a, b) => b.words.compareTo(a.words));
      notifyListeners();
    }));
  }

  void _cancelGroup() {
    for (final s in _subs) {
      s.cancel();
    }
    _subs.clear();
  }

  void _cancel() {
    _userSub?.cancel();
    _cancelGroup();
  }

  // ---------- homework ----------
  Future<void> addHw(String text, String due) => groupDoc.collection('hw').add({
        'text': text.trim(),
        'due': due,
        'by': nick,
        'created': FieldValue.serverTimestamp(),
        'updated': FieldValue.serverTimestamp(),
        'deleted': false,
      });

  Future<void> editHw(String id, String text, String due) => groupDoc.collection('hw').doc(id).update({
        'text': text.trim(),
        'due': due,
        'editedBy': nick,
        'updated': FieldValue.serverTimestamp(),
      });

  Future<void> setDeleted(String id, bool v) => groupDoc.collection('hw').doc(id).update({
        'deleted': v,
        'deletedAt': FieldValue.serverTimestamp(),
        'editedBy': nick,
      });

  void setDone(String id, bool v) {
    if (v) {
      done[id] = true;
    } else {
      done.remove(id);
    }
    notifyListeners();
    userDoc.set({
      'done': {id: v ? true : FieldValue.delete()}
    }, SetOptions(merge: true));
  }

  // ---------- notices and exam ----------
  Future<void> addNews(String text) => groupDoc.collection('news').add({
        'text': text.trim(),
        'by': nick,
        'created': FieldValue.serverTimestamp(),
        'deleted': false,
      });

  Future<void> setNewsDeleted(String id, bool v) => groupDoc.collection('news').doc(id).update({'deleted': v});

  Future<void> setExam(String date, String name) =>
      groupDoc.set({'examDate': date, 'examName': name.trim()}, SetOptions(merge: true));

  // ---------- reminders ----------
  void setRemind(bool on, List<String> times) {
    remindOn = on;
    remind = times..sort();
    notifyListeners();
    userDoc.set({'remindOn': on, 'remind': remind, 'tz': DateTime.now().timeZoneOffset.inMinutes},
        SetOptions(merge: true));
  }

  Future<void> saveToken(String token) => userDoc.set({
        'tokens': FieldValue.arrayUnion([token]),
        'tz': DateTime.now().timeZoneOffset.inMinutes,
      }, SetOptions(merge: true));

  Future<void> report(String text, String where) => db.collection('reports').add({
        'text': text.trim(),
        'where': where,
        'nick': nick,
        'gid': gid,
        'created': FieldValue.serverTimestamp(),
      });
}
