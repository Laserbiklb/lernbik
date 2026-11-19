# Lernbik

Hausaufgaben und Wörter für unseren VHS-Kurs. Android-App und Web-Version (für iPhone): **https://lernbik.web.app**

- Hausaufgaben für die ganze Gruppe, eigene Häkchen, Erinnerungen
- Hinweise und Countdown bis zur Prüfung
- Wortkreis: Wörter und Grammatik aus Pluspunkt Deutsch A1/A2

## Wie es gebaut wird

| Was | Wo | Wann |
|---|---|---|
| Web-Version + Wortkreis | Firebase Hosting | bei jedem Push auf `main` |
| Android-APK | GitHub Releases (`lernbik.apk`) | nur wenn sich `lib/`, `android/` oder `pubspec` ändert |
| Erinnerungen | GitHub Actions (`remind.yml`) | alle 30 Minuten |
| Datenbank-Regeln | `firestore.rules` | bei jedem Push |

Wortkreis liegt in `wortkreis/wortkreis.html` und wird ohne neue App-Version aktualisiert.

### Secrets (Settings → Secrets → Actions)

- `ANDROID_KEYSTORE` – Signaturschlüssel, Base64
- `ANDROID_KEY_PASSWORD`
- `FIREBASE_SA` – Service-Account-JSON aus der Firebase-Konsole

### Lokal testen

```
java -jar cloud-firestore-emulator.jar --port 8080
flutter run -d chrome --dart-define=EMU=true --dart-define=SITE=http://localhost:5000
```
