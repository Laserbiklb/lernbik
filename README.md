# Lernbik

Hausaufgaben und Wörter für unseren VHS-Kurs. Android-App und Web-Version (für iPhone): **https://lernbik.web.app**

- **Heute**: Hinweise, Hausaufgaben mit Datum (auch Prüfungen), Kapitel A1/A2 mit dem aktuellen Kurs-Kapitel
- **Lernen**: Wörter in Runden (Artikel, Übersetzung, Hören, Paare, Buchstaben, Tippen), Wiederholen, Wörterbuch und eigene Wörter,
  Regeln pro Kapitel mit Erklärung (de/ru/en) und erzeugten Aufgaben (gelernt nach 5 Runden ohne Fehler), Trainer für Fälle, Verben, Adjektive
- **Ich**: Rangliste, Einladen, Sprache, Erinnerungen, Admin (aktuelles Kapitel, Helfer)
- Admin ist der Name `Laserbik` (`ownerNick` in `lib/store.dart`); er bestimmt Helfer.

## Wie es gebaut wird

| Was | Wo | Wann |
|---|---|---|
| Web-Version + Wortkreis | Firebase Hosting | bei jedem Push auf `main` |
| Android-APK | GitHub Releases (`lernbik.apk`) | nur wenn sich `lib/`, `android/`, `assets/` oder `pubspec` ändert |
| Erinnerungen | GitHub Actions (`remind.yml`) | alle 30 Minuten |
| Datenbank-Regeln | `firestore.rules` | bei jedem Push |

Die alte Wortkreis-Seite (`wortkreis/wortkreis.html`) bleibt unter `/wortkreis/` erreichbar.

### Lerninhalte

- `assets/learn/*.json` kommen aus Wortkreis: `node tools/extract/extract.cjs wortkreis.html wk.json assets/learn/trainers.json`,
  dann `node tools/extract/build_assets.cjs wk.json assets/learn` und **danach** `python3 tools/i18n/build.py` (deutsche und englische Regeltexte, englische Wortübersetzungen) sowie `python3 tools/i18n/trainers_build.py` (Trainer-Texte auf Deutsch und Englisch).
  Auf Deutsch gibt es keine eingebaute Wortübersetzung: Übersetzungsspiele fallen weg, Buchstaben und Tippen laufen über das Hören, dazu ein Google-Übersetzer-Knopf.
- Aufgaben-Generatoren: `lib/learn/gen_rules.dart` (Regeln), `gen_cases.dart`, `gen_verbs.dart`, `gen_adj.dart` (Trainer). Test: `flutter test`.
- Die Überschriften-Schrift Rajdhani lädt `tools/fonts.sh` (im CI automatisch).

### Secrets (Settings → Secrets → Actions)

- `ANDROID_KEYSTORE` – Signaturschlüssel, Base64
- `ANDROID_KEY_PASSWORD`
- `FIREBASE_SA` – Service-Account-JSON aus der Firebase-Konsole

### Lokal testen

```
java -jar cloud-firestore-emulator.jar --port 8080
flutter run -d chrome --dart-define=EMU=true --dart-define=SITE=http://localhost:5000
```
