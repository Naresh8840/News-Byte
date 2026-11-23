## Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

## Dio / OkHttp
-dontwarn okhttp3.**
-dontwarn okio.**
-keep class okhttp3.** { *; }

## Google Play Core (referenced by Flutter engine)
-dontwarn com.google.android.play.core.**

## Keep model classes used by json_serializable
-keep class com.newsbyte.app.** { *; }
