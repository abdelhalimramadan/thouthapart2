# Flutter
-keep class io.flutter.** { *; }
-keep class com.google.android.material.** { *; }

# Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Google Play Core
-keep class com.google.android.play.core.** { *; }

# Keep all native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep enums
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Keep Parcelable
-keep class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator *;
}

# Your app
-keep class com.example.flutter_moblie_app.** { *; }

# Dio HTTP client
-keep class io.flutter.plugins.** { *; }

# Generic signatures are retained when class name is kept
-keepattributes Signature
-keepattributes RuntimeVisibleAnnotations

# Preserve line numbers for debugging
-keepattributes SourceFile,LineNumberTable

