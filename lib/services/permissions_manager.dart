import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:upnow/utils/preferences_helper.dart';

class PermissionsManager {
  static const String _hasRequestedDisplayOverApps = 'has_requested_display_over_apps';
  static const String _hasRequestedBatteryOptimization = 'has_requested_battery_optimization';
  static const String _hasRequestedNotifications = 'has_requested_notifications';
  static const String _hasRequestedExactAlarm = 'has_requested_exact_alarm';

  // Check if legacy "all critical" permissions are granted (includes exact alarm)
  // Kept for backward compatibility. Prefer hasAllOptimizationPermissions() for UI flows.
  static Future<bool> hasAllCriticalPermissions() async {
    final displayOverApps = await Permission.systemAlertWindow.isGranted;
    final batteryOptimization = await Permission.ignoreBatteryOptimizations.isGranted;
    final notifications = await Permission.notification.isGranted;
    final exactAlarm = await Permission.scheduleExactAlarm.isGranted;

    return displayOverApps && batteryOptimization && notifications && exactAlarm;
  }

  // Optimization permissions (exclude exact alarm)
  static Future<bool> isOverlayGranted() async {
    return await Permission.systemAlertWindow.isGranted;
  }

  static Future<bool> isBatteryOptimizationIgnored() async {
    return await Permission.ignoreBatteryOptimizations.isGranted;
  }

  static Future<bool> isNotificationGranted() async {
    return await Permission.notification.isGranted;
  }

  static Future<Map<String, bool>> getOptimizationStatuses() async {
    return {
      'overlay': await isOverlayGranted(),
      'battery': await isBatteryOptimizationIgnored(),
      'notifications': await isNotificationGranted(),
    };
  }

  static Future<int> getOptimizationScore() async {
    final statuses = await getOptimizationStatuses();
    int score = 0;
    if (statuses['overlay'] == true) score++;
    if (statuses['battery'] == true) score++;
    if (statuses['notifications'] == true) score++;
    return score;
  }

  static Future<bool> hasAllOptimizationPermissions() async {
    return (await getOptimizationScore()) == 3;
  }

  // Check if a specific permission has been requested before
  static Future<bool> hasRequestedPermission(String permissionKey) async {
    return await PreferencesHelper.getBoolValue(permissionKey) ?? false;
  }

  // Mark a permission as requested
  static Future<void> markPermissionAsRequested(String permissionKey) async {
    await PreferencesHelper.setBoolValue(permissionKey, true);
  }

  // Request display over apps permission with explanation
  static Future<bool> requestDisplayOverApps(BuildContext context) async {
    if (await Permission.systemAlertWindow.isGranted) {
      return true;
    }

    // Mark as requested
    await markPermissionAsRequested(_hasRequestedDisplayOverApps);

    // Show explanation dialog
    bool shouldRequest = await _showPermissionDialog(
      context,
      'Display Over Apps',
      'This permission is needed for alarms to function properly, ensuring they can wake you up even when the phone is locked.',
      Icons.layers_outlined,
    );

    if (shouldRequest) {
      final status = await Permission.systemAlertWindow.request();
      return status.isGranted;
    }
    return false;
  }

  // Request battery optimization exemption with explanation
  static Future<bool> requestBatteryOptimization(BuildContext context) async {
    if (await Permission.ignoreBatteryOptimizations.isGranted) {
      return true;
    }

    // Mark as requested
    await markPermissionAsRequested(_hasRequestedBatteryOptimization);

    // Show explanation dialog
    bool shouldRequest = await _showPermissionDialog(
      context,
      'Battery Optimization',
      'Exempting the app from battery optimization ensures your alarms work reliably, even during deep sleep mode.',
      Icons.battery_charging_full,
    );

    if (shouldRequest) {
      final status = await Permission.ignoreBatteryOptimizations.request();
      return status.isGranted;
    }
    return false;
  }

  // Request notification permission with explanation
  static Future<bool> requestNotifications(BuildContext context) async {
    if (await Permission.notification.isGranted) {
      return true;
    }

    // Mark as requested
    await markPermissionAsRequested(_hasRequestedNotifications);

    // Show explanation dialog
    bool shouldRequest = await _showPermissionDialog(
      context,
      'Notifications',
      'This permission allows the app to show alarm notifications and alerts when it\'s time to wake up.',
      Icons.notifications_outlined,
    );

    if (shouldRequest) {
      final status = await Permission.notification.request();
      return status.isGranted;
    }
    return false;
  }

  // Request exact alarm permission with explanation
  static Future<bool> requestExactAlarm(BuildContext context) async {
    if (await Permission.scheduleExactAlarm.isGranted) {
      return true;
    }

    // Mark as requested
    await markPermissionAsRequested(_hasRequestedExactAlarm);

    // Show explanation dialog
    bool shouldRequest = await _showPermissionDialog(
      context,
      'Schedule Exact Alarms',
      'This permission is essential for scheduling alarms at precise times, ensuring accuracy down to the minute.',
      Icons.access_time,
    );

    if (shouldRequest) {
      final status = await Permission.scheduleExactAlarm.request();
      return status.isGranted;
    }
    return false;
  }

  // Helper method to show permission explanation dialog
  static Future<bool> _showPermissionDialog(
    BuildContext context,
    String title,
    String description,
    IconData icon,
  ) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(icon, color: Theme.of(context).primaryColor),
            const SizedBox(width: 10),
            Text(title),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              description,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            const Text(
              'You can change this later in settings.',
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Later'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Allow'),
          ),
        ],
      ),
    ) ?? false;
  }
} 