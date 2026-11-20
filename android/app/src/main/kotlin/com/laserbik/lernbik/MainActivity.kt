package com.laserbik.lernbik

import android.speech.tts.TextToSpeech
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.Locale

/** German text to speech for the word games (channel "lernbik/tts"). */
class MainActivity : FlutterActivity() {
    private var tts: TextToSpeech? = null
    private var ready = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "lernbik/tts").setMethodCallHandler { call, result ->
            when (call.method) {
                "init" -> {
                    if (tts != null) {
                        result.success(ready)
                        return@setMethodCallHandler
                    }
                    var answered = false
                    tts = TextToSpeech(this) { status ->
                        if (status == TextToSpeech.SUCCESS) {
                            val r = tts?.setLanguage(Locale.GERMANY) ?: TextToSpeech.LANG_NOT_SUPPORTED
                            ready = r != TextToSpeech.LANG_MISSING_DATA && r != TextToSpeech.LANG_NOT_SUPPORTED
                            tts?.setSpeechRate(0.95f)
                        }
                        if (!answered) {
                            answered = true
                            result.success(ready)
                        }
                    }
                }
                "say" -> {
                    val text = call.argument<String>("text") ?: ""
                    if (ready && text.isNotBlank()) tts?.speak(text, TextToSpeech.QUEUE_FLUSH, null, "lb")
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onDestroy() {
        tts?.shutdown()
        tts = null
        super.onDestroy()
    }
}
