# Keep the AlarmReceiver class
-keep class com.example.upnow.AlarmReceiver { *; }
-keep class com.example.upnow.AlarmActivity { *; }
-keep class com.example.upnow.MainActivity { *; }

# Keep these classes' methods
-keepclassmembers class com.example.upnow.** {
    public *;
    private *;
}

# Keep any classes/methods involved with Alarms
-keep class * extends android.content.BroadcastReceiver
-keepclassmembers class * extends android.content.BroadcastReceiver {
    public <init>();
}

# Flutter local notifications plugin
-keep class com.dexterous.** { *; }

# Keep permission related classes
-keep class androidx.core.app.** { *; }
-keep class android.app.NotificationManager { *; }
-keep class android.app.NotificationChannel { *; }
-keep class android.app.PendingIntent { *; }

# Method channel
-keep class io.flutter.plugin.common.MethodChannel { *; }
-keep class io.flutter.plugin.common.MethodChannel$* { *; }
-keep class io.flutter.plugin.common.MethodCallHandler { *; }
-keep class io.flutter.plugin.common.MethodCall { *; }

# Necessary for alarm functionality
-keep class android.app.AlarmManager { *; } 