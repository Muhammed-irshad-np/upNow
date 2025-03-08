import 'dart:io';

import 'package:flutter/material.dart';
import 'package:upnow/utils/app_theme.dart';
import 'package:upnow/widgets/gradient_button.dart';
import 'package:upnow/services/alarm_service.dart';
import 'package:upnow/models/alarm_model.dart';
import 'package:upnow/database/hive_database.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:upnow/screens/alarm/alarm_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              title: 'Debug & Testing',
              children: [
                _buildSettingTile(
                  icon: Icons.alarm_add,
                  title: 'Test Alarm (2 min)',
                  subtitle: 'Create a test alarm for 2 minutes from now',
                  onTap: () => _createTestAlarm(context),
                ),
                _buildSettingTile(
                  icon: Icons.notifications_active,
                  title: 'Test Notification',
                  subtitle: 'Send an immediate test notification',
                  onTap: () => _sendTestNotification(context),
                ),
                _buildSettingTile(
                  icon: Icons.list,
                  title: 'Check Pending Alarms',
                  subtitle: 'Log all pending alarm notifications',
                  onTap: () => _checkPendingAlarms(context),
                ),
                _buildSettingTile(
                  icon: Icons.security,
                  title: 'Check Permissions',
                  subtitle: 'Check notification and alarm permissions',
                  onTap: () => _checkPermissions(context),
                ),
                _buildSettingTile(
                  icon: Icons.notification_important,
                  title: 'IMMEDIATE Notification',
                  subtitle: 'Immediate notification test (should appear instantly)',
                  onTap: () => _sendImmediateNotification(context),
                ),
                _buildSettingTile(
                  icon: Icons.timer,
                  title: '10-SECOND Delayed Notification',
                  subtitle: 'Test exact notification timing (10 seconds)',
                  onTap: () => _sendDelayedNotification(context),
                ),
                _buildSettingTile(
                  icon: Icons.bug_report,
                  title: 'DIAGNOSTIC TEST',
                  subtitle: 'Run a comprehensive test of notification system',
                  onTap: () => _runDiagnosticTest(context),
                ),
                _buildSettingTile(
                  icon: Icons.info_outline,
                  title: 'Check Notification Status',
                  subtitle: 'Detailed check of notification status and permissions',
                  onTap: () => _checkNotificationStatus(context),
                ),
                _buildSettingTile(
                  icon: Icons.battery_alert,
                  title: 'Battery Optimization',
                  subtitle: 'Check battery optimization settings',
                  onTap: () => _checkBatteryOptimization(context),
                ),
                _buildSettingTile(
                  icon: Icons.send,
                  title: 'Direct Notification',
                  subtitle: 'Send a direct notification',
                  onTap: () => _sendDirectNotification(context),
                ),
                _buildSettingTile(
                  icon: Icons.notifications_outlined,
                  title: 'Ultra-simple Notification',
                  subtitle: 'Send a simple notification',
                  onTap: () => _sendUltraSimpleNotification(context),
                ),
                _buildSettingTile(
                  icon: Icons.notifications_outlined,
                  title: 'Alarm-focused Notification',
                  subtitle: 'Send a notification focused on the alarm',
                  onTap: () => _sendAlarmFocusedNotification(context),
                ),
                SizedBox(height: 10),
                Divider(
                  color: Colors.white30,
                  thickness: 1,
                ),
                
                // ALARM DEBUGGING SECTION
                SizedBox(height: 10),
                const Text(
                  'ALARM DEBUGGING',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white70,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 10),
                
                // Add TEST ALARM (5-MIN) button
                _buildSettingTile(
                  icon: Icons.alarm_add,
                  title: 'CREATE 5-MIN TEST ALARM',
                  subtitle: 'Creates and schedules a test alarm 5 minutes from now',
                  onTap: () => AlarmScreen.createAndScheduleTestAlarm(context),
                ),
              ],
            ),
            _buildSection(
              title: 'App Settings',
              children: [
                _buildSettingTile(
                  icon: Icons.notifications_outlined,
                  title: 'Notifications',
                  subtitle: 'Manage notification settings',
                  onTap: () {},
                ),
                _buildSettingTile(
                  icon: Icons.color_lens_outlined,
                  title: 'Theme',
                  subtitle: 'Dark mode',
                  onTap: () {},
                ),
                _buildSettingTile(
                  icon: Icons.volume_up_outlined,
                  title: 'Sound',
                  subtitle: 'Alarm sounds and volume',
                  onTap: () {},
                ),
              ],
            ),
            _buildSection(
              title: 'Sleep Tracking',
              children: [
                _buildSettingTile(
                  icon: Icons.bedtime_outlined,
                  title: 'Sleep Detection',
                  subtitle: 'Sensitivity: Medium',
                  onTap: () {},
                ),
                _buildSettingTile(
                  icon: Icons.watch_outlined,
                  title: 'Sleep Schedule',
                  subtitle: 'Set your ideal sleep times',
                  onTap: () {},
                ),
                _buildSwitchTile(
                  icon: Icons.health_and_safety_outlined,
                  title: 'Sleep Reminders',
                  subtitle: 'Remind you to go to sleep',
                  value: true,
                  onChanged: (value) {},
                ),
              ],
            ),
            _buildSection(
              title: 'Alarm Settings',
              children: [
                _buildSwitchTile(
                  icon: Icons.vibration_outlined,
                  title: 'Vibration',
                  subtitle: 'Vibrate when alarm sounds',
                  value: true,
                  onChanged: (value) {},
                ),
                _buildSettingTile(
                  icon: Icons.auto_awesome_outlined,
                  title: 'Dismissal Tasks',
                  subtitle: 'Configure wake-up tasks',
                  onTap: () {},
                ),
                _buildSwitchTile(
                  icon: Icons.snooze_outlined,
                  title: 'Snooze',
                  subtitle: '5 minutes',
                  value: true,
                  onChanged: (value) {},
                ),
              ],
            ),
            _buildSection(
              title: 'App Info',
              children: [
                _buildSettingTile(
                  icon: Icons.info_outline,
                  title: 'About',
                  subtitle: 'Version 1.0.0',
                  onTap: () {},
                ),
                _buildSettingTile(
                  icon: Icons.help_outline,
                  title: 'Help & Support',
                  subtitle: 'FAQs and contact info',
                  onTap: () {},
                ),
                _buildSettingTile(
                  icon: Icons.privacy_tip_outlined,
                  title: 'Privacy Policy',
                  subtitle: 'Data usage and permissions',
                  onTap: () {},
                ),
              ],
            ),
            const SizedBox(height: 20),
            GradientButton(
              gradient: AppTheme.morningGradient,
              text: 'Reset All Settings',
              onPressed: () {
                // Show confirmation dialog
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: AppTheme.darkCardColor,
                    title: const Text(
                      'Reset Settings?',
                      style: TextStyle(color: AppTheme.textColor),
                    ),
                    content: const Text(
                      'This will reset all settings to default values. This action cannot be undone.',
                      style: TextStyle(color: AppTheme.secondaryTextColor),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          // Reset settings logic would go here
                          Navigator.pop(context);
                        },
                        child: const Text('Reset'),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
  
  static Future<void> _checkBatteryOptimization(BuildContext context) async {
    if (Platform.isAndroid) {
      final isIgnoringBatteryOptimizations = 
          await Permission.ignoreBatteryOptimizations.isGranted;
          
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppTheme.darkCardColor,
          title: const Text(
            'Battery Optimization',
            style: TextStyle(color: AppTheme.textColor),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Battery Optimization Ignored: ${isIgnoringBatteryOptimizations ? 'Yes' : 'No'}',
                style: const TextStyle(color: AppTheme.secondaryTextColor),
              ),
              const SizedBox(height: 16),
              const Text(
                'To ensure alarms work reliably, this app needs to be exempted from battery optimization.',
                style: TextStyle(color: AppTheme.primaryColor, fontSize: 12),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
            if (!isIgnoringBatteryOptimizations)
              TextButton(
                onPressed: () async {
                  await AlarmService.requestBatteryOptimizationExemption();
                  Navigator.pop(context);
                },
                child: const Text('Request Exemption'),
              ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Battery optimization check is only needed on Android'),
        ),
      );
    }
  }
  // Test functionality methods
  static Future<void> _createTestAlarm(BuildContext context) async {
    try {
      debugPrint('TEST ALARM: Starting test alarm creation...');
      
      // Get current time
      final DateTime now = DateTime.now();
      final DateTime twoMinutesLater = now.add(const Duration(minutes: 2));
      
      debugPrint('TEST ALARM: Current time: ${now.toString()}');
      debugPrint('TEST ALARM: Target time: ${twoMinutesLater.toString()}');
      
      // Create test alarm for 2 minutes from now
      final alarm = AlarmModel(
        hour: twoMinutesLater.hour,
        minute: twoMinutesLater.minute,
        isEnabled: true,
        label: '⚠️ TEST ALARM - 2MIN ⚠️',
        dismissType: DismissType.normal,
        vibrate: true,
        repeat: AlarmRepeat.once,
      );
      
      // Save alarm to database first
      await HiveDatabase.saveAlarm(alarm);
      debugPrint('TEST ALARM: Saved to database with ID: ${alarm.id}');
      
      // Schedule the alarm using the service
      await AlarmService.scheduleAlarm(alarm);
      
      // ALSO schedule a direct test notification using the working 10-second method
      // to have a backup approach
      await _scheduleDirectTestAlarm(twoMinutesLater);
      
      // Verify the alarm was scheduled by checking pending notifications
      final FlutterLocalNotificationsPlugin notifications = FlutterLocalNotificationsPlugin();
      final pending = await notifications.pendingNotificationRequests();
      debugPrint('TEST ALARM: Pending notifications after scheduling: ${pending.length}');
      for (final p in pending) {
        debugPrint('TEST ALARM: Pending notification: ${p.id} - ${p.title}');
      }
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Test alarm scheduled for ${twoMinutesLater.hour}:${twoMinutesLater.minute} using two methods'),
          backgroundColor: Colors.green,
        ),
      );
      
      debugPrint('TEST ALARM: Successfully scheduled test alarm for ${twoMinutesLater.toString()}');
    } catch (e, stackTrace) {
      // Show error message with stack trace for better debugging
      debugPrint('TEST ALARM ERROR: $e');
      debugPrint('TEST ALARM STACK TRACE: $stackTrace');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  // Add a direct scheduling method that uses the same approach as the working 10-second test
  static Future<void> _scheduleDirectTestAlarm(DateTime targetTime) async {
    final FlutterLocalNotificationsPlugin notifications = FlutterLocalNotificationsPlugin();
    
    // Use the exact same notification details as our working 10-second test
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'test_channel',  
      'Test Notifications',
      channelDescription: 'Channel for test notifications',
      importance: Importance.max,
      priority: Priority.max,
      sound: RawResourceAndroidNotificationSound('alarm_sound'),
      playSound: true,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
      visibility: NotificationVisibility.public,
    );
    
    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
    
    // Convert to timezone format
    final tz.TZDateTime tzTime = tz.TZDateTime.from(targetTime, tz.local);
    
    // Create a unique ID - different from the one used by the service
    final int directNotificationId = (DateTime.now().millisecondsSinceEpoch % 100000) + 200000;
    
    // Schedule directly
    debugPrint('TEST ALARM: Scheduling direct backup notification with ID: $directNotificationId for time: ${tzTime.toString()}');
    
    await notifications.zonedSchedule(
      directNotificationId,
      '⚠️ DIRECT BACKUP TEST ALARM ⚠️',
      'This is a direct backup alarm scheduled for ${targetTime.hour}:${targetTime.minute}',
      tzTime,
      platformDetails,
      androidScheduleMode: AndroidScheduleMode.exact,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
    
    debugPrint('TEST ALARM: Direct backup alarm scheduled successfully');
  }
  
  static Future<void> _sendTestNotification(BuildContext context) async {
    try {
      // Get the notifications plugin
      final FlutterLocalNotificationsPlugin notifications = FlutterLocalNotificationsPlugin();
      
      // Create android notification details
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'test_channel',
        'Test Notifications',
        channelDescription: 'Channel for test notifications',
        importance: Importance.max,
        priority: Priority.high,
        sound: RawResourceAndroidNotificationSound('alarm_sound'),
        playSound: true,
      );
      
      // Create iOS notification details
      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
      
      // Combine platform-specific details
      const NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );
      
      // Show the notification immediately
      await notifications.show(
        999, // Unique ID for test notification
        'Test Notification',
        'This is a test notification to verify notifications are working',
        platformDetails,
      );
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Test notification sent'),
          backgroundColor: Colors.green,
        ),
      );
      
      debugPrint('TEST NOTIFICATION: Sent immediately');
    } catch (e) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sending test notification: $e'),
          backgroundColor: Colors.red,
        ),
      );
      debugPrint('TEST NOTIFICATION ERROR: $e');
    }
  }
  
  static Future<void> _checkPendingAlarms(BuildContext context) async {
    try {
      // Get the notifications plugin
      final FlutterLocalNotificationsPlugin notifications = FlutterLocalNotificationsPlugin();
      
      // Get pending notification requests (scheduled alarms)
      final List<PendingNotificationRequest> pendingNotifications = 
          await notifications.pendingNotificationRequests();
      
      // Log the pending notifications
      debugPrint('PENDING ALARMS: Found ${pendingNotifications.length} scheduled notifications');
      
      for (final notification in pendingNotifications) {
        debugPrint('  - ID: ${notification.id}, Title: ${notification.title}, Body: ${notification.body}');
      }
      
      // Show result message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Found ${pendingNotifications.length} pending alarms - check logs for details'),
          backgroundColor: Colors.blue,
        ),
      );
    } catch (e) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error checking pending alarms: $e'),
          backgroundColor: Colors.red,
        ),
      );
      debugPrint('CHECK PENDING ALARMS ERROR: $e');
    }
  }

  static Future<void> _checkPermissions(BuildContext context) async {
    try {
      // Check the permissions
      final hasNotification = await Permission.notification.status;
      final hasExactAlarm = await Permission.scheduleExactAlarm.status;
      
      // Log the permission status
      debugPrint('PERMISSIONS: Notification: $hasNotification, Exact Alarm: $hasExactAlarm');
      
      // Show a dialog with the permission status
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppTheme.darkCardColor,
          title: const Text(
            'Permission Status',
            style: TextStyle(color: AppTheme.textColor),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Notification: ${hasNotification.toString()}',
                style: const TextStyle(color: AppTheme.secondaryTextColor),
              ),
              const SizedBox(height: 8),
              Text(
                'Exact Alarms: ${hasExactAlarm.toString()}',
                style: const TextStyle(color: AppTheme.secondaryTextColor),
              ),
              const SizedBox(height: 16),
              const Text(
                'For alarms to work properly, both permissions should be granted.',
                style: TextStyle(color: AppTheme.primaryColor, fontSize: 12),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
            TextButton(
              onPressed: () async {
                // Request permissions again
                await AlarmService.requestPermissions();
                Navigator.pop(context);
                
                // Show a snackbar
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Permissions requested'),
                    backgroundColor: Colors.blue,
                  ),
                );
              },
              child: const Text('Request Permissions'),
            ),
          ],
        ),
      );
    } catch (e) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error checking permissions: $e'),
          backgroundColor: Colors.red,
        ),
      );
      debugPrint('CHECK PERMISSIONS ERROR: $e');
    }
  }

  static Future<void> _sendImmediateNotification(BuildContext context) async {
    try {
      // Get the notifications plugin
      final FlutterLocalNotificationsPlugin notifications = FlutterLocalNotificationsPlugin();
      
      // Create android notification details with maximum possible settings
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'immediate_channel',
        'Immediate Test',
        channelDescription: 'Channel for immediate test notifications',
        importance: Importance.max,
        priority: Priority.max,
        sound: RawResourceAndroidNotificationSound('alarm_sound'),
        playSound: true,
        enableVibration: true,
        enableLights: true,
        fullScreenIntent: true,
        category: AndroidNotificationCategory.alarm,
        visibility: NotificationVisibility.public,
        actions: [
          AndroidNotificationAction('test_action', 'Test Action')
        ],
      );
      
      // Create iOS notification details
      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
      
      // Combine platform-specific details
      const NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );
      
      // Get the current time for logging
      final now = DateTime.now();
      
      // Show the notification immediately
      await notifications.show(
        123, // Unique ID for this notification
        'IMMEDIATE TEST',
        'This notification should appear immediately - sent at ${now.hour}:${now.minute}:${now.second}',
        platformDetails,
      );
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Immediate notification sent at ${now.hour}:${now.minute}:${now.second}'),
          backgroundColor: Colors.green,
        ),
      );
      
      debugPrint('IMMEDIATE TEST: Notification sent at ${now.toString()}');
    } catch (e, stackTrace) {
      // Detailed error logging
      debugPrint('IMMEDIATE TEST ERROR: $e');
      debugPrint('STACK TRACE: $stackTrace');
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  static Future<void> _sendDelayedNotification(BuildContext context) async {
    try {
      // Get the notifications plugin
      final FlutterLocalNotificationsPlugin notifications = FlutterLocalNotificationsPlugin();
      
      // Create android notification details
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'test_channel',  // Use a simpler channel
        'Test Notifications',
        channelDescription: 'Channel for test notifications',
        importance: Importance.max,
        priority: Priority.max,
        sound: RawResourceAndroidNotificationSound('alarm_sound'),
        playSound: true,
        fullScreenIntent: true,
        category: AndroidNotificationCategory.alarm,
        visibility: NotificationVisibility.public,
      );
      
      const NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );
      
      // Get current timestamp
      final now = DateTime.now();
      // Schedule for 10 seconds from now - shorter time for easier testing
      final scheduledTime = now.add(const Duration(seconds: 10));
      
      // Convert to timezone format
      final tz.TZDateTime tzTime = tz.TZDateTime.from(scheduledTime, tz.local);
      
      // Log detailed scheduling info
      debugPrint('SCHEDULED TEST: Scheduling at ${now.toString()} for ${scheduledTime.toString()}');
      
      // Cancel any existing scheduled notifications first
      await notifications.cancelAll();
      
      // Create a unique ID
      final int notificationId = DateTime.now().millisecondsSinceEpoch % 100000;
      
      // Schedule notification - use standard schedule method
      await notifications.zonedSchedule(
        notificationId,
        '10-SECOND TEST NOTIFICATION',
        'This notification should appear exactly 10 seconds after scheduling',
        tzTime,
        platformDetails,
        // Use standard exact mode - more reliable in testing
        androidScheduleMode: AndroidScheduleMode.exact,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Test notification scheduled for ${scheduledTime.hour}:${scheduledTime.minute}:${scheduledTime.second}'),
          backgroundColor: Colors.blue,
        ),
      );
      
      // Log detailed scheduling info
      debugPrint('SCHEDULED TEST: Scheduled notification for ${tzTime.toString()} with ID $notificationId');
      debugPrint('SCHEDULED TEST: Current time: ${now.toString()}');
      debugPrint('SCHEDULED TEST: Expected delivery: ${scheduledTime.toString()}');
      
      // Verify pending notifications
      final pending = await notifications.pendingNotificationRequests();
      debugPrint('SCHEDULED TEST: Number of pending notifications: ${pending.length}');
      for (final p in pending) {
        debugPrint('SCHEDULED TEST: Pending notification: ${p.id} - ${p.title}');
      }
    } catch (e, stackTrace) {
      // Detailed error logging
      debugPrint('SCHEDULED TEST ERROR: $e');
      debugPrint('STACK TRACE: $stackTrace');
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  static Future<void> _checkNotificationStatus(BuildContext context) async {
    try {
      // Get the notifications plugin
      final FlutterLocalNotificationsPlugin notifications = FlutterLocalNotificationsPlugin();
      
      // Check if app is allowed to show notifications
      final AndroidFlutterLocalNotificationsPlugin? androidPlugin = 
          notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      
      String statusMsg = '';
      
      if (androidPlugin != null) {
        // Check notification permission
        final bool? areNotificationsEnabled = await androidPlugin.areNotificationsEnabled();
        statusMsg += 'Notifications Enabled: $areNotificationsEnabled\n';
        
        // Check exact alarms permission
        final status = await Permission.scheduleExactAlarm.status;
        statusMsg += 'Exact Alarms Permission: $status\n';
        
        // Check battery optimization
        final batteryStatus = await Permission.ignoreBatteryOptimizations.status;
        statusMsg += 'Battery Optimization Ignored: $batteryStatus\n';
        
        // Try to create all channels again
        await _createAllChannels();
        statusMsg += 'Created all notification channels\n';
        
        // Log to console
        debugPrint('NOTIFICATION STATUS: $statusMsg');
        
        // Show dialog with status
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Notification Status'),
            content: Text(statusMsg),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
              TextButton(
                onPressed: () async {
                  await AlarmService.requestPermissions();
                  Navigator.pop(context);
                },
                child: const Text('Request All Permissions'),
              ),
            ],
          ),
        );
      } else {
        debugPrint('Android plugin is null - this should not happen on an Android device');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: Could not get Android notification plugin'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error checking notification status: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  static Future<void> _createAllChannels() async {
    final FlutterLocalNotificationsPlugin notifications = FlutterLocalNotificationsPlugin();
    final AndroidFlutterLocalNotificationsPlugin? androidPlugin = 
        notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidPlugin != null) {
      // Create all our notification channels
      const List<AndroidNotificationChannel> channels = [
        AndroidNotificationChannel(
          'alarm_channel',
          'Alarm Notifications',
          description: 'Channel for alarm notifications',
          importance: Importance.max,
          sound: RawResourceAndroidNotificationSound('alarm_sound'),
          enableVibration: true,
          playSound: true,
          enableLights: true,
        ),
        AndroidNotificationChannel(
          'test_channel',
          'Test Notifications',
          description: 'Channel for test notifications',
          importance: Importance.max,
          sound: RawResourceAndroidNotificationSound('alarm_sound'),
          enableVibration: true,
          playSound: true,
          enableLights: true,
        ),
        AndroidNotificationChannel(
          'immediate_channel',
          'Immediate Test',
          description: 'Channel for immediate test notifications',
          importance: Importance.max,
          sound: RawResourceAndroidNotificationSound('alarm_sound'),
          enableVibration: true,
          playSound: true,
          enableLights: true,
        ),
      ];
      
      // Create each channel
      for (final channel in channels) {
        await androidPlugin.createNotificationChannel(channel);
      }
      
      debugPrint('Successfully created all notification channels');
    }
  }

  static Future<void> _sendDirectNotification(BuildContext context) async {
    try {
      final success = await AlarmService.testDirectNotification();
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success 
              ? 'Direct notification sent successfully' 
              : 'Failed to send direct notification'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    } catch (e) {
      debugPrint('Error sending direct notification: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  static Future<void> _sendUltraSimpleNotification(BuildContext context) async {
    try {
      final success = await AlarmService.testSimpleNotification();
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success 
              ? 'Ultra-simple notification sent successfully' 
              : 'Failed to send ultra-simple notification'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    } catch (e) {
      debugPrint('Error sending ultra-simple notification: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  static Future<void> _sendAlarmFocusedNotification(BuildContext context) async {
    try {
      final success = await AlarmService.testAlarmFocusedNotification();
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success 
              ? 'Alarm-focused notification sent successfully' 
              : 'Failed to send alarm-focused notification'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    } catch (e) {
      debugPrint('Error sending alarm-focused notification: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  static Future<void> _runDiagnosticTest(BuildContext context) async {
    try {
      debugPrint('DIAGNOSTIC: Starting comprehensive notification test');
      final FlutterLocalNotificationsPlugin notifications = FlutterLocalNotificationsPlugin();
      
      // Step 1: Check if we can get the Android plugin
      final AndroidFlutterLocalNotificationsPlugin? androidPlugin = 
          notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      
      if (androidPlugin == null) {
        debugPrint('DIAGNOSTIC: CRITICAL - Android plugin is null');
        _showDiagnosticResult(context, 'Android plugin not available. Are you running on Android?', false);
        return;
      }
      
      // Step 2: Check notification permissions
      final bool? areNotificationsEnabled = await androidPlugin.areNotificationsEnabled();
      debugPrint('DIAGNOSTIC: Notifications enabled: $areNotificationsEnabled');
      
      if (areNotificationsEnabled != true) {
        _showDiagnosticResult(context, 'Notifications are not enabled', false);
        return;
      }
      
      // Step 3: Check exact alarm permission
      final exactAlarmStatus = await Permission.scheduleExactAlarm.status;
      debugPrint('DIAGNOSTIC: Exact alarm permission: $exactAlarmStatus');
      
      if (exactAlarmStatus != PermissionStatus.granted) {
        _showDiagnosticResult(
          context, 
          'Exact alarm permission not granted. Current status: $exactAlarmStatus', 
          false
        );
        return;
      }
      
      // Step 4: Check battery optimization
      final batteryOptStatus = await Permission.ignoreBatteryOptimizations.status;
      debugPrint('DIAGNOSTIC: Battery optimization ignored: $batteryOptStatus');
      
      // Step 5: Check if we have any notification channels
      final pendingNotifications = await notifications.pendingNotificationRequests();
      debugPrint('DIAGNOSTIC: Number of pending notifications: ${pendingNotifications.length}');
      
      // Step 6: Test a simple immediate notification
      debugPrint('DIAGNOSTIC: Attempting to send immediate notification');
      await notifications.show(
        10001, 
        'DIAGNOSTIC TEST', 
        'This is a diagnostic test notification', 
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'test_channel',
            'Test Notifications',
            importance: Importance.max,
            priority: Priority.max,
          ),
        )
      );
      
      // Step 7: Test a scheduled notification for 5 seconds from now
      final now = DateTime.now();
      final fiveSecondsLater = now.add(const Duration(seconds: 5));
      final tzTime = tz.TZDateTime.from(fiveSecondsLater, tz.local);
      
      debugPrint('DIAGNOSTIC: Attempting to schedule notification for 5 seconds from now');
      await notifications.zonedSchedule(
        10002,
        'DIAGNOSTIC SCHEDULED',
        'This notification was scheduled 5 seconds ago',
        tzTime,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'test_channel',
            'Test Notifications',
            importance: Importance.max,
            priority: Priority.max,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exact,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
      
      // Show successful diagnostic message
      _showDiagnosticResult(
        context,
        'All diagnostic tests passed!\n\n'
        '• Notifications are enabled\n'
        '• Exact alarm permission granted\n'
        '• Battery optimization status: $batteryOptStatus\n'
        '• Immediate test notification sent\n'
        '• Scheduled notification set for 5 seconds\n\n'
        'You should see TWO notifications - one immediately and another in 5 seconds.',
        true
      );
      
    } catch (e) {
      debugPrint('DIAGNOSTIC ERROR: $e');
      _showDiagnosticResult(context, 'Diagnostic test failed: $e', false);
    }
  }
  
  static void _showDiagnosticResult(BuildContext context, String message, bool success) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: success ? Colors.green[900] : Colors.red[900],
        title: Text(
          success ? 'Diagnostic Passed' : 'Diagnostic Failed',
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          message,
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: Colors.white)),
          ),
          if (!success)
            TextButton(
              onPressed: () async {
                await AlarmService.requestPermissions();
                Navigator.pop(context);
              },
              child: const Text('Request Permissions', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
    );
  }

  Widget _buildSection({required String title, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 24, bottom: 16),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.darkCardColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: AppTheme.primaryColor,
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: AppTheme.textColor,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          color: AppTheme.secondaryTextColor,
          fontSize: 12,
        ),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: AppTheme.secondaryTextColor,
      ),
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      secondary: Icon(
        icon,
        color: AppTheme.primaryColor,
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: AppTheme.textColor,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          color: AppTheme.secondaryTextColor,
          fontSize: 12,
        ),
      ),
      value: value,
      activeColor: AppTheme.primaryColor,
      onChanged: onChanged,
    );
  }
} 