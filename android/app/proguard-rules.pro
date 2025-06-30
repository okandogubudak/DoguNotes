# Add project specific ProGuard rules here.
# You can control the set of applied configuration files using the
# proguardFiles setting in build.gradle.

# For more details, see
#   http://developer.android.com/guide/developing/tools/proguard.html

# If your project uses WebView with JS, uncomment the following
# and specify the fully qualified class name to the JavaScript interface
# class:
#-keepclassmembers class fqcn.of.javascript.interface.for.webview {
#   public *;
#}

# Uncomment this to preserve the line number information for
# debugging stack traces.
#-keepattributes SourceFile,LineNumberTable

# If you keep the line number information, uncomment this to
# hide the original source file name.
#-renamesourcefileattribute SourceFile

# Keep Flutter related classes
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }
-keep class io.flutter.embedding.**  { *; }

# Keep Play Core missing classes
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }

# Keep SQLite classes
-keep class org.sqlite.** { *; }
-keep class org.sqlite.database.** { *; }

# Keep permission handler
-keep class com.baseflow.permissionhandler.** { *; }

# Keep image picker
-keep class io.flutter.plugins.imagepicker.** { *; }

# Keep file picker
-keep class com.mr.flutter.plugin.filepicker.** { *; }

# Keep audio recording
-keep class com.llfbandit.record.** { *; }

# Keep TTS
-keep class com.tundralabs.fluttertts.** { *; }

# Keep local auth
-keep class io.flutter.plugins.localauth.** { *; }

# Keep shared preferences
-keep class io.flutter.plugins.sharedpreferences.** { *; }

# Keep path provider
-keep class io.flutter.plugins.pathprovider.** { *; }

# Keep notification
-keep class com.dexterous.flutterlocalnotifications.** { *; }

# Keep share plus
-keep class dev.fluttercommunity.plus.share.** { *; }

# Keep UUID
-keep class com.github.yuriy_budiyev.** { *; }

# Keep Gson
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn sun.misc.**
-keep class com.google.gson.** { *; }
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

# Keep model classes
-keep class com.example.note.** { *; }

# Remove logging in release
-assumenosideeffects class android.util.Log {
    public static *** d(...);
    public static *** v(...);
    public static *** i(...);
} 