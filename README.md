# Scorely

## Google Sign-in (Android)

Google Sign-in uses the Android OAuth client for the package name and SHA-1,
and the Web OAuth client ID to request an ID token for InsForge. The Scorely
Web client ID is configured as the default, so `flutter run` works directly.
Override it for another Google Cloud environment with:

```powershell
flutter run --dart-define=GOOGLE_SERVER_CLIENT_ID=YOUR_WEB_CLIENT_ID.apps.googleusercontent.com
```

Do not commit OAuth client secrets. A client ID is public configuration; a
client secret is not needed by the Flutter app.
