# Flutter Local Notifications ProGuard Rules
# Prevent obfuscation of flutter_local_notifications classes
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-dontwarn com.dexterous.flutterlocalnotifications.**

# Keep notification-related classes
-keep class androidx.core.app.NotificationCompat** { *; }
-keep class androidx.work.** { *; }

# Prevent R8 from removing notification resources
-keepclassmembers class **.R$* {
    public static <fields>;
}

# Keep all notification channel related classes
-keep class android.app.NotificationChannel { *; }
-keep class android.app.NotificationManager { *; }