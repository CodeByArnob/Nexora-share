# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# NEXORA Native Services & Components
-keep class io.github.codebyarnob.nexora_app.** { *; }
-keep class io.github.codebyarnob.nexora_app.NexoraTransferService { *; }

# SQLite3 & native dependencies
-keep class org.sqlite.** { *; }

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Play Store Split Compatibility warnings suppression
-dontwarn com.google.android.play.core.**
-dontwarn androidx.**
