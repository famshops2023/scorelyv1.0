# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.**  { *; }

# SQLite3 & Drift Native Libraries
-keep class org.sqlite.** { *; }
-keep class com.simonhmartin.** { *; }
-keep class com.tekartik.sqflite.** { *; }
-dontwarn org.sqlite.**

# Flutter Deferred Components & Play Store splitinstall
-dontwarn io.flutter.embedding.engine.deferredcomponents.**
-dontwarn com.google.android.play.core.**

# In-app Webview & Networking
-dontwarn com.google.android.gms.**
-dontwarn okhttp3.**
-dontwarn okio.**
-dontwarn sun.misc.Unsafe
