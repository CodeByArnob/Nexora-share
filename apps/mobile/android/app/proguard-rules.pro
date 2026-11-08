# Flutter Wrapper & Plugins
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# NEXORA Native Services & Components
-keep class io.github.codebyarnob.nexora_app.** { *; }
-keep class io.github.codebyarnob.nexora_app.NexoraTransferService { *; }

# SQLite & Plugins
-keep class com.tekartik.sqflite.** { *; }
-keep class org.sqlite.** { *; }
-keep class dev.fluttercommunity.plus.device_info.** { *; }
-keep class io.flutter.plugins.pathprovider.** { *; }

# Keep native methods & JNI reflection
-keepclasseswithmembernames class * {
    native <methods>;
}

# Android Models & Enums
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Play Store Split Compatibility warnings suppression
-dontwarn com.google.android.play.core.**
-dontwarn androidx.**

# MobileScanner & ML Kit Barcode Scanning
-keep class dev.steenbakker.mobile_scanner.** { *; }
-keep class com.google.mlkit.vision.barcode.** { *; }
-keep class androidx.camera.** { *; }
-dontwarn androidx.camera.**
