import 'dart:js_interop';

import 'package:web/web.dart' as web;

web.SpeechSynthesisVoice? _voice;

int _score(web.SpeechSynthesisVoice v) =>
    (RegExp(r'natural|online|neural', caseSensitive: false).hasMatch(v.name) ? 4 : 0) +
    (RegExp('google', caseSensitive: false).hasMatch(v.name) ? 3 : 0) +
    (RegExp(r'de[-_]DE', caseSensitive: false).hasMatch(v.lang) ? 2 : 0) +
    (v.localService ? 0 : 1);

web.SpeechSynthesisVoice? _pick() {
  try {
    final vs = web.window.speechSynthesis.getVoices().toDart.where((v) => RegExp(r'^de([-_]|$)', caseSensitive: false).hasMatch(v.lang)).toList();
    if (vs.isEmpty) return null;
    vs.sort((a, b) => _score(b) - _score(a));
    return vs.first;
  } catch (_) {
    return null;
  }
}

Future<void> init() async {
  try {
    _voice = _pick();
    web.window.speechSynthesis.addEventListener(
      'voiceschanged',
      ((web.Event _) {
        _voice = _pick();
      }).toJS,
    );
  } catch (_) {}
}

bool available() => (_voice ??= _pick()) != null;

void say(String text) {
  final v = _voice ??= _pick();
  if (v == null) return;
  try {
    final u = web.SpeechSynthesisUtterance(text);
    u.lang = 'de-DE';
    u.voice = v;
    u.rate = .95;
    web.window.speechSynthesis.cancel();
    web.window.speechSynthesis.speak(u);
  } catch (_) {}
}
