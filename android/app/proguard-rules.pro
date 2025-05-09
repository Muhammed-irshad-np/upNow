# Keep the AlarmReceiver class and related classes
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
-keep class com.dexterous.flutterlocalnotifications.** { *; }

# Keep permission related classes
-keep class androidx.core.app.** { *; }
-keep class android.app.NotificationManager { *; }
-keep class android.app.NotificationChannel { *; }
-keep class android.app.PendingIntent { *; }
-keep class android.content.pm.PackageManager { *; }

# Method channel
-keep class io.flutter.plugin.common.MethodChannel { *; }
-keep class io.flutter.plugin.common.MethodChannel$* { *; }
-keep class io.flutter.plugin.common.MethodCallHandler { *; }
-keep class io.flutter.plugin.common.MethodCall { *; }
-keep class io.flutter.plugin.common.PluginRegistry { *; }

# Necessary for alarm functionality
-keep class android.app.AlarmManager { *; }
-keep class android.content.Intent { *; }
-keep class android.os.Build** { *; }
-keep class android.os.PowerManager { *; }
-keep class android.os.PowerManager$WakeLock { *; }

# Permission handler plugin
-keep class com.baseflow.permissionhandler.** { *; }

# Activity lifecycle
-keep class androidx.lifecycle.** { *; }

# Don't optimize or rename any classes - safety measures for native functionality
-keepattributes *Annotation*,Signature,InnerClasses
-dontoptimize
-dontobfuscate 