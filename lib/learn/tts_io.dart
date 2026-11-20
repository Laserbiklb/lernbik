import 'package:flutter/services.dart';

const _ch = MethodChannel('lernbik/tts');
bool _ok = false;

Future<void> init() async {
  try {
    _ok = await _ch.invokeMethod<bool>('init') ?? false;
  } catch (_) {
    _ok = false;
  }
}

bool available() => _ok;

void say(String text) {
  if (!_ok) return;
  _ch.invokeMethod('say', {'text': text}).catchError((_) => null);
}
