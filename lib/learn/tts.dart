import 'tts_io.dart' if (dart.library.js_interop) 'tts_web.dart' as impl;

/// German text to speech: the browser's voices on the web, Android TextToSpeech in the app.
abstract final class Tts {
  static Future<void> init() => impl.init();
  static bool get available => impl.available();
  static void say(String text) {
    if (text.trim().isEmpty) return;
    impl.say(text);
  }
}
