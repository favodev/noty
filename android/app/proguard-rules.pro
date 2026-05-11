# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Firebase/Google APIs (Commonly needed, harmless if unused)
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# JSON / local data models
-keepattributes *Annotation*, Signature, InnerClasses
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# AndroidX and core
-dontwarn androidx.**
-keep class androidx.lifecycle.DefaultLifecycleObserver

# Method channel native classes
-keep class dev.favo.noty.** { *; }
